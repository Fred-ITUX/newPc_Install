

################################################################################################

osname=$(grep -oP '(?<=^NAME=)"?[^"]+' /etc/os-release | sed 's/^"//' | sed 's/linux //i' | tr '[:upper:]' '[:lower:]')



sessionType="$XDG_SESSION_TYPE"



get_formatted_date(){
    date +%a\ %b\ %d\ %Y\ %H:%M:%S  #### python %a %b %d %Y %H:%M:%S
}


#### Date to grep logs
get_date_comparison(){
    date +%a\ %b\ %d 
}


#### Formatted date for file names
get_file_date(){
    date +%Y\-%m-\%d\_%H-\%M-\%S    #### python %Y-%m-%d_%H-%M-%S
}



get_sys_Info(){
echo -e "
________________________________________________________ 
\t
    Start time :  "$(get_formatted_date)"
    Running for:  $(whoami)@$osname [$(hostname)]
    "
}

get_sysInfo_END(){
    echo -e "\t
    End time   :  $(get_formatted_date)
    \t"
}



check_day_type(){

    dayToCheck=$(date +"%A") #### "%a" --- 3 letter day

    if [ "$dayToCheck" != "Saturday" ] && [ "$dayToCheck" != "Sunday" ]; then
        typeDay="weekday"
    else
        typeDay="weekend"
    fi
}


userCheck(){
    host=$(hostname)
    main="federico"
    laptop="federico-HP"

    #### PC
    if [ "$host" == "$main" ]; then
        pc="$main"
    
    #### Laptop
    elif [ "$host" != "$main" ]; then
        pc="$laptop"
    fi
}

################################################################################################





################################################################################################
####                            Scripts path

LXscripts="$HOME/Nextcloud/Linux/scripts"

PYscripts="$HOME/Nextcloud/Python/scripts"


####                            Logs path

LXlogs="$HOME/Nextcloud/Linux/log"

pathStartupUpdaterClean="$HOME/Nextcloud/Linux/log/startup_updater.txt"

pathStartupUpdaterFull="$HOME/Nextcloud/Linux/log/adv_everyday/upd_"$(get_file_date)".txt"

pathManualUpd="$LXlogs/manual_updater.txt" 

pathROOTKIT="$LXlogs/rk_scan.txt"

pathCLAMSCAN="$LXlogs/clamav_scan.txt"

ufw_log_check="$LXlogs/ufw_log_check.txt"



logCheckerAlarm="$HOME/Nextcloud/Linux/Stuff/alarm.mp3"


################################################################################################





################################################################################################
####                            Bluetooth devices

getActiveDevice(){

    for device in "$@"; do

        deviceInfo=$(bluetoothctl info "$device")

        isAvailable=$(echo -e "$deviceInfo" | grep -i "not available")
        isConnected=$(echo -e "$deviceInfo" | grep -i "Connected: yes")


        if [ ! -z "$isAvailable" ]; then
            device="" #### device unavailable
            break
        fi

        if [ -n "$isConnected" ]; then
           activeDevice="$device"
        fi
        
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


