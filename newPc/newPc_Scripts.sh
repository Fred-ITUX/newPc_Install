#!/bin/bash

###############################################################


#### This script is NOT intended to be run manually
#### It should be launched by setup.sh
####
#### Fedora KDE version of newPc/newPc_Scripts.sh (firewalld, grubby, KDE settings; no dconf, no X11 tear fix)


###############################################################

#### Must be launched by setup.sh: it provides the environment and the helper functions
if [ "$EUID" -ne 0 ] || [ -z "${realUser:-}" ] || ! declare -F asUser >/dev/null; then
    echo "[CRITICAL ERROR] Launch through setup.sh: sudo ./setup.sh $(basename "$0")" >&2; exit 1
fi


nextcloudCheck(){
    shopt -s nullglob dotglob

    sysLogger i "Checking for Nextcloud/ folder presence: ""$userHome"/Nextcloud""

    set -- "$userHome/Nextcloud"/*

    if [ -d "$userHome/Nextcloud" ]; then

            if (( $# > 0 )); then sysLogger i "Nextcloud path found "$userHome/Nextcloud""
            else sysLogger e "$userHome/Nextcloud is empty, aborting"; return 1; fi
    
    else    
        sysLogger e "Run only after Nextcloud setup..."
        return 1
    fi

    sysLogger i "Nextcloud check completed\n"
    shopt -u nullglob dotglob 
}
nextcloudCheck || { sysLogger e "Nextcloud check failed, aborting execution" ; exit 1; }






######################################################################################

failedRuns=()


log="$userHome/Nextcloud/Linux/log/newPc_history/newPc_Scripts_$(date +%F_%H-%M-%S).log"

asUser mkdir -p "$(dirname "$log")" || { sysLogger e "Folder creation failed: $(dirname "$log")" ; exit 1; }
asUser touch "$log"                 || { sysLogger e "File creation failed: $log" ; exit 1; }
exec > >(tee -a "$log") 2>&1


EXTRA_LXscripts="$userHome/Nextcloud/Linux/scripts"

if [ ! -d "$EXTRA_LXscripts"  ]; then sysLogger e "master path not found $EXTRA_LXscripts \nAborting execution"; exit 1; fi


sysLogger i "Adding executable to '*.sh' scripts under "$EXTRA_LXscripts""

find "$EXTRA_LXscripts" -type f -name "*.sh" -exec chmod +x {} + || { sysLogger e "adding execution to all '.sh' files under "$EXTRA_LXscripts" triggered an unexpected error, aborting"; exit 1 ;}

sysLogger i "All the .sh scripts under "$EXTRA_LXscripts" are now executables"



######################################################################################



newpcHistory(){
    local dest="$userHome/Nextcloud/Linux/log/newPc_history"

    sysLogger i "Saving 'newPc' log for history"

    asUser mkdir -p "$dest" || { sysLogger e "failed to create folder "$dest""; return 1;}
    
    # sudo find /root -maxdepth 1 -name 'newPC_*.txt' -exec cp -- {} "$dest/" \;
    sudo find "$userHome" -maxdepth 1 -name 'newPc_*.log' -exec cp -- {} "$dest/" \;

    chown -R "$realUser:$realGroup" "$dest"
}



######################################################################################



startupBootstrap(){
    local fileEntry 
    local autostartPath="$userHome/.config/autostart"
    local autostartFile=""$autostartPath"/startup_routine.desktop"

    sysLogger i "Setup startup routine start at boot"
    # mkdir -p "$autostartPath" || { sysLogger e "unexpected failure during folder creation, aborting"; return 1; }

    fileEntry="[Desktop Entry]
    Type=Application
    Exec="$userHome"/Nextcloud/Linux/scripts/Startup_Routine/startup_routine.sh
    Hidden=false
    NoDisplay=false
    X-GNOME-Autostart-enabled=true
    Name=Startup Routine
    Comment=Run my startup script"

    atomicWrite "startup_routine.desktop" "$autostartPath" "$fileEntry"
    # echo "$fileEntry" > "$autostartFile" || { sysLogger e "write failed, current file status: \n$(cat "$autostartFile")"; return 1; }

    if [ -s "$autostartFile" ]; then
        sysLogger i  "Routine installed"
    else sysLogger e "routine not installed, current file status: \n$(cat "$autostartFile")"
    fi
}



######################################################################################



userGroupCheck(){
    #### docker -- group removed; it is the same as passwordless sudo
    local groups=("video" "render"); local answer

    for group in "${groups[@]}"; do

        getent group "$group" >/dev/null || { 
            
            sysLogger i  "Creating group "$group"" 
            sudo groupadd "$group" 
        } 

        if id -nG "$realUser" | grep -qw "$group"; then
            sysLogger i ""$realUser" belongs to $group"
        else
            sysLogger w ""$realUser" does NOT belong to $group, adding"
            sudo usermod -aG "$group" "$realUser" || { sysLogger e "Failed to add "$realUser" to $group" ; return 1 ; }

            if id -nG "$realUser" | grep -qw "$group"; then
                sysLogger i ""$realUser" added to $group"
            else
                sysLogger e "Failed to add "$realUser" to $group"
                return 1
            fi
        fi

    done
}


######################################################################################



firewallSetup(){
    #### firewalld "block" zone = same policy as the old ufw setup (default reject incoming / allow outgoing):
    ####    > every unsolicited incoming packet is REJECTED (IPv4 and IPv6), replies to outgoing connections are accepted
    ####    > outgoing connections are allowed
    ####    > no service and no port is open (checked on Fedora 45: target %%REJECT%%, empty services / ports)
    local zone="block"
    local activeZones otherZones openServices openPorts

    sysLogger i "firewalld setup, default zone: $zone"

    sudo systemctl enable --now firewalld || { sysLogger e "firewalld enable / start failed"; return 1; }

    #### Applies to the running firewall AND to the saved configuration
    sudo firewall-cmd --set-default-zone="$zone" || { sysLogger e "firewalld: cannot set the default zone to $zone"; return 1; }

    #### An interface bound to another zone (e.g. by a NetworkManager connection) would bypass the default zone
    #### Zone names are the non-indented lines, e.g. "block (default)"
    activeZones=$(sudo firewall-cmd --get-active-zones | awk '/^[^[:space:]]/ {print $1}')
    otherZones=$(grep -vx "$zone" <<< "$activeZones")

    if [ -n "$otherZones" ]; then
        sysLogger e "firewalld: interfaces are bound to other zones: $(tr '\n' ' ' <<< "$otherZones"). Move them to $zone (nmcli connection modify <name> connection.zone $zone)"
        return 1
    fi

    #### Strict policy check: nothing may be open in the zone
    openServices=$(sudo firewall-cmd --zone="$zone" --list-services)
    openPorts=$(sudo firewall-cmd --zone="$zone" --list-ports)

    if [ -n "$openServices" ] || [ -n "$openPorts" ]; then
        sysLogger e "firewalld: zone $zone is not strict. Services: '${openServices}' Ports: '${openPorts}'"
        return 1
    fi

    sysLogger i "firewalld active, current status:\n$(sudo firewall-cmd --zone="$zone" --list-all)"
}



######################################################################################



#### tearFix (AMD TearFree, /etc/X11/xorg.conf.d) removed: X11 only, KDE runs on Wayland



######################################################################################



grubSetup(){
    sysLogger i "Kernel arguments: USB not working after waking up (sleep / hybernation / suspend), zswap off, IPv6 off"

    #### Fedora boots through BLS entries: grubby edits the kernel command line of every installed kernel
    #### (no /etc/default/grub sed + update-grub like on Mint)
    #### TO CONFIRM on Fedora: that a kernel installed LATER inherits these arguments
    local args=(
        "usbcore.autosuspend=-1"
        "zswap.enabled=0"
        "ipv6.disable=1"
    )
    local arg current missing=()

    current=$(sudo grubby --info=DEFAULT) || { sysLogger e "grubby cannot read the default kernel entry"; return 1; }

    #### In case of a 2nd run: only the arguments not already present are added
    for arg in "${args[@]}"; do
        if ! grep -qF -- "$arg" <<< "$current"; then missing+=( "$arg" ); fi
    done

    if [ "${#missing[@]}" -eq 0 ]; then sysLogger i "Kernel arguments already configured"; return 0; fi

    sudo grubby --update-kernel=ALL --args="${missing[*]}" || { sysLogger e "grubby update failed" ; return 1; }

    #### Double check on the default entry
    current=$(sudo grubby --info=DEFAULT)
    for arg in "${args[@]}"; do
        if ! grep -qF -- "$arg" <<< "$current"; then sysLogger e "Kernel argument not applied: $arg"; return 1; fi
    done

    sysLogger i  "Kernel command line updated: ${missing[*]} (active after the next reboot)"
}



######################################################################################


#### Style, UI and enviroment setup


KDE_global_settings(){
    sysLogger i "KDE tweaks block"

    #### kwriteconfig6 edits the KDE config files directly (no running session needed, tested on Fedora 45)
    #### Keys marked [schema] were found in KDE's own schema files (/usr/share/config.kcfg) on Fedora 45
    #### Everything marked TO CONFIRM must be checked on the real machine: System Settings shows the same options

    #### Remove recents: 2 = do not remember opened documents
    asUser kwriteconfig6 --file kactivitymanagerd-pluginsrc --group "Plugin-org.kde.ActivityManager.Resources.Scoring" --key what-to-remember 2

    #### Disable animations to make it smoother  [schema]
    asUser kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 0

    #### GNOME's "app not responding" pop-up timeout (check-alive-timeout): no KDE equivalent found, not set

    #### Disable automatic suspend / screen off / dimming / lock  -- TO CONFIRM on Fedora (powerdevilrc keys not found in a schema file)
    local powerProfile
    for powerProfile in AC Battery LowBattery; do
        asUser kwriteconfig6 --file powerdevilrc --group "$powerProfile" --group SuspendAndIdle --key AutoSuspendAction 0
        asUser kwriteconfig6 --file powerdevilrc --group "$powerProfile" --group Display --key TurnOffDisplayWhenIdle false
        asUser kwriteconfig6 --file powerdevilrc --group "$powerProfile" --group Display --key DimDisplayWhenIdle false
    done
    asUser kwriteconfig6 --file kscreenlockerrc --group Daemon --key Autolock false   #### [schema]


    #### Multitasking / workspaces setup: 4 fixed virtual desktops (KDE never adds them dynamically, and they span every monitor)
    #### Number/Rows in kwinrc are read by KWin at startup only: they cover the next login
    asUser kwriteconfig6 --file kwinrc --group Desktops --key Number 4
    asUser kwriteconfig6 --file kwinrc --group Desktops --key Rows 1

    #### The running KWin keeps its current count: create the missing desktops live over D-Bus (nothing to do if already 4)
    #### Checked on Fedora 45: createDesktop(position, name) appends, kwinrc then gets Id_1..Id_4
    local desktopCount desktopIdx
    desktopCount=$(asUser busctl --user get-property org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager count 2>/dev/null | awk '{print $2}')
    if [ -n "$desktopCount" ]; then
        for (( desktopIdx = desktopCount; desktopIdx < 4; desktopIdx++ )); do
            asUser busctl --user call org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager createDesktop us "$desktopIdx" "Desktop $((desktopIdx + 1))" > /dev/null || sysLogger e "Could not create desktop $((desktopIdx + 1))"
        done
        sysLogger i "Virtual desktops: 4 fixed, shared by every monitor"
    else
        sysLogger i "KWin not reachable: the 4 desktops appear at the next login"
    fi


    #### Shortcuts to move between workspaces (overwrite the defaults)
    #### Replaces KWin's default Meta+Ctrl(+Shift)+Left/Right with the old Mint keys:
    ####   Ctrl+Alt+Left/Right   = switch to the previous/next desktop
    ####   Shift+Alt+Left/Right  = move the focused window to the previous/next desktop
    #### Value format: "active key,default key,friendly name". Only the active key changes;
    #### the default is kept so "Reset to default" in System Settings still works.
    #### Checked for conflicts: these four keys are free in kglobalshortcutsrc. Applies at the next login.
    asUser kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch One Desktop to the Left"  "Ctrl+Alt+Left,Meta+Ctrl+Left,Switch One Desktop to the Left"
    asUser kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch One Desktop to the Right" "Ctrl+Alt+Right,Meta+Ctrl+Right,Switch One Desktop to the Right"
    asUser kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window One Desktop to the Left"  "Shift+Alt+Left,Meta+Ctrl+Shift+Left,Window One Desktop to the Left"
    asUser kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window One Desktop to the Right" "Shift+Alt+Right,Meta+Ctrl+Shift+Right,Window One Desktop to the Right"

    #### Meta+H minimizes the focused window (checked: Meta+H is free in kglobalshortcutsrc)
    ####    > KWin's "Window Minimize" already has Meta+PgDown: both keys are kept, tab separated
    ####    > value format "active keys,default key,friendly name"; applies at the next login (not verified live)
    sysLogger i "Shortcut Meta+H: minimize the focused window"
    asUser kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Minimize" $'Meta+H\tMeta+PgDown,Meta+PgDown,Minimize Window' || { sysLogger e "Minimize shortcut not written"; return 1; }


    #### Meta+T opens Konsole (it was KWin's "Edit Tiles", removed on purpose; Konsole keeps its own default Ctrl+Alt+T)
    ####    > "Edit Tiles" is released by setting its active key to none, the default (Meta+T) stays so "Reset to default" in System Settings still works
    ####    > Plasma launches apps through their .desktop file via the [services] group in kglobalshortcutsrc (key _launch); several keys are tab separated
    ####    > applies at the next login, as the other global shortcuts (not verified live)
    sysLogger i "Shortcut Meta+T: Konsole (Edit Tiles unbound)"
    asUser kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Edit Tiles" "none,Meta+T,Toggle Tiles Editor" || { sysLogger e "Edit Tiles not unbound"; return 1; }
    asUser kwriteconfig6 --file kglobalshortcutsrc --group services --group org.kde.konsole.desktop --key _launch $'Meta+T\tCtrl+Alt+T' || { sysLogger e "Konsole shortcut not written"; return 1; }


    #### Shortcut: Super+N opens the file manager (Nemo)
    #### Replaces GNOME's built-in "Home folder" key (<Super>n). Plasma launches apps through
    #### their .desktop file via the [services] group in kglobalshortcutsrc (key _launch).
    #### Meta+N was checked: free in kglobalshortcutsrc. Nemo is already the default for inode/directory.
    #### Format not yet verified live; needs a logout if kglobalaccel doesn't reload the file.
    #### asUser kwriteconfig6 --file kglobalshortcutsrc --group services --group nemo.desktop --key _launch "Meta+N"

    #### tearing: forbid in fullscreen windows (KWin default is true)
    asUser kwriteconfig6 --file kwinrc --group Compositing --key AllowTearing false

    #### Night light setup: off, and "Constant" mode (no sunset / sunrise schedule) so Shortcuts/night_light.sh decides alone when it is active
    #### [schema: Mode accepts Constant or DarkLight on Fedora 45]
    asUser kwriteconfig6 --file kwinrc --group NightColor --key Active false
    asUser kwriteconfig6 --file kwinrc --group NightColor --key Mode Constant
    # asUser kwriteconfig6 --file kwinrc --group NightColor --key NightTemperature 2500 #### 1000~10000

    #### Pointer acceleration: always off (flat profile) on every mouse found at deploy time
    #### Checked on Fedora 45: kcminputrc [Libinput][vendor][product][name] PointerAccelerationProfile=1 = flat (KWin shows pointerAccelerationProfileFlat=true)
    local inputEvent inputDir inputVendor inputProduct inputName
    for inputEvent in /sys/class/input/event*; do
        if udevadm info -q property -p "$inputEvent" 2>/dev/null | grep -q "^ID_INPUT_MOUSE=1"; then
            inputDir="$inputEvent/device"
            inputVendor=$((16#$(<"$inputDir/id/vendor")))
            inputProduct=$((16#$(<"$inputDir/id/product")))
            inputName=$(<"$inputDir/name")
            asUser kwriteconfig6 --file kcminputrc --group Libinput --group "$inputVendor" --group "$inputProduct" --group "$inputName" --key PointerAccelerationProfile 1
        fi
    done


    ####            Terminal customization (Konsole)

    #### Profile file: underline cursor, no blink, 26 rows x 90 columns, 20px padding (was gtk.css in theme_updater.sh)
    #### Key names found in Konsole's library on Fedora 45 (CursorShape: 0 block, 1 I-beam, 2 underline)
    local konsoleProfile
    konsoleProfile="[Appearance]
Font=DejaVu Sans Mono,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1

[Cursor Options]
BlinkingCursorEnabled=false
CursorShape=2

[General]
Name=Custom
Parent=FALLBACK/
TerminalColumns=90
TerminalMargin=20
TerminalRows=26"

    atomicWrite "Custom.profile" "$userHome/.local/share/konsole" "$konsoleProfile" || { sysLogger e "Konsole profile not written"; return 1; }
    asUser kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "Custom.profile"


    #### GNOME's indexer (tracker, now "localsearch") is removed by newPc_Install.sh (appToPurge)
    sysLogger i "Disabling Baloo (home folder indexing)"
    #### Tested on Fedora 45 without a session: writes Indexing-Enabled=false in baloofilerc
    asUser balooctl6 disable || sysLogger e "balooctl6 disable failed"


    #### KWin re-reads its config on request; the rest applies at the next login
    asUser qdbus-qt6 org.kde.KWin /KWin reconfigure > /dev/null 2>&1 || sysLogger i "KWin not reachable: settings apply at the next login"
}



KDE_performance(){
    local limitConfPath; local limitConf
    
    sysLogger i  "Increase files processes - allows more open handles if needed, doesn't use more RAM (standard 1024)"
    echo -e "* soft nofile 1048576\n* hard nofile 1048576" | sudo tee /etc/security/limits.d/99-nofile.conf


    sysLogger i  "Reduce session stalls"

    limitConfPath="$userHome/.config/systemd/user.conf.d"
    limitConf="[Manager]
    DefaultLimitNOFILE=1048576
    DefaultTasksMax=32768"

    # mkdir -p "$limitConfPath"

    # if [ ! -d "$limitConfPath" ]; then
    #     sysLogger e "failed creation of the folder "$limitConfPath""
    # fi


    # # echo "$limitConf" > "$limitConfPath/limits.conf"
    atomicWrite "limits.conf" "$limitConfPath" "$limitConf"

    if [ -s "$limitConfPath/limits.conf" ]; then
        sysLogger i  "User conf applied to "$limitConfPath/limits.conf""
    else sysLogger e "user conf failed to apply to "$limitConfPath/limits.conf""
    fi
}



KDEmonitorsRgbFull(){
    #### Every enabled monitor: RGB range Full (the default "Automatic" sends the limited range to TV-timing modes, which washes the blacks out)
    ####    > kscreen-doctor has no help text for it, but its binary knows output.<name>.rgbrange.<automatic|full|limited>
    ####    > sudo strips WAYLAND_DISPLAY and kscreen-doctor needs the compositor socket: take its name from the user's runtime dir
    local waylandSocket outputs name total full
    waylandSocket=$(find "$userRuntime" -maxdepth 1 -name 'wayland-[0-9]*' ! -name '*.lock' -printf '%f\n' 2>/dev/null | head -1)
    if [ -z "$waylandSocket" ]; then sysLogger e "Wayland socket not found in $userRuntime"; return 1; fi
    outputs=$(asUser env WAYLAND_DISPLAY="$waylandSocket" kscreen-doctor -j | jq -r '.outputs[] | select(.enabled) | .name')
    if [ -z "$outputs" ]; then sysLogger e "No enabled monitor found (kscreen-doctor)"; return 1; fi

    for name in $outputs; do
        asUser env WAYLAND_DISPLAY="$waylandSocket" kscreen-doctor "output.$name.rgbrange.full" > /dev/null 2>&1 || { sysLogger e "RGB range not set on $name"; return 1; }
        sysLogger i "RGB range set to Full on $name"
    done

    #### Read it back: every enabled monitor must now report "RgbRange: Full"
    total=$(echo "$outputs" | wc -l)
    full=$(asUser env WAYLAND_DISPLAY="$waylandSocket" kscreen-doctor -o | sed 's/\x1b\[[0-9;]*m//g' | grep -c "RgbRange: Full")
    if [ "$full" -ne "$total" ]; then sysLogger w "RGB range Full reported on $full of $total monitors"; return 1; fi
    sysLogger i "RGB range Full confirmed on all $total monitors"
}





#### dconfSetup removed: dconf_manager.sh restores GNOME keybindings / extensions only



themeSetup(){
    sysLogger i "Starting theme setup"

    local themeScript="$userHome/Nextcloud/Linux/scripts/newPc/theme_updater.sh"
    
    if [ -f "$themeScript" ]; then
        sysLogger i "Correctly read the script "$themeScript""
    else
        sysLogger e "No script: "$themeScript""; return 1
    fi

    "$themeScript" || { sysLogger e "themeScript returned an error" ; return 1; }


    sysLogger i "Done theme setup"
}




######################################################################################



nemoSetup(){

    #### Samba usershares: Fedora has no sambashare group. Its samba-usershares package already ships
    #### /var/lib/samba/usershares (root:usershares, 1770), checked on Fedora 45, so this only runs where sambashare exists
    if getent group sambashare >/dev/null; then
        sysLogger i  "Nemo / Nautilus use Samba net usershare to manage user shares"
        sudo mkdir -p /var/lib/samba/usershares
        sudo chown root:sambashare /var/lib/samba/usershares
        sudo chmod 1770 /var/lib/samba/usershares
    else
        sysLogger i "No sambashare group: Samba usershares not configured"
    fi

    #### Nemo as the default file manager (dolphin is purged by newPc_Install.sh)
    #### TO CONFIRM on Fedora: that Plasma (folder links, "open containing folder") follows ~/.config/mimeapps.list
    asUser xdg-mime default nemo.desktop inode/directory || sysLogger e "Could not set nemo as the default file manager"


    local actionExtract=(
        "[Nemo Action]"
        "Active=true"
        "Name=Extract here"
        "Comment=Extract the selected archive(s), each into a folder of its own"
        "Exec=/bin/bash "$userHome/Nextcloud/Linux/scripts/Nemo_scripts/extract.sh" %F"
        "Icon-Name=package-x-generic"
        "Selection=NotNone"
        "Extensions=zip;7z;rar;tar;gz;xz;tgz;tbz2;txz;"
        "Quote=double"
    )


    local actionMedaInfo=(
        "[Nemo Action]"
        "Active=true"
        "Name=Video info"
        "Comment=Show duration, bit rate, FPS, size and dimensions of the selected video(s)"
        "Exec=/bin/bash "$userHome/Nextcloud/Linux/scripts/Nemo_scripts/mediainfo.sh" %F"
        "Icon-Name=video-x-generic"
        "Selection=NotNone"
        "Extensions=mp4;mkv;avi;mov;webm;m4v;wmv;flv;mpg;mpeg;ts;m2ts;3gp;ogv;"
        "Dependencies=mediainfo;zenity;"
        "Quote=double"
    )

    sysLogger i "Building nemo actions into "$userHome/.local/share/nemo/actions/""

    asUser mkdir -p "$userHome/.local/share/nemo/actions" || { sysLogger e "Failed to create folder $userHome/.local/share/nemo/actions"; return 1; }

    printf "%s\n" "${actionExtract[@]}" > "$userHome/.local/share/nemo/actions/extract_here.nemo_action"

    printf "%s\n" "${actionMedaInfo[@]}" > "$userHome/.local/share/nemo/actions/video_info.nemo_action"

    #### Written by root (plain redirections above): hand both files back to the user
    chown "$realUser:$realGroup" "$userHome/.local/share/nemo/actions/extract_here.nemo_action" "$userHome/.local/share/nemo/actions/video_info.nemo_action" || sysLogger e "Could not change the owner of the nemo actions"

    if [ ! -s "$userHome/.local/share/nemo/actions/extract_here.nemo_action" ] || [ ! -s "$userHome/.local/share/nemo/actions/video_info.nemo_action" ] ; then
        sysLogger e "Nemo action failed to build"; return 1
    else
        sysLogger i "Nemo action built"
    fi
}



######################################################################################



flatpakOverrides(){
    #### RESET ALL --        flatpak override --user --reset

    local z app y

    #### GPU acceleration
    sysLogger i "Flatpak override setup"
    local driApp=(
        "com.google.Chrome"
        "com.brave.Browser"
        "com.valvesoftware.Steam"
        "com.discordapp.Discord"
        "org.gimp.GIMP"
        "org.audacityteam.Audacity"
        "com.obsproject.Studio"
        "org.kde.kdenlive"
        "org.chromium.Chromium"
        # "com.nextcloud.desktopclient.nextcloud"
    )

    for z in "${driApp[@]}"; do 
        sysLogger i "Adding GPU acceleration to app "$z""
        asUser flatpak override --user --device=dri "$z" || { sysLogger e "Failed to apply override to app "$z"" ; }
    done

    #### No raw device access: GPU only (dri is granted above by the driApp loop)
    local noDeviceApps=(
        "org.gimp.GIMP"
        "org.kde.kdenlive"
        "org.audacityteam.Audacity"
    )
    local n

    for n in "${noDeviceApps[@]}"; do
        sysLogger i "Removing raw device access from "$n""
        asUser flatpak override --user --nodevice=all "$n" || { sysLogger e "Failed to remove device access from app "$n"" ; }
    done

    local localPath="$userHome/.local/share"
    local roThemes=(
        "icons"
        "themes"
        "fonts"
    )

    sysLogger i "Theme whitelist read only path for all flatpak: "$localPath""

    for y in "${roThemes[@]}"; do
        sysLogger i "Read only override for "$y""
        asUser flatpak override --user --filesystem=""$localPath"/"$y"":ro  || { sysLogger e "Failed to apply override for path "$y"" ; }
    done

    #### Dark pop-ups for GTK3 Flatpak apps: the sandbox has no access to the host's GTK settings, so it falls back to the light theme.
    #### Adwaita is built into GTK3 (no package, no files). Breeze:dark did NOT render dark under the runtime's GTK 3.24 (tested with VSCodium).
    #### Global override: an app-level GTK_THEME (even an empty one) beats it, so never write one per app.
    sysLogger i "Dark GTK theme for all flatpak apps (GTK_THEME=Adwaita:dark)"
    asUser flatpak override --user --env=GTK_THEME=Adwaita:dark || { sysLogger e "Failed to set GTK_THEME override" ; }

    #### Chromium: throwaway browser for sites outside the policy, never stores credentials
    ####    > downloads only in ~/Downloads, no webcam / security keys, no bluetooth / casting, no keyring
    sysLogger i "Restricting Chromium permissions"
    asUser flatpak override --user \
        --nofilesystem=home --filesystem=xdg-download \
        --nodevice=all \
        --no-talk-name=org.freedesktop.secrets --no-talk-name=org.kde.kwalletd5 --no-talk-name=org.kde.kwalletd6 \
        --system-no-talk-name=org.bluez --system-no-talk-name=org.freedesktop.Avahi \
        org.chromium.Chromium || { sysLogger e "Failed to restrict Chromium permissions" ; }


    #### OBS: recordings only in ~/Videos, no capture devices, no plugins that launch host commands
    sysLogger i "Restricting OBS permissions"
    asUser flatpak override --user \
        --nofilesystem=host --filesystem=xdg-videos \
        --nodevice=all \
        --no-talk-name=org.freedesktop.Flatpak \
        com.obsproject.Studio || { sysLogger e "Failed to restrict OBS permissions" ; }


    #### nomacs: home is read only (see roHomeApps below), write access only where images are handled
    local nomacsApp="org.nomacs.ImageLounge"
    local nomacsNoAccess=(
        "/media"
        "/mnt"
        "/run/media"
    )
    local nomacsRW=(
        "xdg-pictures"
        "xdg-download"
    )
    local p

    sysLogger i "Restricting nomacs permissions"
    for p in "${nomacsNoAccess[@]}"; do
        asUser flatpak override --user --nofilesystem="$p" "$nomacsApp" || { sysLogger e "Failed to remove nomacs access to $p" ; }
    done
    for p in "${nomacsRW[@]}"; do
        asUser flatpak override --user --filesystem="$p" "$nomacsApp" || { sysLogger e "Failed to apply nomacs write override for $p" ; }
    done


    #### Okular: PDFs are never modified (home is read only, see roHomeApps below); printing removed (CUPS purged)
    sysLogger i "Restricting Okular permissions"
    asUser flatpak override --user \
        --nofilesystem=host \
        --nosocket=cups \
        org.kde.okular || { sysLogger e "Failed to restrict Okular permissions" ; }


    #### Home read only: viewers launched from the CLI with a plain path (the document portal only covers file managers / dialogs)
    ####    > read only: no modification of anything in home; write access stays where granted above
    local roHomeApps=(
        "org.nomacs.ImageLounge"
        "org.kde.okular"
    )
    local roApp

    for roApp in "${roHomeApps[@]}"; do
        sysLogger i "Home read only for $roApp"
        asUser flatpak override --user --filesystem=home:ro "$roApp" || { sysLogger e "Failed to apply home read only to $roApp" ; }
    done


    #### OnlyOffice: documents live in the unlocked Cryptomator vaults; ~/Downloads as exchange folder
    sysLogger i "Restricting OnlyOffice permissions"
    asUser flatpak override --user \
        --nofilesystem=host \
        --filesystem=xdg-download \
        --filesystem="$userHome/.local/share/Cryptomator/mnt" \
        org.onlyoffice.desktopeditors || { sysLogger e "Failed to restrict OnlyOffice permissions" ; }


    #### VLC: only opens local files; read only (subtitles / next file in folder still work), no keyring, GPU only
    sysLogger i "Restricting VLC permissions"
    asUser flatpak override --user \
        --filesystem=host:ro \
        --nodevice=all --device=dri \
        --no-talk-name=org.freedesktop.secrets --no-talk-name=org.kde.kwalletd5 --no-talk-name=org.kde.kwalletd6 --no-talk-name=org.kde.kwalletd \
        org.videolan.VLC || { sysLogger e "Failed to restrict VLC permissions" ; }


    #### Smart card reader (pcsc): no app here uses a card or a hardware key
    local noPcscApps=(
        "com.brave.Browser"
        "com.google.Chrome"
        "com.discordapp.Discord"
        "org.keepassxc.KeePassXC"
    )

    for app in "${noPcscApps[@]}"; do
        sysLogger i "Removing smart card access from "$app""
        asUser flatpak override --user --nosocket=pcsc "$app" || { sysLogger e "Failed to remove smart card access from app "$app"" ; }
    done


    #### The whitelisted Claude paths must exist before the override: a missing path may be skipped and Codium would then write into its throwaway home
    asUser install -d -m 700 "$userHome/.claude" || { sysLogger e "Failed to create $userHome/.claude" ; }
    if [ ! -e "$userHome/.claude.json" ]; then
        asUser sh -c 'printf "{}" > "$1"' _ "$userHome/.claude.json" || { sysLogger e "Failed to create $userHome/.claude.json" ; }
    fi


    ### VSCodium: a text editor and nothing more. Must be the LAST flatpak able to spawn commands on the host
    ###    > no org.freedesktop.Flatpak = no "flatpak-spawn --host". Checks / installs are run by the user in a host terminal
    ###    > active: from here on Codium has no host access, so checks for the KDE configuration / deploy scripts are run by the user in a host terminal
    sysLogger i "Restricting VSCodium permissions"
    ###    > only GPU (dri) and network are kept: no agents / keyrings / buses; filesystem = whitelist below
    ###    > ~/.claude + ~/.claude.json: Claude Code login (plain file, no keyring needed) and sessions / memory
    ###    > ~/Nextcloud + ~/Github: all the work done on the pc. Scripts there are run as root: read diffs before running them
    asUser flatpak override --user \
        --nofilesystem=host --nofilesystem=host-os --nofilesystem=host-etc --nofilesystem=home \
        --filesystem="$userHome/.claude" \
        --filesystem="$userHome/.claude.json" \
        --filesystem="$userHome/Nextcloud" \
        --filesystem="$userHome/Github" \
        --nofilesystem=xdg-run/gnupg \
        --disallow=devel \
        --nosocket=ssh-auth --nosocket=gpg-agent --nosocket=cups \
        --nosocket=pulseaudio --nosocket=session-bus --nosocket=system-bus \
        --nodevice=all --device=dri \
        --no-talk-name=org.freedesktop.Flatpak \
        --no-talk-name=org.freedesktop.secrets --no-talk-name=org.kde.kwalletd5 --no-talk-name=org.kde.kwalletd6 --no-talk-name=org.kde.kwalletd \
        com.vscodium.codium || { sysLogger e "Failed to restrict VSCodium permissions" ; }

}





######################################################################################



deamonsPurge(){
    sysLogger i "Disabling unused deamons"

    local deamonsToDisable=(
        "NetworkManager-wait-online.service"    #### Wait for network
        "avahi-daemon.socket"                   #### Network discovery. Cannot be purged on Fedora: removing avahi drags plasma-desktop out
        "avahi-daemon.service"                  ####    > socket first: it would start the service again on demand
        )
    
    for deamon in "${deamonsToDisable[@]}"; do

        sysLogger i "Disabling $deamon"
        sudo systemctl disable "$deamon" || sysLogger e "failed to disable "$deamon""
    
    done

    #### One call for all: stopped one by one, the avahi socket job got cancelled and the daemon crashed (seen on Fedora 45)
    sysLogger i "Stopping ${deamonsToDisable[*]}"
    sudo systemctl stop "${deamonsToDisable[@]}" || sysLogger e "failed to stop ${deamonsToDisable[*]}"

    #### avahi cannot be purged (see newPc_Install.sh): masked = systemd refuses to start it, whoever asks
    sysLogger i "Masking avahi-daemon.socket avahi-daemon.service"
    sudo systemctl mask avahi-daemon.socket avahi-daemon.service || sysLogger e "failed to mask avahi"
}



######################################################################################



swapSetup(){
    sysLogger i "Swap allocation and setup started"

    local SWAP=6 #### GB, on top of the zram swap Fedora sets up by default
    
    #### Favor RAM over SWAP -- range 0 to 100 higher the number higher the priority of SWAP over RAM
    local SWAPPINESS=10

    #### Filesystem cache - more memory used to cache file access paths and metadata = smoother UI in file managers -- range 0 to 200+ 
    local CACHE_PRESSURE=10

    local swapFavor ; local cacheFavor


    if (( SWAPPINESS <= 30 && SWAPPINESS >= 0 )) ; then
        swapFavor="RAM"

    elif (( SWAPPINESS > 30 && SWAPPINESS <= 100 )) ; then
        swapFavor="SWAP"

    elif (( SWAPPINESS > 100 || SWAPPINESS < 0 )); then
        sysLogger e "Swappiness error: not in range 0 - 100. Current: $SWAPPINESS)"; return 1

    else
        sysLogger e  "Unexpected swappiness error: $SWAPPINESS \nExiting"; return 1
    fi


    if (( CACHE_PRESSURE <= 30 && CACHE_PRESSURE >= 0 )) ; then
        cacheFavor="More RAM for cache"

    elif (( CACHE_PRESSURE > 30 && CACHE_PRESSURE <= 200 )) ; then
        cacheFavor="Less RAM for cache"

    elif (( CACHE_PRESSURE > 200 || CACHE_PRESSURE < 0 )); then
        sysLogger e "CACHE_PRESSURE error: not in range 0 - 200. Current: $CACHE_PRESSURE)"; return 1

    else
        sysLogger e "Unexpected CACHE_PRESSURE error: $CACHE_PRESSURE \nExiting" ; return 1
    fi

    sysLogger i "SWAP config: 
    	> ${SWAP}GB swap memory will be created
        > SWAPPINESS=$SWAPPINESS   CACHE_PRESSURE=$CACHE_PRESSURE
	    > Swap favor:  $swapFavor - $cacheFavor
    "

    sysLogger i "Starting creating swapspace\n"

	#### In case of a 2nd run: the swap file already exists and is in fstab, only the sysctl part is re-applied
	if grep -qE '^[[:space:]]*/swapspace[[:space:]]' /etc/fstab; then
		sysLogger i "/swapspace already present in /etc/fstab, skipping creation"
	else
	sudo swapon --show
	free -h
	df -h
	#### btrfs (Fedora default): a swap file must be NOCOW and uncompressed, fallocate + mkswap is not enough.
	#### `btrfs filesystem mkswapfile` creates it correctly, already 600 and formatted.
	#### TO CONFIRM on Fedora: the btrfs branch and the SELinux label of /swapspace (boot-time swapon) were not tested
	local rootFs; rootFs=$(findmnt -no FSTYPE /)
	if [ "$rootFs" == "btrfs" ]; then
		sudo btrfs filesystem mkswapfile --size "$SWAP"g /swapspace || { sysLogger e "btrfs mkswapfile failed in swap allocation" ; return 1; }
		ls -lh /swapspace
	else
		sudo fallocate -l "$SWAP"G /swapspace || { sysLogger e "fallocate failed in swap allocation" ; return 1; }
		ls -lh /swapspace
		sudo chmod 600 /swapspace || { sysLogger e "chmod failed in swap allocation" ; return 1; }
		ls -lh /swapspace
		sudo mkswap /swapspace  || { sysLogger e "mkswap failed in swap allocation" ; return 1; }
	fi
	sudo swapon /swapspace  || { sysLogger e "swapon failed in swap allocation" ; return 1; }
	sudo swapon --show
	free -h

	sudo cp /etc/fstab /etc/"$(date "+%Y-%m-%d_%H-%M-%S")"_fstab.bak
	echo '/swapspace none swap sw 0 0' | sudo tee -a /etc/fstab
	fi
	cat /proc/sys/vm/swappiness

	printf 'vm.swappiness=%s\nvm.vfs_cache_pressure=%s\n' "$SWAPPINESS" "$CACHE_PRESSURE" \
	| sudo tee /etc/sysctl.d/99-local-vm.conf >/dev/null
	sudo sysctl --system


    sysLogger i "Finished creating swapspace"

	local swapCheck; swapCheck="$(sudo swapon --show)"
	sysLogger i "Swap status check:\n$swapCheck \n"

    sysLogger i "Swap allocation and setup terminated"
}



