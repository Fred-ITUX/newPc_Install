#!/bin/bash

#### distro name for logging
osname=$(grep -oP '(?<=^NAME=)"?[^"]+' /etc/os-release | sed 's/^"//' | sed 's/linux //i' | tr '[:upper:]' '[:lower:]')

#### prompt avoid
export DEBIAN_FRONTEND=noninteractive


echo -e "
_____________________________________________________ 
\t" #### keep a empty line under, otherwise gets removed from log_cleaner.py script 

echo "
    Start  --  $(date)
    Running for:  $(whoami)@$osname [$(hostname)]"

####



echo "
    
    • Fix broken pkg:"
sudo dpkg --configure -a 
sudo apt --fix-broken install -y 





echo "
    
    • Update:"
sudo apt --fix-missing -q update | grep -v "Run 'apt list --upgradable' to see them."
    



echo "
    
    • Upgrade:"
sudo apt full-upgrade -y




echo "
    
    • Flatpak update:" 
sudo flatpak update -y 




echo "
    
    • Autoremove:"
sudo apt autoremove -y
sudo apt clean



echo " 
    End  --  $(date)
"


