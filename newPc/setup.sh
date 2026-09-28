#!/bin/bash
set -uo pipefail

#########################################################################
####
####    Launch platform -- the ONLY place where sudo is typed:
####        sudo ./setup.sh <script.sh>
####
####    Privilege model:
####      > setup.sh and the child script run as ROOT: no further password prompts
####      > root keeps its own HOME / environment: root tools never write into the user's home
####      > anything touching the user's home or GNOME session goes through `asUser`
####
####    Everything exported below is inherited by the child script and by any
####    script the child launches or sources directly (theme_updater.sh, dconf_manager.sh).
####    It is NOT inherited through `sudo -u` (sudo strips exported functions and resets
####    the environment): that is why `asUser` passes the session variables explicitly.
####
#########################################################################


repo="https://github.com/Fred-ITUX/newPc_Install"
runningScript="${1:-}"


#### Privilege and user checks
[ "$EUID" -eq 0 ] || { echo "[ERROR] Run with sudo: sudo $0 <script.sh>" >&2; exit 1; }

[ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ] || { echo "[ERROR] Run via sudo from your normal user, not from a root shell" >&2; exit 1; }

[[ "$SUDO_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo "[ERROR] Unsafe username: $SUDO_USER" >&2; exit 1; }

id -- "$SUDO_USER" >/dev/null 2>&1 || { echo "[ERROR] No such user: $SUDO_USER" >&2; exit 1; }

[ -n "$runningScript" ] || { echo "[ERROR] No script to execute given, exiting" >&2; exit 1; }



#########################################################################
####    Exported variables
####    Children use ONLY these to refer to the real user.
####    Never use $USER, $HOME, $SUDO_USER or $(whoami) in children: as root they resolve to root.
#########################################################################

realUser="$SUDO_USER"
realUid="$(id -u "$realUser")"
realGroup="$(id -gn "$realUser")"
userHome="$(getent passwd "$realUser" | cut -d: -f6)"
userRuntime="/run/user/$realUid"
DEBUG="${DEBUG:-false}"     #### `sudo DEBUG=true ./setup.sh ...` enables the dry-run paths

export realUser realUid realGroup userHome userRuntime DEBUG

[ -d "$userHome" ] || { echo "[ERROR] No home dir for $realUser" >&2; exit 1; }

[ -S "$userRuntime/bus" ] || echo "[WARNING] No session bus at $userRuntime/bus: gsettings / dconf / systemctl --user will fail. Run from a logged-in desktop session." >&2



#########################################################################
####    Exported functions
#########################################################################

sysLogger(){
    local logType="${1:-}"
    local logBody="${2:-}"
    local caller="${FUNCNAME[1]:-MAIN}"
    local DEBUG="${DEBUG:-false}"

    logType=$( echo "$logType" | tr '[:lower:]' '[:upper:]' )

    case "$logType" in
        W) logType="WARNING" ;;
        I) logType="INFO" ;;
        E) logType="ERROR" ;;
        D|DEBUG) if $DEBUG; then logType="DEBUG"; caller="${FUNCNAME[2]:-MAIN}"; else return 0 ; fi ;;

        *) sysLogger e "Type '$logType' is not a valid log type"; return 1 ;;
    esac

    echo -e "[$logType] {$caller} $(date "+%Y-%m-%d %H:%M:%S") -> $logBody"
}


asUser(){
    #### Runs an external command as the real user, inside their session.
    #### Use for: gsettings, dconf, flatpak --user, systemctl --user, gh, git, and ANY write under $userHome
    #### Only external commands: exported functions do not survive the user switch.
    local sessionEnv=( "XDG_RUNTIME_DIR=$userRuntime" "DBUS_SESSION_BUS_ADDRESS=unix:path=$userRuntime/bus" )
    [ -n "${DISPLAY:-}" ] && sessionEnv+=( "DISPLAY=$DISPLAY" )

    sudo -u "$realUser" -H env "${sessionEnv[@]}" "$@"
}


