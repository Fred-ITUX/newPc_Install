#!/bin/bash
set -uo pipefail


if [ -d "$HOME/Nextcloud" ]; then
    echo -e "Nextcloud path found $HOME/Nextcloud\n"
    read -r -p "Press enter to continue" 
else    
    echo -e "Run only after Nextcloud setup..."
    exit 1
fi


brokenEnv=false

if [ -s "$HOME/.bash_common" ]; then source "$HOME/.bash_common"; else echo -e "[CRITICAL ERROR] Bash module not found: $HOME/.bash_common"; brokenEnv=true; fi

if $brokenEnv; then
    echo -e "[CRITICAL ERROR] Enviroment degraded, functions disabled"
    return 1
fi;



[ "$EUID" -ne 0 ] || { sysLogger e "Run as normal user, not root." >&2; exit 1; }


######################################################################################



log="$HOME/Nextcloud/Linux/log/newPc_history/newPc_Scripts_$(date +%F_%H-%M-%S).log"

mkdir -p "$(dirname "$log")" || { sysLogger e "Folder creation failed: "$(dirname "$log")"" ; exit 1; }
exec > >(tee -a "$log") 2>&1 || { sysLogger e "File creation failed: "$log"" ; exit 1; }



EXTRA_LXscripts="$HOME/Nextcloud/Linux/scripts"

if [ ! -d "$EXTRA_LXscripts"  ]; then sysLogger e "master path not found $EXTRA_LXscripts \nAborting execution"; exit 1; fi


sysLogger i "Adding executable to '*.sh' scripts under "$EXTRA_LXscripts""

find "$EXTRA_LXscripts" -type f -name "*.sh" -exec chmod +x {} + || { sysLogger e "adding execution to all '.sh' files under "$EXTRA_LXscripts" triggered an unexpected error, aborting"; exit 1 ;}

sysLogger i "All the .sh scripts under "$EXTRA_LXscripts" are now executables"



######################################################################################



newpcHistory(){
    local dest="$HOME/Nextcloud/Linux/log/newPc_history"

    sysLogger i "Saving 'newPc' log for history"

    mkdir -p "$dest" || { sysLogger e "failed to create folder "$dest""; return 1;}
    
    sudo find /root -maxdepth 1 -name 'newPC_*.txt' -exec cp -- {} "$dest/" \;
    sudo chown -R "$USER:$USER" "$dest"
}



######################################################################################



startupBootstrap(){
    local fileEntry 
    local autostartPath="$HOME/.config/autostart"
    local autostartFile=""$autostartPath"/startup_routine.desktop"

    sysLogger i "Setup startup routine start at boot"
    mkdir -p "$autostartPath" || { sysLogger e "unexpected failure during folder creation, aborting"; return 1; }

    fileEntry="[Desktop Entry]
    Type=Application
    Exec=/home/federico/Nextcloud/Linux/scripts/Startup_Routine/startup_routine.sh
    Hidden=false
    NoDisplay=false
    X-GNOME-Autostart-enabled=true
    Name=Startup Routine
    Comment=Run my startup script"

    echo "$fileEntry" > "$autostartFile" || { sysLogger e "write failed, current file status: \n$(cat "$autostartFile")"; return 1; }

    if [ -s "$autostartFile" ]; then
        sysLogger i  "Routine installed"
    else sysLogger e "routine not installed, current file status: \n$(cat "$autostartFile")"
    fi
}



######################################################################################



GNOME_performance(){
    local limitConfPath; local limitConf
    
    sysLogger i  "Increase files processes - allows more open handles if needed, doesn't use more RAM (standard 1024)"
    echo -e "* soft nofile 1048576\n* hard nofile 1048576" | sudo tee /etc/security/limits.d/99-nofile.conf


    sysLogger i  "Reduce GNOME stalls"

    limitConfPath="$HOME/.config/systemd/user.conf.d"
    limitConf="[Manager]
    DefaultLimitNOFILE=1048576
    DefaultTasksMax=32768"

    mkdir -p "$limitConfPath"

    if [ ! -d "$limitConfPath" ]; then
        sysLogger e "failed creation of the folder "$limitConfPath""
    fi


    echo "$limitConf" > "$limitConfPath/limits.conf"


    if [ -s "$limitConfPath/limits.conf" ]; then
        sysLogger i  "User conf applied to "$limitConfPath/limits.conf""
    else sysLogger e "user conf failed to apply to "$limitConfPath/limits.conf""
    fi
}




######################################################################################