######################################################################################


tmpfsSetup(){
    #### /tmp in RAM: faster temp I/O, wiped at every boot. Size is a cap, not a reservation (RAM is used only for files actually stored)
    #### % of physical RAM (man 5 tmpfs): scales with each PC, same 30% as runtimeDirSetup
    #### Fedora already mounts /tmp as tmpfs (tmp.mount, 50% of RAM): the fstab line below takes over and sets the size
    #### TO CONFIRM on Fedora: `findmnt /tmp` after the reboot must show size=30%
    local SIZE="30%"
    local fstabLine="tmpfs /tmp tmpfs defaults,noatime,mode=1777,size=$SIZE 0 0"
    local tmpEntryRegex='^[[:space:]]*tmpfs[[:space:]]+/tmp[[:space:]]'

    sysLogger i "tmpfs on /tmp setup started"

    #### In case of a 2nd run
    if grep -qxF "$fstabLine" /etc/fstab; then
        sysLogger i "/tmp entry already present in /etc/fstab"

    #### Entry present but with other options (e.g. an older fixed size): replace that line only
    elif grep -qE "$tmpEntryRegex" /etc/fstab; then
        sudo cp /etc/fstab /etc/"$(date "+%Y-%m-%d_%H-%M-%S")"_fstab.bak || { sysLogger e "fstab backup failed, aborting"; return 1; }

        sysLogger i "Replacing old /tmp entry: $(grep -E "$tmpEntryRegex" /etc/fstab)"

        #### | as sed delimiter: the line contains / but never |
        sudo sed -i -E "s|${tmpEntryRegex}.*|$fstabLine|" /etc/fstab || { sysLogger e "fstab /tmp entry update failed"; return 1; }
        sysLogger i "Updated in /etc/fstab: $fstabLine"

    else
        sudo cp /etc/fstab /etc/"$(date "+%Y-%m-%d_%H-%M-%S")"_fstab.bak || { sysLogger e "fstab backup failed, aborting"; return 1; }

        #### A missing trailing newline would glue the new line onto the last entry
        if [ -n "$(tail -c1 /etc/fstab)" ]; then
            echo | sudo tee -a /etc/fstab >/dev/null || { sysLogger e "fstab newline fix failed"; return 1; }
        fi

        echo "$fstabLine" | sudo tee -a /etc/fstab >/dev/null || { sysLogger e "fstab write failed"; return 1; }
        sysLogger i "Added to /etc/fstab: $fstabLine"
    fi

    #### Double check: exact line present + fstab syntax valid (only the exit code counts, unrelated entries may print warnings)
    grep -qxF "$fstabLine" /etc/fstab || { sysLogger e "fstab check failed: line not found: $fstabLine"; return 1; }

    local verifyOut
    verifyOut=$(findmnt --verify 2>&1) || { sysLogger e "fstab syntax check failed:\n$verifyOut"; return 1; }
    sysLogger i "findmnt --verify output:\n$verifyOut"

    sysLogger i "fstab verified: $(grep -F '/tmp' /etc/fstab)\n/tmp gets the new tmpfs settings after the next reboot"
}




