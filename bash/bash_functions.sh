#!/bin/bash

if [ -f "$HOME/.bash_common" ]; then source "$HOME/.bash_common"; else echo -e "[CRITICAL ERROR] Bash module not found: $HOME/.bash_common" ; fi

userCheck

##################################################

bashUpd(){
    if [ -z "$LXscripts" ]; then local LXscripts="$HOME/Nextcloud/Linux/scripts"; fi
    
    cp "$LXscripts"/bash/bash_rc.sh "$HOME"/.bashrc 
    source "$HOME"/.bashrc
    
    cp "$LXscripts"/bash/bash_functions.sh "$HOME"/.bash_functions
    source "$HOME"/.bash_functions

    cp "$LXscripts"/bash/bash_common.sh "$HOME"/.bash_common
    source "$HOME"/.bash_common

    exec bash
}

##################################################

shutdown_routine(){
    "$LXscripts/Shortcuts/night_light.sh" off
    echo "$(date +"%Y-%m-%d");$(uptime | cut -d ',' -f 1 | awk '{print $3, $4}')" >> "$PYscripts/UptimePlot/"$(date +%Y)"_uptime.csv"
    if [ -f "$HOME/.bash_history" ]; then sudo rm "$HOME/.bash_history"; fi
    killp15 "brave" &
    killp15 "chrome" &
    sleep 1s
    if [ "$pc" == "$main" ]; then
        kdenBkpDir="$HOME/Videos/Edit/Kden/kdenFiles/data/kdenlive/.backup" #### rm kden bkp to avoid stacking

        #### Turn off the monitors
        #### 01 -- On   |   05 -- Off   |   04 -- Standby / Sleep
        ddcutil --display 1 setvcp d6 04
        # ddcutil --display 2 setvcp d6 05

        if [ -d "$kdenBkpDir" ]; then sudo rm -rf "$kdenBkpDir"; fi; fi
}


shutdown(){
    shutdown_routine
    sudo shutdown now
}

reboot(){
    read -r -p ''
    shutdown_routine
    sudo reboot now
}

end(){
    read -r -p ''
    shutdown_routine
    shutdown
}

##################################################

