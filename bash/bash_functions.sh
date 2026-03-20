#!/bin/bash

if [ -f ~/.bash_UT ]; then . ~/.bash_UT; fi 

################################################################################################

bashUpd(){

    LXscripts="$HOME/Nextcloud/Linux/scripts"
    cp "$LXscripts"/bash/bash_RC.sh "$HOME"/.bashrc 
    source "$HOME"/.bashrc
    
    cp "$LXscripts"/bash/bash_aliases.sh "$HOME"/.bash_aliases
    source "$HOME"/.bash_aliases
    
    cp "$LXscripts"/bash/bash_functions.sh "$HOME"/.bash_functions
    source "$HOME"/.bash_functions

    cp "$LXscripts"/bash/bash_UT.sh "$HOME"/.bash_UT
    source "$HOME"/.bash_UT

    exec bash
}

################################################################################################

shutdown_routine(){
    "$LXscripts/Shortcuts/night_light.sh" off

    echo "$(date +"%Y-%m-%d");$(uptime | cut -d ',' -f 1 | awk '{print $3, $4}')" >> "$PYscripts/UptimePlot/"$(date +%Y)"_uptime.csv"

    sudo rm "$HOME/.bash_history"

    kdenBkpDir="$HOME/Videos/Edit/Kden/kdenFiles/data/kdenlive/.backup"
    if [ -d "$kdenBkpDir" ]; then sudo rm -rf "$kdenBkpDir"; fi #### rm kden bkp to avoid stacking
}

shutdown(){
    shutdown_routine
    sudo shutdown now
}

reboot(){
    read -r -p '' #### double check press
    shutdown_routine
    sudo reboot now
}

end(){
    read -r -p '' #### double check press
    shutdown_routine
    shutdown
}

################################################################################################

sysUPD(){
    export DEBIAN_FRONTEND=noninteractive #### safety prompt avoid
    get_sys_Info

    echo -e "\n\t
        • Fix broken pkg:
        \t"
    sudo dpkg --configure -a 
    sudo apt --fix-broken install -y 


    echo -e "\n\t
        • Update:
        \t"
    sudo apt --fix-missing -q update
        

    echo -e "\n\t
        • Upgrade:
        \t"
    sudo apt full-upgrade -y


    echo -e "\n\t
        • Flatpak update:
        \t" 
    sudo flatpak update -y 


    echo -e "\n\t
        • Autoremove:
        \t"
    sudo apt autoremove -y
    sudo apt clean


    echo -e "\n\t
        • 2nd Fix broken pkg:
        \t"
    sudo dpkg --configure -a 
    sudo apt --fix-broken install -y 

    get_sysInfo_END
    python3 "$LXscripts/Startup_Routine/log_cleaner.py"
} 

updater(){
    sysUPD >> "$pathManualUpd" 
    gedit "$pathManualUpd" &
}    

################################################################################################

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
        isGnome=$(echo "$XDG_CURRENT_DESKTOP")
        if [ "$isGnome" == "GNOME" ]; then printOut=$(echo -e "$(gnome-shell --version 2>/dev/null | cut -d' ' -f3)"); else printOut=""; fi
        echo "$printOut"
    }

    #### Bold title ---- New lines inserted to fold the function
    echo -e "\033[1mSystem Info:\033[0m $(get_formatted_date) \nOS: $(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/*release | cut -d= -f2 | tr -d \") \nKernel: $(uname -r) \nUptime: $(uptime -p | sed 's/up //') \nPackages: $(dpkg -l | wc -l) \nFlatpak pkg: $(flatpak list  | wc -l) \nShell: $(get_shell_version) \nDE: ${XDG_CURRENT_DESKTOP:-Unknown} $(get_gnome_version) \nSession: ${XDG_SESSION_TYPE:-unknown} \nWM: $(get_wm) \nCompositor: $(get_compositor) \nTheme: $(get_gtk_theme) \nIcons: $(get_icon_theme) \nFont: $(get_font_name) \nCPU: $(lscpu | grep 'Model name' | sed 's/Model name:\s*//') \nGPU: $(lspci | grep VGA | cut -d: -f3 | xargs) \nRAM: $(free -h | awk '/Mem:/ {print $3 " / " $2}') \nSWAP: $(free -h | awk '/Swap:/ {print $3 " / " $2}')"
}

