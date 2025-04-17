#!/bin/bash

start_time=$(date '+%d-%m-%Y___%H-%M-%S')

StartDiskSpace=$(df -h)

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
read -r -p "Press Enter to continue..."
echo "Continuing..."





echo "




+---------------------------------+ 

        START INSTALL GNOME

+---------------------------------+




"
# gnome
sudo apt install gnome gnome-tweaks -y

# REQUIREMENT for ffmpeg media online (twitch and other streaming platforms)
sudo apt install ubuntu-restricted-extras -y
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
echo -e "If it freezes spam ENTER:\n"
# latex 
sudo apt install texlive-full -y 

echo "




+---------------------------------+ 

        END   INSTALL LATEX

+---------------------------------+




"



echo "




+------------------------------------+ 

        START INSTALL SCANNERS

+------------------------------------+




"
echo -e "\n\n\n\n  Clamav:"
# clamav - antivirus and DB create-update
sudo apt install clamav clamav-daemon clamav-freshclam -y
clamconf
sudo freshclam
echo -e "\n\n\n\n  Rk hunter:"
# rkhunter - rootkit
sudo apt install rkhunter -y
echo "




+------------------------------------+ 

        END   INSTALL SCANNERS

+------------------------------------+




"









########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################




touch "$pathFile"

echo -e "\n\nFrom now on is automatic\n Continuing with the script...\n\n\tCheck log: $pathFile "



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
# check broken pkg and updater
sudo dpkg --configure -a 
sudo apt --fix-broken install -y  
sudo apt update
sudo apt full-upgrade -y 
sudo apt autoremove -y 
sudo apt clean
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




+----------------------------------------+ 

        START INSTALL PC UTILITIES

+----------------------------------------+




"

pcUtilitiesPackages=(
        #### Github & gh
        wget 
        curl 
        git 
        gh              #### gh (github session login)
        smartmontools   #### temp check
        neofetch        #### sys info
        gufw            #### firewall
        htop            #### task manager
        redshift        #### night light
        playerctl       #### media player control
        fzf             #### terminal interactive selection
        nemo            #### file explorer
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
)

printf '%s\n\n' "${pcUtilitiesPackages[@]}" \
  | xargs -I{} bash -c 'echo -e "\n\n\n\t• Installing: {}" && sudo apt install -y "{}"' \
>> "$pathFile" 2>&1

echo "




+----------------------------------------+ 

        END   INSTALL PC UTILITIES

+----------------------------------------+




"







echo "




+----------------------------------------------------+ 

        START INSTALL GAMING LIBS && UTILITIES

+----------------------------------------------------+




"

# apps, utilities, checkers, AMD GPU info
sudo apt install gamemode zram-tools cpufrequtils radeontop -y 

# additional libraries for compatibility
sudo apt install lib32gcc-s1 lib32stdc++6 libvulkan1 libvulkan1:i386 libx11-6:i386 libxext6:i386 libxrandr2:i386 libxrender1:i386 libxslt1.1:i386 libfreetype6:i386 libpng16-16:i386 libz1:i386 libsdl2-2.0-0 libsdl2-2.0-0:i386 vainfo libva-glx2 libva-glx2:i386 libva2 libva2:i386  libcurl4-openssl-dev libxrandr-dev libxinerama-dev libudev-dev libpci3 -y

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
sudo apt install liba52-0.7.4 libfaac-dev libopus-dev libvorbis-dev libflac-dev libtheora-dev libquicktime2 libswscale-dev libpostproc-dev libavfilter-dev libbluray-dev libdvdread8 libdvdnav4 libopenexr-dev libpng-dev libjpeg-dev kdenlive-data gpac v4l-utils libx264-dev libx265-dev gmic libdvdnav-dev libdvdread-dev libv4l-0 libx11-6 libxext6 libpulse0 libomxil-bellagio0 libjack-jackd2-0 libsdl2-2.0-0 libfaad2 libglib2.0-0 libxrender1 -y 



# gimp 
sudo apt install libjpeg-turbo8 libgegl-dev libheif1 libjpeg-turbo8 libgegl-dev libheif1 libtiff-tools libtiff-dev libpng-dev libwebp-dev colord icc-profiles argyll imagemagick exiv2 libexif-dev pngquant libopenjp2-7 -y 
echo "




+--------------------------------------------------------------+ 

        END   INSTALL EDITING DEPENDENCIES && MEDIA LIBS

+--------------------------------------------------------------+




"





echo "




+---------------------------------------+ 

        START INSTALL COMMON APPS

+---------------------------------------+




"
appPackages=(
        vlc
        gedit 
        gnome-text-editor 
        xreader
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
        piper           #### logitech mouse software
        #### clipboard manager - lib dependencies
        gir1.2-gda-5.0 
        gir1.2-gsound-1.0 

)


printf '%s\n\n' "${appPackages[@]}" \
  | xargs -I{} bash -c 'echo -e "\n\n\n\t• Installing {}..." && sudo apt install -y "{}"' \
>> "$pathFile" 2>&1

echo "




+---------------------------------------+ 

        END   INSTALL COMMON APPS

+---------------------------------------+




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



#### swap allocation 
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



flatpakAppPackages=(
    com.brave.Browser
    app/com.google.Chrome/x86_64/stable
    com.github.tchx84.Flatseal/x86_64/stable    #### flatseal - flatpak permissions
    app/com.mattjakeman.ExtensionManager/x86_64/stable  #### GNOME - Extension Manager
    #### Steam
    com.valvesoftware.Steam 
    com.valvesoftware.Steam.CompatibilityTool.Proton-GE
    #### Gimp
    org.gimp.GIMP/x86_64/stable
    ##############
    app/com.discordapp.Discord/x86_64/stable
    app/org.musescore.MuseScore/x86_64/stable   #### music sheet editor
    app/net.christianbeier.Gromit-MPX/x86_64/stable #### draw on screen
    page.codeberg.libre_menu_editor.LibreMenuEditor #### app info and editor
    org.cubocore.CoreKeyboard       #### virtual keyboard (EOL)
    com.obsproject.Studio           #### OBS
    org.audacityteam.Audacity       #### Audacity
    app/org.keepassxc.KeePassXC/x86_64/stable   #### Database DB
)



printf '%s\n\n' "${flatpakAppPackages[@]}" \
  | xargs -I{} bash -c 'echo -e "\n\n\n\t• Installing {}..." && flatpak install -y "{}"' \
>> "$pathFile" 2>&1

#### required steam addon
sudo apt install steam-devices -y 



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
# check broken pkg and updater
sudo dpkg --configure -a 
sudo apt --fix-broken install -y  
sudo apt update
sudo apt full-upgrade -y 
sudo apt autoremove -y 
sudo apt clean

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




########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################



#### log
end_time=$(date '+%d-%m-%Y___%H:%M:%S')

EndDiskSpace=$(df -h)


echo "

                +------------------+ 

                        INFO

                +------------------+

"

echo -e "Start time:\t\t$start_time"
echo -e "End time:\t\t$end_time"

echo -e "\n\n"


echo -e "Start disk space:\t\t$StartDiskSpace"
echo -e "End disk space:\t\t$EndDiskSpace \n\n"




} >> "$pathFile" 2>&1 


#### Bash easy updater
# bashupd
sudo cp $HOME/newPc_Install/bashRC.sh $HOME/.bashrc && exec bash
# aliupd
sudo cp $HOME/newPc_Install/bash_aliases.sh $HOME/.bash_aliases && source $HOME/.bash_aliases

echo -e "Rebooting now..."
sleep 3s
reboot 





########################################################################################################
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