sysUPD(){
    export DEBIAN_FRONTEND=noninteractive #### safety prompt avoid

    local UPD_path="${XDG_RUNTIME_DIR}/UPD_logs"

    if [ ! -d "$UPD_path" ]; then mkdir -p "$UPD_path" ; fi

    local outputLog="${1:-}"

    local fixPkg="$UPD_path/UPD_fixPkg.log"
    local update="$UPD_path/UPD_update.log"
    local upgrade="$UPD_path/UPD_upgrade.log"
    local flatpakUpdt="$UPD_path/UPD_flatpakUpdt.log"
    local cleanup="$UPD_path/UPD_cleanup.log"
    local completeLog="$UPD_path/UPD_completeLog.log"

    echo -n > "$fixPkg" ; echo -n > "$update" ; echo -n > "$upgrade" ; echo -n > "$flatpakUpdt" ; echo -n > "$cleanup" ; echo -n > "$completeLog"

    UPD_fix(){
        echo -e "\n• Fix broken pkg: \n"
        sudo dpkg --configure -a 
        sudo apt-get --fix-broken install -y 
    } > "$fixPkg"


    UPD_updater(){
        echo -e "\n• Update: \n"
        sudo apt-get --fix-missing -q update
    } > "$update"


    UPD_upgrade(){
        echo -e "\n• Upgrade: \n"
        sudo apt-get dist-upgrade -y #### full-upgrade
    } > "$upgrade"


    UPD_flatpak(){
        echo -e "\n• Flatpak update: \n" 
        sudo flatpak update -y 
    } > "$flatpakUpdt"


    UPD_cleanup(){
        echo -e "\n• Autoremove: \n"
        sudo apt-get autoremove -y ; sudo apt-get clean
    } > "$cleanup"


    #### If the content matches with the empty preset, that block does not get saved
    UPD_check(){

        if [ -n "$content_fixPkg" ] && [ -n "$content_update" ] && [ -n "$content_upgrade" ] && [ -n "$content_flatpakUpdt" ] && [ -n "$content_cleanup" ]; then
            echo -e "\n\t> Nothing to report" >> "$completeLog"; return 0
        fi

        if [ -n "$content_fixPkg" ]; then echo -n > "$fixPkg"
            else cat "$fixPkg" >> "$completeLog"
        fi

        #### Reverse logic -- the only useful output is in case of ERRORS / WARNINGS
        if [ -z "$content_update" ]; then echo -n > "$update"
            else cat "$update" >> "$completeLog"
        fi


        if [ -n "$content_upgrade" ]; then echo -n > "$upgrade"
            else cat "$upgrade" >> "$completeLog"
        fi


        if [ -n "$content_flatpakUpdt" ]; then echo -n > "$flatpakUpdt"
            else cat "$flatpakUpdt" >> "$completeLog"
        fi


        if [ -n "$content_cleanup" ]; then echo -n > "$cleanup"
            else cat "$cleanup" >> "$completeLog"
        fi
    }


    UPD_fix
    UPD_updater
    UPD_upgrade
    UPD_flatpak
    UPD_cleanup
    UPD_fix

    #### Indent text to allow fold per-day
    sed 's/^/\t/' -i "$fixPkg"
    sed 's/^/\t/' -i "$update"
    sed 's/^/\t/' -i "$upgrade"
    sed 's/^/\t/' -i "$flatpakUpdt"
    sed 's/^/\t/' -i "$cleanup"
    sed 's/^/\t/' -i "$completeLog"


    #### Retain full log
    local strtp_full="$pathStartupUpdaterFull"
    getSysInfoStart     >> "$strtp_full"
    cat "$fixPkg"       >> "$strtp_full" 
    cat "$update"       >> "$strtp_full" 
    cat "$upgrade"      >> "$strtp_full" 
    cat "$flatpakUpdt"  >> "$strtp_full" 
    cat "$cleanup"      >> "$strtp_full" 
    getSysInfoEnd       >> "$strtp_full"
    

    local content_fixPkg=$( cat "$fixPkg" | grep -iE "0 upgraded, 0 newly installed, 0 to remove" )
    local content_update=$( cat "$update" | grep -iE "WARN|ERR|ERROR|REMOVED" )
    local content_upgrade=$( cat "$upgrade" | grep -iE "0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded" )
    local content_flatpakUpdt=$( cat "$flatpakUpdt" | grep -iE "Nothing to do" )
    local content_cleanup=$( cat "$cleanup" | grep -iE "0 upgraded, 0 newly installed, 0 to remove" )



    getSysInfoStart >> "$completeLog"

    UPD_check

    getSysInfoEnd >> "$completeLog"

    echo -e "$completeLog" | py "$LXscripts/Startup_Routine/log_cleaner.py" 

    cat "$completeLog" >> "$1"
} 

updater(){
    sysUPD "$pathManualUpd" 
    gedit "$pathManualUpd" &
}

##################################################

systemInfo(){
    get_wm(){
    if [ "$XDG_CURRENT_DESKTOP" == "GNOME" ]; then echo "Mutter"; elif [ "$XDG_CURRENT_DESKTOP" == "KDE" ]; then echo "KWin"
    else
        wm=$(xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | awk -F'#' '/^_NET_SUPPORTING_WM_CHECK/ {print $2}' | xargs -I{} xprop -id {} _NET_WM_NAME 2>/dev/null | cut -d '"' -f2)
        echo "${wm:-Unknown}" 
    fi 
    }
    get_compositor(){
        if pgrep -x picom > /dev/null; then
            echo "picom"
        elif pgrep -x compton > /dev/null; then
            echo "compton"
        elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
            echo "KWin (built-in)"
        elif [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
            echo "Mutter (built-in)"
        else
            echo "Unknown"
        fi
    }

    get_gtk_theme() {
        gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'"
    }
    get_icon_theme() {
        gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'"
    }
    get_font_name() {
        gsettings get org.gnome.desktop.interface font-name 2>/dev/null | tr -d "'"
    }

    get_shell_version() {
        case "$SHELL" in
            */bash) bash --version | head -n1 ;;
            */zsh) zsh --version ;;
            */fish) fish --version ;;
            *) echo "$SHELL" ;;
        esac
    }

    get_gnome_version(){
        local isGnome=$(echo "$XDG_CURRENT_DESKTOP")
        if [ "$isGnome" == "GNOME" ]; then printOut=$(echo -e "$(gnome-shell --version 2>/dev/null | cut -d' ' -f3)"); else printOut=""; fi
        echo "$printOut"
    }

    #### Bold title ---- New lines inserted to fold the function
    echo -e "\033[1mSystem Info:\033[0m $(get_formatted_date) \nOS: $(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/*release | cut -d= -f2 | tr -d \") \nKernel: $(uname -r) \nUptime: $(uptime -p | sed 's/up //') \nPackages: $(dpkg -l | wc -l) \nFlatpak pkg: $(flatpak list  | wc -l) \nShell: $(get_shell_version) \nDE: ${XDG_CURRENT_DESKTOP:-Unknown} $(get_gnome_version) \nSession: ${XDG_SESSION_TYPE:-unknown} \nWM: $(get_wm) \nCompositor: $(get_compositor) \nTheme: $(get_gtk_theme) \nIcons: $(get_icon_theme) \nFont: $(get_font_name) \nCPU: $(lscpu | grep 'Model name' | sed 's/Model name:\s*//') \nGPU: $(lspci | grep VGA | cut -d: -f3 | xargs) \nRAM: $(free -h | awk '/Mem:/ {print $3 " / " $2}') \nSWAP: $(free -h | awk '/Swap:/ {print $3 " / " $2}')"
}

