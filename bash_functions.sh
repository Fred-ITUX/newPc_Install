
#### SysInfo & path 
if [ -f ~/.sysUT.sh ]; then
    . ~/.sysUT.sh
fi



################################################################################################

                            #################################
                            ####                         ####
                            ####        FUNCTIONS        ####
                            ####                         ####
                            #################################


infoUpd(){

    sudo cp "$LXscripts"/bashRC.sh "$HOME"/.bashrc 
    source "$HOME"/.bashrc
    
    sudo cp "$LXscripts"/bash_aliases.sh "$HOME"/.bash_aliases
    source "$HOME"/.bash_aliases
    
    sudo cp "$LXscripts"/bash_functions.sh "$HOME"/.bash_functions
    source "$HOME"/.bash_functions

    sudo cp "$LXscripts"/sysInfoUT/sysUT.sh "$HOME"/.sysUT.sh
    source "$HOME"/.sysUT.sh

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
    cvlc $HOME/Nextcloud/Linux/Stuff/alarm.mp3 --gain=3
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
