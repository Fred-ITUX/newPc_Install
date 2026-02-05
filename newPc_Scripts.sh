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






######################################################################################
#### UFW Firewall setup
set -e

sudo ufw default reject incoming 
sudo ufw default allow outgoing 

UFW_CONF="/etc/default/ufw"

#### Disable ipv6
if grep -q '^IPV6=yes' "$UFW_CONF"; then
    sed -i 's/^IPV6=yes/IPV6=no/' "$UFW_CONF"
fi

ufw reload
######################################################################################





######################################################################################
#### GRUB USB not working after waking up (sleep / hybernation / suspend)
grub_line_path="/etc/default/grub"
grub_line='GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"'
mod_line='GRUB_CMDLINE_LINUX_DEFAULT="quiet splash usbcore.autosuspend=-1"'

if grep -q "$grub_line" "$grub_line_path"; then
    sudo sed -i "s/^$grub_line/$mod_line/" "$grub_line_path"
fi
sudo update-grub
######################################################################################





######################################################################################
##### GNOME tweaks

#### Remove recents from gnome settings
gsettings set org.gnome.desktop.privacy remember-recent-files false

#### Disable gnome animation to make it smoother
gsettings set org.gnome.desktop.interface enable-animations false

#### Disable app not responding pop-up (default 5000)
gsettings set org.gnome.mutter check-alive-timeout 0

#### Disable automatic suspend / blank
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'

#### Multitasking / workspaces setup
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
gsettings set org.gnome.mutter workspaces-only-on-primary false

# #### Disable edge tiling --- keep true for fullscreen shortcut
# gsettings set org.gnome.mutter edge-tiling false

#### Keep Super Key for overview / search
gsettings set org.gnome.mutter overlay-key 'Super_L'

#### Night light setup
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 1
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 0
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 2500 #### 1000~10000

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

#### Allow all flatpak to see and use fonts and themes
flatpak override --user --filesystem=/home/federico/.themes 
flatpak override --user --filesystem=/home/federico/.fonts 
######################################################################################




######################################################################################
#### Deamons disable

#### Wait for network
sudo systemctl disable NetworkManager-wait-online.service
#### Local network discovery
sudo systemctl disable avahi-daemon.service

#### Keep clamav disabled by default (on-demand activation)
sudo systemctl disable clamav-daemon.service

#### Disable CUPS (printer deamon)
sudo systemctl disable cups.service cups.socket
sudo systemctl stop cups.service cups.socket


######################################################################################


#### Save newPc log fir history
logFile=$(sudo ls /root/ | grep .txt)
sudo cp /root/$logFile $HOME/Nextcloud/Linux/log/newPc_history/
sudo chown $USER $HOME/Nextcloud/Linux/log/newPc_history/*



######################################################################################
#### Launch scripts
$HOME/Nextcloud/Linux/scripts/New_Pc/theme_updater.sh &
$HOME/Nextcloud/Kden/scripts/editing_setup.sh &
$HOME/Nextcloud/Linux/scripts/Github/cloning.sh &
$HOME/Nextcloud/Linux/scripts/New_Pc/gnome_shortcut_dump/load-shortcuts.sh &
######################################################################################





######################################################################################
#### Git login
git config --global user.email "thealldedfred@gmail.com"                                      
git config --global user.name "Fred-ITUX"

#### Github login
gh auth login --hostname github.com --git-protocol https --web
######################################################################################

