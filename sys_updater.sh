#!/bin/bash

#### prompt avoid
export DEBIAN_FRONTEND=noninteractive

#########################################################################
#### distro name for logging
osname=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/OSname.sh)

#### formatted date
dateSTR=$(python3 $HOME/Nextcloud/Linux/scripts/sysInfoUT/date.py)

#### log standard setup (Start -- date , Running for: ...)
sysInfo=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/sysInfo.sh)

#### log standard setup end part (end date)
sysInfo_END=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/sysInfo_END.sh)
#########################################################################

#### log setup - START
echo -e "$sysInfo"


echo -e "\n\t
    • Fix broken pkg:
    \t"
sudo dpkg --configure -a 
sudo apt --fix-broken install -y 


echo -e "\n\t
    • Update:
    \t"
# sudo apt --fix-missing -q update | grep -v "Run 'apt list --upgradable' to see them."
sudo apt --fix-missing -q update
    

echo -e "\n\t
    • Upgrade:
    \t"
sudo apt full-upgrade -y


echo -e "\n\t
    • Flatpak update:
    \t" 
sudo flatpak update -y 


echo -e "\n\t
    • Autoremove:
    \t"
sudo apt autoremove -y
sudo apt clean


echo -e "\n\t
    • 2nd Fix broken pkg:
    \t"
sudo dpkg --configure -a 
sudo apt --fix-broken install -y 


#### log setup - END
sysInfo_END=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/sysInfo_END.sh)
echo -e "$sysInfo_END"