#!/bin/bash

################################################################################################

sessionType="${XDG_SESSION_TYPE:-unknown}"

DEBUG="${DEBUG:-false}" 


################################################################################################
####                            Scripts path

LXscripts="$HOME/Nextcloud/Linux/scripts"

PYscripts="$HOME/Nextcloud/Python/scripts"


####                            Logs path

LXlogs="$HOME/Nextcloud/Linux/log"

pathStartupUpdaterClean="$HOME/Nextcloud/Linux/log/startup_updater.log"

get_pathStartupUpdaterFull(){ echo "$HOME/Nextcloud/Linux/log/adv_everyday/upd_"$(get_file_date)".log"; } 

pathManualUpd="$LXlogs/manual_updater.log" 

pathROOTKIT="$LXlogs/rk_scan.log"

pathCLAMSCAN="$LXlogs/clamav_scan.log"

ufw_log_check="$LXlogs/ufw_log_check.log"

repoPushLog="$LXlogs/startup_repo_push.log"

logCheckerAlarm="$HOME/Nextcloud/Linux/Stuff/alarm.mp3"

################################################################################################





################################################################################################
####                            Bluetooth devices

#### Sony WH-CH720N
bluetoothHeadset="00:A4:1C:04:E1:1F"

#### Earbuds / in-ear other bluetooth devices -- TWS
bletoothInEar=""

#### Other bluetooth controllers
bluetoothController=""

#### Only ps5 controller
ps5Controller="24:A6:FA:8B:8A:B9"

################################################################################################


userCheck(){
    local host="$HOSTNAME"
    hostMain="federico"

    host=$(stringNormalizeLow "$host")

    case "$host" in
        federico) pc="$hostMain" ; pid_log_file="$LXlogs/pids_main.log" ;;
        federico-hp) pc="$host"; pid_log_file="$LXlogs/pids_extra.log" ;;

        *) pc="unknown"; pid_log_file="$LXlogs/pids_unknown.log" ;;
    esac 
}


get_osname(){
    source /etc/os-release
    local sourcedName="${PRETTY_NAME,,}"
    
    local o=$( stringNormalizeLow "$sourcedName" | sed 's/linux//' )
    osname=$( stringNormalizeNoBlanks "$o" )
}


get_formatted_date(){ date "+%a %b %d %Y %H:%M:%S" ; } #### python %a %b %d %Y %H:%M:%S


get_date_comparison(){ date "+%a %b %d" ; }


get_file_date(){ date "+%Y-%m-%d_%H-%M-%S" ; }    #### python %Y-%m-%d_%H-%M-%S


get_logger_date(){ date "+%Y-%m-%d %H:%M:%S" ; } #### date "+%F %T"


check_day_type(){
    dayToCheck=$(date +"%A") #### "%a" --- 3 letter day
    if [ "$dayToCheck" != "Saturday" ] && [ "$dayToCheck" != "Sunday" ]; then typeDay="weekday" ; else typeDay="weekend" ; fi 
}


##################################################

getSysInfoStart(){
userCheck
get_osname
echo -e "________________________________________________________ 
\t
Start time :  "$(get_formatted_date)"
    Running for:  $(whoami)@$osname [$pc]"
}


getSysInfoEnd(){
    echo -e "\t
End time   :  $(get_formatted_date)
    \t"
}


##################################################

createVenv(){
    local venvPath="$HOME/.venv"
    local requirements="$HOME/Nextcloud/Python/requirements.txt"

    if [ -d "$venvPath" ]; then sysLogger e "venv already present, not creating"; return 0; fi

    sysLogger i "Creating venv $venvPath \n"

    python3 -m venv "$venvPath" || { sysLogger e "venv creation failed (is python3-venv installed?)"; return 1; }

    source "$venvPath/bin/activate" || { sysLogger e "Cannot activate the venv just created"; return 1; }

    if [ -s "$requirements" ]; then
        pip install -r "$requirements" || { sysLogger e "requirements.txt install failed"; deactivate 2>/dev/null || true; return 1; }

    else sysLogger e "No requirements.txt found, skipping package install"; fi

    echo -e "\n\n $(pip list) \n\n\n"

    deactivate 2>/dev/null || true
    return 0
}


py(){
    local venvPath="$HOME/.venv"
    local pyScript="${1:-}"
    local pyArgs=( "${@:2}" )          #### everything after the script path; $@ is never mutated
    local filename extension rc

    filename=$(basename -- "$pyScript")
    extension="${filename##*.}"

    venvRecheck(){
        sysLogger e "Venv corrupted, cannot activate. Deleting it and recreating..."

        #### Unset current active venv state cleanly before wiping
        deactivate 2>/dev/null || true

        [ -n "$venvPath" ] || { sysLogger e "venvPath empty, refusing rm -rf"; return 1; }
        rm -rf "$venvPath"

        createVenv                       || { sysLogger e "Venv recreation failed";   return 1; }
        "$venvPath/bin/python" --version || { sysLogger e "Venv missing or corrupted"; return 1; }
        source "$venvPath/bin/activate"  || { sysLogger e "Failed to activate venv";   return 1; }
    }

    if [ "$extension" != 'py' ] || [ ! -f "$pyScript" ] ; then sysLogger e "Not a python script"; return 1; fi

    if [ ! -d "$venvPath" ]; then
        sysLogger w "Venv not found in expected path: $venvPath , creating..."
        createVenv || return 1
    fi

    #### Suppress 'No such file' stderr
    source "$venvPath/bin/activate" 2>/dev/null || venvRecheck || return 1

    python "$pyScript" "${pyArgs[@]}"
    rc=$?

    deactivate 2>/dev/null || true
    return "$rc"
}

