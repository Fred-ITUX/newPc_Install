
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
    latexFile="$1"
    secDelay=3

    filePath=$(dirname "$latexFile")

    echo -e "Moving to file path: $filePath"
    cd "$filePath"

    while true; do   
        latex "$latexFile"
        sleep "$secDelay"
    done
}


################################################################################################

prio(){
    pName="$1"
    #### Negative to give more priority
    NEWprio=10

    if [ "$pName" = "" ]; then
       exit 0
    fi

    PID=$(pgrep -i "$pName")
    processName=$(ps -p "$PID" -o comm=)
    
    if [ -n "$PID" ]; then
        sudo renice -n -"$NEWprio" -p "$PID"
        echo -e "\nReniced $processName (PID $PID) to -$NEWprio"
    else
        echo "Process not found."
    fi
}

################################################################################################

sysInfo(){
    echo -e "\033[1mSystem Info:\033[0m"
    echo -e "OS: $(lsb_release -ds || cat /etc/*release | grep PRETTY_NAME | cut -d= -f2 | tr -d \")"
    echo -e "Kernel: $(uname -r)"
    echo -e "Uptime: $(uptime -p | sed 's/up //')"
    echo -e "Packages: $(dpkg -l | wc -l)"
    echo -e "Flatpak pkg: $(flatpak list  | wc -l)"
    echo -e "Shell: $SHELL"
    echo -e "DE: $XDG_CURRENT_DESKTOP"
    echo -e "Session: $sessionType"
    echo -e "$(neofetch --stdout | grep -E '^ *WM: ') "
    echo -e "CPU: $(lscpu | grep 'Model name' | sed 's/Model name:\s*//')"
    echo -e "GPU: $(lspci | grep VGA | cut -d: -f3 | xargs)"
    echo -e "RAM: $(free -h | awk '/Mem:/ {print $3 " / " $2}')"
    echo -e "SWAP: $(free -h | awk '/Swap:/ {print $3 " / " $2}')"
}

################################################################################################

de(){
    echo -e "Xorg sessions:"
    ls /usr/share/xsessions/
    
    echo -e "\nWayland sessions:"
    ls /usr/share/wayland-sessions/

    echo -e "\nCurrent session:"
    echo "$XDG_SESSION_DESKTOP - $sessionType"
}

################################################################################################
