
#### SysInfo & path 
if [ -f ~/.bash_UT ]; then
    . ~/.bash_UT
fi



################################################################################################

                            ###############################
                            ####                       ####
                            ####        ALIASES        ####
                            ####                       ####
                            ###############################

#### Bash easy updater
alias bashupd='sudo cp $LXscripts/bashRC.sh $HOME/.bashrc && source ~/.bashrc'
alias aliupd='sudo cp $LXscripts/bash_aliases.sh $HOME/.bash_aliases && source $HOME/.bash_aliases'
alias utupd='sudo cp $LXscripts/sysInfoUT/sysUT.sh $HOME/.sysUT.sh && source $HOME/.sysUT.sh'

alias bashrc='sudo nano .bashrc'
alias aliases='sudo nano .bash_aliases'
alias functions='sudo nano .bash_functions'


#### Making files executable
alias addx='sudo chmod +x'
alias addExec="echo -e 'Adding x to all .sh files in $LXscripts' && sudo find $HOME/Nextcloud/Linux/scripts -type f -name "*.sh" -exec chmod +x {} +"


#### Quality of life
alias c='clear'
alias e='exit'
alias kernels='dpkg --list | grep linux-image'
alias neo='neofetch'
alias py='python3'


#### Copy,zip and unzip with ETA and progress bar
alias cp2='rsync -ah --progress -r'
alias zip2='7z a -tzip'
alias unzip2='7z x'


#### minecraft
alias minecraft='gamemoderun java -jar $HOME/Nextcloud/Games/Minecraft/TLauncher/TLauncher.jar && exit'


#### limits CPU usage         CPUQuota=80% -- limits too much - Cpu Weight=5 -- lowers the priority
alias lowCpu="sudo systemd-run --scope -p CPUWeight=5"


#### Manual updater
alias updater="$LXscripts/sys_updater.sh  >> "$pathManualUpd" 2>&1 && python3 $LXscripts/Startup_Routine/log_cleaner_MANUAL.py"


#### Rootkit scan
alias rscan="$LXscripts/Scans/rk_hunter_scan.sh  >> "$pathROOTKIT" 2>&1"


#### Ps5 github triggers script
alias ps5Triggers="$HOME/trigger-control/build/trigger-control"


#### Night light with delay for when starting games
alias gameNightLight="sleep 30s && $LXscripts/Shortcuts/night_light_on.sh && exit"


##### auto cursor mover
alias mouseMover="$LXscripts/Other/mouse_mover.sh"
#### auto clicker
alias mouseClicker="$LXscripts/Other/auto_clicker.sh"


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
alias kdenUpd="$HOME/Nextcloud/Kden/scripts/kden_bkp_version_update.sh"


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
alias converterMetric="python3 $PYscripts/imp_to_metric_conv.py"






#### Github newPc_Install script update (from Nextcloud to Github repo)
alias newPcUPD="$LXscripts/Other/github_newPc.sh"


#### Testing script
alias test="$LXscripts/Other/test.sh"





#### Shutdown aliases
alias end="read -r -p '' && shutdown"

alias shutdown="$LXscripts/Other/shutdown_routine.sh && sudo shutdown now"

alias reboot="read -r -p '' && $LXscripts/Other/shutdown_routine.sh && sudo reboot now"

################################################################################################