# #### Check status
# tmpfsStatus(){
#     echo "== /tmp entry in /etc/fstab =="
#     if ! grep -E '^[[:space:]]*tmpfs[[:space:]]+/tmp[[:space:]]' /etc/fstab; then
#         echo "No tmpfs /tmp entry"
#     fi

#     echo -e "\n== fstab backups =="
#     ls -1 /etc/*_fstab.bak 2>/dev/null

#     echo -e "\n== Live /tmp (changes only after reboot) =="
#     findmnt -no SOURCE,FSTYPE,OPTIONS /tmp
#     df -h /tmp
# }


# #### Undo modification
# tmpfsUndo(){
#     #### Restores the newest backup made by tmpfsSetup: check tmpfsStatus first, it's the whole fstab
#     local lastBak
#     lastBak=$(ls -1t /etc/*_fstab.bak 2>/dev/null | head -n1)

#     if [ -z "$lastBak" ]; then
#         sysLogger e "No fstab backup found in /etc"
#         return 1
#     fi

#     sudo cp "$lastBak" /etc/fstab || { sysLogger e "Restore failed from $lastBak"; return 1; }
#     sysLogger i "Restored /etc/fstab from $lastBak\nPrevious /tmp settings come back after the next reboot"
# }



######################################################################################


runtimeDirSetup(){
    #### /run/user/<uid> (XDG_RUNTIME_DIR) is a separate tmpfs, sized by systemd-logind (default 10% of RAM), NOT by /etc/fstab
    
    #### Adaptive percentage based on available RAM
    local SIZE="30%"
    local dropInDir="/etc/systemd/logind.conf.d"
    local dropInFile="$dropInDir/runtime-size.conf"
    local sizeLine="RuntimeDirectorySize=$SIZE"

    sysLogger i "Runtime dir size setup started"

    #### In case of a 2nd run
    if [ -f "$dropInFile" ] && grep -qxF "$sizeLine" "$dropInFile"; then
        sysLogger i "$sizeLine already present in $dropInFile"
    else
        #### Drop-in instead of editing logind.conf: package updates may replace logind.conf, never the drop-ins
        sudo mkdir -p "$dropInDir" || { sysLogger e "Failed to create $dropInDir"; return 1; }

        printf '[Login]\n%s\n' "$sizeLine" | sudo tee "$dropInFile" >/dev/null || { sysLogger e "Write failed: $dropInFile"; return 1; }
        sysLogger i "Written $dropInFile: $sizeLine"
    fi

    #### Double check: cat-config prints logind.conf + all drop-ins in load order, the LAST active line is the one applied
    local verifyOut effectiveLine
    verifyOut=$(systemd-analyze cat-config systemd/logind.conf 2>&1) || { sysLogger e "logind config check failed:\n$verifyOut"; return 1; }

    effectiveLine=$(grep -E '^[[:space:]]*RuntimeDirectorySize=' <<< "$verifyOut" | tail -n1)

    if [ "$effectiveLine" != "$sizeLine" ]; then
        sysLogger e "logind config check failed: effective setting is '${effectiveLine:-none}', expected '$sizeLine' (another drop-in overrides it?)"
        return 1
    fi

    sysLogger i "logind verified: $sizeLine\n$userRuntime gets the new size after the next login/reboot"
}


