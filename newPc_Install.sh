#!/bin/bash

start_time=$(date '+%d-%m-%Y___%H-%M-%S')

pathFile="$HOME/newPC_$start_time.txt"


SWAP=16







########################################################


echo "

    +--------------------------+ 

            REQUIREMENTS

    +--------------------------+

    > ~45GB of apps and utilities (7GB for latex)
    > ~30min to end
    > "$SWAP"GB swap memory will be created
    > The pc will automatically reboot at the end
    
        
        
        
        
"
read -r -p "Press Enter to continue..." key
echo "Continuing..."





echo "




+---------------------------------+ 

        START INSTALL GNOME

+---------------------------------+




"
# gnome
sudo apt install gnome -y

# REQUIREMENT for ffmpeg media online (twitch and other streaming platforms)
sudo apt ubuntu-restricted-extras -y
echo "




+---------------------------------+ 

        END   INSTALL GNOME

+---------------------------------+




"





echo "




+-----------------------------------+ 

        START INSTALL FLATPAK

+-----------------------------------+




"
# flatpak download
sudo apt install flatpak -y
flatpak install flathub -y
echo "




+-----------------------------------+ 

        END   INSTALL FLATPAK

+-----------------------------------+




"




 
echo "




+----------------------------------+ 

        START INSTALL PYTON3

+----------------------------------+




"
# pyhton3 addons
sudo apt install python3-full -y
# pip install
sudo apt install python3-pip -y
# pip kernel 
sudo apt install python3-ipykernel -y


# pipx install
sudo apt install pipx -y
# pipx path fix
pipx ensurepath


# pandas
sudo apt install python3-pandas -y
sudo apt install python3-xlsxwriter -y
# seaborn
sudo apt install python3-seaborn -y
# notifications
sudo apt install python3-notify2 -y
# metadata modifier - mp3 script
sudo apt install python3-mutagen -y
# fuzzy check
sudo apt install python3-fuzzywuzzy -y

# speech to text - kdenlive subtitle dependencies
sudo apt install python3-srt -y
# speech to text -- global configuration
pip3 install vosk --break-system-packages

echo "




+----------------------------------+ 

        END   INSTALL PYTON3

+----------------------------------+




"




echo "




+---------------------------------+ 

        START INSTALL LATEX

+---------------------------------+




"
echo "If it freezes spam ENTER"
# latex 
sudo apt install texlive-full -y 


echo "




+---------------------------------+ 

        END   INSTALL LATEX

+---------------------------------+




"








echo "




+----------------------------------+ 

        START INSTALL CLAMAV

+----------------------------------+




"

echo "Prompts will appear..."
# clamav - antivirus and DB create-update
sudo apt install clamav clamav-daemon clamav-freshclam -y
clamconf
sudo freshclam
echo "




+----------------------------------+ 

        END   INSTALL CLAMAV       

+----------------------------------+




"



echo "




+------------------------------------+ 

        START INSTALL RKHUNTER

+------------------------------------+




"

# rkhunter - rootkit
sudo apt install rkhunter -y
echo "




+------------------------------------+ 

        END   INSTALL RKHUNTER

+------------------------------------+




"







########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################






echo "From now on is automatic
    Continuing with the script..."


touch "$pathFile"

echo "Created file $pathFile"


#### prompt avoid
export DEBIAN_FRONTEND=noninteractive


