#!/bin/bash

start_time=$(date '+%d-%m-%Y___%H-%M-%S')

pathFile="$HOME/newPC_$start_time.txt"

## sudo no pswd 
user=$(whoami)
echo "ADD
    $user ALL=(ALL) NOPASSWD:ALL
    to 'sudo visudo'
    before '@includedir /etc/sudoers.d'
"
read -r -p "Press Enter to continue..." key






echo "




"

echo "

+------------------+ 

    REQUIREMENTS

+------------------+

"
echo "  
    > ~45GB of apps and utilities (7GB for latex)
    > ~30min to end
    > 16GB swap memory will be created
    > The pc will automatically reboot at the end
    
        
        
        
        
        "
read -r -p "Press Enter to continue..." key
echo "Continuing..."





echo "

+-----------------------------+ 

      START GNOME INSTALL

+-----------------------------+

"
# gnome
sudo apt install gnome -y
echo "

+---------------------------+ 

      END GNOME INSTALL

+---------------------------+

"





echo "

+---------------------------+ 

    START FLATPAK INSTALL

+---------------------------+

"
# flatpak download
sudo apt install flatpak -y
flatpak install flathub -y
echo "

+-------------------------+ 

    END FLATPAK INSTALL

+-------------------------+

"



echo "




"





 
echo "

+-------------------------------+ 

    START PYTON3 FULL INSTALL

+-------------------------------+

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
sudo apt install python3-fuzzywuzzy 

# speech to text - kdenlive subtitle dependencies
sudo apt install python3-srt -y
# speech to text -- global configuration
pip3 install vosk --break-system-packages

echo "

+-----------------------------+ 

    END PYTON3 FULL INSTALL

+-----------------------------+

"



echo "Downloading latex...
    If it freezes spam ENTER"

# latex 
echo "

+-------------------------+ 

    START LATEX INSTALL

+-------------------------+

"
sudo apt install texlive-full -y

# cv dependencies
sudo apt install texlive awesome* -y
echo "

+-----------------------+ 

    END LATEX INSTALL

+-----------------------+

"
echo "Latex install terminated...



"




echo "Downloading clamav...
    Prompts will appear"



echo "

+--------------------------+ 

    START CLAMAV INSTALL

+--------------------------+

"
# clamav - antivirus and DB create-update
sudo apt install clamav -y
sudo apt install clamav-daemon -y
sudo apt install clamav-freshclam -y
clamconf
sudo freshclam
echo "

+------------------------+ 

    END CLAMAV INSTALL

+------------------------+

"


# rkhunter - rootkit
echo "

+----------------------------+ 

    START RKHUNTER INSTALL

+----------------------------+

"
sudo apt install rkhunter -y
echo "

+--------------------------+ 

    END RKHUNTER INSTALL

+--------------------------+

"



echo "From now on is automatic
    Continuing with the script..."


touch "$pathFile"

