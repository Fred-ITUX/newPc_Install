#!/bin/bash

#### Privilege and user checks
[ "$EUID" -eq 0 ] || { echo "[ERROR] Run with sudo: sudo $0 <script.sh>" >&2; exit 1; }

[ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ] || { echo "[ERROR] Run via sudo from your normal user, not from a root shell" >&2; exit 1; }

[[ "$SUDO_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo "[ERROR] Unsafe username: $SUDO_USER" >&2; exit 1; }

id -- "$SUDO_USER" >/dev/null 2>&1 || { echo "[ERROR] No such user: $SUDO_USER" >&2; exit 1; }



realUser="$SUDO_USER"
realUid="$(id -u "$realUser")"
realGroup="$(id -gn "$realUser")"
userHome="$(getent passwd "$realUser" | cut -d: -f6)"
userRuntime="/run/user/$realUid"
DEBUG="${DEBUG:-false}"     #### `sudo DEBUG=true ./setup.sh ...` enables the dry-run paths

export realUser realUid realGroup userHome userRuntime DEBUG

[ -d "$userHome" ] || { echo "[ERROR] No home dir for $realUser" >&2; exit 1; }

[ -S "$userRuntime/bus" ] || echo "[WARNING] No session bus at $userRuntime/bus: kwriteconfig6 / plasma-apply-* / systemctl --user will fail. Run from a logged-in desktop session." >&2

########################################################################

get_logger_date(){ date "+%Y-%m-%d %H:%M:%S" ; } #### date "+%F %T"

sysLogger(){
    local logType="${1:-}"
    local logBody="${2:-}"
    local caller="${FUNCNAME[1]:-MAIN}"
    local DEBUG="${DEBUG:-false}"
    local color=""
    local reset=""

    #### Called through a wrapper (PID_sysLogger, *debugLogger): skip it and report the real caller
    if [[ ${FUNCNAME[1]} == PID_sysLogger || ${FUNCNAME[1]} == *debugLogger ]]; then caller="${FUNCNAME[2]:-MAIN}"; fi

    #### Syslogger gets used a lot, avoid the double fork (cannot be POSIX as is anyways)
    #### logType=$( echo "$logType" | tr '[:lower:]' '[:upper:]' )
    logType="${logType^^}"

    case "$logType" in
        W) logType="WARNING"; color='\e[33m' ;;
        I) logType="INFO";    color='\e[32m' ;;
        E) logType="ERROR";   color='\e[31m' ;;
        
        D|DEBUG) if [ "$DEBUG" == true ]; then
                     logType="DEBUG"; color='\e[36m'
                 else
                     return 0
        fi ;;


        *) echo "[ERROR] Type '$logType' is not a valid log type"; return 1 ;;
    esac

    #### Color only when stdout is a terminal; files, pipes and $(...) stay plain
    if [ -t 1 ]; then reset='\e[0m'; else color=""; fi

    echo -e "[${color}${logType}${reset}] {$caller} $(get_logger_date) -> $logBody"
}


asUser(){
    #### Runs an external command as the real user, inside their session.
    #### Use for: kwriteconfig6, plasma-apply-*, flatpak --user, systemctl --user, gh, git, and ANY write under $userHome
    #### Only external commands: exported functions do not survive the user switch.
    local sessionEnv=( "XDG_RUNTIME_DIR=$userRuntime" "DBUS_SESSION_BUS_ADDRESS=unix:path=$userRuntime/bus" )
    if [ -n "${DISPLAY:-}" ]; then sessionEnv+=( "DISPLAY=$DISPLAY" ); fi
    #### Wayland session: GUI tools need the compositor socket name too (sudo strips it, like DISPLAY)
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then sessionEnv+=( "WAYLAND_DISPLAY=$WAYLAND_DISPLAY" ); fi

    sudo -u "$realUser" -H env "${sessionEnv[@]}" "$@"
}


