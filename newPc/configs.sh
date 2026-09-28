#!/bin/bash
set -uo pipefail

local_user="${SUDO_USER:-$(whoami)}"

export XDG_RUNTIME_DIR="/run/user/$(id -u "$local_user")"
export HOME="$(getent passwd "$local_user" | cut -d: -f6)"

export userHome="$HOME"

#########################################################################

enviromentCheck(){
    echo -e "\n\n[CHECK] "$(date "+%Y-%m-%d %H:%M:%S")" -> Function correctly sourced from "$(dirname "$0")/configs.sh"\n"
}

export -f enviromentCheck

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

export -f sysLogger


atomicWrite(){
    #### Takes the wanted filename, the path and the body and applies the `atomic write` process
    local fileName="${1:-}"
    local destination="${2:-XDG_RUNTIME_DIR}" 
    local body="${3:-}"

    if [ -z "$fileName" ]; then echo -e "Usage: atomicWrite <fileName :- aborts if none provided>\n\t<destination :- defaults to XDG_RUNTIME_DIR>\n\t<body :- defaults to NULL>"; return 1; fi

    local tempFile="${XDG_RUNTIME_DIR}/tmp_"$fileName".XXXXXX"

    local destFile=""$destination"/"$fileName""

    mktemp "$tempFile" || { sysLogger e  "Failed to create temp file "$tempFile""; return 1; }

    echo "$body" > "$tempFile" || { sysLogger e "Failed to write into "$tempFile"" ; return 1; }

    if [ -r "$tempFile" ]; then
        mv "$tempFile" "$destFile" || { sysLogger e "File created but failed to move "$tempFile" to "$destFile""; return 1; }
    else
        sysLogger e "Failed to move "$tempFile" to "$destFile""; return 1
    fi
}

export -f atomicWrite

#########################################################################

