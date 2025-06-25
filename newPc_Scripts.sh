#!/bin/bash


read -r -p "Run only after Nextcloud setup..." 




######################################################################################
##### GNOME actual tweaks

#### Remove recents from gnome settings
gsettings set org.gnome.desktop.privacy remember-recent-files false

#### Disable gnome animation to make it smoother
gsettings set org.gnome.desktop.interface enable-animations false


#### Remove useless Ubuntu sessions options from login
sudo rm /usr/share/xsessions/ubuntu*.desktop
sudo rm /usr/share/wayland-sessions/ubuntu*.desktop


#### Enable gnome triple buffer rendering
mkdir -p ~/.config/environment.d
echo "MUTTER_DEBUG_TRIPLE_BUFFER=1
CLUTTER_PAINT=disable-clipped-redraws:disable-culling" | sudo tee  ~/.config/environment.d/gnome-performance.conf


#### Disable zswap (compresses SWAP into RAM)
echo "N" | sudo tee /sys/module/zswap/parameters/enabled

######################################################################################




#### executable scripts --- except bashrc && bash_aliases
sudo find $HOME/Nextcloud/ -type f -name "*.sh" -exec chmod +x {} +



######################################################################################
#### Nemo / Nautilus use Samba’s net usershare to manage user shares
sudo mkdir -p /var/lib/samba/usershares
sudo chown root:sambashare /var/lib/samba/usershares
sudo chmod 1770 /var/lib/samba/usershares
######################################################################################





#### firewall setup check
sudo ufw default reject incoming 
sudo ufw default allow outgoing 




######################################################################################
#### Git login
git config --global user.email "thealldedfred@gmail.com"                                      
git config --global user.name "Fred-ITUX"

#### Github login
gh auth login --hostname github.com --git-protocol https --web
######################################################################################

