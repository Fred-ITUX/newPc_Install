
#### distro name for logging
osname=$(grep -oP '(?<=^NAME=)"?[^"]+' /etc/os-release | sed 's/^"//' | sed 's/linux //i' | tr '[:upper:]' '[:lower:]')

#### date log for debugging
dateStr=$(date +'%Y-%m-%d_%H-%M-%S')


######################################################################

#### Logs path
pathManualUpd="$HOME/Nextcloud/Linux/log/manual_updater.txt" 
pathShutdown="$HOME/Nextcloud/Linux/log/shutdown_log.txt"
pathROOTKIT="$HOME/Nextcloud/Linux/log/rk_scan.txt"
pathCLAMSCAN="$HOME/Nextcloud/Linux/log/clamav_scan.txt"


#### Scripts path
LXscripts="$HOME/Nextcloud/Linux/scripts"
PYscripts="$HOME/Nextcloud/Python/scripts"


######################################################################



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
alias alarm="vlc $HOME/Nextcloud/Linux/Stuff/alarm.mp3 --gain=5"
alias minecraft='gamemoderun java -jar $HOME/Nextcloud/Games/Minecraft/TLauncher/TLauncher.jar && exit'


#### limits CPU usage         CPUQuota=80% -- limits too much - Cpu Weight=5 -- lowers the priority
alias lowCpu="sudo systemd-run --scope -p CPUWeight=5"


#### manual updater
alias updater='$LXscripts/sys_updater.sh  >> "$pathManualUpd" 2>&1'


#### rootkit scan
alias rscan='$LXscripts/Scans/rk_hunter_scan.sh  >> "$pathROOTKIT" 2>&1'


#### Ps5 github triggers script
alias ps5Triggers="$HOME/trigger-control/build/trigger-control"


#### Night light with delay for when starting games
alias gameNightLight="sleep 30s && $LXscripts/Shortcuts/night_light_on.sh && exit"


######################################################################
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


######################################################################










######################################################################
#### Shutdown aliases

alias end="read -r -p '' key && shutdown"
alias shutdown=" 
{
    echo \"___________________________________________\"
    uptime_result=\$(uptime | cut -d ',' -f 1 | awk '{print \$3, \$4}')
    echo \"Uptime: \$uptime_result\"
    date
} >> \"\$pathShutdown\" 2>&1 && sudo shutdown now
"


alias reboot="
read -r -p '' key
{
    echo \"___________________________________________\"
    uptime_result=\$(uptime | cut -d ',' -f 1 | awk '{print \$3, \$4}')
    echo \"Uptime: \$uptime_result\"
    date
} >> \"\$pathShutdown\" 2>&1 && sudo reboot now
"

######################################################################






######################################################################

#### Git newPc_Install script update (from Nextcloud to Github repo)

alias newPcUPD='
{
    cp $LXscripts/New_Pc/newPc_Install.sh $HOME/newPc_Install/
    cp $LXscripts/bash_aliases.sh $HOME/newPc_Install/
    cp $LXscripts/bashRC.sh $HOME/newPc_Install/
    cp $LXscripts/sys_updater.sh $HOME/newPc_Install/
    cp $LXscripts/New_Pc/setup.sh $HOME/newPc_Install/
    cp $LXscripts/New_Pc/README.md $HOME/newPc_Install/

    cd $HOME/newPc_Install/
    git add .
    git commit -m "updated script"
    git pull origin main
    git push
    cd
}
'






######################################################################

                #################################
                ####                         ####
                ####        FUNCTIONS        ####
                ####                         ####
                #################################

vscan() {

    cd "$1"
    echo "Checking files:"
    ls -al

    echo -e "\n\nOutput file: $pathCLAMSCAN"
    $LXscripts/Scans/clamav_scan.sh >> "$pathCLAMSCAN" 2>&1
    
}

alias vscanpwd='vscan "$(pwd)"'



######################################################################

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
######################################################################


