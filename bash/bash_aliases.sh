
#### SysInfo & path 
if [ -f ~/.bash_UT ]; then
    . ~/.bash_UT
fi


################################################################################################

                        #######################################
                        ####                               ####
                        ####        QUALITY OF LIFE        ####
                        ####                               ####
                        #######################################

#### Quality of life
alias c='clear'
alias e='exit'
alias kernels='dpkg --list | grep linux-image'
alias py='python3'

#### Making files executable
alias addx='sudo chmod +x'

#### Single-threaded copy with ETA
alias cp2='rsync -ah --progress -r'

################################################################################################







################################################################################################

                            ###############################
                            ####                       ####
                            ####        SCRIPTS        ####
                            ####                       ####
                            ###############################

#### Github
alias repo_newPcUPD="$LXscripts/Github/newPc.sh"
alias repo_phoneUPD="$LXscripts/Github/phoneScripts.sh"
alias repo_codeUPD="$LXscripts/Github/codium_update.sh"

#### System info
alias systemInfo="$LXscripts/Hardware_Info/system_info.sh"

#### Password gen
alias pswd="python3 $PYscripts/passwd_gen.py"


#### weather check
alias weather="$LXscripts/DE_Addon/weather.sh"


#### percentage calculator
alias percentage="python3 $PYscripts/perc_calc.py"

################################################################################################








################################################################################################

                            ###############################
                            ####                       ####
                            ####        EDITING        ####
                            ####                       ####
                            ###############################

#### kden
alias kden="$HOME/Nextcloud/Kden/scripts/kden_custom_launch.sh"
alias kdenProject="$HOME/Nextcloud/Kden/scripts/kden_project_template.sh"
alias kdenBKP="$HOME/Nextcloud/Kden/scripts/kden_temp_bkp.sh"
alias kdenUpd="$HOME/Nextcloud/Kden/scripts/kden_bkp_version_update.sh"


#### editing utilities
alias sub="python3 $PYscripts/subtitle.py"
alias yt="$HOME/Nextcloud/Kden/scripts/yt-dlp_downloader.sh"
alias editing="$LXscripts/Sessions/Session_editing.sh && kden"


#### Styling
alias table="python3 $PYscripts/Style/tableStyle.py"
alias tableEcho="python3 $PYscripts/Style/tableStyle_ECHO.py"


#### Converters
alias converterImg="python3 $PYscripts/FileModder/image_converter.py"
alias converterWav="python3 $PYscripts/FileModder/wav_converter.py"
alias converterMkv="python3 $PYscripts/FileModder/mkv_converter.py"
alias converterMetric="python3 $PYscripts/measure_unit_converter.py"

################################################################################################







################################################################################################

####                                    Games
#### minecraft
alias minecraft='gamemoderun java -jar $HOME/Nextcloud/Games/Minecraft/TLauncher/TLauncher.jar && exit'


#### Ps5 github triggers script
alias ps5Triggers="$HOME/trigger-control/build/trigger-control"


################################################################################################








################################################################################################

####                            Shutdown aliases

alias end="read -r -p '' && shutdown"

alias shutdown="$LXscripts/Other/shutdown_routine.sh && sudo shutdown now"

alias reboot="read -r -p '' && $LXscripts/Other/shutdown_routine.sh && sudo reboot now"

alias logout="gnome-session-quit"

################################################################################################

