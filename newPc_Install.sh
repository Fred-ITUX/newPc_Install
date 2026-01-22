#!/bin/bash

start_time=$(date '+%d-%m-%Y___%H-%M-%S')

StartDiskSpace=$(df -h)

pathFile="$HOME/newPC_$start_time.txt"


###########################################################################################
####                            Swap allocation and setup

SWAP=6 #### GB

#### Favor RAM over SWAP -- range 0 to 100 higher the number higher the priority of SWAP over RAM
SWAPPINESS=10

#### Filesystem cache - more memory used to cache file access paths and metadata = smoother UI in file managers -- range 0 to 200+ 
CACHE_PRESSURE=20



if [ $SWAPPINESS -le 30 ] && [ $SWAPPINESS -ge 0 ] ; then
   SwapFavor="RAM"

elif [ $SWAPPINESS -gt 30 ] && [ $SWAPPINESS -le 100 ] ; then
    SwapFavor="SWAP"

elif [ $SWAPPINESS -gt 100 ] || [ $SWAPPINESS -lt 0 ]; then
    echo -e "Swappiness error: not in range 0 - 100. Current: $SWAPPINESS)"
    exit 1

else
    echo -e "Unexpected swappiness error: $SWAPPINESS \nExiting"
    exit 1
fi


if [ $CACHE_PRESSURE -le 30 ] && [ $CACHE_PRESSURE -ge 0 ] ; then
   cacheFavor="More RAM for cache"

elif [ $CACHE_PRESSURE -gt 30 ] && [ $CACHE_PRESSURE -le 200 ] ; then
    cacheFavor="Less RAM for cache"

elif [ $CACHE_PRESSURE -gt 200 ] || [ $CACHE_PRESSURE -lt 0 ]; then
    echo -e "CACHE_PRESSURE error: not in range 0 - 200. Current: $CACHE_PRESSURE)"
    exit 1

else
    echo -e "Unexpected CACHE_PRESSURE error: $CACHE_PRESSURE \nExiting"
    exit 1
fi
###########################################################################################


safetyUpdateCheck(){
sudo dpkg --configure -a 
sudo apt --fix-broken install -y  
sudo apt update
sudo apt full-upgrade -y 
sudo apt autoremove -y 
sudo apt clean
}

###########################################################################################


echo -e "\n\n
    +--------------------------+ 

            REQUIREMENTS

    +--------------------------+

    > "$SWAP"GB swap memory will be created
    > "Swap favor:  "$SwapFavor" - "$cacheFavor" "
    > The system will automatically reboot at the end \n\n"

read -r -p "Press Enter to continue..."
echo -e "Continuing..."





echo -e "\n\n\n\n\n
+---------------------------------+ 

        START INSTALL GNOME

+---------------------------------+\n\n\n\n\n"
sudo apt install gnome-shell gnome-terminal gnome-tweaks ubuntu-restricted-extras -y #### ubuntu extras for DRM streaming
echo -e "\n\n\n\n\n
+---------------------------------+ 

        END   INSTALL GNOME

+---------------------------------+\n\n\n\n\n"




echo -e "\n\n\n\n\n
+----------------------------------+ 

        START INSTALL PYTON3

+----------------------------------+\n\n\n\n\n"

pythonPackages=(
    python3-pip
    python3-ipykernel
    python3-pandas
    python3-xlsxwriter
    python3-seaborn
    python3-mutagen
    python3-fuzzywuzzy
    python3-pil
    python3-srt
    pipx
)

# python3-full

printf '%s\n\n' "${pythonPackages[@]}" \
  | xargs -I{} bash -c 'echo -e "\n\n\n\t• Installing {}..." && sudo apt install -y "{}"' \
>> "$pathFile" 2>&1


pipx ensurepath #### pipx path fix
pip3 install vosk --break-system-packages #### speech to text -- system-wide install
pipx install yt-dlp #### pipx install "yt-dlp[default]"

