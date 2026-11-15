#!/bin/bash

################################################################################################
####
####    TEMPORARY REVIEW FILE -- Fedora KDE versions of functions from Startup_Routine/startup_common.sh
####
####    Not sourced by anything. Review each function, then move it into startup_common.sh
####    (the rest of that file works on Fedora as it is).
####
####    Functions in this file:
####      > firewalldStatusCheck            replaces ufwStatusCheck (new name: it no longer checks UFW)
####      > launcher_firewalldStatusCheck   replaces launcher_ufwStatusCheck
####            - startup_routine.sh lists "launcher_ufwStatusCheck" in unFuncs: rename it there too
####            - log file: $LXlogs/firewalld_log_check.log (the ufw_log_check variable of bash_common.sh is no longer used)
####      > SESSION_editing                 Konsole instead of GNOME Terminal
####
####    Left out on purpose: gSettingsSetup (GNOME settings, user decision: ignored).
####
################################################################################################


firewalldStatusCheck(){
    #### Fedora replacement for ufwStatusCheck: same behaviour (check, self-heal, alarm), firewalld instead of UFW.
    #### Expected state = what newPc/Fedora/newPc_Scripts.sh firewallSetup configures:
    ####    > firewalld running, default zone "block" (incoming rejected, outgoing allowed)
    ####    > no interface bound to another zone, no service and no port open in the zone
    PID_debugLogger "Starting firewalld check"
    local zone="block"
    local logFile="$LXlogs/firewalld_log_check.log"
    local fwStatus issues

    #### Every firewall-cmd / systemctl line below must match the FIREWALL alias in enable_sudo_whitelist.sh character by character
    firewalldIssues(){
        #### Prints one line per problem found; prints nothing when the firewall is in the expected state
        local state defaultZone otherZones openServices openPorts

        #### tail: a stopped firewalld answers on two lines, the last one is the state ("not running")
        state=$( sudo -n /usr/bin/firewall-cmd --state 2>&1 | tail -n 1 )
        if [ "$state" != "running" ]; then echo "firewalld is not running ($state)"; return 0; fi

        defaultZone=$( sudo -n /usr/bin/firewall-cmd --get-default-zone 2>&1 )
        if [ "$defaultZone" != "$zone" ]; then echo "default zone is '$defaultZone', expected '$zone'"; fi

        #### Zone names are the non-indented lines, e.g. "block (default)"
        otherZones=$( sudo -n /usr/bin/firewall-cmd --get-active-zones 2>&1 | awk '/^[^[:space:]]/ {print $1}' | grep -vx "$zone" | tr '\n' ' ' )
        if [ -n "$otherZones" ]; then echo "interfaces bound to other zones: $otherZones"; fi

        openServices=$( sudo -n /usr/bin/firewall-cmd --zone=block --list-services 2>&1 )
        if [ -n "$openServices" ]; then echo "services open in $zone: $openServices"; fi

        openPorts=$( sudo -n /usr/bin/firewall-cmd --zone=block --list-ports 2>&1 )
        if [ -n "$openPorts" ]; then echo "ports open in $zone: $openPorts"; fi
    }

    #### A denied sudo would look like "not running": tell the two cases apart first.
    #### `sudo -n -l <command>` only asks sudo whether the command is allowed, it does not run it:
    #### it works even when firewalld is stopped (every firewall-cmd call needs the daemon, tested on Fedora 45)
    if ! sudo -n -l /usr/bin/firewall-cmd --state > /dev/null 2>&1; then
        PID_sysLogger e "Cannot query firewalld (sudo denied or firewall-cmd missing)"; raiseAlarm "Firewall check failed: cannot query firewalld"; return 1
    fi

    issues="$(firewalldIssues)"

    if [ -z "$issues" ]; then
        PID_sysLogger i "firewalld is running with the expected policy (zone $zone, nothing open)"; PID_debugLogger "firewalld check done"; return 0
    fi

    PID_sysLogger w "firewalld not in the expected state, self-healing process triggered: $issues"

    {   getSysInfoStart
        echo -e "\n • firewalld before self-heal:\n$issues"

        #### Only the two safe repairs: start the firewall and put the strict zone back as default.
        #### Open services / ports and interfaces in other zones are NOT touched: someone set them on purpose, so they are reported instead
        sudo -n /usr/bin/systemctl enable --now firewalld
        sudo -n /usr/bin/firewall-cmd --set-default-zone=block

    } >> "$logFile" 2>&1

    issues="$(firewalldIssues)"
    fwStatus=$( sudo -n /usr/bin/firewall-cmd --zone=block --list-all 2>&1 )
    echo -e "\n • firewalld after self-heal:\n${issues:-no issues left}\n$fwStatus" >> "$logFile"

    if [ -n "$issues" ]; then
        PID_sysLogger e "firewalld self-heal failed. $issues"; raiseAlarm "Firewall self-heal failed: $issues"; return 1
    fi

    #### A firewall found off or misconfigured is a security event even when healed
    PID_sysLogger w "firewalld self-healing process completed"; raiseAlarm "firewalld was found inactive or misconfigured and has been self-healed"
    PID_debugLogger "firewalld check done (healed)"
}


launcher_firewalldStatusCheck(){ firewalldStatusCheck & }


SESSION_editing(){
    export FLATPAK_LOG_LEVEL=0

    sysLogger i "Audacity"
    flatpak run org.audacityteam.Audacity 2>/dev/null &
    sleep 5s

    #### Quoted: an unquoted & in a URL ends the command and runs the rest as a separate command
    local editingUrls=(
        "https://www.youtube.com/feed/subscriptions"
        "https://www.remove.bg/upload"
        "https://notube.link/it/youtube-app-211"
        "https://www.google.com/imghp?hl=it&ogbl"
    )

    sysLogger i "Brave incognito"
    flatpak run com.brave.Browser --incognito "${editingUrls[@]}" 2>/dev/null &
    sleep 5s


    sysLogger i "GIMP"
    flatpak run org.gimp.GIMP 2>/dev/null &
    sleep 5s


    sysLogger i "OBS"
    flatpak run com.obsproject.Studio 2>/dev/null &
    sleep 5s

    sysLogger i "Text editors"
    gedit "$HOME/Nextcloud/Kden/DaFixare.txt" "$HOME/Nextcloud/Kden/Other/Docs/MusicInfo.txt" &

    sysLogger i "Nemo double instance"
    nemo --tabs "$HOME/Downloads/" "$HOME/Videos/Edit/Projects/" "$HOME/Videos/Edit/" "$HOME/Videos/" &> /dev/null &
    nemo --tabs "$HOME/Downloads/" "$HOME/Videos/Edit/Projects/" "$HOME/Videos/Edit/" "$HOME/Videos/" &> /dev/null &


    sysLogger i "Pavucontrol"
    pavucontrol 2>/dev/null &


    sysLogger i "Terminal double instance"
    cd "$HOME"
    #### TO CONFIRM on Fedora: Konsole in place of GNOME Terminal
    konsole --new-tab & 
    konsole --new-tab & 
}
