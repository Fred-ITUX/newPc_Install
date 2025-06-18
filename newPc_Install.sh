#!/bin/bash

start_time=$(date '+%d-%m-%Y___%H-%M-%S')

StartDiskSpace=$(df -h)

pathFile="$HOME/newPC_$start_time.txt"

SWAP=16



########################################################


echo -e "\n\n
    +--------------------------+ 

            REQUIREMENTS

    +--------------------------+

    > ~45GB of apps and utilities (7GB for latex)
    > ~30min to end
    > "$SWAP"GB swap memory will be created
    > The pc will automatically reboot at the end \n\n\n
"
read -r -p "Press Enter to continue..."
echo -e "Continuing..."





echo -e "\n\n\n\n\n
+---------------------------------+ 

        START INSTALL GNOME

+---------------------------------+\n\n\n\n\n"

# gnome
sudo apt install gnome gnome-tweaks -y

# REQUIREMENT for ffmpeg media online (twitch and other streaming platforms)
sudo apt install ubuntu-restricted-extras -y
echo -e "\n\n\n\n\n
+---------------------------------+ 

        END   INSTALL GNOME

+---------------------------------+\n\n\n\n\n"






echo -e "\n\n\n\n\n
+-----------------------------------+ 

        START INSTALL FLATPAK

+-----------------------------------+\n\n\n\n\n"

# flatpak download
sudo apt install flatpak -y
flatpak install flathub -y
echo -e "\n\n\n\n\n
+-----------------------------------+ 

        END   INSTALL FLATPAK

+-----------------------------------+\n\n\n\n\n"





 
echo -e "\n\n\n\n\n
+----------------------------------+ 

        START INSTALL PYTON3

+----------------------------------+\n\n\n\n\n"

# Python apt packages
pythonPackages=(
  python3-full
  python3-pip
  python3-ipykernel
  python3-pandas
  python3-xlsxwriter
  python3-seaborn
  python3-notify2
  python3-mutagen
  python3-fuzzywuzzy
  python3-pil
  python3-srt
  pipx
)

printf '%s\n\n' "${pythonPackages[@]}" \
  | xargs -I{} bash -c 'echo -e "\n\n\n\t• Installing {}..." && sudo apt install -y "{}"' \
>> "$pathFile" 2>&1


# pipx path fix
pipx ensurepath
# speech to text -- system-wide install
pip3 install vosk --break-system-packages
# yt downloader
pipx install "yt-dlp[default]"

echo -e "\n\n\n\n\n
+----------------------------------+ 

        END   INSTALL PYTON3

+----------------------------------+\n\n\n\n\n"




echo -e "\n\n\n\n\n
+---------------------------------+ 

        START INSTALL LATEX

+---------------------------------+\n\n\n\n\n"

echo -e "If it freezes spam ENTER:\n"
# latex 
sudo apt install texlive-full -y 

echo -e "\n\n\n\n\n
+---------------------------------+ 

        END   INSTALL LATEX

+---------------------------------+\n\n\n\n\n"




echo -e "\n\n\n\n\n
+------------------------------------+ 

        START INSTALL SCANNERS

+------------------------------------+\n\n\n\n\n"

echo -e "\n\n\n\n  Clamav:"
# clamav - antivirus and DB create-update
sudo apt install clamav clamav-daemon clamav-freshclam -y
clamconf
sudo freshclam
echo -e "\n\n\n\n  Rk hunter:"
# rkhunter - rootkit
sudo apt install rkhunter -y
echo -e "\n\n\n\n\n
+------------------------------------+ 

        END   INSTALL SCANNERS

+------------------------------------+\n\n\n\n\n"

########################################################################################################
########################################################################################################
########################################################################################################


touch "$pathFile"

echo -e "\n\nFrom now on is automatic\n Continuing with the script...\n\n\tCheck log: $pathFile "



#### prompt avoid
export DEBIAN_FRONTEND=noninteractive


