#!/bin/bash

################################################################################################

osname=$(grep -oP '(?<=^NAME=)"?[^"]+' /etc/os-release | sed 's/^"//' | sed 's/linux //i' | tr '[:upper:]' '[:lower:]')

sessionType="$XDG_SESSION_TYPE"

get_formatted_date(){ date +%a\ %b\ %d\ %Y\ %H:%M:%S ; } #### python %a %b %d %Y %H:%M:%S

get_date_comparison(){ date +%a\ %b\ %d ; }

get_file_date(){ date +%Y\-%m-\%d\_%H-\%M-\%S ; }    #### python %Y-%m-%d_%H-%M-%S


get_logger_date(){ date +%Y\-%m-\%d\ %H:\%M:\%S ; }

get_sys_Info(){
echo -e "
________________________________________________________ 
\t
    Start time :  "$(get_formatted_date)"
    Running for:  $(whoami)@$osname [$(hostname)]"
}

get_sysInfo_END(){
    echo -e "\t
    End time   :  $(get_formatted_date)
    \t"
}



check_day_type(){
    dayToCheck=$(date +"%A") #### "%a" --- 3 letter day
    if [ "$dayToCheck" != "Saturday" ] && [ "$dayToCheck" != "Sunday" ]; then typeDay="weekday" ; else typeDay="weekend" ; fi }


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
        pid_log_file="$LXlogs/pids_laptop.txt"
    fi
}

raiseAlarm(){
    logCheck="${1:-}"
    if [ -f "$logCheck" ]; then gedit "$logCheck" > /dev/null 2>&1 & fi
    vlc "$logCheckerAlarm" > /dev/null 2>&1 &
}


sysLogger(){
    local logType="${1:-}"
    local logBody="${2:-}"
    local caller="${FUNCNAME[1]:-MAIN}"
    logType="${logType^^}"
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
    logType="${logType^^}"
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
    if [ "$DEBUG" == true ]; then sysLogger DEBUG "$1" >> "/tmp/exclusive_beforePID.log"; fi   
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
bletoothInEar="41:42:32:02:B1:95"

#### Other bluetooth controllers
bluetoothController=""

#### Only ps5 controller
ps5Controller="24:A6:FA:8B:8A:B9"

################################################################################################


