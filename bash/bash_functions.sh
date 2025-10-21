
#### SysInfo & path 
if [ -f ~/.bash_UT ]; then
    . ~/.bash_UT
fi


################################################################################################

bashUpd(){

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

    #### launch updater & append to the log
    $LXscripts/sys_updater.sh >> "$pathManualUpd"

    #### launch log cleaner
    python3 $LXscripts/Startup_Routine/log_cleaner_MANUAL.py
    gedit "$pathManualUpd"
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
            *.rar)     7z x -mmt="$mmt" "$file" ;;
            *)         echo "❌ Unsupported file type: $file" ;;
        esac
    done
}

################################################################################################

vscan(){

    cd "$1"
    files=$(ls -A) #### -A removes the dots

    echo -e "🦠 Checking files:\n$files \n\nOutput file: $pathCLAMSCAN"
    
    $LXscripts/Scans/clamav_scan.sh >> "$pathCLAMSCAN" 2>&1

    pathCLAMSCAN_check=$(cat "$pathCLAMSCAN" | grep -i "infected files: " | sort --unique )

    if [ "$pathCLAMSCAN_check" != "Infected files: 0" ]; then
        vlc "$logCheckerAlarm"  #### --gain=3
        gedit "$pathCLAMSCAN" &
    fi

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

    #### Clear line + newline before playing sound
    printf "\r%*s\r" "$(tput cols)" ""

    #### Launch vlc (cvlc terminal only)
    cvlc $HOME/Nextcloud/Linux/Stuff/alarm.mp3 #--gain=1
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

}

################################################################################################

latexUPD(){
    latexFile="$1"
    secDelay=3

    filePath=$(dirname "$latexFile")

    echo -e "Moving to file path: $filePath"
    cd "$filePath"

    while true; do   
        pdflatex "$latexFile"
        sleep "$secDelay"
    done
}

################################################################################################

dummyFile(){

    source_path="$1"
    dest_path="$HOME/Downloads/dummy" 

    fileExt="mkv"

    mkdir -p "$dest_path"

    if [ "$source_path" == "" ]; then
        echo -e "Path error"
    
    else 
        #### Find all .mkv files in the directory and create dummy to keep filenames
        find "$source_path" -maxdepth 1 -type f -name "*.$fileExt" -print0 | while IFS= read -r -d '' file; do
            filename=$(basename "$file")
            dummy="$dest_path/$filename"
            touch "$dummy"
        done
        echo "Created dummys into: $dest_path"
    fi
}

################################################################################################

videoLen(){
    source_path="$1"
    totalMilliseconds=0
    fileExt="mkv"

    if [ "$source_path" == "" ]; then
        echo -e "Path error"

    else 
        while IFS= read -r -d '' file; do

            videoLengthRaw=$(mediainfo --Inform="Video;%Duration%" "$file")
            
            #### LC_NUMERIC=C tells printf to use the C (POSIX) locale where decimal separator is .
            videoLength=$(LC_NUMERIC=C printf "%.0f" "$videoLengthRaw")

            totalMilliseconds=$((totalMilliseconds + videoLength ))

        done < <(find "$source_path" -maxdepth 1 -type f -name "*.$fileExt" -print0)
    fi
    totalSeconds=$((totalMilliseconds / 1000))
    hours=$((totalSeconds / 3600))
    minutes=$(((totalSeconds % 3600) / 60))
    seconds=$((totalSeconds % 60))
    echo -e "\nTotal Duration: $(printf "%02d:%02d:%02d" $hours $minutes $seconds)"
}

################################################################################################

gitUPD(){
    git add .
    git commit -m "manual update"
    git pull origin main
    git push
}

################################################################################################

fan(){
    speed="$1"
    shortcuts="$LXscripts/Shortcuts/GPU_fan_speed/gpu_fan_speed"
    case "$speed" in 
        "35") "$shortcuts"_35.sh
        ;;
        "50") "$shortcuts"_50.sh
        ;;
        "75") "$shortcuts"_75.sh
        ;;
        "100") "$shortcuts"_100.sh
        ;;
        *) echo -e "Speed error: $speed (35 - 40 - 50 - 75 - 100)"
    esac
}

################################################################################################

minecraft(){
    gamemoderun java -jar /media/federico/SSD450GB/minecraft/launcher/TLauncher.jar

    nemo --tabs /media/federico/SSD450GB/minecraft/curseforge /media/federico/SSD450GB/minecraft/curseforge/curse_minecraft/Instances /media/federico/SSD450GB/minecraft/versions /home/federico/Nextcloud/Games/Minecraft &
    exit
}

################################################################################################