userGroupCheck(){
    local groups=("docker" "video" "render"); local answer

    for group in "${groups[@]}"; do

        getent group "$group" >/dev/null || { 
            
            read -p "Group '$group' not found, do you want to create it? y/n: " answer
            
            if [ "$answer" == 'y' ]; then
                sysLogger i  "Creating group "$group"" 
                sudo groupadd "$group" 
            else sysLogger i  "Not creating group "$group""
            fi 
        } 

        if id -nG "$USER" | grep -qw "$group"; then
            sysLogger i "$USER belongs to $group"
        else
            sysLogger e "$USER does NOT belong to $group"
            sudo usermod -aG "$group" "$USER"
        fi
    done   
}


######################################################################################



firewallSetup(){
    local UFW_CONF="/etc/default/ufw"

    sysLogger i "UFW Firewall setup"
    sudo ufw default reject incoming || sysLogger e "UFW setuf fail for: ufw default reject incoming"
    sudo ufw default allow outgoing  || sysLogger e "UFW setuf fail for: ufw default allow outgoing"

    #### Disable ipv6
    if grep -q '^IPV6=yes' "$UFW_CONF"; then
        sudo sed -i 's/^IPV6=yes/IPV6=no/' "$UFW_CONF"
    fi

    sudo ufw reload || { sysLogger e "firewall reload failed"; return 1; }
    sudo ufw enable || { sysLogger e "firewall enable failed"; return 1; }

    sysLogger i "UFW reloaded, current status:\n$(sudo ufw status verbose)"
}



######################################################################################



tearFix(){
    #### NOTE: The TearFree X11 config is inert on Wayland
    local cnfgContent; local cnfgFile

    sysLogger i "X11 screen tear fix"
    cnfgContent='Section "Device"
        Identifier  "AMD Graphics"
        Driver      "amdgpu"
        Option      "TearFree" "true"
    EndSection'
    cnfgFile="/etc/X11/xorg.conf.d/20-amd.conf"

    echo "$cnfgContent" | sudo tee "$cnfgFile"

    if [ -s "$cnfgFile" ]; then
        sysLogger i  "Config file created "$cnfgFile""
    fi
}



######################################################################################



grupSetup(){
    sysLogger i "GRUB USB not working after waking up (sleep / hybernation / suspend)"
    
    local grub_line_path="/etc/default/grub"
    local grub_line='GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"'
    local mod_line='GRUB_CMDLINE_LINUX_DEFAULT="quiet splash usbcore.autosuspend=-1 zswap.enabled=0"'

    if grep -q "$grub_line" "$grub_line_path"; then
        sudo sed -i "s/^$grub_line/$mod_line/" "$grub_line_path"
    
    else sysLogger e "grub grep failed, grub not updated"; return 1

    fi

    sudo update-grub || {  sysLogger e "grub update failed" ; return 1; }
    sysLogger i  "Grub updated with new ruleset"
}



######################################################################################



GNOME_global_settings(){
    sysLogger i "GNOME tweaks block"

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
    gsettings set org.gnome.shell.app-switcher current-workspace-only false

    # #### Disable edge tiling --- keep true for fullscreen shortcut
    # gsettings set org.gnome.mutter edge-tiling false

    #### Keep Super Key for overview / search
    gsettings set org.gnome.mutter overlay-key 'Super_L'

    #### Night light setup
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 0
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 0
    # gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 2500 #### 1000~10000


    ####            Terminal customization

    #### Get default key value & set the cursor to underline
    local PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')

    if [ -z "$PROFILE" ]; then
        sysLogger e "Gnome terminal profile missing: "$PROFILE", aborting"
        return 1
    fi

    gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/" cursor-shape 'underline'

    # gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/" use-transparent-background true
    # gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/" background-transparency-percent 30

    # gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/" use-transparent-background false


    gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/" cursor-blink-mode off

    gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/" default-size-rows 80

    gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/" default-size-columns 24


    #### Check for all available customization options
    #### gsettings list-keys "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/"


    sysLogger i "Disabling gnome tracker (home folder indexing)"
    systemctl --user mask tracker-miner-fs-3.service
    systemctl --user mask tracker-extract-3.service
    systemctl --user mask tracker-writeback-3.service
    tracker3 reset -s -r


    #### Remove useless Ubuntu sessions options from login
    sudo rm /usr/share/xsessions/ubuntu*.desktop
    sudo rm /usr/share/wayland-sessions/ubuntu*.desktop


    #### Enable gnome triple buffer rendering !!!! EXPERIMENTAL !!!!
    # mkdir -p ~/.config/environment.d
    # echo "MUTTER_DEBUG_TRIPLE_BUFFER=1
    # CLUTTER_PAINT=disable-clipped-redraws:disable-culling" | sudo tee  ~/.config/environment.d/gnome-performance.conf
}



######################################################################################