{

echo -e "

        +------------------------+ 

                CODE START

        +------------------------+

"




echo -e "\n\n\n
+-----------------------------------------------------------+ 

        START UPDATE, FULL UPGRADE AND CHECK INSTALLS

+-----------------------------------------------------------+\n\n\n"

# check broken pkg and updater
sudo dpkg --configure -a 
sudo apt --fix-broken install -y  
sudo apt update
sudo apt full-upgrade -y 
sudo apt autoremove -y 
sudo apt clean
echo -e "\n\n\n
+---------------------------------------------------------+ 

        END UPDATE, FULL UPGRADE AND CHECK INSTALLS

+---------------------------------------------------------+\n\n\n"


########################################################################################################
########################################################################################################
########################################################################################################




echo -e "\n\n\n\n\n
        +------------------------------------------+ 

                REPOSITORY && APT APPS BEGIN

        +------------------------------------------+\n\n\n\n\n"




echo -e "\n\n\n\n\n
+----------------------------------------+ 

        START INSTALL PC UTILITIES

+----------------------------------------+\n\n\n\n\n"


pcUtilitiesPackages=(
        #### Github & gh
        wget 
        curl 
        git 
        gh                                      #### github session login
        smartmontools                           #### temp check
        neofetch                                #### sys info
        gufw                                    #### firewall
        htop                                    #### task manager
        redshift                                #### brightness and night light -- X11
        ddcutil                                 #### only brightness            -- Wayland
        playerctl                               #### media player control
        fzf                                     #### terminal interactive selection
        nemo                                    #### file explorer
        moreutils                               #### ts command and other ut
        #### Wine
        wine 
        wine64 
        wine32 
        winetricks
        #### Pulseaudio
        pulseaudio
        pavucontrol 
        pulseaudio-module-bluetooth 
        bluez 
        bluez-tools
        font-manager
        jq                                      #### lightweight, flexible command-line JSON processor
)

printf '%s\n\n' "${pcUtilitiesPackages[@]}" \
  | xargs -I{} bash -c 'echo -e "\n\n\n\t• Installing: {}" && sudo apt install -y "{}"' \
>> "$pathFile" 2>&1

echo -e "\n\n\n\n\n
+----------------------------------------+ 

        END   INSTALL PC UTILITIES

+----------------------------------------+\n\n\n\n\n"








echo -e "\n\n\n\n\n
+----------------------------------------------------+ 

        START INSTALL GAMING LIBS && UTILITIES

+----------------------------------------------------+\n\n\n\n\n"


# apps, utilities, checkers, AMD GPU info
sudo apt install gamemode zram-tools cpufrequtils radeontop -y 

# additional libraries for compatibility
sudo apt install lib32gcc-s1 lib32stdc++6 libvulkan1 libvulkan1:i386 libx11-6:i386 libxext6:i386 libxrandr2:i386 libxrender1:i386 libxslt1.1:i386 libfreetype6:i386 libpng16-16:i386 libz1:i386 libsdl2-2.0-0 libsdl2-2.0-0:i386 vainfo libva-glx2 libva-glx2:i386 libva2 libva2:i386  libcurl4-openssl-dev libxrandr-dev libxinerama-dev libudev-dev libpci3 -y

echo -e "\n\n\n\n\n
+----------------------------------------------------+ 

        END   INSTALL GAMING LIBS && UTILITIES

+----------------------------------------------------+\n\n\n\n\n"










echo -e "\n\n\n\n\n
+--------------------------------------------------------------+ 

        START INSTALL EDITING DEPENDENCIES && MEDIA LIBS

+--------------------------------------------------------------+\n\n\n\n\n"

# kden plugins and addons, melt (backend), mediainfo (media details), handbrake (file converter), nomacs (simple photo editor/viewer)
sudo apt install ffmpeg* melt frei0r-plugins ladspa-sdk sox gstreamer1.0-libav libx264-dev libx265-dev libvpx-dev libmp3lame0 handbrake mediainfo nomacs libmlt-data -y 

# more media and editing oriented libs
sudo apt install liba52-0.7.4 libfaac-dev libopus-dev libvorbis-dev libflac-dev libtheora-dev libquicktime2 libswscale-dev libpostproc-dev libavfilter-dev libbluray-dev libdvdread8 libdvdnav4 libopenexr-dev libpng-dev libjpeg-dev kdenlive-data gpac v4l-utils libx264-dev libx265-dev gmic libdvdnav-dev libdvdread-dev libv4l-0 libx11-6 libxext6 libpulse0 libomxil-bellagio0 libjack-jackd2-0 libsdl2-2.0-0 libfaad2 libglib2.0-0 libxrender1 -y 

# gimp 
sudo apt install libjpeg-turbo8 libgegl-dev libheif1 libjpeg-turbo8 libgegl-dev libheif1 libtiff-tools libtiff-dev libpng-dev libwebp-dev colord icc-profiles argyll imagemagick exiv2 libexif-dev pngquant libopenjp2-7 -y 
echo -e "\n\n\n\n\n
+--------------------------------------------------------------+ 

        END   INSTALL EDITING DEPENDENCIES && MEDIA LIBS

+--------------------------------------------------------------+\n\n\n\n\n"






echo -e "\n\n\n\n\n
+---------------------------------------+ 

        START INSTALL COMMON APPS

+---------------------------------------+\n\n\n\n\n"


appPackages=(
        vlc
        gedit 
        gnome-text-editor 
        xreader
        piper                                   #### logitech mouse software
        rocm-smi                                #### AMD GPU smi info
        #### libre office & fonts
        libreoffice 
        fonts-liberation 
        fonts-dejavu 
        fonts-cantarell 
        fonts-noto 
        fonts-stix 
        pdftk 
        tesseract-ocr 
        poppler-utils 
        libreoffice-gtk3
        #### clipboard manager - lib dependencies
        gir1.2-gda-5.0 
        gir1.2-gsound-1.0 
        #### themes & libs for gtk
        xdg-utils
        gir1.2-xapp-1.0
        libcanberra-gtk-module 
        libcanberra-gtk3-module
        
)


printf '%s\n\n' "${appPackages[@]}" \
  | xargs -I{} bash -c 'echo -e "\n\n\n\t• Installing {}..." && sudo apt install -y "{}"' \
>> "$pathFile" 2>&1

echo -e "\n\n\n\n\n
+---------------------------------------+ 

        END   INSTALL COMMON APPS

+---------------------------------------+\n\n\n\n\n"






echo -e "\n\n\n\n\n
        +----------------------------------------+ 

                REPOSITORY && APT APPS END

        +----------------------------------------+\n\n\n\n\n"





########################################################################################################
########################################################################################################
########################################################################################################



echo -e "

            +-------------------+ 

                    OTHER

            +-------------------+

"




echo -e "\n\n\n
+----------------------------------+ 

        GTK TERMINAL PADDING

+----------------------------------+\n\n\n"


#### padding for older and newer gtk compatibility

echo -e "VteTerminal,
TerminalScreen,
vte-terminal {
    padding: 20px 20px 20px 20px;
    -VteTerminal-inner-border: 20px 20px 20px 20px;}" | sudo tee -a ~/.config/gtk-2.0/gtk.css

echo -e "VteTerminal,
TerminalScreen,
vte-terminal {
    padding: 20px 20px 20px 20px;
    -VteTerminal-inner-border: 20px 20px 20px 20px;}" | sudo tee -a ~/.config/gtk-3.0/gtk.css

echo -e "VteTerminal,
TerminalScreen,
vte-terminal {
    padding: 20px 20px 20px 20px;
    -VteTerminal-inner-border: 20px 20px 20px 20px;}" | sudo tee -a ~/.config/gtk-4.0/gtk.css



################################################################################################



#### swap allocation 
echo -e "\n\n\n\n\n
+-----------------------------------+ 

        START SWAP ALLOCATION

+-----------------------------------+\n\n\n"

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
echo -e "vm.swappiness=30" | sudo tee -a /etc/sysctl.conf    
cat /proc/sys/vm/vfs_cache_pressure
sudo sysctl vm.vfs_cache_pressure=40
echo -e "vm.vfs_cache_pressure=40" | sudo tee -a /etc/sysctl.conf
echo -e "\n\n\n
+---------------------------------+ 

        END SWAP ALLOCATION

+---------------------------------+\n\n\n\n\n"


########################################################################################################
########################################################################################################
########################################################################################################

echo -e "\n\n\n\n\n
        +--------------------------------+ 

                FLATPAK APPS BEGIN

        +--------------------------------+\n\n\n\n\n"

flatpakAppPackages=(
    com.brave.Browser
    app/com.google.Chrome/x86_64/stable
    com.github.tchx84.Flatseal/x86_64/stable                    #### flatseal - flatpak permissions
    app/com.mattjakeman.ExtensionManager/x86_64/stable          #### GNOME - Extension Manager
    app/com.vscodium.codium/x86_64/stable                       #### VS Codium
    com.nextcloud.desktopclient.nextcloud                       #### Nextcloud desktop client
    app/com.usebottles.bottles/x86_64/stable                    #### Bottles - WINE client
    #### Steam
    com.valvesoftware.Steam 
    com.valvesoftware.Steam.CompatibilityTool.Proton-GE
    #runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/24.08 #### Gamescope for Wayland
    #### Gimp
    org.gimp.GIMP/x86_64/stable
    ##############
    app/com.discordapp.Discord/x86_64/stable
    app/org.musescore.MuseScore/x86_64/stable                   #### music sheet editor
    app/net.christianbeier.Gromit-MPX/x86_64/stable             #### draw on screen
    page.codeberg.libre_menu_editor.LibreMenuEditor             #### app info and editor
    com.obsproject.Studio                                       #### OBS
    org.audacityteam.Audacity                                   #### Audacity
    app/org.keepassxc.KeePassXC/x86_64/stable                   #### Database DB
)



printf '%s\n\n' "${flatpakAppPackages[@]}" \
  | xargs -I{} bash -c 'echo -e "\n\n\n\t• Installing {}..." && flatpak install -y "{}"' \
>> "$pathFile" 2>&1

#### required steam addon
sudo apt install steam-devices -y 


echo -e "\n\n\n\n\n
            +------------------------------+ 

                    FLATPAK APPS END

            +------------------------------+\n\n\n\n\n"


########################################################################################################
########################################################################################################
########################################################################################################


echo -e "\n\n\n\n\n
            +--------------------------------------------+ 

                    START PRE-INSTALLED APPS PURGE

            +--------------------------------------------+\n\n\n\n\n"

appToPurge=(
        #### Mint / Ubuntu apps
        thunderbird* 
        cheese 
        hypnotix 
        rhythmbox 
        aisleriot 
        celluloid  
        hexchat 
        onboard 
        mahjongg 
        pix 
        remmina 
        five-or-more 
        four-in-a-row 
        drawing 
        xed 
        lightsoff 
        hitori 
        quadrapassel 
        shotwell 
        swell-foop 
        tali 
        evolution 
        evince 
        iagno 
        warpinator
        #### Gnome apps
        gnome-mahjongg 
        gnome-mines 
        gnome-sudoku 
        gnome-todo 
        gnome-chess 
        gnome-2048 
        gnome-contacts 
        gnome-maps 
        gnome-tetravex 
        gnome-music 
        gnome-nibbles 
        gnome-klotski 
        gnome-robots 
        gnome-weather 
        gnome-remote-desktop 
        gnome-taquin 
)

printf '%s\n' "${appToPurge[@]}" \
  | xargs -I{} bash -c 'echo -e "\n\n\n\t• Uninstalling {}..." && sudo apt purge -y "{}"' \
>> "$pathFile" 2>&1

#### Cinammon DE remover
sudo apt purge cinnamon* -y
sudo apt purge mintwelcome -y


echo -e "\n\n\n\n\n
            +------------------------------------------+ 

                    END PRE-INSTALLED APPS PURGE

            +------------------------------------------+\n\n\n\n\n"




###############################################################

##########        DON'T ADD CODE AFTER THIS          ##########

###############################################################


echo -e "\n\n\n\n\n
+------------------------------------------------------------+ 

        START FINAL UPDATE, UPGRADE, CHECKS && CLEANUP

+------------------------------------------------------------+\n\n\n\n\n"

# check broken pkg and updater
sudo dpkg --configure -a 
sudo apt --fix-broken install -y  
sudo apt update
sudo apt full-upgrade -y 
sudo apt autoremove -y 
sudo apt clean

echo -e "\n\n\n\n\n
+----------------------------------------------------------+ 

        END FINAL UPDATE, UPGRADE, CHECKS && CLEANUP

+----------------------------------------------------------+\n\n\n\n\n"





echo -e "\n\n\n\n\n\n\n\n\n\n\n\n\n
            +----------------------+ 

                    END CODE

            +----------------------+\n\n\n"


########################################################################################################
########################################################################################################
########################################################################################################


#### log
end_time=$(date '+%d-%m-%Y___%H:%M:%S')

EndDiskSpace=$(df -h)


echo -e "\n\n
                +------------------+ 

                        INFO

                +------------------+\n\n"

echo -e "Start time:\t$start_time"
echo -e "End time  :\t$end_time"

echo -e "\n\nStart disk space:\t$StartDiskSpace"
echo -e "End disk space      :\t$EndDiskSpace \n\n"


} >> "$pathFile" 2>&1 


#### Bash easy updater
# bashupd
sudo cp $HOME/newPc_Install/bashRC.sh $HOME/.bashrc
# aliupd
sudo cp $HOME/newPc_Install/bash_aliases.sh $HOME/.bash_aliases && source $HOME/.bash_aliases

echo -e "Rebooting now..."
sleep 3s
reboot 




########################################################################################################
########################################################################################################
########################################################################################################

                        ####################################
                        ####                            ####
                        ####        OLD & UNUSED        ####
                        ####                            ####
                        ####################################

# # # telegram
# # flatpak install app/org.telegram.desktop/x86_64/stable -y

# # # whatsapp
# # flatpak install app/com.github.eneshecan.WhatsAppForLinux/x86_64/stable -y

# # # xclicker - auto clicker --- replaced by script
# # # flatpak install xyz.xclicker.xclicker -y 

