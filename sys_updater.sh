#!/bin/bash

#### prompt avoid
export DEBIAN_FRONTEND=noninteractive

#### SysInfo & path 
if [ -f ~/.sysUT.sh ]; then
    . ~/.sysUT.sh
fi


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


#### log standard setup end part (end date)
sysInfo_END=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/sysInfo_END.sh)
echo -e "$sysInfo_END"