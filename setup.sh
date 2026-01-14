#!/bin/bash


user=${SUDO_USER:-$(whoami)}

#### Ensure sudo run
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo."
    exit 1
fi


sudoers_file="/etc/sudoers.d/$user"

#### Add user to sudoers
echo "$user ALL=(ALL) NOPASSWD:ALL" | tee "$sudoers_file"

#### Set correct permissions
chmod 440 "$sudoers_file"

#### Validate sudoers syntax
visudo -c

if [[ $? -eq 0 ]]; then
    echo "Sudo privileges granted successfully for $user."
else
    echo "Error: Invalid sudoers syntax! Removing file..."
    rm "$sudoers_file"
    exit 1
fi






#### Git clone repo script && script exec 
sudo apt install git -y
cd $HOME
git clone https://github.com/Fred-ITUX/newPc_Install
cd $HOME/newPc_Install/
sudo find $HOME/newPc_Install/ -type f -name "*.sh" -exec chmod +x {} +


#### Launch the script
$HOME/newPc_Install/newPc_Install.sh