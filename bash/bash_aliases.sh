
#### SysInfo & path 
if [ -f ~/.bash_UT ]; then
    . ~/.bash_UT
fi


################################################################################################

#### Quality of life
alias c='clear'
alias e='exit'

#### Single-threaded copy with ETA
alias cp2="rsync -ah --progress -r"

#### Compress with limited cores
alias zip2="7z a -mmt=2"

#### Making files executable
alias addx='sudo chmod +x'

################################################################################################




################################################################################################

alias pswd="python3 $PYscripts/passwd_gen.py"

alias percentage="python3 $PYscripts/perc_calc.py"

alias math="python3 $PYscripts/Games/math_calc.py"


#### kden
alias kden="$HOME/Nextcloud/Kden/scripts/kden_custom_launch.sh"
alias kdenProject="$HOME/Nextcloud/Kden/scripts/kden_project_template.sh"
alias kdenBKP="$HOME/Nextcloud/Kden/scripts/kden_temp_bkp.sh"
alias kdenUpd="$HOME/Nextcloud/Kden/scripts/kden_bkp_version_update.sh"

#### editing utilities
alias sub="python3 $PYscripts/subtitle.py"
alias yt="$HOME/Nextcloud/Kden/scripts/yt-dlp_downloader.sh"
alias editing="$LXscripts/Sessions/Session_editing.sh && kden"

#### Converters
alias convImg="python3 $PYscripts/FileModder/image_converter.py"
alias convWav="python3 $PYscripts/FileModder/wav_converter.py"
alias convMkv="python3 $PYscripts/FileModder/mkv_converter.py"
alias convMetric="python3 $PYscripts/measure_unit_converter.py"

################################################################################################


################################################################################################
####                            Shutdown aliases

alias end="read -r -p '' && shutdown"

alias shutdown="$LXscripts/Other/shutdown_routine.sh && sudo shutdown now"

alias reboot="read -r -p '' && $LXscripts/Other/shutdown_routine.sh && sudo reboot now"

alias logout="gnome-session-quit"

################################################################################################