echo -e "\n\n\n\n\n
+----------------------------------+ 

        END   INSTALL PYTON3

+----------------------------------+\n\n\n\n\n"

#### latex 
echo -e "LateX (texlive-full) install.\n Spam ENTER if it freezes.\n"
sudo apt install texlive-full -y 

echo -e "\n\n\n\n\n
+------------------------------------+ 

        START INSTALL SCANNERS

+------------------------------------+\n\n\n\n\n"
echo -e "\n\n\n\n  Clamav:"
sudo apt install clamav clamav-daemon clamav-freshclam -y
clamconf
sudo freshclam
echo -e "\n\n\n\n  Rk hunter:"
sudo apt install rkhunter -y
echo -e "\n\n\n\n\n
+------------------------------------+ 

        END   INSTALL SCANNERS

+------------------------------------+\n\n\n\n\n"



##################################################################
##################################################################


touch "$pathFile"

echo -e "\n\nFrom now on is automatic\n Continuing with the script...\n\n\tCheck log: $pathFile "

export DEBIAN_FRONTEND=noninteractive #### prompt avoid


{

echo -e "\n\n
        +------------------------+ 

                CODE START

        +------------------------+\n\n\n"




echo -e "\n\n\n
+-----------------------------------------------------------+ 

        START UPDATE, FULL UPGRADE AND CHECK INSTALLS

+-----------------------------------------------------------+\n\n\n"
safetyUpdateCheck
echo -e "\n\n\n
+---------------------------------------------------------+ 

        END UPDATE, FULL UPGRADE AND CHECK INSTALLS

+---------------------------------------------------------+\n\n\n"


##################################################################
##################################################################

echo -e "\n\n\n\n\n
        +------------------------------------------+ 

                REPOSITORY && APT APPS BEGIN

        +------------------------------------------+\n\n\n\n\n"



echo -e "\n\n\n\n\n
+---------------------------------------+ 

        START INSTALL COMMON APPS

+---------------------------------------+\n\n\n\n\n"

appPackages=(
        flatpak
        wget 
        curl 
        git 
        gh                                      #### github session login
        smartmontools                           #### temp check
        neofetch                                #### sys info
        gufw                                    #### firewall
        htop                                    #### task manager
        redshift                                #### brightness and night light -- X11
        xdotool                                 #### X11 -- window / keyboard utilities
        ddcutil                                 #### change monitors brightness
        playerctl                               #### media player control
        fzf                                     #### terminal interactive selection
        nemo                                    #### file explorer
        moreutils                               #### ts command and other ut
        jq                                      #### lightweight, flexible command-line JSON processor
        rar
        p7zip-full 
        p7zip-rar
        tree                                    #### ls tree
        wine 
        wine64 
        wine32 
        winetricks
        pulse*
        pavucontrol 
        pulseaudio-module-bluetooth 
        bluez 
        bluez-tools
        font-manager
        vlc
        gedit 
        piper                                   #### logitech mouse software
        #### clipboard manager - lib dependencies
        gir1.2-gda-5.0 
        gir1.2-gsound-1.0 
        #### themes & libs for gtk
        xdg-utils
        gir1.2-xapp-1.0
        libcanberra-gtk-module 
        libcanberra-gtk3-module
        adwaita-*                               ##### adwaita icons
)


printf '%s\n\n' "${appPackages[@]}" \
  | xargs -I{} bash -c 'echo -e "\n\n\n\t• Installing {}..." && sudo apt install -y "{}"' \
>> "$pathFile" 2>&1


echo -e "\n\n\n\n\n
+---------------------------------------+ 

        END   INSTALL COMMON APPS

+---------------------------------------+\n\n\n\n\n"





echo -e "\n\n\n\n\n
+---------------------------------------------+ 

        START INSTALL LIBS && UTILITIES

+---------------------------------------------+\n\n\n\n\n"

echo -e "\n\n\n • Development / Build Tools"
sudo apt install -y build-essential cmake git pkg-config wget curl libx11-dev libxext-dev libxfixes-dev libxcb1-dev libxcb-dri3-dev libxcb-xfixes0-dev libdrm-dev libopengl-dev libfontconfig1-dev libcurl4-openssl-dev libxrandr-dev libxinerama-dev libudev-dev libpci3 || true

echo -e "\n\n\n • Video / Kdenlive / MLT / FFmpeg"
sudo apt install -y ffmpeg ffmpegthumbs melt libmlt7 libmlt++7 libmlt-data libmlt-dev libmlt++-dev frei0r-plugins libvpx-dev libx264-dev libx265-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libavfilter-dev libavdevice-dev libpostproc-dev libbluray-dev libchromaprint-dev libmp3lame0 libopus-dev libvorbis-dev libflac-dev libtheora-dev libquicktime2 liba52-0.7.4 libfaac-dev libfaad2 libdvdread8 libdvdread-dev libdvdnav4 libdvdnav-dev libv4l-0 v4l-utils mediainfo kdenlive-data mkvtoolnix mpv || true

echo -e "\n\n\n • Audio / Sound / Plugins"
sudo apt install -y ladspa-sdk sox libpulse-dev libjack-jackd2-dev libsoxr-dev || true

echo -e "\n\n\n • Graphics / Photo / Imaging"
sudo apt install -y libgegl-dev libheif1 libtiff-tools libtiff-dev libpng-dev libjpeg-dev libwebp-dev colord icc-profiles argyll imagemagick exiv2 libexif-dev pngquant libopenjp2-7 gmic || true

echo -e "\n\n\n • Hardware Acceleration / GPU / Video Output"
sudo apt install -y libva-dev vainfo mesa-va-drivers libvdpau-dev libva-glx2 libva2 libva2:i386 mesa-utils mesa-vulkan-drivers libvulkan1 libvulkan1:i386 || true

echo -e "\n\n\n • 32-bit / Gaming / Extra Libraries"
sudo apt install -y lib32gcc-s1 lib32stdc++6 libx11-6:i386 libxext6:i386 libxrandr2:i386 libxrender1:i386 libxslt1.1:i386 libfreetype6:i386 libpng16-16:i386 libsdl2-2.0-0 libsdl2-2.0-0:i386 gamemode zram-tools cpufrequtils radeontop || true

echo -e "\n\n\n\n\n
+---------------------------------------------+ 

        END   INSTALL LIBS && UTILITIES

+---------------------------------------------+\n\n\n\n\n"





echo -e "\n\n\n\n\n
        +----------------------------------------+ 

                REPOSITORY && APT APPS END

        +----------------------------------------+\n\n\n\n\n"


##################################################################
##################################################################



echo -e "\n\n\n
+----------------------------------+ 

        GTK TERMINAL PADDING

+----------------------------------+\n\n\n"

#### padding for older and newer gtk compatibility
terminalPadding="VteTerminal,
TerminalScreen,
vte-terminal {
    padding: 20px 20px 20px 20px;
    -VteTerminal-inner-border: 20px 20px 20px 20px;}"

echo -e "$terminalPadding" | sudo tee -a ~/.config/gtk-2.0/gtk.css

echo -e "$terminalPadding" | sudo tee -a ~/.config/gtk-3.0/gtk.css

echo -e "$terminalPadding" | sudo tee -a ~/.config/gtk-4.0/gtk.css


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


sudo sysctl vm.swappiness="$SWAPPINESS"
echo -e "vm.swappiness=$SWAPPINESS" | sudo tee -a /etc/sysctl.conf   
echo "$"$SWAPPINESS"" | sudo tee /proc/sys/vm/swappiness


sudo sysctl vm.vfs_cache_pressure="$CACHE_PRESSURE"
echo "$CACHE_PRESSURE" | sudo tee /proc/sys/vm/vfs_cache_pressure
echo -e "vm.vfs_cache_pressure=$CACHE_PRESSURE" | sudo tee -a /etc/sysctl.conf



swapCheck=$(sudo swapon --show)
echo -e "Swap check: $swapCheck"

echo -e "\n\n\n
+---------------------------------+ 

        END SWAP ALLOCATION

+---------------------------------+\n\n\n\n\n"


##################################################################
##################################################################

echo -e "\n\n\n\n\n
        +--------------------------------+ 

                FLATPAK APPS BEGIN

        +--------------------------------+\n\n\n\n\n"

flatpak install flathub -y 

flatpakAppPackages=(
    com.brave.Browser
    app/com.google.Chrome/x86_64/stable
    org.torproject.torbrowser-launcher
    com.github.tchx84.Flatseal/x86_64/stable                    #### flatseal - flatpak permissions
    app/com.mattjakeman.ExtensionManager/x86_64/stable          #### GNOME - Extension Manager
    app/com.vscodium.codium/x86_64/stable                       #### VS Codium
    com.nextcloud.desktopclient.nextcloud                       #### Nextcloud desktop client
    app/com.usebottles.bottles/x86_64/stable                    #### Bottles - WINE client
    app/org.kde.okular/x86_64/stable                            #### Pdf reader / highlight
    com.valvesoftware.Steam 
    com.valvesoftware.Steam.CompatibilityTool.Proton-GE
    org.nomacs.ImageLounge                                      #### Photo viewer / light editor
    org.gimp.GIMP/x86_64/stable                                 #### Gimp
    app/com.discordapp.Discord/x86_64/stable
    # app/org.musescore.MuseScore/x86_64/stable                   #### music sheet editor
    app/net.christianbeier.Gromit-MPX/x86_64/stable             #### draw on screen
    page.codeberg.libre_menu_editor.LibreMenuEditor             #### app info and editor
    com.obsproject.Studio                                       #### OBS
    org.audacityteam.Audacity                                   #### Audacity
    app/org.keepassxc.KeePassXC/x86_64/stable                   #### Database DB
    org.libreoffice.LibreOffice 
    org.gnome.TextEditor
    # net.pcsx2.PCSX2                                             #### Ps2
    # org.ppsspp.PPSSPP                                           #### PsP
    net.kuribo64.melonDS/x86_64/stable                          #### Ds
    app/io.mgba.mGBA/x86_64/stable                              #### Gba
)


printf '%s\n\n' "${flatpakAppPackages[@]}" \
  | xargs -I{} bash -c 'echo -e "\n\n\n\t• Installing {}..." && flatpak install flathub -y "{}"' \
>> "$pathFile" 2>&1

sudo apt install steam-devices -y #### required steam addon


echo -e "\n\n\n\n\n
            +------------------------------+ 

                    FLATPAK APPS END

            +------------------------------+\n\n\n\n\n"


##################################################################
##################################################################


echo -e "\n\n\n\n\n
            +--------------------------------------------+ 

                    START PRE-INSTALLED APPS PURGE

            +--------------------------------------------+\n\n\n\n\n"

appToPurge=(
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
        mintchat
        baobab
        totem
        oeg
        mintistall
        mintwelcome
        transmission-gtk 
        webapp-manager
        gnome-software
        gnome-calendar
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

#### Remove Cinammon DE and re-install nemo
sudo apt purge cinnamon* -y
sudo apt install nemo -y


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
safetyUpdateCheck
echo -e "\n\n\n\n\n
+----------------------------------------------------------+ 

        END FINAL UPDATE, UPGRADE, CHECKS && CLEANUP

+----------------------------------------------------------+\n\n\n\n\n"



echo -e "\n\n\n\n\n\n\n\n\n\n\n\n\n
            +----------------------+ 

                    END CODE

            +----------------------+\n\n\n"


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

reboot 
