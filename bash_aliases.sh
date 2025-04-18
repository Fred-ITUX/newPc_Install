

#########################################################################
#### distro name for logging
osname=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/OSname.sh)

#### formatted date
dateSTR=$(python3 $HOME/Nextcloud/Linux/scripts/sysInfoUT/date.py)

#### formatted date for file names
dateSTR_FILE=$(python3 $HOME/Nextcloud/Linux/scripts/sysInfoUT/date_filename.py)

#### log standard setup (Start -- date , Running for: ...)
sysInfo=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/sysInfo.sh)

#### log standard setup end part (end date)
sysInfo_END=$($HOME/Nextcloud/Linux/scripts/sysInfoUT/sysInfo_END.sh)
#########################################################################


################################################################################################

#### Logs path
pathManualUpd="$HOME/Nextcloud/Linux/log/manual_updater.txt" 
pathShutdown="$HOME/Nextcloud/Linux/log/shutdown_log.txt"
pathROOTKIT="$HOME/Nextcloud/Linux/log/rk_scan.txt"
pathCLAMSCAN="$HOME/Nextcloud/Linux/log/clamav_scan.txt"


#### Scripts path
LXscripts="$HOME/Nextcloud/Linux/scripts"
PYscripts="$HOME/Nextcloud/Python/scripts"


################################################################################################




#### Bash easy updater
alias bashupd='sudo cp $LXscripts/bashRC.sh $HOME/.bashrc && exec bash'
alias aliupd='sudo cp $LXscripts/bash_aliases.sh $HOME/.bash_aliases && source $HOME/.bash_aliases'


#### Quality of life
alias c='clear'
alias e='exit'
alias bashrc='sudo nano .bashrc'
alias aliases='sudo nano .bash_aliases'
alias kernels='dpkg --list | grep linux-image'


#### copy,zip and unzip with ETA and progress bar
alias cp2='rsync -ah --progress -r'
alias zip2='7z a -tzip'
alias unzip2='7z x'


#### Apps & Utilities
alias neo='neofetch'
alias py='python3'
alias sql='sudo mysql'
alias minecraft='gamemoderun java -jar $HOME/Nextcloud/Games/Minecraft/TLauncher/TLauncher.jar && exit'


#### limits CPU usage         CPUQuota=80% -- limits too much - Cpu Weight=5 -- lowers the priority
alias lowCpu="sudo systemd-run --scope -p CPUWeight=5"


#### manual updater
alias updater='$LXscripts/sys_updater.sh  >> "$pathManualUpd" 2>&1 && python3 $LXscripts/Startup_Routine/log_cleaner_MANUAL.py'


#### rootkit scan
alias rscan='$LXscripts/Scans/rk_hunter_scan.sh  >> "$pathROOTKIT" 2>&1'


#### Ps5 github triggers script
alias ps5Triggers="$HOME/trigger-control/build/trigger-control"


#### Night light with delay for when starting games
alias gameNightLight="sleep 30s && $LXscripts/Shortcuts/night_light_on.sh && exit"


##### auto cursor mover
alias mouseMover="$LXscripts/Other/mouse_mover.sh"
#### auto clicker
alias mouseClicker="$LXscripts/Other/auto_clicker.sh"



################################################################################################
#### Scripts shortcut


#### Password gen
alias pswd="python3 $PYscripts/passwd_gen.py"


#### weather check
alias weather="$LXscripts/DE_Addon/weatherFIXED.sh"

#### percentage calculator
alias percentage="python3 $PYscripts/perc_calc.py"


#### kden
alias kden="$HOME/Nextcloud/Kden/scripts/kden_custom_launch.sh"
alias kdenProject="$HOME/Nextcloud/Kden/scripts/kden_project_template.sh"
alias kdenBKP="$HOME/Nextcloud/Kden/scripts/kden_temp_bkp.sh"


#### editing utilities
alias sub="python3 $PYscripts/subtitle.py"
alias yt="$HOME/Nextcloud/Kden/scripts/yt-dlp_downloader.sh"


#### Styling
alias table="python3 $PYscripts/Style/tableStyle.py"
alias tableEcho="python3 $PYscripts/Style/tableStyle_ECHO.py"
alias title="python3 $PYscripts/Style/titleCase.py"


#### Converters
alias converterImg="python3 $PYscripts/FileModder/image_converter.py"
alias converterWav="python3 $PYscripts/FileModder/wav_converter.py"
alias converterMkv="python3 $PYscripts/FileModder/mkv_converter.py"


#### Github newPc_Install script update (from Nextcloud to Github repo)
alias newPcUPD="$LXscripts/Other/github_newPc.sh"



################################################################################################










################################################################################################
#### Shutdown aliases

alias end="read -r -p '' && shutdown"

alias shutdown="$LXscripts/Other/shutdown_routine.sh && sudo shutdown now"

alias reboot="read -r -p '' && $LXscripts/Other/shutdown_routine.sh && sudo reboot now"

################################################################################################












################################################################################################

                #################################
                ####                         ####
                ####        FUNCTIONS        ####
                ####                         ####
                #################################

vscan() {

    cd "$1"
    
    files=$(ls -A) #### -A removes the dots

    echo -e "🦠 Checking files:\n$files \n\nOutput file: $pathCLAMSCAN"
    
    $LXscripts/Scans/clamav_scan.sh >> "$pathCLAMSCAN" 2>&1
    
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