################################################################################################

BKP_nxt(){
    if [ -z "$1" ]; then echo -e "Enter bkp destination path."
    elif [ -n "$1" ] && [ -d "$1" ]; then
        7z a -mmt=4 "$1/bkp_nextcloud_$(get_file_date).zip" "$HOME/Nextcloud"
        echo -e "Created $1/bkp_nextcloud_$(get_file_date).zip"
    else echo -e "Not a valid path: $1"; fi
}


BKP_home(){
    if [ -z "$1" ]; then echo -e "Enter bkp destination path."
    elif [ -n "$1" ] && [ -d "$1" ]; then
        7z a -mmt=4 "$1/homebkp_$(get_file_date).zip"  $HOME/.config $HOME/.gnupg $HOME/.linuxmint     $HOME/.local $HOME/.pki $HOME/.ssh    $HOME/.gtkrc-2.0 $HOME/.gtkrc-xfce $HOME/.lesshst    $HOME/.profile $HOME/.wget-hsts $HOME/.Xauthority $HOME/.xsession-errors   
        echo -e "Created $zipName"
    else echo -e "Not a valid path: $1"; fi
}

################################################################################################

extract(){
    file="$1"
    mmt=3   #### mmt = limits the cores used

    if [[ "$file" == "a" ]]; then files=(*.zip *.7z *.tar *.tar.gz *.rar); elif [[ -n "$file" ]]; then files=("$file"); fi

    if [ -z "$file" ]; then echo -e "Usage: extract <filename> or extract <a>" && files=(""); fi

    for file in "${files[@]}"; do
        [[ -e "$file" ]] || continue

        echo -e "\n📦 Extracting: $file"
        case "$file" in 
            *.zip)     7z x -mmt="$mmt" "$file" ;; 
            *.7z)      7z x -mmt="$mmt" "$file" ;;
            *.tar)     tar -xvf "$file" ;;
            *.tar.gz)  tar -xvzf "$file" ;;
            *.rar)     7z x -mmt="$mmt" "$file" ;; #### -mmt... -p"" file for password archives
            *)         echo "❌ Unsupported file type: $file" ;;
        esac
    done
}

################################################################################################

vscan(){
    sudo systemctl start clamav-daemon.service
    cd "$1"
    files=$(ls -A) #### -A removes the dots

    echo -e "🦠 Checking files:\n$files \n\nOutput file: $pathCLAMSCAN"
    
    clamScanning(){
        dir="${1:-$(pwd)}"
        max_size="5M" 

        echo -e "$(get_sys_Info)
            • Scanning dir: $dir - Max "$max_size"B
            • Clamav signatures DB update..."

        sudo freshclam --q #### freshclam update DB (--q suppress output)

        echo -e "    • Signatures DB updated, starting scan"

        sudo clamscan --remove --recursive --infected --max-filesize="$max_size"  "$dir" 

        get_sysInfo_END
    }  >> "$pathCLAMSCAN" 2>&1

    clamScanning

    pathCLAMSCAN_check=$(grep -i "infected files:" "$pathCLAMSCAN" | sort -u)

    if [ "$pathCLAMSCAN_check" != "Infected files: 0" ]; then vlc "$logCheckerAlarm"; fi

    gedit "$pathCLAMSCAN" &
    sudo systemctl disable clamav-daemon.service
} 

rscan(){
    export DEBIAN_FRONTEND=noninteractive
    get_sys_Info
    sudo rkhunter --check --propupd --skip-keypress --no-color -x --report-warnings-only
    get_sysInfo_END 
} >> "$pathROOTKIT" 2>&1

################################################################################################

alarm(){
    timeAmount="$1"
    total_seconds=$((timeAmount * 60))  #### alarm in minutes

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
    cvlc "$HOME/Nextcloud/Linux/Stuff/alarm.mp3" #--gain=1 #### Launch vlc (cvlc terminal only)
}

################################################################################################

stopwatch(){
    time=0
    echo -e "⏰ Starting stopwatch: $(get_formatted_date)\n"

    while true; do
        mins=$(( time / 60 ))
        secs=$(( time % 60 ))

        printf "\r⏳ Time: %02d:%02d" "$mins" "$secs"
        sleep 1s
        (( time++ ))
    done
}