{
echo "


"

echo "

    +----------------+ 

        CODE START

    +----------------+

"

echo "




"



# update , upgrade , autoremove
echo "

+--------------------+ 

    START UPDATERS

+--------------------+

"
sudo apt update && sudo apt full-upgrade -y && sudo apt --fix-broken install -y && sudo apt autoremove -y && sudo apt clean
echo "

+------------------+ 

    END UPDATERS

+------------------+

"

echo "








"

    #############################################
    ####                                     ####
    ####              REPO APPS              ####
    ####                                     ####
    #############################################

echo "

    +---------------+ 

        REPO APPS

    +---------------+

"



echo "

+----------------------------------------+ 

        START CURL && WGET INSTALL

+----------------------------------------+

"
# wget , curl
sudo apt install curl -y
sudo apt install wget -y
echo "

+--------------------------------------+ 

        END CURL && WGET INSTALL

+--------------------------------------+

"


echo "



"



echo "

+-----------------------+ 

    START VLC INSTALL

+-----------------------+

"
# keep apt version for CLI command (clvc)
sudo apt install vlc -y
sudo apt install -y libdvdnav-dev libdvdread-dev libv4l-0 libx11-6 libxext6 libpulse0 libomxil-bellagio0 libjack-jackd2-0 libsdl2-2.0-0 libfaad2 libglib2.0-0 libxrender1
sudo apt install -y ubuntu-restricted-extras

echo "

+---------------------+ 

    END VLC INSTALL

+---------------------+

"


echo "




"



echo "

+-----------------------------------+ 

        START XREADER INSTALL

+-----------------------------------+

"
# pdf reader
sudo apt install xreader -y
echo "

+---------------------------------+ 

        END XREADER INSTALL

+---------------------------------+

"



echo "




"



echo "

+---------------------------------+ 

        START GEDIT INSTALL

+---------------------------------+

"
# gedit for cli
sudo apt install gedit -y
echo "

+-------------------------------+ 

        END GEDIT INSTALL

+-------------------------------+

"







echo "




"




echo "

+---------------------------------------------------+ 

        START GAMING LIBS & UTILITIES INSTALL

+---------------------------------------------------+

"
# apps
sudo apt install gamemode -y
sudo apt install cpufrequtils -y
sudo apt install zram-tools -y

# libs
sudo apt install lib32gcc-s1 lib32stdc++6 libvulkan1 libvulkan1:i386 -y
sudo apt install libx11-6:i386 libxext6:i386 libxrandr2:i386 libxrender1:i386 libxslt1.1:i386 libfreetype6:i386 libpng16-16:i386 libz1:i386 -y
sudo apt install libsdl2-2.0-0 libsdl2-2.0-0:i386 -y
sudo apt install vainfo libva-glx2 libva-glx2:i386 libva2 libva2:i386 -y
# Install additional libraries for compatibility
sudo apt install -y libcurl4-openssl-dev libxrandr-dev libxinerama-dev libudev-dev libpci3

# AMD GPU info
sudo apt install radeontop -y


echo "

+-------------------------------------------------+ 

        END GAMING LIBS & UTILITIES INSTALL

+-------------------------------------------------+

"



echo "










"


echo "

+-------------------------------------------------------------+ 

        START EDITING DEPENDENCIES & MEDIA LIBS INSTALL

+-------------------------------------------------------------+

"

# kden plugins and addons, melt (backend), mediainfo (media details), handbrake (file converter)
sudo apt install ffmpeg melt frei0r-plugins ladspa-sdk sox gstreamer1.0-libav libx264-dev libx265-dev libvpx-dev libmp3lame0 handbrake mediainfo -y
# more media and editing oriented libs
sudo apt install liba52-0.7.4 libfaac-dev libopus-dev libvorbis-dev libflac-dev libtheora-dev libquicktime2 \
libswscale-dev libpostproc-dev libavfilter-dev libbluray-dev libdvdread8 libdvdnav4 libopenexr-dev libpng-dev \
libjpeg-dev kdenlive-data gpac v4l-utils libx264-dev libx265-dev gmic -y

# gimp 
sudo apt install libjpeg-turbo8 libgegl-dev libheif1 -y
sudo apt install libjpeg-turbo8 libgegl-dev libheif1 libtiff-tools libtiff-dev libpng-dev libwebp-dev colord icc-profiles argyll imagemagick exiv2 libexif-dev pngquant libopenjp2-7 -y

# nomacs - photo viewer and easy editor
sudo apt install nomacs -y

echo "

+-----------------------------------------------------------+ 

        END EDITING DEPENDENCIES & MEDIA LIBS INSTALL

+-----------------------------------------------------------+

"


echo "










"


echo "

+--------------------------------------------------------+ 

        START LIBRE OFFICE, LIBS && PLUGIN INSTALL

+--------------------------------------------------------+

"
# libre office full
sudo apt install libreoffice -y

# compatibility fonts
sudo apt install fonts-liberation fonts-dejavu fonts-cantarell fonts-noto -y

# math font
sudo apt install fonts-stix -y

# improve PDF 
sudo apt install pdftk tesseract-ocr poppler-utils -y

# quickstarter
sudo apt install libreoffice-gtk3 -y



echo "

+------------------------------------------------------+ 

        END LIBRE OFFICE, LIBS && PLUGIN INSTALL

+------------------------------------------------------+

"





echo "










"




echo "

+------------------------------------+ 

        START REDSHIFT INSTALL

+------------------------------------+

"
# redshift - required for night light script $HOME/Nextcloud/Linux/scripts/night_light.sh
sudo apt install redshift -y
echo "

+----------------------------------+ 

        END REDSHIFT INSTALL

+----------------------------------+

"



echo "



"



# wine install
echo "

+------------------------+ 

    START WINE INSTALL

+------------------------+

"
sudo apt install wine -y
# redundancy
sudo apt install wine64 wine32 -y
echo "

+----------------------+ 

    END WINE INSTALL

+----------------------+

"



echo "



"



# gnome-tweaks
echo "

+--------------------------------+ 

    START GNOME TWEAKS INSTALL

+--------------------------------+

"
sudo apt install gnome-tweaks -y
echo "

+------------------------------+ 

    END GNOME TWEAKS INSTALL

+------------------------------+

"




echo "




"

echo "

+------------------------------+ 

    START WINETRICKS INSTALL

+------------------------------+

"
# winetricks install
sudo apt install winetricks -y
echo "

+----------------------------+ 

    END WINETRICKS INSTALL

+----------------------------+

"


# pano - clipboard manager - lib dependencies
echo "

+--------------------------------+ 

    START GIR-GDA LIBS INSTALL

+--------------------------------+

"
sudo apt install gir1.2-gda-5.0 gir1.2-gsound-1.0 -y
echo "

+------------------------------+ 

    END GIR-GDA LIBS INSTALL

+------------------------------+

"




# htop - task manager
echo "

+------------------------+ 

    START HTOP INSTALL

+------------------------+

"
sudo apt install htop -y
echo "

+----------------------+ 

    END HTOP INSTALL

+----------------------+

"



# piper - logitech mouse software
echo "

+-------------------------+ 

    START PIPER INSTALL

+-------------------------+

"
sudo apt install piper -y
echo "

+-----------------------+ 

    END PIPER INSTALL

+-----------------------+

"
echo "




"







# pulse audio - mixer 
echo "

+--------------------------------------------+ 

    START PULSEAUDIO & PAVUCONTROL INSTALL

+--------------------------------------------+

"
sudo apt install pulseaudio -y
sudo apt install pavucontrol -y
# bluetooth utilities
sudo apt install pulseaudio-module-bluetooth bluez bluez-tools -y
echo "

+------------------------------------------+ 

    END PULSEAUDIO & PAVUCONTROL INSTALL

+------------------------------------------+

"




echo "




"


# gufw - firewall
echo "

+------------------------+ 

    START GUFW INSTALL

+------------------------+

"
sudo apt install gufw -y
### sets to incoming reject
sudo ufw default reject
echo "

+----------------------+ 

    END GUFW INSTALL

+----------------------+

"








# neofetch - system info
echo "

+----------------------------+ 

    START NEOFETCH INSTALL

+----------------------------+

"
sudo apt install neofetch -y
echo "

+--------------------------+ 

    END NEOFETCH INSTALL

+--------------------------+

"


echo "




"






echo "

+-----------------------+ 

    START GIT INSTALL

+-----------------------+

"
sudo apt install git -y
echo "

+---------------------+ 

    END GIT INSTALL

+---------------------+

"



echo "




"




#### font-manager - custom font add / install
echo "

+--------------------------------+ 

    START FONT-MANAGER INSTALL

+--------------------------------+

"
sudo apt install font-manager -y
echo "

+------------------------------+ 

    END FONT-MANAGER INSTALL

+------------------------------+

"




echo "




"


echo "

+-------------------------------------+ 

      START SMARTMONTOOLS INSTALL

+-------------------------------------+

"
# temp check for HDD, SSD, NVME ... --- required for Nextcloud/Linux/scripts/disk_check.py
sudo apt install smartmontools -y
echo "

+-----------------------------------+ 

      END SMARTMONTOOLS INSTALL

+-----------------------------------+

"



echo "




"






###############################################################

###################       OTHER                ################

###############################################################

echo "

+------------------------+ 

    NANO CUSTOM SYNTAX

+------------------------+

"
# nano highlights syntax
curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh



echo "




"


# terminal padding 
echo "

+----------------------+ 

    TERMINAL PADDING

+----------------------+

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




echo "

"




# nautilus dark mode
echo "

+---------------------+ 

    NAUTILUS ADDONS

+---------------------+

"

# install check
sudo apt install nautilus -y
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
# nautilus right-click terminal option
sudo apt install nautilus-extension-gnome-terminal -y



echo "




"





# swap allocation 
echo "

+---------------------------+ 

    START SWAP ALLOCATION

+---------------------------+

"
sudo swapon --show
free -h
df -h
sudo fallocate -l 16G /swapspace
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

+-------------------------+ 

    END SWAP ALLOCATION

+-------------------------+

"









echo "










"




sleep 10s
###############################################################

##############           FLATPAK                 ##############

###############################################################




echo "

+--------------------------------------+ 

    FLATPAK APPS INSTALLATIONS BEGIN

+--------------------------------------+

"



echo "




"






echo "

+----------------------------+ 

    START INSTALL FLATSEAL

+----------------------------+

"
flatpak install flatseal -y
echo "

+--------------------------+ 

    END INSTALL FLATSEAL

+--------------------------+

"







echo "




"



# Extension Manager 
echo "

+-------------------------------------+ 

    START EXTENSION MANAGER INSTALL

+-------------------------------------+

"
flatpak install app/com.mattjakeman.ExtensionManager/x86_64/stable -y
echo "

+-----------------------------------+ 

    END EXTENSION MANAGER INSTALL

+-----------------------------------+

"




echo "




"



# warpinator - file transfer --- already in PPA MINT ONLY
echo "

+-------------------------------+ 

    START  WARPINATOR INSTALL

+-------------------------------+

"
flatpak install org.x.Warpinator -y
echo "

+----------------------------+ 

    END WARPINATOR INSTALL

+----------------------------+

"

echo "




"




echo "

+-------------------------+ 

    START STEAM INSTALL

+-------------------------+

"
# steam
flatpak install com.valvesoftware.Steam -y
# required addon
sudo apt install steam-devices -y
echo "

+-----------------------+ 

    END STEAM INSTALL

+-----------------------+

"

sleep 10s




echo "

+------------------------+ 

    START GIMP INSTALL

+------------------------+

"
# gimp - photo editor
flatpak install org.gimp.GIMP -y
flatpak install -y runtime/org.gimp.GIMP.Plugin.GMic/x86_64/2-40 
echo "

+----------------------+ 

    END GIMP INSTALL

+----------------------+

"


echo "




"



echo "

+---------------------------+ 

    START DISCORD INSTALL

+---------------------------+

"
# discord
flatpak install discordapp -y
echo "

+-------------------------+ 

    END DISCORD INSTALL

+-------------------------+

"









echo "




"




echo "

+-----------------------------+ 

    START MUSESCORE INSTALL

+-----------------------------+

"
# musescore - music sheet editor
flatpak install musescore -y
echo "

+---------------------------+ 

    END MUSESCORE INSTALL

+---------------------------+

"

echo "




"


sleep 10s


echo "

+--------------------------+ 

    START GROMIT INSTALL

+--------------------------+

"
# gromit - on screen annotations (draw on screen)
flatpak install gromit -y
echo "

+------------------------+ 

    END GROMIT INSTALL

+------------------------+

"





echo "




"



echo "

+------------------------------+ 

    START STRAWBERRY INSTALL

+------------------------------+

"
# strawberry - music player ( alternative to Clementine(EOL) )
flatpak install org.strawberrymusicplayer.strawberry -y
echo "

+----------------------------+ 

    END STRAWBERRY INSTALL

+----------------------------+

"
 

echo "




"



sleep 10s




echo "

+----------------------------+ 

    START TELEGRAM INSTALL

+----------------------------+

"
# telegram
flatpak install app/org.telegram.desktop/x86_64/stable -y
echo "

+--------------------------+ 

    END TELEGRAM INSTALL

+--------------------------+

"

echo "




"



echo "

+----------------------------+ 

    START WHATSAPP INSTALL

+----------------------------+

"
# whatsapp
flatpak install app/com.github.eneshecan.WhatsAppForLinux/x86_64/stable -y
echo "

+--------------------------+ 

    END WHATSAPP INSTALL

+--------------------------+

"





echo "




"





echo "

+-----------------------------+ 

    START MAIN MENU INSTALL

+-----------------------------+

"
# main menu - detailed app info and editor
flatpak install page.codeberg.libre_menu_editor.LibreMenuEditor -y
echo "

+---------------------------+ 

    END MAIN MENU INSTALL

+---------------------------+

"


echo "




"



echo "

+---------------------------+ 

    START SPOTIFY INSTALL

+---------------------------+

"
# spotify
flatpak install com.spotify.Client -y
echo "

+-------------------------+ 

    END SPOTIFY INSTALL

+-------------------------+

"

echo "




"



echo "

+----------------------------+ 

    START XCLICKER INSTALL

+----------------------------+

"
# xclicker - auto clicker
flatpak install xyz.xclicker.xclicker -y
echo "

+--------------------------+ 

    END XCLICKER INSTALL

+--------------------------+

"



echo "




"



echo "

+--------------------------------+ 

    START COREKEYBOARD INSTALL

+--------------------------------+

"
# CoreKeyboard - virtual keyboard (EOL)
flatpak install org.cubocore.CoreKeyboard -y
echo "

+------------------------------+ 

    END COREKEYBOARD INSTALL

+------------------------------+

"

echo "




"




echo "

+--------------------------------+ 

    START STICKY NOTES INSTALL

+--------------------------------+

"
# sticky notes
flatpak install com.vixalien.sticky -y
echo "

+------------------------------+ 

    END STICKY NOTES INSTALL

+------------------------------+

"

echo "




"




echo "

+-----------------------+ 

    START OBS INSTALL

+-----------------------+

"
# obs - screen capture
flatpak install com.obsproject.Studio -y
echo "

+---------------------+ 

    END OBS INSTALL

+---------------------+

"





echo "

+----------------------------+ 

    START AUDACITY INSTALL

+----------------------------+

"
# audacity
flatpak install org.audacityteam.Audacity -y
echo "

+--------------------------+ 

    END AUDACITY INSTALL

+--------------------------+

"



echo "












"



echo "

+-----------------------------------------+ 

        START TUBECONVERTER INSTALL

+-----------------------------------------+

"
# tubeconverter
flatpak install org.nickvision.tubeconverter -y
echo "

+---------------------------------------+ 

        END TUBECONVERTER INSTALL

+---------------------------------------+

"






echo "












"






echo "

+-------------------------------------+ 

        START KEEPASSXC INSTALL

+-------------------------------------+

"
# password manager
flatpak install app/org.keepassxc.KeePassXC/x86_64/stable -y
echo "

+-----------------------------------+ 

        END KEEPASSXC INSTALL

+-----------------------------------+

"



echo "












"


###############################################################

###############           PPA                   ###############

###############################################################


echo "

+----------------------------------+ 

    PPA APPS INSTALLATIONS BEGIN

+----------------------------------+

"


echo "




"




# vscodium - open source and telemetry-free visual studio code
echo "

+----------------------------+ 

    START VSCODIUM INSTALL

+----------------------------+

"
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor \
    | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
    
    echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
    | sudo tee /etc/apt/sources.list.d/vscodium.list
    
    sudo apt update && sudo apt install codium
echo "

+--------------------------+ 

    END VSCODIUM INSTALL

+--------------------------+

"



echo "




"



# brave ppa - browser
echo "

+-------------------------+ 

    START BRAVE INSTALL

+-------------------------+

"
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update
sudo apt install brave-browser -y
echo "

+-----------------------+ 

    END BRAVE INSTALL

+-----------------------+

"



echo "




"



# nextcloud - self-hosted cloud storage -- webhosting
echo "

+-----------------------------+ 

    START NEXTCLOUD INSTALL

+-----------------------------+

"
sudo add-apt-repository ppa:nextcloud-devs/client -y
sudo apt update
sudo apt install nextcloud-client -y
echo "

+---------------------------+ 

    END NEXTCLOUD INSTALL

+---------------------------+

"



echo "

















"




###############################################################

#############            CLEANUP           ####################              

###############################################################

echo "

+------------------------------------+ 

    START PRE-INSTALLED APPS PURGE

+------------------------------------+

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
sudo apt purge mintwelcome -y
sudo apt purge drawing -y
sudo apt purge xed -y
sudo apt purge lightsoff -y
sudo apt purge hitori -y
sudo apt purge quadrapassel -y
sudo apt purge shotwell -y
sudo apt purge swell-foop -y
sudo apt purge tali -y
sudo apt purge evolution -y


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
sudo apt purge evince -y

### cinammon DE remove
sudo apt purge cinnamon* -y




echo "

+----------------------------------+ 

    END PRE-INSTALLED APPS PURGE

+----------------------------------+

"


echo "






"


###############################################################

##########        DON'T ADD CODE AFTER THIS          ##########

###############################################################


echo "








"


# update , upgrade , autoremove
echo "

+------------------------+ 

    START 2ND UPDATERS

+------------------------+

"
sudo apt update && sudo apt full-upgrade -y && sudo apt --fix-broken install -y && sudo apt autoremove -y && sudo apt clean && flatpak update -y
echo "

+----------------------+ 

    END 2ND UPDATERS

+----------------------+

"




echo "

+--------------+ 

    END CODE

+--------------+

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
