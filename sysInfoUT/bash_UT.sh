
################################################################################################
####                            Sys Info

# osname=$(grep -oP '(?<=^NAME=)"?[^"]+' /etc/os-release | sed 's/^"//' | sed 's/linux //i' | tr '[:upper:]' '[:lower:]')
osname=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/OSname.sh)


#### formatted date
dateSTR=$(python3 $HOME/Nextcloud/Linux/scripts/sysInfoUT/date.py)

#### same date format
#### echo -e "$(date +%a\ %b\ %d\ %Y\ %H:%M:%S)"
UnixDateComparison=$(date +%a\ %b\ %d) 


#### formatted date for file names
dateSTR_FILE=$(python3 $HOME/Nextcloud/Linux/scripts/sysInfoUT/date_filename.py)

#### log standard setup (Start -- date , Running for: ...)
sysInfo=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/sysInfo.sh)

#### log standard setup end part (end date)
sysInfo_END=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/sysInfo_END.sh)


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

LXlogs="$HOME/Nextcloud/Linux/log"

PYscripts="$HOME/Nextcloud/Python/scripts"



####                            Logs path

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