##################################################

BKP_nxt(){
    if [ -z "$1" ]; then sysLogger e "Enter bkp destination path."
    elif [ -n "$1" ] && [ -d "$1" ]; then
        7z a -mmt=8 "$1/bkp_nextcloud_$(get_file_date).zip" "$HOME/Nextcloud"
        sysLogger i "Created $1/bkp_nextcloud_$(get_file_date).zip"
    else sysLogger e "Not a valid path: $1"; fi
}


BKP_home(){
    if [ -z "$1" ]; then sysLogger e "Enter bkp destination path."
    elif [ -n "$1" ] && [ -d "$1" ]; then
        7z a -mmt=8 "$1/homebkp_$(get_file_date).zip"  $HOME/.config $HOME/.gnupg $HOME/.linuxmint     $HOME/.local $HOME/.pki $HOME/.ssh    $HOME/.gtkrc-2.0 $HOME/.gtkrc-xfce $HOME/.lesshst    $HOME/.profile $HOME/.wget-hsts $HOME/.Xauthority $HOME/.xsession-errors   
        sysLogger i "Created $zipName"
    else sysLogger e "Not a valid path: $1"; fi
}

##################################################

extract(){
    local file="$1"; local mmt=6

    if [[ "$file" == "a" ]]; then files=(*.zip *.7z *.tar *.tar.gz *.rar); elif [[ -n "$file" ]]; then files=("$file"); fi

    if [ -z "$file" ]; then echo -e "Usage: extract <filename> or extract <a>" && files=(""); fi

    for file in "${files[@]}"; do
        [[ -e "$file" ]] || continue

        sysLogger i "Extracting: $file"
        case "$file" in 
            *.zip)     7z x -mmt="$mmt" "$file" ;; 
            *.7z)      7z x -mmt="$mmt" "$file" ;;
            *.tar)     tar -xvf "$file" ;;
            *.tar.gz)  tar -xvzf "$file" ;;
            *.rar)     7z x -mmt="$mmt" "$file" ;; #### -mmt... -p"" file for password archives
            *)         sysLogger e "Unsupported file type: $file" ;;
        esac
    done
}

##################################################

alarm(){
    local timeAmount="$1"; local total_seconds=$((timeAmount * 60))  #### alarm in minutes

    echo -e "⏰ Starting timer: ${timeAmount} minute(s)"
    sleep 1s

    #### Clean output in terminal at each iteration
    while (( total_seconds > 0 )); do
        mins=$(( total_seconds / 60 ))
        secs=$(( total_seconds % 60 ))

        printf "\r⏳ Time left: %02d:%02d " "$mins" "$secs"

        sleep 1s
        (( total_seconds-- ))
    done

    printf "\r%*s\r" "$(tput cols)" "" #### Clear line + newline before playing sound
    cvlc "$HOME/Nextcloud/Linux/Stuff/alarm.mp3" #--gain=1
}

