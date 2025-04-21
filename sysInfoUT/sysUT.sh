
################################################################################################
####                            Sys Info

# osname=$(grep -oP '(?<=^NAME=)"?[^"]+' /etc/os-release | sed 's/^"//' | sed 's/linux //i' | tr '[:upper:]' '[:lower:]')
osname=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/OSname.sh)

#### formatted date
dateSTR=$(python3 $HOME/Nextcloud/Linux/scripts/sysInfoUT/date.py)

#### formatted date for file names
dateSTR_FILE=$(python3 $HOME/Nextcloud/Linux/scripts/sysInfoUT/date_filename.py)

#### log standard setup (Start -- date , Running for: ...)
sysInfo=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/sysInfo.sh)

#### log standard setup end part (end date)
sysInfo_END=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/sysInfo_END.sh)


################################################################################################






################################################################################################
####                            Scripts path

LXscripts="$HOME/Nextcloud/Linux/scripts"
PYscripts="$HOME/Nextcloud/Python/scripts"


################################################################################################









################################################################################################
####                            Logs path

pathManualUpd="$HOME/Nextcloud/Linux/log/manual_updater.txt" 
pathShutdown="$HOME/Nextcloud/Linux/log/shutdown_log.txt"
pathROOTKIT="$HOME/Nextcloud/Linux/log/rk_scan.txt"
pathCLAMSCAN="$HOME/Nextcloud/Linux/log/clamav_scan.txt"

ufw_log_check="$HOME/Nextcloud/Linux/log/ufw_log_check.txt"

################################################################################################


