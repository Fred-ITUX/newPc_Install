
#### SysInfo & path 
if [ -f ~/.bash_UT ]; then
    . ~/.bash_UT
fi


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

updater(){
    $LXscripts/sys_updater.sh >> "$pathManualUpd" 
    python3 $LXscripts/Startup_Routine/log_cleaner_MANUAL.py
    gedit "$pathManualUpd" &
}    

################################################################################################

extract(){

    file="$1"
    mmt=3   #### mmt = limits the cores used

    if [[ "$file" == "a" ]]; then
        files=(*.zip *.7z *.tar *.tar.gz *.rar)

    elif [[ -n "$file" ]]; then
        files=("$file")
    fi

    if [ -z "$file" ]; then
        echo -e "Usage: extract <filename> or extract <a>"
        files=("")
    fi


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
    
    $LXscripts/Scans/clamav_scan.sh >> "$pathCLAMSCAN" 2>&1

    pathCLAMSCAN_check=$(cat "$pathCLAMSCAN" | grep -i "infected files: " | sort --unique )

    if [ "$pathCLAMSCAN_check" != "Infected files: 0" ]; then
        vlc "$logCheckerAlarm"  #### --gain=3
        gedit "$pathCLAMSCAN" &
    fi
    sudo systemctl disable clamav-daemon.service
} 

################################################################################################

rscan(){

    $LXscripts/Scans/rk_hunter_scan.sh  

} >> "$pathROOTKIT" 2>&1

################################################################################################

alarm(){

    #### alarm in minutes
    timeAmount="$1"
    total_seconds=$((timeAmount * 60))

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

    cvlc $HOME/Nextcloud/Linux/Stuff/alarm.mp3 #--gain=1 #### Launch vlc (cvlc terminal only)
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

killp9() {
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
    path="$1"
    
    echo -e "Adding executable propriety to all .sh files in: $path"
    sudo find "$path" -type f -name "*.sh" -exec chmod +x {} +
    # sudo find $HOME/Nextcloud -type f -name "*.sh" -exec chmod +x {} +
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