atomicWrite(){
    #### Writes <body> into <destination>/<fileName> atomically, owned by the real user
    local fileName="${1:-}"
    local destination="${2:-$userRuntime}"
    local body="${3:-}"
    local tempFile

    if [ -z "$fileName" ]; then echo -e "Usage: atomicWrite <fileName :- aborts if none provided>\n\t<destination :- defaults to $userRuntime>\n\t<body :- defaults to NULL>"; return 1; fi

    asUser mkdir -p "$destination" || { sysLogger e "Failed to create folder $destination"; return 1; }

    #### Temp file in the SAME folder as the target, so the final mv is an atomic rename (not a cross-filesystem copy)
    tempFile=$(asUser mktemp "$destination/.tmp_$fileName.XXXXXX") || { sysLogger e "Failed to create temp file in $destination"; return 1; }

    asUser chmod 0644 "$tempFile"

    printf '%s\n' "$body" | asUser tee "$tempFile" >/dev/null || { asUser rm -f "$tempFile"; sysLogger e "Failed to write into $tempFile"; return 1; }

    asUser mv -f "$tempFile" "$destination/$fileName" || { asUser rm -f "$tempFile"; sysLogger e "Failed to move $tempFile to $destination/$fileName"; return 1; }
}

export -f sysLogger asUser atomicWrite



#########################################################################
####    Main
#########################################################################

echo -e "\n\t > Starting $(date "+%Y-%m-%d %H:%M:%S")"
sysLogger i "\t > Real user: $realUser ($realUid:$realGroup)   Home: $userHome"


sysLogger i "Checking internet connectivity, the script will abort if the systems results offline."

timeout 10 getent hosts archive.ubuntu.com >/dev/null || { sysLogger e "No network. Aborting."; exit 1; }

sysLogger i "\nSystem online, continuing\n"


#### Install git if not already present
apt update || { sysLogger e "Apt update failed, not continuing with stale package index"; exit 1; }
apt install git -y || { sysLogger e "Git install failed. No point in keeping execution, exiting"; exit 1; }


#### Clone repo script && script exec -- the repo belongs to the user: every git call goes through asUser
repoPath="$userHome/Github/newPc_Install"
childScript="$repoPath/newPc/$runningScript"

echo -e "\n\t > Script to execute: $runningScript"


if [ -d "$repoPath" ]; then
    sysLogger w "folder $repoPath already present. \n\nChoose what to do now? \n\t'yes'\t> use it as is \n\t'no'\t> stop execution  \n\t'pull'\t> update the local folder \n\t'rm'\t> purge the current folder and re-clone\n"
    read -rp "Answer: " ans

    ans=$( printf '%s' "$ans" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]' )

    case "$ans" in

        "yes"|"y") sysLogger i "Continuing with local version" ;;
        "no"|"n") sysLogger e "Aborting execution"; exit 0 ;;

        "pull") sysLogger i "Updating local folder";
                    asUser git -C "$repoPath" pull || { sysLogger e "git failed to execute pull, exiting"; exit 1; }
                    ;;

        "rm") sysLogger i "Removing local version and cloning";
                    rm -rf "$repoPath" || { sysLogger e "failed to remove the folder $repoPath"; exit 1; }
                    asUser git clone --depth 1 "$repo" "$repoPath" || { sysLogger e "failed to clone the repo" ; exit 1; }
                    ;;

        *) sysLogger e "Not a valid option selected, exiting"; exit 1 ;;

    esac

else
    sysLogger i "Cloning $repo  ->  $repoPath"
    asUser mkdir -p "$userHome/Github" || { sysLogger e "failed to create $userHome/Github" ; exit 1; }
    asUser git clone --depth 1 "$repo" "$repoPath" || { sysLogger e "failed to clone the repo" ; exit 1; }
fi


#### Launched through `bash`: no exec bit needed, so no chmod that would dirty the git worktree and break the next `pull`
sysLogger i "Checking for script to run: $childScript"

[ -f "$childScript" ] || { sysLogger e "Script not found: $childScript" >&2; exit 1; }

sysLogger i "Script found, executing now as root (user context via asUser -> $realUser)...\n"

bash "$childScript" || { sysLogger e "$childScript terminated with an error" >&2; exit 1; }

sysLogger i "Function terminated correctly\n"