#### Check status
# runtimeDirStatus(){
#     local dropInFile="/etc/systemd/logind.conf.d/runtime-size.conf"

#     echo "== Drop-in file =="
#     if [ -f "$dropInFile" ]; then
#         cat "$dropInFile"
#     else
#         echo "Not present: $dropInFile"
#     fi

#     echo -e "\n== Setting systemd will apply (last active line wins) =="
#     systemd-analyze cat-config systemd/logind.conf | grep -E '^[[:space:]]*#?RuntimeDirectorySize'

#     echo -e "\n== Live mount size (changes only after login/reboot) =="
#     #### Runs as root: $userRuntime (from setup.sh) is the real user's /run/user/<uid>, $(id -u) would be 0
#     df -h "$userRuntime"
# }


#### Undo modification
# runtimeDirUndo(){
#     local dropInDir="/etc/systemd/logind.conf.d"
#     local dropInFile="$dropInDir/runtime-size.conf"

#     if [ -f "$dropInFile" ]; then
#         sudo rm "$dropInFile" || { sysLogger e "Failed to remove $dropInFile"; return 1; }
#         sysLogger i "Removed $dropInFile"
#     else
#         sysLogger i "Nothing to undo: $dropInFile not present"
#     fi

#     #### rmdir only removes an empty folder: other drop-ins (if any) are left untouched
#     if [ -d "$dropInDir" ] && [ -z "$(ls -A "$dropInDir")" ]; then
#         sudo rmdir "$dropInDir" || { sysLogger e "Failed to remove empty $dropInDir"; return 1; }
#         sysLogger i "Removed empty $dropInDir"
#     fi

