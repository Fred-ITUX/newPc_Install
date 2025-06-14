
#### SysInfo & path 
if [ -f ~/.bash_UT ]; then
    . ~/.bash_UT
fi


################################################################################################

bashUpd(){

    cp "$LXscripts"/bashRC.sh "$HOME"/.bashrc 
    source "$HOME"/.bashrc
    
    cp "$LXscripts"/bash_aliases.sh "$HOME"/.bash_aliases
    source "$HOME"/.bash_aliases
    
    cp "$LXscripts"/bash_functions.sh "$HOME"/.bash_functions
    source "$HOME"/.bash_functions

    cp "$LXscripts"/sysInfoUT/bash_UT.sh "$HOME"/.bash_UT
    source "$HOME"/.bash_UT

    exec bash
}


################################################################################################

#### Manual updater
updater(){

    #### launch updater & append to the log
    $LXscripts/sys_updater.sh >> "$pathManualUpd"

    #### launch log cleaner
    python3 $LXscripts/Startup_Routine/log_cleaner_MANUAL.py

}    


################################################################################################

vscan(){

    cd "$1"
    
    files=$(ls -A) #### -A removes the dots

    echo -e "🦠 Checking files:\n$files \n\nOutput file: $pathCLAMSCAN"
    
    $LXscripts/Scans/clamav_scan.sh >> "$pathCLAMSCAN" 2>&1

    python3 $LXscripts/Startup_Routine/log_checker_Vscan.py  
} 


################################################################################################

#### Rootkit scan
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

    #### Clear line + newline before playing sound
    printf "\r%*s\r" "$(tput cols)" ""

    #### Launch vlc (cvlc terminal only)
    cvlc $HOME/Nextcloud/Linux/Stuff/alarm.mp3 --gain=1
}

################################################################################################

#### zips all files in current dir individually
zip_folders() {
    # Loop through each folder in the current directory
    for folder in */; do
        # Remove the trailing slash to get the folder name
        folder_name="${folder%/}"

        # Create a zip file named after the folder
        zip -r "${folder_name}.zip" "$folder_name"

        echo -e "\nCompressed $folder_name into ${folder_name}.zip\n"
    done
}

################################################################################################

#### Kill all for specific app PID
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

}


################################################################################################

latexUPD(){

    file="$1"
    secDelay=3

    while true; do   
        latex "$file"
        sleep "$secDelay"
    done

}



################################################################################################


fanSpeed(){

    #### In percentage -- range of rpm 0-255
    speed=$1

    if [ $speed -eq 0 ]; then
       rpm=24
    
    elif [ $speed -eq 30 ]; then
       rpm=96

    elif [ $speed -eq 50 ]; then
       rpm=128

    elif [ $speed -eq 100 ]; then
        rpm=255

    else
        rpm="Not valid"
    fi

    if [ "$rpm" != "Not valid"  ]; then
        echo 1 | sudo tee /sys/class/drm/card1/device/hwmon/hwmon4/pwm1_enable && echo "$rpm" | sudo tee /sys/class/drm/card1/device/hwmon/hwmon4/pwm1
    fi

}

################################################################################################


prio(){


    GAME_NAME="$1"

    #### negative to give priority
    NEWprio=18

    if [ "$GAME_NAME" = "" ]; then
       exit 0
    fi

    PID=$(pgrep "$GAME_NAME")
    processName=$(ps -p "$PID" -o comm=)
    
    if [ -n "$PID" ]; then
        sudo renice -n -"$NEWprio" -p "$PID"
        echo -e "\nReniced $processName (PID $PID) to -$NEWprio"
    else
        echo "Game not found."
    fi


}