##################################################


raiseAlarm(){
    local logCheck="${1:-}"
    if [ -f "$logCheck" ]; then gedit "$logCheck" > /dev/null 2>&1 & fi
    vlc "$logCheckerAlarm" --gain 0.3 > /dev/null 2>&1 &
}


sysLogger(){
    local logType="${1:-}"
    local logBody="${2:-}"
    local caller="${FUNCNAME[1]:-MAIN}"
    logType=$( echo -e "$logType" | tr '[:lower:]' '[:upper:]' )
    
    declare -a options=('W' 'I' 'E' 'DEBUG')

    if  [ -z "$logType" ] || [[ ! " ${options[*]} " =~ [[:space:]]${logType}[[:space:]] ]]; then echo -e "Type error $logType"; return 1; fi

    case "$logType" in
        W) logType="WARNING" ;;
        I) logType="INFO" ;;
        E) logType="ERROR" ;;
        DEBUG) logType="DEBUG"; caller="${FUNCNAME[2]:-MAIN}" ;;
    esac

    echo -e "[$logType] {$caller} $(get_logger_date) -> $logBody"
}


PID_sysLogger(){
    local logType="${1:-}"
    local logBody="${2:-}"
    local caller="${FUNCNAME[1]:-MAIN}"
    logType=$( echo -e "$logType" | tr '[:lower:]' '[:upper:]' )
    declare -a options=('W' 'I' 'E' 'DEBUG')
    if  [ -z "$logType" ] || [[ ! " ${options[*]} " =~ [[:space:]]${logType}[[:space:]] ]]; then echo -e "Type error $logType"; return 1; fi

    case "$logType" in
        W) logType="WARNING" ;;
        I) logType="INFO" ;;
        E) logType="ERROR" ;;
        DEBUG) logType="DEBUG"; caller="${FUNCNAME[2]:-MAIN}" ;;
    esac

    echo -e "[$logType] {$caller} $(get_logger_date) -> $logBody" >> "$pid_log_file" 
}


debugLogger(){
    if [ "$DEBUG" == true ]; then sysLogger DEBUG "$1"; fi
}


PID_debugLogger(){
    if [ "$DEBUG" == true ]; then sysLogger DEBUG "$1"  >> "$pid_log_file"; fi  
}


EX_PID_debugLogger(){
    if [ "$DEBUG" == true ]; then sysLogger DEBUG "$1" >> "${XDG_RUNTIME_DIR}/exclusive_beforePID.log"; fi   
}


kindLogger(){ 
    local logBody="${1:-}"
    if [ -z "$logBody" ]; then return 1; fi
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $logBody" ; 
} 


##################################################


stringStrip(){
    local string="${1:-}"

    if [ -n "$string" ]; then
        string="${string#"${string%%[![:space:]]*}"}"  #### remove leading
        string="${string%"${string##*[![:space:]]}"}"  #### remove trailing
        echo "$string"

    else echo -e "Usage VAR=\$( stringStrip \$STRING )"; fi
}


stringFullStrip(){ #### Removes multiple spaces in between too 
    local string="${1:-}"

    if [ -n "$string" ]; then
        string=$( echo "$string" | awk '{$1=$1;print}' ) #### / awk '{$1=$1};1'
        echo "$string"

    else echo -e "Usage VAR=\$( stringStrip \$STRING )"; fi
}


stringUpper(){
    local string="${1:-}"

    if [ -n "$string" ]; then echo "$string" | tr '[:lower:]' '[:upper:]' #### NON-POSIX -- echo ${string^^}
    else echo -e "Usage VAR=\$( stringUpper \$STRING )"; fi
}


stringLower(){
    local string="${1:-}"

    if [ -n "$string" ]; then echo "$string" | tr '[:upper:]' '[:lower:]' #### NON-POSIX -- echo ${string,,}
    else echo -e "Usage VAR=\$( stringLower \$STRING )"; fi
}


stringNormalizeLow(){
    local string="${1:-}"

    if [ -n "$string" ]; then
        string=$( stringStrip "$string" )
        string=$( stringLower "$string" )
        echo "$string"

    else echo -e "Usage VAR=\$( stringNormalizeLow \$STRING )"; fi
}


stringNormalizeUpp(){
    local string="${1:-}"

    if [ -n "$string" ]; then
        string=$( stringStrip "$string" )
        string=$( stringUpper "$string" )
        echo "$string"

    else echo -e "Usage VAR=\$( stringNormalizeUpp \$STRING )"; fi
}


stringNormalizeNoBlanks(){
    local string="${1:-}"

    if [ -n "$string" ]; then
        string=$( stringFullStrip "$string" )
        string=$( stringLower "$string" )
        string=$( echo "$string" | tr ' ' '_' )
        echo "$string"

    else echo -e "Usage VAR=\$( stringNormalizeNoBlanks \$STRING )"; fi
}


################################################################################################