#     sysLogger i "Back to the default (10% of RAM) after the next login/reboot"
# }





######################################################################################


dataDisksSetup(){
    #### Data disks mounted at boot by systemd, found by LABEL (no UUIDs): 
    #### a replacement disk only needs the same label (e2label);
    #### nofail = a missing disk never blocks the boot (wanted, not required, by local-fs.target)
    
    #### Fedora's desktop mounts removable disks under /run/media/<user>, but an fstab entry decides its own path:
    #### the disks stay under /media/<user>, where every other script expects them (systemd creates missing mountpoint folders)
    #### TO CONFIRM on Fedora: `findmnt` after the reboot

    #### New disk: add its label below
    local labels=( 
        HDD1TB 
        HDD2TB 
        SSD1TB 
        )
    local mediaPath="/media/$realUser"
    local label fstabLine backupDone=0
    local presentLabels=()

    sysLogger i "Data disks fstab setup started"

    for label in "${labels[@]}"; do

        #### A disk that is not plugged in gets no fstab entry (no "timed out waiting for device" at every boot)
        if [ ! -e "/dev/disk/by-label/$label" ]; then
            sysLogger w "Disk $label not found, skipped: plug it in and run again to add it"
            continue
        fi
        presentLabels+=( "$label" )

        fstabLine="LABEL=$label $mediaPath/$label ext4 defaults,nofail,x-systemd.device-timeout=10s 0 2"

        #### The mountpoint folders don't exist on a fresh Fedora (on Mint the desktop had already created them),
        #### and `findmnt --verify` below reports a missing one as an error (seen in the Fedora 45 test run)
        sudo mkdir -p "$mediaPath/$label" || { sysLogger e "Cannot create mountpoint $mediaPath/$label"; return 1; }

        #### In case of a 2nd run: any entry already using this mountpoint, whatever its source (UUID=, LABEL=, /dev/...)
        if grep -qE "^[[:space:]]*[^#[:space:]]+[[:space:]]+$mediaPath/$label[[:space:]]" /etc/fstab; then
            sysLogger i "$mediaPath/$label entry already present in /etc/fstab"
            continue
        fi

        #### One backup per run, before the first change
        if [ "$backupDone" -eq 0 ]; then
            sudo cp /etc/fstab /etc/"$(date "+%Y-%m-%d_%H-%M-%S")"_fstab.bak || { sysLogger e "fstab backup failed, aborting"; return 1; }
            backupDone=1
        fi

        #### A missing trailing newline would glue the new line onto the last entry
        if [ -n "$(tail -c1 /etc/fstab)" ]; then
            echo | sudo tee -a /etc/fstab >/dev/null || { sysLogger e "fstab newline fix failed"; return 1; }
        fi

        echo "$fstabLine" | sudo tee -a /etc/fstab >/dev/null || { sysLogger e "fstab write failed"; return 1; }
        sysLogger i "Added to /etc/fstab: $fstabLine"
    done

    #### Double check: one entry per mountpoint of the disks found + fstab syntax valid (only the exit code counts, unrelated entries may print warnings)
    for label in "${presentLabels[@]}"; do
        grep -qE "^[[:space:]]*[^#[:space:]]+[[:space:]]+$mediaPath/$label[[:space:]]" /etc/fstab || { sysLogger e "fstab check failed: no entry for $mediaPath/$label"; return 1; }
    done

    local verifyOut
    verifyOut=$(findmnt --verify 2>&1) || { sysLogger e "fstab syntax check failed:\n$verifyOut"; return 1; }
    sysLogger i "findmnt --verify output:\n$verifyOut"

    sysLogger i "fstab verified:\n$(grep -F "$mediaPath/" /etc/fstab)\nThe data disks are mounted by systemd from the next reboot"
}