################################################################################################

killp9(){
    process="$1"
    #### Reads each PID into an indexed array, splitting on whitespace/newlines:
    pids=($(pgrep -f "$process"))

    for pid in "${pids[@]}"; do
        echo -e "Killing process - $process: $pid"
        sudo kill -9 $pid
    done
}

################################################################################################

addExec(){
    if [ -n "$1" ]; then echo -e "Adding executable propriety to all .sh files in: $1" && sudo find "$1" -type f -name "*.sh" -exec chmod +x {} +; fi
}

################################################################################################

latexUPD(){
    latexFile="$1"
    cd $(dirname "$latexFile")       ####  LaTeX dumps the files to the current working directory
    latexPdf=$(echo -e "$latexFile" | awk '{$1=$1; gsub(/\.tex/, "") ; print}' )
    flatpak run org.kde.okular "$latexPdf.pdf" &
    check(){
        stat -c "%Y" "$latexFile"    #### check file update
    }
    ver1=$(check)
    while true; do
        sleep 1s
        ver2=$(check)
        if [ "$ver1" != "$ver2" ]; then
            ver1=$(check)
            xelatex -shell-escape "$latexFile" #### Shell escape is required for minted package
        fi
    done
}

################################################################################################

minecraft(){
    gamemoderun java -jar /media/federico/SSD450GB/minecraft/launcher/TLauncher.jar

    nemo --tabs /media/federico/SSD450GB/minecraft/curseforge /media/federico/SSD450GB/minecraft/curseforge/curse_minecraft/Instances /media/federico/SSD450GB/minecraft/versions /home/federico/Nextcloud/Games/Minecraft &
    exit
}

################################################################################################

ej(){
    disk="$1"

    externalDisk=$(lsblk -rno NAME,MOUNTPOINT | grep EXT | awk '{print $1}' )

    if [ "$externalDisk" != '' ]; then
    
    diskNamePrompt=$(lsblk -rno NAME,MOUNTPOINT,SIZE | grep sdd2 | tr '└─' ' ')
    echo -e $"External storage detected: $diskNamePrompt \n "
    read -p "Do you want to eject it? y/n " choiche
        if [ "$choiche" == "y" ]; then
            disk="$externalDisk" 
        fi
    fi

    diskCheck=$(lsblk | grep "$disk")

    if [ -z  "$disk" ]; then
        echo -e "Usage: ej </disk>"

    elif [ -z "$diskCheck" ]; then
        echo -e "Invalid disk: $disk"
    else
        echo -e "Unmounting..."
        udisksctl unmount -b "/dev/$disk" #### example: udisksctl unmount -b /dev/sdd2 
        echo -e "Turning off..."
        udisksctl power-off -b "/dev/$disk"
        echo -e "Done. The drive can now be safely removed."
    fi
}

################################################################################################

pizza(){
    date=$(date +"%Y-%m-%d")
    echo -e "$date" >> $HOME/Nextcloud/Python/scripts/PizzaPlot/pizza_data.csv
    python3 $HOME/Nextcloud/Python/scripts/PizzaPlot/pizza.py
    echo -e "🍕 Pizza 🍕"
    flatpak run org.nomacs.ImageLounge $HOME/Nextcloud/Python/scripts/PizzaPlot/PizzaPlot.png &
}

################################################################################################

orion-install(){
    flatpak install app/com.ktechpit.orion/x86_64/stable -y
    flatpak run com.ktechpit.orion/x86_64/stable &
}

orion-uninstall(){
    flatpak uninstall app/com.ktechpit.orion/x86_64/stable -y
    rm -rf $HOME/.var/app/com.ktechpit.orion
    rm $HOME/Downloads/.Orion.id
    rm -rf $HOME/Downloads/Orion

}

################################################################################################

allRepoPush(){
    scripts=$(find "$LXscripts/Github" -maxdepth 1 -type f -name  "*_update.sh" )
    
    for script in $scripts; do
        echo -e "\n >>> Running -- $(basename "$script")" && bash "$script"
        if [ $? -ne 0 ]; then echo -e "⚠️ [ERROR] $(basename "$script") failed!"; fi done
}

################################################################################################

