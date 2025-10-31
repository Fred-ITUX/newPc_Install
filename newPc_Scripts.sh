#!/bin/bash


read -r -p "Run only after Nextcloud setup..." 


#### executable scripts --- except bashrc && bash_aliases
sudo find $HOME/Nextcloud/ -type f -name "*.sh" -exec chmod +x {} +


#### Disable zswap (compresses SWAP into RAM)
echo "N" | sudo tee /sys/module/zswap/parameters/enabled

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


#### Remove useless Ubuntu sessions options from login
sudo rm /usr/share/xsessions/ubuntu*.desktop
sudo rm /usr/share/wayland-sessions/ubuntu*.desktop


#### Enable gnome triple buffer rendering
mkdir -p ~/.config/environment.d
echo "MUTTER_DEBUG_TRIPLE_BUFFER=1
CLUTTER_PAINT=disable-clipped-redraws:disable-culling" | sudo tee  ~/.config/environment.d/gnome-performance.conf


######################################################################################







######################################################################################
#### Flatpacks override settings 

#### GPU acceleration
gpuAcc(){
    flatpak override --user --device=dri
}
gpuAcc com.google.Chrome
gpuAcc com.brave.Browser
gpuAcc com.valvesoftware.Steam
gpuAcc com.discordapp.Discord
gpuAcc org.gimp.GIMP
gpuAcc org.audacityteam.Audacity

#### Steam SSD whitelist (for external storing)
ssdPerm(){
    flatpak override --user --filesystem=/media/federico/SSD450GB
}
ssdPerm com.valvesoftware.Steam
ssdPerm com.usebottles.bottles

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
#### Launch scripts
$HOME/Nextcloud/Linux/scripts/New_Pc/theme_updater.sh &
$HOME/Nextcloud/Kden/scripts/kden_appimage_extract.sh &
$HOME/Nextcloud/Linux/scripts/Github/cloning.sh &
######################################################################################





######################################################################################
#### Git login
git config --global user.email "thealldedfred@gmail.com"                                      
git config --global user.name "Fred-ITUX"

#### Github login
gh auth login --hostname github.com --git-protocol https --web
######################################################################################

