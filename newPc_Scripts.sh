#!/bin/bash

if [ -d $HOME/Nextcloud ]; then
    echo -e "Nextcloud path found $HOME/Nextcloud\n"
    read -r -p "Press enter to continue" 
else    
    echo -e "Run only after Nextcloud setup..."
    exit 0
fi


#### executable scripts --- except bashrc && bash_aliases
sudo find $HOME/Nextcloud/ -type f -name "*.sh" -exec chmod +x {} +


#### Disable zswap (compresses SWAP into RAM)
echo "N" | sudo tee /sys/module/zswap/parameters/enabled

#### Increase files processes - allows more open handles if needed, doesn't use more RAM (standard 1024)
echo -e "* soft nofile 1048576\n* hard nofile 1048576" | sudo tee /etc/security/limits.d/99-nofile.conf

#### Reduce GNOME stalls
mkdir -p ~/.config/systemd/user.conf.d
cat << 'EOF' > ~/.config/systemd/user.conf.d/limits.conf
[Manager]
DefaultLimitNOFILE=1048576
DefaultTasksMax=infinity
EOF

#### Disable CUPS (printer deamon)
sudo systemctl disable cups.service cups.socket
sudo systemctl stop cups.service cups.socket




#### firewall setup check
sudo ufw default reject incoming 
sudo ufw default allow outgoing 


######################################################################################
##### GNOME tweaks

#### Remove recents from gnome settings
gsettings set org.gnome.desktop.privacy remember-recent-files false

#### Disable gnome animation to make it smoother
gsettings set org.gnome.desktop.interface enable-animations false

#### Disable app not responding pop-up (default 5000)
gsettings set org.gnome.mutter check-alive-timeout 0


#### Disable gnome tracker (home folder indexing)
systemctl --user mask tracker-miner-fs-3.service
systemctl --user mask tracker-extract-3.service
systemctl --user mask tracker-writeback-3.service
tracker3 reset -s -r


#### Remove useless Ubuntu sessions options from login
sudo rm /usr/share/xsessions/ubuntu*.desktop
sudo rm /usr/share/wayland-sessions/ubuntu*.desktop


#### Enable gnome triple buffer rendering
mkdir -p ~/.config/environment.d
echo "MUTTER_DEBUG_TRIPLE_BUFFER=1
CLUTTER_PAINT=disable-clipped-redraws:disable-culling" | sudo tee  ~/.config/environment.d/gnome-performance.conf


######################################################################################





######################################################################################
#### Nemo / Nautilus use Samba’s net usershare to manage user shares
sudo mkdir -p /var/lib/samba/usershares
sudo chown root:sambashare /var/lib/samba/usershares
sudo chmod 1770 /var/lib/samba/usershares

#### HDD & SSDs mount directories
sudo mkdir /media/federico/SSD1TB/
sudo mkdir /media/federico/SSD450GB/
sudo mkdir /media/federico/HDD2TB/
######################################################################################






######################################################################################
#### Flatpacks override settings -- flatpak override --user --reset

#### GPU acceleration
flatpak override --user --device=dri com.google.Chrome
flatpak override --user --device=dri com.brave.Browser
flatpak override --user --device=dri com.valvesoftware.Steam
flatpak override --user --device=dri com.discordapp.Discord 
flatpak override --user --device=dri org.gimp.GIMP
flatpak override --user --device=dri org.audacityteam.Audacity
flatpak override --user --device=dri com.obsproject.Studio

#### Steam SSD whitelist (for external storing)
flatpak override --user --filesystem=/media/federico/SSD450GB com.valvesoftware.Steam
flatpak override --user --filesystem=/media/federico/SSD450GB com.usebottles.bottles

######################################################################################




######################################################################################
#### Launch scripts
$HOME/Nextcloud/Linux/scripts/New_Pc/theme_updater.sh &
$HOME/Nextcloud/Kden/scripts/editing_setup.sh &
$HOME/Nextcloud/Linux/scripts/Github/cloning.sh &
######################################################################################





######################################################################################
#### Git login
git config --global user.email "thealldedfred@gmail.com"                                      
git config --global user.name "Fred-ITUX"

#### Github login
gh auth login --hostname github.com --git-protocol https --web
######################################################################################

