#!/bin/bash
set -uo pipefail


nextcloudCheck(){
    shopt -s nullglob dotglob

    set -- "$HOME/Nextcloud"/*

    if [ -d "$HOME/Nextcloud" ]; then

            if (( $# > 0 )); then echo -e "Nextcloud path found "$HOME/Nextcloud""
            else echo "$HOME/Nextcloud is empty, aborting"; return 1; fi

        read -p "Press enter to continue" 
    
    else    
        echo -e "Run only after Nextcloud setup..."
        return 1
    fi

    shopt -u nullglob dotglob 
}
nextcloudCheck || { echo -e "Nextcloud check failed, aborting execution" ; exit 1; }



brokenEnv=false

if [ -s "$HOME/.bash_common" ]; then source "$HOME/.bash_common"; else echo -e "[CRITICAL ERROR] Bash module not found: $HOME/.bash_common"; brokenEnv=true; fi

if $brokenEnv; then
    echo -e "[CRITICAL ERROR] Enviroment degraded, functions disabled"
    return 1
fi;



[ "$EUID" -ne 0 ] || { sysLogger e "Run as normal user, not root." >&2; exit 1; }


######################################################################################

failedRuns=()

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



grubSetup(){
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

    gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/" default-size-rows 26 #### default 24

    gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/" default-size-columns 90 #### default 80


    #### Check for all available customization options
    #### gsettings list-keys "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/"


    sysLogger i "Disabling gnome tracker (home folder indexing)"
    systemctl --user mask tracker-miner-fs-3.service
    systemctl --user mask tracker-extract-3.service
    systemctl --user mask tracker-writeback-3.service
    tracker3 reset -s -r


    #### Remove useless Ubuntu sessions options from login
    if [ -f "/usr/share/xsessions/ubuntu*.desktop" ]; then
        sudo rm "/usr/share/xsessions/ubuntu*.desktop"    
    fi

    if [ -f "/usr/share/wayland-sessions/ubuntu*.desktop" ]; then
        sudo rm "/usr/share/wayland-sessions/ubuntu*.desktop"    
    fi


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
    #### RESET ALL --        flatpak override --user --reset

    fOverGPU(){
        flatpak override --user --device=dri "$1"
    }

    #### GPU acceleration
    sysLogger i "Flatpak override setup"
    fOverGPU com.google.Chrome
    fOverGPU com.brave.Browser
    fOverGPU com.valvesoftware.Steam
    fOverGPU com.discordapp.Discord 
    fOverGPU org.gimp.GIMP
    fOverGPU org.audacityteam.Audacity
    fOverGPU com.obsproject.Studio
    fOverGPU org.kde.kdenlive

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
            "$script" || sysLogger e "execution failed for "$script"\n"     

        else sysLogger e "failed to launch "$script"\n"
        fi

    done 


}



######################################################################################



swapSetup(){
    sysLogger i "Swap allocation and setup started"

    local SWAP=4 #### GB +2GB default 
    
    #### Favor RAM over SWAP -- range 0 to 100 higher the number higher the priority of SWAP over RAM
    local SWAPPINESS=10

    #### Filesystem cache - more memory used to cache file access paths and metadata = smoother UI in file managers -- range 0 to 200+ 
    local CACHE_PRESSURE=10

    local swapFavor ; local cacheFavor


    if [ $SWAPPINESS -le 30 ] && [ $SWAPPINESS -ge 0 ] ; then
        swapFavor="RAM"

    elif [ $SWAPPINESS -gt 30 ] && [ $SWAPPINESS -le 100 ] ; then
        swapFavor="SWAP"

    elif [ $SWAPPINESS -gt 100 ] || [ $SWAPPINESS -lt 0 ]; then
        echo -e "Swappiness error: not in range 0 - 100. Current: $SWAPPINESS)"; return 1

    else
        echo -e "Unexpected swappiness error: $SWAPPINESS \nExiting"; return 1
    fi


    if [ $CACHE_PRESSURE -le 30 ] && [ $CACHE_PRESSURE -ge 0 ] ; then
        cacheFavor="More RAM for cache"

    elif [ $CACHE_PRESSURE -gt 30 ] && [ $CACHE_PRESSURE -le 200 ] ; then
        cacheFavor="Less RAM for cache"

    elif [ $CACHE_PRESSURE -gt 200 ] || [ $CACHE_PRESSURE -lt 0 ]; then
        echo -e "CACHE_PRESSURE error: not in range 0 - 200. Current: $CACHE_PRESSURE)"; return 1

    else
        echo -e "Unexpected CACHE_PRESSURE error: $CACHE_PRESSURE \nExiting" ; return 1
    fi

    sysLogger i "SWAP config: 
    	> "$SWAP"GB swap memory will be created
        > SWAPPINESS=$SWAPPINESS   CACHE_PRESSURE=$CACHE_PRESSURE
	    > Swap favor:  "$swapFavor" - "$cacheFavor"
    "

    sysLogger i "Starting creating swapspace\n"

	sudo swapon --show
	free -h
	df -h
	sudo fallocate -l "$SWAP"G /swapspace
	ls -lh /swapspace
	sudo chmod 600 /swapspace
	ls -lh /swapspace
	sudo mkswap /swapspace
	sudo swapon /swapspace
	sudo swapon --show
	free -h

	sudo cp /etc/fstab /etc/"$(date "+%Y-%m-%d_%H-%M-%S")"_fstab.bak
	echo '/swapspace none swap sw 0 0' | sudo tee -a /etc/fstab
	cat /proc/sys/vm/swappiness

	printf 'vm.swappiness=%s\nvm.vfs_cache_pressure=%s\n' "$SWAPPINESS" "$CACHE_PRESSURE" \
	| sudo tee /etc/sysctl.d/99-local-vm.conf >/dev/null
	sudo sysctl --system

	printf 'vm.swappiness=%s\nvm.vfs_cache_pressure=%s\n' "$SWAPPINESS" "$CACHE_PRESSURE" \
    | sudo tee /etc/sysctl.d/99-local-vm.conf >/dev/null
	sudo sysctl --system


    sysLogger i "Finished creating swapspace"

	local swapCheck=$(sudo swapon --show)
	sysLogger i "Swap status check:\n$swapCheck \n"

    sysLogger i "Swap allocation and setup terminated"
}



######################################################################################


#### All these device-config scripts are better explained here: `Linux/docu/Audio/2026_09_26/2026_09_26-audio_config_scripts.md`


#### Completely purges the handsfree profiles (sound + mic with worse audio quality)
#### This breaks the report of the battery in with bluez that will not see it anymore
# bluetoothProfilePurge(){
#     #### Removes the Bluetooth HSP/HFP (handsfree) profile: headsets can only connect as A2DP.
#     #### Writes a persistent WirePlumber user config. Idempotent: a no-op once the config is in place.

#     wpVersion="$(wireplumber --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)"

#     case "$wpVersion" in
#         0.4)
#             confFile="$HOME/.config/wireplumber/bluetooth.lua.d/51-disable-handsfree.lua"
#             confText='bluez_monitor.properties["bluez5.roles"] = "[ a2dp_sink a2dp_source ]"
#     bluez_monitor.properties["bluez5.hfphsp-backend"] = "none"'
#             ;;
#         0.5)
#             confFile="$HOME/.config/wireplumber/wireplumber.conf.d/51-disable-handsfree.conf"
#             confText='monitor.bluez.properties = {
#     bluez5.roles = [ a2dp_sink a2dp_source ]
#     bluez5.hfphsp-backend = "none"
#     }'
#             ;;
#         *)
#             echo "[CRITICAL ERROR] Unsupported or missing WirePlumber version: '${wpVersion}'" >&2
#             exit 1
#             ;;
#     esac

#     #### Already applied: nothing to do
#     [ "$(cat "$confFile" 2>/dev/null)" = "$confText" ] && exit 0

#     mkdir -p "$(dirname "$confFile")" || exit 1
#     printf '%s\n' "$confText" > "$confFile" || exit 1

#     #### Config is read when WirePlumber starts: restart it now, or it applies from the next session
#     systemctl --user restart wireplumber 2>/dev/null || echo "[INFO] Handsfree disabled: restart the session to apply"
# }



#### Locked in config that prevents any automatic switching to tha handsfree profile
bluetoothProfileAntiSwitch(){
    #### Keeps Bluetooth headsets on A2DP: WirePlumber never switches to, nor restores, the HSP/HFP profile.
    #### HSP/HFP stays registered on purpose: its control channel is what carries the headset battery level.
    #### Writes a persistent WirePlumber user config. Idempotent: a no-op once the config is in place.

    wpVersion="$(wireplumber --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)"

    case "$wpVersion" in
        0.4)
            confFile="$HOME/.config/wireplumber/policy.lua.d/51-bt-no-headset-switch.lua"
            oldConf="$HOME/.config/wireplumber/bluetooth.lua.d/51-disable-handsfree.lua"
            confText='bluetooth_policy.policy["media-role.use-headset-profile"] = false
    bluetooth_policy.policy["use-persistent-storage"] = false'
            ;;
        0.5)
            confFile="$HOME/.config/wireplumber/wireplumber.conf.d/51-bt-no-headset-switch.conf"
            oldConf="$HOME/.config/wireplumber/wireplumber.conf.d/51-disable-handsfree.conf"
            confText='wireplumber.settings = {
    bluetooth.autoswitch-to-headset-profile = false
    bluetooth.use-persistent-storage = false
    }'
            ;;
        *)
            echo "[CRITICAL ERROR] Unsupported or missing WirePlumber version: '${wpVersion}'" >&2
            exit 1
            ;;
    esac

    #### Already applied: nothing to do
    [ ! -e "$oldConf" ] && [ "$(cat "$confFile" 2>/dev/null)" = "$confText" ] && exit 0

    #### Previous config removed HSP/HFP entirely, and battery reporting with it
    rm -f "$oldConf"

    mkdir -p "$(dirname "$confFile")" || exit 1
    printf '%s\n' "$confText" > "$confFile" || exit 1

    #### Config is read when WirePlumber starts: restart it now, or it applies from the next session
    systemctl --user restart wireplumber 2>/dev/null || echo "[INFO] Config written: restart the session to apply"

}



#### Hides unwanted audio devices from PipeWire (desktop "federico" only: names are hardware-specific).
wireplumberAudioDeviceBlacklist(){
    ####   Kept:     Bluetooth headset, onboard jack output, USB microphone (Q9-1)
    ####   Disabled: GPU HDMI audio, webcam microphone, onboard S/PDIF output, onboard analog input
    #### Writes a persistent WirePlumber user config. Idempotent: a no-op once the config is in place.

    wpVersion="$(wireplumber --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)"

    case "$wpVersion" in
        0.4)
            confFile="$HOME/.config/wireplumber/main.lua.d/52-audio-blacklist.lua"
            confText='-- Whole cards: GPU HDMI audio (monitor has no speakers), webcam microphone
    table.insert(alsa_monitor.rules, {
    matches = {
        { { "device.name", "equals", "alsa_card.pci-0000_06_00.1" } },
        { { "device.name", "equals", "alsa_card.usb-Sonix_Technology_Co.__Ltd._JOYACCESS-02" } },
    },
    apply_properties = { ["device.disabled"] = true },
    })

    -- Single nodes on the onboard card: S/PDIF output, analog input (jack output stays)
    table.insert(alsa_monitor.rules, {
    matches = {
        { { "node.name", "equals", "alsa_output.pci-0000_08_00.4.iec958-stereo" } },
        { { "node.name", "equals", "alsa_input.pci-0000_08_00.4.analog-stereo" } },
    },
    apply_properties = { ["node.disabled"] = true },
    })'
            ;;
        0.5)
            confFile="$HOME/.config/wireplumber/wireplumber.conf.d/52-audio-blacklist.conf"
            confText='monitor.alsa.rules = [
    {
        ## Whole cards: GPU HDMI audio (monitor has no speakers), webcam microphone
        matches = [
        { device.name = "alsa_card.pci-0000_06_00.1" }
        { device.name = "alsa_card.usb-Sonix_Technology_Co.__Ltd._JOYACCESS-02" }
        ]
        actions = { update-props = { device.disabled = true } }
    }
    {
        ## Single nodes on the onboard card: S/PDIF output, analog input (jack output stays)
        matches = [
        { node.name = "alsa_output.pci-0000_08_00.4.iec958-stereo" }
        { node.name = "alsa_input.pci-0000_08_00.4.analog-stereo" }
        ]
        actions = { update-props = { node.disabled = true } }
    }
    ]'
            ;;
        *)
            echo "[CRITICAL ERROR] Unsupported or missing WirePlumber version: '${wpVersion}'" >&2
            exit 1
            ;;
    esac

    #### Already applied: nothing to do
    [ "$(cat "$confFile" 2>/dev/null)" = "$confText" ] && exit 0

    mkdir -p "$(dirname "$confFile")" || exit 1
    printf '%s\n' "$confText" > "$confFile" || exit 1

    #### Config is read when WirePlumber starts: restart it now, or it applies from the next session
    systemctl --user restart wireplumber 2>/dev/null || echo "[INFO] Config written: restart the session to apply"
}





######################################################################################


mainLauncher(){

    sysLogger i "Function mainLauncher started"

    local functions=(
        newpcHistory
        startupBootstrap
        GNOME_performance
        userGroupCheck
        firewallSetup
        tearFix
        grubSetup
        GNOME_global_settings
        nemoSetup
        flatpakOverrides
        deamonsPurge
        scriptLauncher
        swapSetup
        # bluetoothProfilePurge
        bluetoothProfileAntiSwitch
        wireplumberAudioDeviceBlacklist
    )

    for func in "${functions[@]}"; do
        sysLogger i "Launching function: "$func""
        "$func" || { sysLogger e "$func failed" ; failedRuns+=("$func"); }
    done

    sysLogger i "Function mainLauncher terminated"

    for failed in "${failedRuns[@]}"; do
        sysLogger e "Run failed - $failed"
    done 

} >> "$log" 2>&1 
mainLauncher



######################################################################################



GH_gitConfig(){
    sysLogger i "Git 'gh' config started, expect prompts"

    sysLogger i "Checking internet connectivity, the script will abort if the system results offline."
    timeout 10 getent hosts archive.ubuntu.com > /dev/null || { sysLogger e "No network. Aborting."; return 1; }


    sysLogger i "Attempting GIT login using 'gh'"
    if ! command gh > /dev/null ; then sysLogger e "'gh' command not found"
    else gh auth login --hostname github.com --git-protocol https --web
    fi

    sysLogger i "Git 'gh' config terminated"
}
GH_gitConfig || { sysLogger e "GH_gitConfig failed" ; }