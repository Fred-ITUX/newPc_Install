#!/bin/bash


#### Get display info `ddcutil detect`
#### --sn -- uses `Serial number:`


#### 3CM3131PVV = HP
#### H4ZN504596 = Samsung

#### Fedora KDE version of Shortcuts/night_light.sh: KDE Night Light instead of the GNOME gsettings keys
#### nightLightSet <true|false> [temperature]
#### KWin keeps Night Light in ~/.config/kwinrc [NightColor] (key names checked in KDE's schema file on Fedora 45);
#### the mode "Constant" (on whenever active, no sunset schedule) is set once by newPc/newPc_Scripts.sh
#### TO CONFIRM on Fedora: that KWin applies the change on "reconfigure" (needs a running Plasma session, not testable in a container)
nightLightSet(){
    local active="$1"
    local temperature="${2:-}"

    kwriteconfig6 --file kwinrc --group NightColor --key Active "$active"

    if [ -n "$temperature" ]; then
        kwriteconfig6 --file kwinrc --group NightColor --key NightTemperature "$temperature"
    fi

    #### Ask KWin to re-read kwinrc
    qdbus-qt6 org.kde.KWin /KWin reconfigure > /dev/null 2>&1
}


brightnessSetup(){
    ddcutil --sn "3CM3131PVV" setvcp 10 "$rBright"
    ddcutil --sn "H4ZN504596" setvcp 10 "$lBright"
}


lowBrightness(){
    local rBright=20
    local lBright=5

    nightLightSet false
    brightnessSetup
    status="🕯️"
}   




nightLight(){
    lowBrightness
    
    local temperature=3500 #### 2500

    nightLightSet true "$temperature"
    status="🌙"
}




turnOff(){
    nightLightSet false
    
    ### Reset screen brightness to default values    
    local rBright=70
    local lBright=70
                                           
    brightnessSetup
    status=""
}


cinemaMode(){
    nightLightSet false
    ddcutil --sn "3CM3131PVV" setvcp 10 50
    ddcutil --sn "H4ZN504596" setvcp 10 1 
    status="📽️"
}





case "$1" in 
    "low") lowBrightness;;
    "on") nightLight;;
    "cinemaMode") cinemaMode ;;

    "off") turnOff;;
    *) echo "Night light set error"; turnOff;;
esac



echo "$status" > "${XDG_RUNTIME_DIR}/out_night_light_check.txt"