#### For the laptop branch:
#### undo to avoid warnings at each boot
#### sudo cp /etc/fstab /etc/"$(date "+%Y-%m-%d_%H-%M-%S")"_fstab.bak
#### sudo sed -i -E '/^LABEL=(HDD1TB|HDD2TB|SSD1TB)[[:space:]]+\/media\/[^[:space:]]+\/(HDD1TB|HDD2TB|SSD1TB)[[:space:]]/d' /etc/fstab
#### sudo systemctl daemon-reload
#### sudo systemctl reset-failed
#### findmnt --verify



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
#             confFile="$userHome/.config/wireplumber/bluetooth.lua.d/51-disable-handsfree.lua"
#             confText='bluez_monitor.properties["bluez5.roles"] = "[ a2dp_sink a2dp_source ]"
#     bluez_monitor.properties["bluez5.hfphsp-backend"] = "none"'
#             ;;
#         0.5)
#             confFile="$userHome/.config/wireplumber/wireplumber.conf.d/51-disable-handsfree.conf"
#             confText='monitor.bluez.properties = {
#     bluez5.roles = [ a2dp_sink a2dp_source ]
#     bluez5.hfphsp-backend = "none"
#     }'
#             ;;
#         *)
#             echo "[CRITICAL ERROR] Unsupported or missing WirePlumber version: '${wpVersion}'" >&2
#             return 1
#             ;;
#     esac