##################################################

stopwatch(){
    local time=0
    echo -e "⏰ Starting stopwatch: $(get_formatted_date)\n"

    while true; do
        mins=$(( time / 60 ))
        secs=$(( time % 60 ))

        printf "\r⏳ Time: %02d:%02d" "$mins" "$secs"
        sleep 1s
        (( time++ ))
    done
}

##################################################

killp9(){
    local process="$1"
    local pids=($(pgrep -f "$process")) #### Reads each PID into an indexed array, splitting on whitespace/newlines

    for pid in "${pids[@]}"; do
        sysLogger i "Killing process - $process: $pid"
        sudo kill -9 "$pid"
    done
}

killp15(){
    local process="$1"
    local pids=($(pgrep -f "$process")) #### Reads each PID into an indexed array, splitting on whitespace/newlines

    for pid in "${pids[@]}"; do
        sysLogger i "Killing process - $process: $pid"
        sudo kill -15 "$pid"
    done
}

##################################################

latexSET(){
    nemo --tabs "$HOME/Nextcloud/Docker" "$HOME/Nextcloud/Latex" &
    
    gnome-terminal --tab --working-directory="$HOME/Nextcloud/Latex"  &  

    gnome-terminal --tab --working-directory="$HOME/Nextcloud/Docker/Containers/latex" & 
}

latexUPD(){
    local latexFile="$HOME/$1"
    cd $(dirname "$latexFile")       ####  LaTeX dumps the files to the current working directory
    
    local latexPdf=$(echo -e "$latexFile" | awk '{$1=$1; gsub(/\.tex/, "") ; print}' )
    flatpak run org.kde.okular "$latexPdf.pdf" &
    
    check(){
        stat -c "%Y" "$latexFile"    #### check file update
    }

    local ver1=$(check)
    
    while true; do
        sleep 1s
        local ver2=$(check)
        if [ "$ver1" != "$ver2" ]; then
            local ver1=$(check)
            xelatex -shell-escape "$latexFile" #### Shell escape is required for minted package
        fi
    done
}

##################################################

minecraft(){                
    local mcFolder="/media/federico/SSD1TB/minecraft"
    nemo --tabs "$mcFolder/curseforge" "$mcFolder/curseforge/curse_minecraft/Instances" "$mcFolder/versions" "$HOME/Nextcloud/Games/Minecraft" &
    gamemoderun java -jar "$mcFolder/launcher/TLauncher.jar" 
}

##################################################

pizza(){
    echo -e "$(date +"%Y-%m-%d")" >> "$PYscripts/PizzaPlot/pizza_data.csv"
    py "$PYscripts/PizzaPlot/pizza.py"
    echo -e "🍕 Pizza 🍕"
    flatpak run org.nomacs.ImageLounge "$PYscripts/PizzaPlot/PizzaPlot.png" &
}

##################################################

orion-install(){
    flatpak install app/com.ktechpit.orion/x86_64/stable -y
    flatpak run com.ktechpit.orion/x86_64/stable &
}

orion-uninstall(){
    flatpak uninstall app/com.ktechpit.orion/x86_64/stable -y
    rm -rf "$HOME/.var/app/com.ktechpit.orion"
    rm "$HOME/Downloads/.Orion.id"
    rm -rf "$HOME/Downloads/Orion"
}

##################################################

allRepoPush(){
    local scripts=$(find "$LXscripts/Github" -maxdepth 1 -type f -name  "*_update.sh" )
    
    for script in $scripts; do
        sysLogger i "Running -- $(basename "$script")" && bash "$script"
        if [ $? -ne 0 ]; then sysLogger e "$(basename "$script") failed!"; fi done
    sysLogger i "Repo update done."
}

##################################################

getFileInfo(){
    for file in "$@"; do

        mediainfo --Output=$'General;File Name: %FileName%\\r\\nBit Rate: %BitRate/String%\\r\\nDuration: %Duration/String3%\\r\\nFPS: %FrameRate%\\r\\nSize: %FileSize/String%\nVideo;\\r\\nDimensions: %Width%x%Height%\\r\\n' "$file"

    done | zenity --text-info --width=500 --height=300 --title="Video Info"
}

##################################################
