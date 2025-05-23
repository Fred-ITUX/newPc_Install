
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

PYscripts="$HOME/Nextcloud/Python/scripts"



####                            Logs path

pathManualUpd="$HOME/Nextcloud/Linux/log/manual_updater.txt" 

pathShutdown="$HOME/Nextcloud/Linux/log/shutdown_log.txt"

pathROOTKIT="$HOME/Nextcloud/Linux/log/rk_scan.txt"

pathCLAMSCAN="$HOME/Nextcloud/Linux/log/clamav_scan.txt"

ufw_log_check="$HOME/Nextcloud/Linux/log/ufw_log_check.txt"

################################################################################################


