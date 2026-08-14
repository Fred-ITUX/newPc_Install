#!/bin/bash

################################################################################################

osname=$(grep -oP '(?<=^NAME=)"?[^"]+' /etc/os-release | sed 's/^"//' | sed 's/linux //i' | tr '[:upper:]' '[:lower:]')

sessionType="$XDG_SESSION_TYPE"

userCheck(){
    host=$(hostname)
    main="federico"
    laptop="federico-HP"

    #### PC
    if [ "$host" == "$main" ]; then
        pc="$main"
        pid_log_file="$LXlogs/pids_main.log"
    
    #### Laptop
    elif [ "$host" != "$main" ]; then
        pc="$laptop"
        pid_log_file="$LXlogs/pids_laptop.log"
    fi
}


##################################################


get_formatted_date(){ date +%a\ %b\ %d\ %Y\ %H:%M:%S ; } #### python %a %b %d %Y %H:%M:%S


get_date_comparison(){ date +%a\ %b\ %d ; }


get_file_date(){ date +%Y\-%m-\%d\_%H-\%M-\%S ; }    #### python %Y-%m-%d_%H-%M-%S


get_logger_date(){ date +%Y\-%m-\%d\ %H:\%M:\%S ; } #### date "+%F %T"


check_day_type(){
    dayToCheck=$(date +"%A") #### "%a" --- 3 letter day
    if [ "$dayToCheck" != "Saturday" ] && [ "$dayToCheck" != "Sunday" ]; then typeDay="weekday" ; else typeDay="weekend" ; fi 
}


##################################################

getSysInfoStart(){
echo -e "
________________________________________________________ 
\t
Start time :  "$(get_formatted_date)"
    Running for:  $(whoami)@$osname [$(hostname)]"
}


getSysInfoEnd(){
    echo -e "\t
End time   :  $(get_formatted_date)
    \t"
}


##################################################

createVenv(){
    if [ -d "$HOME/.venv" ]; then sysLogger e "venv already present, not creating"

    else

        sysLogger i "Creating venv $HOME/.venv \n"

        python3 -m venv "$HOME/.venv"

        source "$HOME/.venv/bin/activate"

        if [ -s "$HOME/Nextcloud/Python/requirements.txt" ]; then
            pip install -r "$HOME/Nextcloud/Python/requirements.txt"
        
        else sysLogger e "No requirements.txt found, skipping package install" ; fi

        echo -e "\n\n $(pip list) \n\n\n" 
        deactivate; fi
}


py(){
    local pyScript="${1:-}"
    local filename=$(basename -- "$pyScript")
    local extension="${filename##*.}"
    local venvPath="$HOME/.venv"

    venvRecheck(){
        sysLogger e "Venv corrupted, cannot activate. Deleting it and recreating..." 

        #### Unset current active venv state cleanly before wiping
        deactivate 2>/dev/null || true


        rm -rf "$venvPath"
        createVenv
        
        "$HOME/.venv/bin/python" --version || { sysLogger e "Venv missing or corrupted"; return 1 ;}

        source "$HOME/.venv/bin/activate" || { sysLogger e "Failed to activate venv"; }
    }


    if [ "$extension" != 'py' ] || [ ! -f "$pyScript" ] ; then sysLogger e "Not a python script"; return 1; fi

    if [ ! -d "$venvPath" ]; then sysLogger w "Venv not found in expected path: $venvPath , creating..."; createVenv; fi

        
    #### Suppress 'No such file' stderr
    source "$HOME/.venv/bin/activate" 2>/dev/null || venvRecheck 

    python "$1"; deactivate
}

##################################################


raiseAlarm(){
    logCheck="${1:-}"
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
        string=$( echo -e "$testString" | awk '{$1=$1;print}' ) #### / awk '{$1=$1};1'
        echo -e "$string"

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
        string=$( echo -e "$string" | tr ' ' '_' )
        echo "$string"

    else echo -e "Usage VAR=\$( stringNormalizeNoBlanks \$STRING )"; fi
}


################################################################################################








################################################################################################
####                            Scripts path

LXscripts="$HOME/Nextcloud/Linux/scripts"

PYscripts="$HOME/Nextcloud/Python/scripts"


####                            Logs path

LXlogs="$HOME/Nextcloud/Linux/log"

pathStartupUpdaterClean="$HOME/Nextcloud/Linux/log/startup_updater.log"

pathStartupUpdaterFull="$HOME/Nextcloud/Linux/log/adv_everyday/upd_"$(get_file_date)".log"

pathManualUpd="$LXlogs/manual_updater.log" 

pathROOTKIT="$LXlogs/rk_scan.log"

pathCLAMSCAN="$LXlogs/clamav_scan.log"

ufw_log_check="$LXlogs/ufw_log_check.log"

repoPushLog="$LXlogs/startup_repo_push.log"

logCheckerAlarm="$HOME/Nextcloud/Linux/Stuff/alarm.mp3"

################################################################################################





################################################################################################
####                            Bluetooth devices

getActiveDevice(){
    for device in "$@"; do

        deviceInfo=$(bluetoothctl info "$device")

        isAvailable=$(echo -e "$deviceInfo" | grep -i "not available")
        isConnected=$(echo -e "$deviceInfo" | grep -i "Connected: yes")

        if [ ! -z "$isAvailable" ]; then device=""  ; break ;
        else activeDevice="$device"; fi      
    done
}

#### Sony WH-CH720N
bluetoothHeadset="00:A4:1C:04:E1:1F"

#### Earbuds / in-ear other bluetooth devices -- TWS
bletoothInEar=""

#### Other bluetooth controllers
bluetoothController=""

#### Only ps5 controller
ps5Controller="24:A6:FA:8B:8A:B9"

################################################################################################