nemoSetup(){

    sysLogger i  "Nemo / Nautilus use Samba net usershare to manage user shares"
    sudo mkdir -p /var/lib/samba/usershares
    sudo chown root:sambashare /var/lib/samba/usershares
    sudo chmod 1770 /var/lib/samba/usershares

    nemoScripts="$HOME/.local/share/nemo/scripts"

    if [ ! -d "$nemoScripts" ]; then
        sysLogger w "Folder "$nemoScripts" did not exist, creating"
        mkdir -p "$nemoScripts" || { sysLogger e "unexpected failure during folder creation, exiting"; return 1;} 
    fi


    if [ -s "$EXTRA_LXscripts/Other/NEMO_mediainfo.sh" ]; then
        sysLogger i "Copying "$EXTRA_LXscripts/Other/NEMO_mediainfo.sh"  ->  "$nemoScripts""
        cp "$EXTRA_LXscripts/Other/NEMO_mediainfo.sh" "$nemoScripts"
    fi

    if [ ! -s "$HOME/.local/share/nemo/scripts/NEMO_mediainfo.sh" ]; then
        sysLogger e "copy failed"
    fi
}



######################################################################################



flatpakOverrides(){

    #### GPU acceleration
    sysLogger i "Flatpak override setup"
    flatpak override --user --device=dri com.google.Chrome
    flatpak override --user --device=dri com.brave.Browser
    flatpak override --user --device=dri com.valvesoftware.Steam
    flatpak override --user --device=dri com.discordapp.Discord 
    flatpak override --user --device=dri org.gimp.GIMP
    flatpak override --user --device=dri org.audacityteam.Audacity
    flatpak override --user --device=dri com.obsproject.Studio

    #### Steam SSD whitelist (for external storing)
    flatpak override --user --filesystem=/media/federico/SSD1TB com.valvesoftware.Steam
    flatpak override --user --filesystem=/media/federico/SSD1TB com.usebottles.bottles

    #### Allow all flatpak to see and use fonts and themes
    flatpak override --user --filesystem="$HOME/.local/share/icons":ro  
    flatpak override --user --filesystem="$HOME/.local/share/themes":ro  
    flatpak override --user --filesystem="$HOME/.local/share/fonts":ro  
}



######################################################################################



deamonsPurge(){
    sysLogger i "Disabling unused deamons"

    local deamonsToDisable=(
        "NetworkManager-wait-online.service"    #### Wait for network
        "avahi-daemon.service"                  #### Local network discovery
        "clamav-daemon.service"                 #### Keep clamav disabled by default (on-demand activation)
        "cups.service"                          #### Disable CUPS (printer deamon)
        "cups.socket"
        )
    
    for deamon in "${deamonsToDisable[@]}"; do

        sysLogger i "Disabling $deamon"
        sudo systemctl disable "$deamon" || sysLogger e "failed to disable "$deamon""

        sysLogger i "Stopping $deamon"
        sudo systemctl stop "$deamon"  || sysLogger e "failed to stop "$deamon""
    
    done

    sysLogger i "Extra step, purging 'cups' (printer deamon)"
    sudo apt purge cups -y
}



######################################################################################



GH_gitConfig(){
    sysLogger i "Checking internet connectivity, the script will abort if the systems results offline."
    timeout 10 getent hosts archive.ubuntu.com2 > /dev/null || { sysLogger e "No network. Aborting."; return 1; }


    sysLogger i "Attempting GIT login using 'gh'"
    if ! command gh > /dev/null ; then sysLogger e "'gh' command not found"
    else gh auth login --hostname github.com --git-protocol https --web
    fi
}



######################################################################################



scriptLauncher(){

    local scripts=(
        "$EXTRA_LXscripts/New_Pc/theme_updater.sh"
        "$EXTRA_LXscripts/Github/01_cloning.sh"
        "$EXTRA_LXscripts/New_Pc/gnome_shortcut_dump/load-shortcuts.sh"
        "$EXTRA_LXscripts/New_Pc/gnome_extensions_settings_dump/02_ext_set_restore.sh"
    )

    for script in "${scripts[@]}"; do

        if [ -s "$script" ]; then
            sysLogger i "Launching "$script"\n"
            # "$script" || sysLogger e "execution failed for "$script"\n"     

        else sysLogger e "failed to launch "$script"\n"
        fi

    done 


}



######################################################################################



mainLauncher(){

    sysLogger i "Function mainLauncher start"

    newpcHistory

    startupBootstrap
    
    GNOME_performance
    
    userGroupCheck
    
    firewallSetup
    
    tearFix
    
    grupSetup

    GNOME_global_settings

    nemoSetup

    flatpakOverrides

    deamonsPurge

    GH_gitConfig

    scriptLauncher

    sysLogger i "Function mainLauncher terminated"

} >> "$log" 2>&1 


mainLauncher