#     #### Already applied: nothing to do
#     [ "$(cat "$confFile" 2>/dev/null)" = "$confText" ] && return 0

#     mkdir -p "$(dirname "$confFile")" || return 1
#     printf '%s\n' "$confText" > "$confFile" || return 1

#     #### Config is read when WirePlumber starts: restart it now, or it applies from the next session
#     systemctl --user restart wireplumber 2>/dev/null || echo "[INFO] Handsfree disabled: restart the session to apply"
# }




#### Locked in config that prevents any automatic switching to tha handsfree profile
bluetoothProfileAntiSwitch(){
    #### Keeps Bluetooth headsets on A2DP: WirePlumber never switches to, nor restores, the HSP/HFP profile.
    #### HSP/HFP stays registered on purpose: its control channel is what carries the headset battery level.
    #### Writes a persistent WirePlumber user config. Idempotent: a no-op once the config is in place.

    local wpVersion confFile oldConf confText
    wpVersion="$(wireplumber --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)"

    case "$wpVersion" in
        0.4)
            confFile="$userHome/.config/wireplumber/policy.lua.d/51-bt-no-headset-switch.lua"
            oldConf="$userHome/.config/wireplumber/bluetooth.lua.d/51-disable-handsfree.lua"
            confText='bluetooth_policy.policy["media-role.use-headset-profile"] = false
    bluetooth_policy.policy["use-persistent-storage"] = false'
            ;;
        0.5)
            confFile="$userHome/.config/wireplumber/wireplumber.conf.d/51-bt-no-headset-switch.conf"
            oldConf="$userHome/.config/wireplumber/wireplumber.conf.d/51-disable-handsfree.conf"
            confText='wireplumber.settings = {
    bluetooth.autoswitch-to-headset-profile = false
    bluetooth.use-persistent-storage = false
    }'
            ;;
        *)
            sysLogger e "Unsupported or missing WirePlumber version: '${wpVersion}'" >&2
            return 1
            ;;
    esac

    #### Already applied: nothing to do
    if [ ! -e "$oldConf" ] && [ "$(cat "$confFile" 2>/dev/null)" = "$confText" ]; then
        return 0
    fi

    #### Previous config removed HSP/HFP entirely, and battery reporting with it
    asUser rm -f "$oldConf"


    # mkdir -p "$(dirname "$confFile")" ||       { sysLogger e "bluetoothProfileAntiSwitch failed on 'mkdir -p'" ; return 1; }
    # printf '%s\n' "$confText" > "$confFile" || { sysLogger e "bluetoothProfileAntiSwitch failed on 'printf '%s\n''" ; return 1; }

    atomicWrite "$(basename "$confFile")" "$(dirname "$confFile")" "$confText" || { sysLogger e "bluetoothProfileAntiSwitch: config write failed" ; return 1; }


    #### Config is read when WirePlumber starts: restart it now, or it applies from the next session
    asUser systemctl --user restart wireplumber 2>/dev/null || sysLogger i "Config written: restart the session to apply"

}



