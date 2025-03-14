#!/bin/bash


user=${SUDO_USER:-$(whoami)}



# Ensure the script is being run with sudo to have permission
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo."
    exit 1
fi

# Define the sudoers file path
sudoers_file="/etc/sudoers.d/$user"

# Add user to sudoers safely
echo "$user ALL=(ALL) NOPASSWD:ALL" | tee "$sudoers_file"

# Set correct permissions
chmod 440 "$sudoers_file"

# Validate sudoers syntax
visudo -c

if [[ $? -eq 0 ]]; then
    echo "Sudo privileges granted successfully for $user."
else
    echo "Error: Invalid sudoers syntax! Fixing..."
    rm "$sudoers_file"
    exit 1
fi






#### Git clone repo script && script exec 
sudo apt install git -y
cd $HOME
git clone https://github.com/Fred-ITUX/newPc_Install
cd $HOME/newPc_Install/
sudo find $HOME/newPc_Install/ -type f -name "*.sh" -exec chmod +x {} +


#### Lunch the script
$HOME/newPc_Install/newPc_Install.sh