
################################################################################################
####                            Sys Info

# osname=$(grep -oP '(?<=^NAME=)"?[^"]+' /etc/os-release | sed 's/^"//' | sed 's/linux //i' | tr '[:upper:]' '[:lower:]')
osname=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/OSname.sh)



#### formatted date
get_formatted_date(){
    #python3 $HOME/Nextcloud/Linux/scripts/sysInfoUT/date.py
    date +%a\ %b\ %d\ %Y\ %H:%M:%S
}
dateSTR=$(get_formatted_date)

#### same date format
get_date_comparison(){
    date +%a\ %b\ %d 
}
UnixDateComparison=$(get_date_comparison)

#### formatted date for file names
get_file_date(){
    python3 $HOME/Nextcloud/Linux/scripts/sysInfoUT/date_filename.py
}
dateSTR_FILE=$(get_file_date)



#### log standard setup (Start -- date , Running for: ...)
sysInfo=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/sysInfo.sh)

#### log standard setup end part (end date)
get_sysInfo_END(){
    echo -e "\t
    End time   :  $(get_formatted_date)\n
    \t"
}
sysInfo_END=$(get_sysInfo_END)




#### Pc checks
pc=$(hostname)
main="federico"
laptop_HP="federico-HP"


#### day to check
dayToCheck=$(date +"%A") #### "%a" --- 3 letter day
if [ "$dayToCheck" != "Saturday" ] && [ "$dayToCheck" != "Sunday" ]; then
    typeDay="weekday"
else
    typeDay="weekend"
fi


#### Session type
sessionType="$XDG_SESSION_TYPE"


################################################################################################





################################################################################################
####                            Scripts path

LXscripts="$HOME/Nextcloud/Linux/scripts"

PYscripts="$HOME/Nextcloud/Python/scripts"



####                            Logs path

LXlogs="$HOME/Nextcloud/Linux/log"

pathManualUpd="$LXlogs/manual_updater.txt" 

pathShutdown="$LXlogs/shutdown_log.txt"

pathROOTKIT="$LXlogs/rk_scan.txt"

pathCLAMSCAN="$LXlogs/clamav_scan.txt"

ufw_log_check="$LXlogs/ufw_log_check.txt"

################################################################################################






################################################################################################
####                            Bluetooth devices

#### Sony WH-CH720N
bluetoothHeadset="00:A4:1C:04:E1:1F"

#### Earbuds / in-ear other bluetooth devices -- TWS
bletoothInEar="41:42:32:02:B1:95"

#### Other bluetooth controllers
bluetoothController=""

#### Only ps5 controller
ps5Controller="24:A6:FA:8B:8A:B9"

################################################################################################