#### Hides unwanted audio devices from PipeWire (desktop "federico" only: names are hardware-specific).
wireplumberAudioDeviceBlacklist(){
    ####   Kept:     Bluetooth headset, onboard jack output, USB microphone (Q9-1)
    ####   Disabled: GPU HDMI audio, webcam microphone, onboard S/PDIF output, onboard analog input
    #### Writes a persistent WirePlumber user config. Idempotent: a no-op once the config is in place.

    local wpVersion confFile confText
    wpVersion="$(wireplumber --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)"

    case "$wpVersion" in
        0.4)
            confFile="$userHome/.config/wireplumber/main.lua.d/52-audio-blacklist.lua"
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
            confFile="$userHome/.config/wireplumber/wireplumber.conf.d/52-audio-blacklist.conf"
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
            sysLogger e "Unsupported or missing WirePlumber version: '${wpVersion}'" >&2
            return 1
            ;;
    esac

    #### Already applied: nothing to do
    if [ "$(cat "$confFile" 2>/dev/null)" = "$confText" ]; then
        return 0
    fi

    # mkdir -p "$(dirname "$confFile")" || return 1
    # printf '%s\n' "$confText" > "$confFile" || return 1

    atomicWrite "$(basename "$confFile")" "$(dirname "$confFile")" "$confText" || { sysLogger e "wireplumberAudioDeviceBlacklist: config write failed" ; return 1; }


    #### Config is read when WirePlumber starts: restart it now, or it applies from the next session
    asUser systemctl --user restart wireplumber 2>/dev/null || sysLogger i "Config written: restart the session to apply"
}




######################################################################################



#### Install the zero trust policies for chromium browsers

#### Same functions present in bash_functions.sh, but there they are run via `bash -c`
#### so they would require exporting sysLogger; kept echo for that reason

jsPolicyRoot(){
    #### Root-level task: writes to /etc, so it runs as root, not through asUser
    #### $userHome comes from setup.sh: $SUDO_USER is not usable here (it would be root)

    local file="${1:-}"
    local targetDir="${2:-}"

    if [ -z "$file" ] || [ -z "$targetDir" ] ; then sysLogger e "Usage: jsPolicyRoot <file> <target dir>"; return 1 ;fi

    local policySrc="$userHome/Nextcloud/Stuff/BrowserStuff/Policy/"$file""


    if [ ! -s "$policySrc" ]; then sysLogger e "JSON not found: $policySrc"; return 1; fi
    if ! python3 -m json.tool "$policySrc" > /dev/null; then sysLogger e "JS policy backup is not valid JSON: $policySrc"; return 1; fi

    #### 644: the Flatpak sandboxes read it as the normal user
    if install -D -m 644 "$policySrc" "$targetDir/$file"; then
        sysLogger i "JS policy installed: $targetDir/$file"
    else
        sysLogger e "Cannot install the JS policy in $targetDir"; return 1
    fi
}


jsPolicy(){
    #### Already root (launched by setup.sh): no sudo wrapper
    jsPolicyRoot 'jsPolicy.json' '/etc/brave/policies/managed'      || return 1
    jsPolicyRoot 'jsPolicy.json' '/etc/opt/chrome/policies/managed' || return 1
}

jsPolicyChromium(){
    #### Chromium has no /etc/ access
    local chromiumPath="/var/lib/flatpak/extension/org.chromium.Chromium.Policy.system-policies/x86_64/1/policies/managed"
    jsPolicyRoot 'jsPolicy_Chromium.json' "$chromiumPath" || return 1
}



######################################################################################



podmanConfigs(){

    #### Turn off "Emulate Docker CLI using podman"
    local silenceEmulateFile="/etc/containers/nodocker"
    if [ ! -f "$silenceEmulateFile" ]; then
        mkdir -p "/etc/containers" || { sysLogger e "Failed to create the folder /etc/containers" ; return 1;  }
        touch "$silenceEmulateFile" || { sysLogger e "Failed to create the emulate silencer" ; return 1;  }
    else
        sysLogger i "Docker emulate silencer was already present: "$silenceEmulateFile""
    fi


    #### userns config -- keep the right user in the container
    local localConfigFile=""$userHome"/.config/containers/containers.conf"

    asUser mkdir -p ""$userHome"/.config/containers/" || { sysLogger e "Failed to create folder ""$userHome"/.config/containers/""; return 1 ;  }

    #### In case of a 2nd run
    if [ -s "$localConfigFile" ]; then

        sysLogger i "File "$localConfigFile" already present and non-empty; checking for config presence"

        #### Check for config ID
        if isLinePresent whole 'userns = "keep-id"' "$localConfigFile"; then

            sysLogger i "keep-id entry already present in "$localConfigFile""; return 0

        else
            sysLogger i "Other contents were found, but no keep-id; checking for other userns configs"

            if isLinePresent start 'userns=' "$localConfigFile"; then
                sysLogger e "Another userns config is already present, this requires a manual intervention"; return 1
            fi

            if isLinePresent whole '[containers]' "$localConfigFile"; then
                #### If the type [containers] is already present, add the config under it
                asUser sed -i '/^[[:space:]]*\[containers\][[:space:]]*$/a userns = "keep-id"' "$localConfigFile" || { sysLogger e "sed insert failed"; return 1; }

            else
                #### If the type is missing, add that too
                printf '%s\n' '[containers]' 'userns = "keep-id"' | asUser tee -a "$localConfigFile" >/dev/null || { sysLogger e "append failed"; return 1; }
            fi

        fi

    else
        echo '[containers]' | asUser tee -a "$localConfigFile" >/dev/null || { sysLogger e "Failed to add type to config"; return 1; }
        echo 'userns = "keep-id"' | asUser tee -a "$localConfigFile" >/dev/null || { sysLogger e "Failed to add content to config"; return 1; }
    fi

    #### Double check that the config is present
    if isLinePresent whole 'userns = "keep-id"' "$localConfigFile"; then
        sysLogger i "Config correctly applied"
    else
        sysLogger e "Config failed to apply"; return 1
    fi
}



######################################################################################




mainLauncher(){

    sysLogger i "Function mainLauncher started"

    local functions=(
        newpcHistory
        startupBootstrap
        KDE_performance
        KDE_global_settings
        KDEmonitorsRgbFull
        themeSetup
        userGroupCheck
        firewallSetup
        grubSetup
        nemoSetup
        flatpakOverrides
        deamonsPurge
        #### scriptLauncher #### currently all external scripts have their own function
        swapSetup
        tmpfsSetup
        runtimeDirSetup
        dataDisksSetup
        #### bluetoothProfilePurge
        bluetoothProfileAntiSwitch
        wireplumberAudioDeviceBlacklist
        jsPolicy
        jsPolicyChromium
        podmanConfigs
    )

    for func in "${functions[@]}"; do
        sysLogger i "Launching function: "$func""
        "$func" || { sysLogger e "$func failed" ; failedRuns+=("$func"); }

    done

    sysLogger i "Function mainLauncher terminated"

    for failed in "${failedRuns[@]}"; do
        sysLogger e "Run failed - $failed"
    done

    if [ "${#failedRuns[@]}" -gt 0 ]; then return 1; fi
}

sysLogger i "All functions compiled, launching main now"

mainLauncher || { sysLogger e "mainLauncher reported an ERROR" ; }

sysLogger i "Main execution complete" 


######################################################################################



GH_gitConfig(){
    sysLogger i "Git 'gh' config started, expect prompts"

    sysLogger i "Attempting GIT login using 'gh'"

    if ! command -v gh > /dev/null ; then 
        sysLogger e "'gh' command not found"
    else 
        asUser gh auth login --hostname github.com --git-protocol https --web
    fi

    sysLogger i "Git 'gh' config terminated"
}
GH_gitConfig || { sysLogger e "GH_gitConfig failed" ; }