{

echo "

        +------------------------+ 

                CODE START

        +------------------------+

"




echo "

+-----------------------------------------------------------+ 

        START UPDATE, FULL UPGRADE AND CHECK INSTALLS

+-----------------------------------------------------------+

"
# update , full-upgrade to avoid packages issues , autoremove and clean
sudo apt update && sudo apt full-upgrade -y && sudo apt --fix-broken install -y && sudo dpkg --configure -a && sudo apt autoremove -y && sudo apt clean
echo "

+---------------------------------------------------------+ 

        END UPDATE, FULL UPGRADE AND CHECK INSTALLS

+---------------------------------------------------------+

"





########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################








echo "





        +------------------------------------------+ 

                REPOSITORY && APT APPS BEGIN

        +------------------------------------------+





"








echo "




+-------------------------------------------------+ 

        START INSTALL CURL, WGET, GIT && GH

+-------------------------------------------------+




"
# wget , curl, git, gh (github session login)
sudo apt install wget curl git gh -y 
echo "




+-------------------------------------------------+ 

        END   INSTALL CURL, WGET, GIT && GH

+-------------------------------------------------+




"








echo "




+---------------------------------------------+ 

        START INSTALL VLC && MEDIA LIBS

+---------------------------------------------+




"
# keep apt version for CLI command (clvc) + libs
sudo apt install vlc libdvdnav-dev libdvdread-dev libv4l-0 libx11-6 libxext6 libpulse0 libomxil-bellagio0 libjack-jackd2-0 libsdl2-2.0-0 libfaad2 libglib2.0-0 libxrender1 -y 
echo "




+---------------------------------------------+ 

        END   INSTALL VLC && MEDIA LIBS

+---------------------------------------------+




"







echo "




+-----------------------------------+ 

        START INSTALL XREADER

+-----------------------------------+




"
# pdf reader
sudo apt install xreader -y
echo "




+-----------------------------------+ 

        END   INSTALL XREADER

+-----------------------------------+




"







echo "




+----------------------------------------------+ 

        START INSTALL SIMPLE TEXT EDITOR

+----------------------------------------------+




"

# gedit for cli - gnome-text-editor for daily use
sudo apt install gedit gnome-text-editor -y 
echo "




+----------------------------------------------+ 

        END   INSTALL SIMPLE TEXT EDITOR

+----------------------------------------------+




"









echo "




+----------------------------------------------------+ 

        START INSTALL GAMING LIBS && UTILITIES

+----------------------------------------------------+




"

# apps, utilities, checkers, AMD GPU info
sudo apt install gamemode zram-tools cpufrequtils radeontop -y 

# libs
sudo apt install lib32gcc-s1 lib32stdc++6 libvulkan1 libvulkan1:i386 libx11-6:i386 libxext6:i386 libxrandr2:i386 libxrender1:i386 libxslt1.1:i386 libfreetype6:i386 libpng16-16:i386 libz1:i386 libsdl2-2.0-0 libsdl2-2.0-0:i386 vainfo libva-glx2 libva-glx2:i386 libva2 libva2:i386 -y 

# Install additional libraries for compatibility
sudo apt install libcurl4-openssl-dev libxrandr-dev libxinerama-dev libudev-dev libpci3 -y 
echo "




+----------------------------------------------------+ 

        END   INSTALL GAMING LIBS && UTILITIES

+----------------------------------------------------+




"









echo "




+--------------------------------------------------------------+ 

        START INSTALL EDITING DEPENDENCIES && MEDIA LIBS

+--------------------------------------------------------------+




"
# kden plugins and addons, melt (backend), mediainfo (media details), handbrake (file converter), nomacs (simple photo editor/viewer)
sudo apt install ffmpeg melt frei0r-plugins ladspa-sdk sox gstreamer1.0-libav libx264-dev libx265-dev libvpx-dev libmp3lame0 handbrake mediainfo nomacs -y 
# more media and editing oriented libs
sudo apt install liba52-0.7.4 libfaac-dev libopus-dev libvorbis-dev libflac-dev libtheora-dev libquicktime2 libswscale-dev libpostproc-dev libavfilter-dev libbluray-dev libdvdread8 libdvdnav4 libopenexr-dev libpng-dev libjpeg-dev kdenlive-data gpac v4l-utils libx264-dev libx265-dev gmic -y 

# gimp 
sudo apt install libjpeg-turbo8 libgegl-dev libheif1 libjpeg-turbo8 libgegl-dev libheif1 libtiff-tools libtiff-dev libpng-dev libwebp-dev colord icc-profiles argyll imagemagick exiv2 libexif-dev pngquant libopenjp2-7 -y 
echo "




+--------------------------------------------------------------+ 

        END   INSTALL EDITING DEPENDENCIES && MEDIA LIBS

+--------------------------------------------------------------+




"









echo "




+--------------------------------------------------------+ 

        START INSTALL LIBRE OFFICE, LIBS && PLUGIN

+--------------------------------------------------------+




"
# libre office full
sudo apt install libreoffice -y

# compatibility fonts
sudo apt install fonts-liberation fonts-dejavu fonts-cantarell fonts-noto -y 

# math font, improve PDF, quickstarter, theme compatibility
sudo apt install fonts-stix pdftk tesseract-ocr poppler-utils libreoffice-gtk3 -y 
echo "




+--------------------------------------------------------+ 

        END   INSTALL LIBRE OFFICE, LIBS && PLUGIN

+--------------------------------------------------------+




"







echo "




+------------------------------------+ 

        START INSTALL REDSHIFT

+------------------------------------+




"
# redshift - required for night light script 
sudo apt install redshift -y 
echo "




+------------------------------------+ 

        END   INSTALL REDSHIFT

+------------------------------------+




"














echo "




+-----------------------------------------+ 

        START INSTALL WINE COMPLETE

+-----------------------------------------+




"
# standard package + explicit redundancy
sudo apt install wine wine64 wine32 winetricks -y
echo "




+-----------------------------------------+ 

        END   INSTALL WINE COMPLETE

+-----------------------------------------+




"







echo "




+----------------------------------------+ 

        START INSTALL GNOME TWEAKS

+----------------------------------------+




"
# gnome-tweaks
sudo apt install gnome-tweaks -y 
echo "




+----------------------------------------+ 

        END   INSTALL GNOME TWEAKS

+----------------------------------------+




"









echo "




+--------------------------------------------------+ 

        START INSTALL CLIPBOARD MANAGER LIBS

+--------------------------------------------------+




"
# clipboard manager - lib dependencies
sudo apt install gir1.2-gda-5.0 gir1.2-gsound-1.0 -y 
echo "




+--------------------------------------------------+ 

        END   INSTALL CLIPBOARD MANAGER LIBS

+--------------------------------------------------+




"






echo "




+--------------------------------+ 

        START INSTALL HTOP

+--------------------------------+




"
# htop - task manager
sudo apt install htop -y 
echo "




+--------------------------------+ 

        END   INSTALL HTOP

+--------------------------------+




"







echo "




+---------------------------------+ 

        START INSTALL PIPER

+---------------------------------+




"

# piper - logitech mouse software
sudo apt install piper -y 
echo "




+---------------------------------+ 

        END   INSTALL PIPER

+---------------------------------+




"








echo "




+-----------------------------------------------------+ 

        START INSTALL PULSEAUDIO && PAVUCONTROL

+-----------------------------------------------------+




"

# pulse audio - mixer 
sudo apt install pulseaudio pavucontrol -y 
# bluetooth utilities
sudo apt install pulseaudio-module-bluetooth bluez bluez-tools -y 
echo "




+-----------------------------------------------------+ 

        END   INSTALL PULSEAUDIO && PAVUCONTROL

+-----------------------------------------------------+




"







echo "




+-----------------------------------------+ 

        START INSTALL GUFW FIREWALL

+-----------------------------------------+




"

# gufw firewall
sudo apt install gufw -y 
echo "




+-----------------------------------------+ 

        END   INSTALL GUFW FIREWALL

+-----------------------------------------+




"









echo "




+------------------------------------+ 

        START INSTALL NEOFETCH

+------------------------------------+




"

# neofetch - system info
sudo apt install neofetch -y 
echo "




+------------------------------------+ 

        END   INSTALL NEOFETCH

+------------------------------------+




"








echo "




+----------------------------------------+ 

        START INSTALL FONT-MANAGER

+----------------------------------------+




"

#### font-manager - custom font add / install
sudo apt install font-manager -y 
echo "




+----------------------------------------+ 

        END   INSTALL FONT-MANAGER

+----------------------------------------+




"








echo "




+-----------------------------------------+ 

        START INSTALL SMARTMONTOOLS

+-----------------------------------------+




"

# temp check for HDD, SSD, NVME ... --- required for Nextcloud/Linux/scripts/disk_check.py
sudo apt install smartmontools -y 
echo "




+-----------------------------------------+ 

        END   INSTALL SMARTMONTOOLS

+-----------------------------------------+




"




echo "




+--------------------------------+ 

        START INSTALL NEMO

+--------------------------------+




"
# nemo - file explorer
sudo apt install nemo -y
echo "




+--------------------------------+ 

        END   INSTALL NEMO

+--------------------------------+




"














echo "





        +----------------------------------------+ 

                REPOSITORY && APT APPS END

        +----------------------------------------+





"





########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################








echo "

            +-------------------+ 

                    OTHER

            +-------------------+

"




# terminal padding 
echo "

+----------------------------------+ 

        GTK TERMINAL PADDING

+----------------------------------+

"


# padding for older and newer gtk compatibility

echo "VteTerminal,
TerminalScreen,
vte-terminal {
    padding: 20px 20px 20px 20px;
    -VteTerminal-inner-border: 20px 20px 20px 20px;}" | sudo tee -a ~/.config/gtk-2.0/gtk.css

echo "VteTerminal,
TerminalScreen,
vte-terminal {
    padding: 20px 20px 20px 20px;
    -VteTerminal-inner-border: 20px 20px 20px 20px;}" | sudo tee -a ~/.config/gtk-3.0/gtk.css

echo "VteTerminal,
TerminalScreen,
vte-terminal {
    padding: 20px 20px 20px 20px;
    -VteTerminal-inner-border: 20px 20px 20px 20px;}" | sudo tee -a ~/.config/gtk-4.0/gtk.css



################################################################################################







# swap allocation 
echo "

+-----------------------------------+ 

        START SWAP ALLOCATION

+-----------------------------------+

"

sudo swapon --show
free -h
df -h
sudo fallocate -l "$SWAP"G /swapspace
ls -lh /swapspace
sudo chmod 700 /swapspace
ls -lh /swapspace
sudo mkswap /swapspace
sudo swapon /swapspace
sudo swapon --show
free -h
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapspace none swap sw 0 0' | sudo tee -a /etc/fstab
cat /proc/sys/vm/swappiness
sudo sysctl vm.swappiness=30
echo "vm.swappiness=30" | sudo tee -a /etc/sysctl.conf    
cat /proc/sys/vm/vfs_cache_pressure
sudo sysctl vm.vfs_cache_pressure=40
echo "vm.vfs_cache_pressure=40" | sudo tee -a /etc/sysctl.conf
echo "

+---------------------------------+ 

        END SWAP ALLOCATION

+---------------------------------+

"














########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################





echo "




        +--------------------------------+ 

                FLATPAK APPS BEGIN

        +--------------------------------+




"






echo "




+------------------------------------+ 

        START INSTALL FLATSEAL

+------------------------------------+




"
# flatseal - flatpak permissions
flatpak install com.github.tchx84.Flatseal/x86_64/stable -y
echo "




+------------------------------------+ 

        END   INSTALL FLATSEAL

+------------------------------------+




"










echo "




+---------------------------------------------------+ 

        START INSTALL GNOME EXTENSION MANAGER

+---------------------------------------------------+




"
# GNOME - Extension Manager 
flatpak install app/com.mattjakeman.ExtensionManager/x86_64/stable -y 
echo "




+---------------------------------------------------+ 

        END   INSTALL GNOME EXTENSION MANAGER

+---------------------------------------------------+




"











echo "




+---------------------------------+ 

        START INSTALL STEAM

+---------------------------------+




"

# steam
flatpak install com.valvesoftware.Steam -y

# required addon
sudo apt install steam-devices -y 

# protonGE
flatpak install com.valvesoftware.Steam.CompatibilityTool.Proton-GE -y 
echo "




+---------------------------------+ 

        END   INSTALL STEAM

+---------------------------------+




"







echo "




+--------------------------------+ 

        START INSTALL GIMP

+--------------------------------+




"
# gimp - photo editor + libs
flatpak install org.gimp.GIMP runtime/org.gimp.GIMP.Plugin.GMic/x86_64/2-40 -y
echo "




+--------------------------------+ 

        END   INSTALL GIMP

+--------------------------------+




"









echo "




+-----------------------------------+ 

        START INSTALL DISCORD

+-----------------------------------+




"
# discord
flatpak install app/com.discordapp.Discord/x86_64/stable -y 
echo "




+-----------------------------------+ 

        END   INSTALL DISCORD

+-----------------------------------+




"










echo "




+-------------------------------------+ 

        START INSTALL MUSESCORE

+-------------------------------------+




"
# musescore - music sheet editor
flatpak install app/org.musescore.MuseScore/x86_64/stable -y 
echo "




+-------------------------------------+ 

        END   INSTALL MUSESCORE

+-------------------------------------+




"











echo "




+----------------------------------+ 

        START INSTALL GROMIT

+----------------------------------+




"
# gromit - on screen annotations (draw on screen)
flatpak install app/net.christianbeier.Gromit-MPX/x86_64/stable -y
echo "




+----------------------------------+ 

        END   INSTALL GROMIT

+----------------------------------+




"









echo "




+--------------------------------------+ 

        START INSTALL STRAWBERRY

+--------------------------------------+




"
# strawberry - music player ( alternative to Clementine(EOL) )
flatpak install org.strawberrymusicplayer.strawberry -y 
echo "




+--------------------------------------+ 

        END   INSTALL STRAWBERRY

+--------------------------------------+




"








echo "




+------------------------------------+ 

        START INSTALL TELEGRAM

+------------------------------------+




"
# telegram
flatpak install app/org.telegram.desktop/x86_64/stable -y
echo "




+------------------------------------+ 

        END   INSTALL TELEGRAM

+------------------------------------+




"









echo "




+------------------------------------+ 

        START INSTALL WHATSAPP

+------------------------------------+




"
# whatsapp
flatpak install app/com.github.eneshecan.WhatsAppForLinux/x86_64/stable -y
echo "




+------------------------------------+ 

        END   INSTALL WHATSAPP

+------------------------------------+




"









echo "




+-------------------------------------+ 

        START INSTALL MAIN MENU

+-------------------------------------+




"
# main menu - detailed app info and editor
flatpak install page.codeberg.libre_menu_editor.LibreMenuEditor -y 
echo "




+-------------------------------------+ 

        END   INSTALL MAIN MENU

+-------------------------------------+




"








echo "




+------------------------------------+ 

        START INSTALL XCLICKER

+------------------------------------+




"
# xclicker - auto clicker
flatpak install xyz.xclicker.xclicker -y 
echo "




+------------------------------------+ 

        END   INSTALL XCLICKER

+------------------------------------+




"






echo "




+----------------------------------------+ 

        START INSTALL COREKEYBOARD

+----------------------------------------+




"
# CoreKeyboard - virtual keyboard (EOL)
flatpak install org.cubocore.CoreKeyboard -y
echo "




+----------------------------------------+ 

        END   INSTALL COREKEYBOARD

+----------------------------------------+




"









echo "




+----------------------------------------+ 

        START INSTALL STICKY NOTES

+----------------------------------------+




"
# sticky notes
flatpak install com.vixalien.sticky -y
echo "




+----------------------------------------+ 

        END   INSTALL STICKY NOTES

+----------------------------------------+




"












echo "




+-------------------------------+ 

        START INSTALL OBS

+-------------------------------+




"
# obs - screen capture
flatpak install com.obsproject.Studio -y
echo "




+-------------------------------+ 

        END   INSTALL OBS

+-------------------------------+




"











echo "




+------------------------------------+ 

        START INSTALL AUDACITY

+------------------------------------+




"
# audacity
flatpak install org.audacityteam.Audacity -y
echo "




+------------------------------------+ 

        END   INSTALL AUDACITY

+------------------------------------+




"










echo "




+-----------------------------------------+ 

        START INSTALL TUBECONVERTER

+-----------------------------------------+




"

# tubeconverter
flatpak install org.nickvision.tubeconverter -y
echo "




+-----------------------------------------+ 

        END   INSTALL TUBECONVERTER

+-----------------------------------------+




"










echo "




+-------------------------------------+ 

        START INSTALL KEEPASSXC

+-------------------------------------+




"

# database - password manager
flatpak install app/org.keepassxc.KeePassXC/x86_64/stable -y
echo "




+-------------------------------------+ 

        END   INSTALL KEEPASSXC

+-------------------------------------+




"








echo "






            +------------------------------+ 

                    FLATPAK APPS END

            +------------------------------+







"






########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################




echo "





            +------------------------------------------+ 

                    PPA APPS INSTALLATIONS BEGIN

            +------------------------------------------+





"






echo "




+------------------------------------+ 

        START INSTALL VSCODIUM

+------------------------------------+




"
# vscodium - open source and telemetry-free visual studio code
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor \
    | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
    
    echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
    | sudo tee /etc/apt/sources.list.d/vscodium.list
    
    sudo apt update && sudo apt install codium
echo "




+------------------------------------+ 

        END   INSTALL VSCODIUM

+------------------------------------+




"





echo "




+---------------------------------+ 

        START INSTALL BRAVE

+---------------------------------+




"

# brave ppa - browser
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update
sudo apt install brave-browser -y
echo "




+---------------------------------+ 

        END   INSTALL BRAVE

+---------------------------------+




"





echo "




+-------------------------------------+ 

        START INSTALL NEXTCLOUD

+-------------------------------------+




"

# nextcloud - self-hosted cloud storage -- webhosting
sudo add-apt-repository ppa:nextcloud-devs/client -y
sudo apt update
sudo apt install nextcloud-client -y
echo "




+-------------------------------------+ 

        END   INSTALL NEXTCLOUD

+-------------------------------------+




"









echo "





            +----------------------------------------+ 

                    PPA APPS INSTALLATIONS END

            +----------------------------------------+





"




########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################





echo "





            +--------------------------------------------+ 

                    START PRE-INSTALLED APPS PURGE

            +--------------------------------------------+





"



sudo apt purge firefox* -y
sudo apt purge thunderbird* -y
sudo apt purge cheese -y
sudo apt purge hypnotix -y
sudo apt purge rhythmbox -y
sudo apt purge aisleriot -y
sudo apt purge celluloid -y 
sudo apt purge hexchat -y
sudo apt purge onboard -y
sudo apt purge mahjongg -y
sudo apt purge pix -y
sudo apt purge remmina -y
sudo apt purge five-or-more -y
sudo apt purge four-in-a-row -y
sudo apt purge drawing -y
sudo apt purge xed -y
sudo apt purge lightsoff -y
sudo apt purge hitori -y
sudo apt purge quadrapassel -y
sudo apt purge shotwell -y
sudo apt purge swell-foop -y
sudo apt purge tali -y
sudo apt purge evolution -y
sudo apt purge evince -y
sudo apt purge iagno -y



sudo apt purge gnome-mahjongg -y
sudo apt purge gnome-mines -y
sudo apt purge gnome-sudoku -y
sudo apt purge gnome-todo -y
sudo apt purge gnome-chess -y
sudo apt purge gnome-2048 -y
sudo apt purge gnome-contacts -y
sudo apt purge gnome-maps -y
sudo apt purge gnome-tetravex -y
sudo apt purge gnome-music -y
sudo apt purge gnome-nibbles -y
sudo apt purge gnome-klotski -y
sudo apt purge gnome-robots -y
sudo apt purge gnome-weather -y
sudo apt purge gnome-remote-desktop -y
sudo apt purge gnome-taquin -y



### cinammon DE remove
sudo apt purge cinnamon* -y
sudo apt purge blueman -y
sudo apt purge mintwelcome -y



echo "






            +------------------------------------------+ 

                    END PRE-INSTALLED APPS PURGE

            +------------------------------------------+





"







###############################################################

##########        DON'T ADD CODE AFTER THIS          ##########

###############################################################




echo "









+------------------------------------------------------------+ 

        START FINAL UPDATE, UPGRADE, CHECKS && CLEANUP

+------------------------------------------------------------+



"
# update , upgrade , autoremove
sudo apt update && sudo apt full-upgrade -y && sudo apt --fix-broken install -y && sudo dpkg --configure -a && sudo apt autoremove -y && sudo apt clean
echo "

+----------------------------------------------------------+ 

        END FINAL UPDATE, UPGRADE, CHECKS && CLEANUP

+----------------------------------------------------------+



"




echo "

            +----------------------+ 

                    END CODE

            +----------------------+

"



##############################################
##############################################
##############################################
##############################################

## log
end_time=$(date '+%d-%m-%Y___%H:%M:%S')

echo "Start time: $start_time"
echo "End time:   $end_time"

} >> "$pathFile" 2>&1 && reboot 