atomicWrite(){
    #### Same checks as bash_common.sh atomicWrite, but every step runs as the real user (setup.sh is root)
    local fileName="${1:-}"
    local destination="${2:-}"
    local body="${3:-}"
    local tempFile destFile

    if [ -z "$fileName" ] || [ -z "$destination" ] || [ -z "$body" ]; then echo -e "Usage: atomicWrite <fileName> <destination> <body>"; return 1; fi

    asUser mkdir -p "$destination" || { sysLogger e "Failed to create folder $destination"; return 1; }

    #### Temp file in the SAME folder as the target, so the final mv is an atomic rename (not a cross-filesystem copy)
    tempFile=$(asUser mktemp "$destination/.tmp_$fileName.XXXXXX") || { sysLogger e "Failed to create temp file in $destination"; return 1; }

    destFile="$destination/$fileName"

    asUser chmod 0644 "$tempFile"

    #### `echo` might be unsafe here as it would treat a body like '-n' or '-e' as an option and not print it
    printf '%s\n' "$body" | asUser tee "$tempFile" >/dev/null || { sysLogger e "Failed to write into $tempFile"; asUser rm -f "$tempFile"; return 1; }

    if [ -r "$tempFile" ]; then
        asUser mv -f "$tempFile" "$destFile" || { sysLogger e "Failed to move $tempFile to $destFile; removing temp file"; asUser rm -f "$tempFile"; return 1; }
    else
        sysLogger e "Unreadable file $tempFile"; asUser rm -f "$tempFile"; return 1
    fi
}


isLinePresent(){
    #### Checks whether a line is present in a file. Whitespace is ignored.
    #### Returns 0 = found, 1 = not found, 2 = usage/file error
    local position="${1:-}"
    local content="${2:-}"
    local file="${3:-}"
    local needle

    if [ -z "$position" ] || [ -z "$content" ] || [ -z "$file" ]; then
        echo "Usage: isLinePresent <whole|start|end|any> <content> <file>"; return 2
    fi
    if [ ! -r "$file" ]; then
        echo "isLinePresent: cannot read "$file""; return 2
    fi

    #### Remove all whitespace from the search text
    needle="$(printf '%s' "$content" | tr -d '[:space:]')"

    #### Remove all whitespace from the file's lines, then compare as plain text
    case "$position" in
        whole) sed 's/[[:space:]]//g' "$file" | grep -qxF -- "$needle" ;;
        any)   sed 's/[[:space:]]//g' "$file" | grep -qF  -- "$needle" ;;
        start) sed 's/[[:space:]]//g' "$file" | awk -v n="$needle" 'index($0, n) == 1 { f=1 } END { exit !f }' ;;
        end)   sed 's/[[:space:]]//g' "$file" | awk -v n="$needle" 'length($0) >= length(n) && substr($0, length($0) - length(n) + 1) == n { f=1 } END { exit !f }' ;;
        *) echo "Invalid position: "$position" (use whole/start/end/any)"; return 2 ;;
    esac
}



export -f get_logger_date sysLogger asUser atomicWrite isLinePresent

########################################################################
testTempErrorsLog="${userRuntime}/asUSER-TEST_error_logger.log"
if [ -f "$testTempErrorsLog" ]; then echo -n > "$testTempErrorsLog"; fi 
set -uo pipefail
exec 2> >(tee -a "$testTempErrorsLog" >&2)
DEBUG=true     ####    true     false

########################################################################

#### newPc_Scripts.sh test suite -- all the enviroment is replicated above 1:1
#### Emulate launching any script with sudo while keeping the correct user path
#### sudo "$(getent passwd "${SUDO_USER:-$(whoami)}" | cut -d: -f6)/Nextcloud/Linux/scripts/TestSuite/test.sh"
#### This script only requires sudo directly

















if [ -s "$testTempErrorsLog" ]; then echo -e "\nERRORS:\n$(cat "$testTempErrorsLog")" ; fi 