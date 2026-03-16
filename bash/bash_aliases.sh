#!/bin/bash

if [ -f ~/.bash_UT ]; then . ~/.bash_UT; fi               

#### Quality of life
alias c='clear'
alias e='exit'
alias addx='sudo chmod +x'


alias cp2="rsync -ah --progress -r"     #### Single-threaded copy with ETA
alias zip2="7z a -mmt=3"                #### Compress with limited cores



alias pswd="python3 $PYscripts/passwd_gen.py"

alias percentage="python3 $PYscripts/perc_calc.py"

alias math="python3 $PYscripts/Games/math_calc.py"

alias test-py="python3 $HOME/Nextcloud/Linux/scripts/Other/test.py"
alias test-sh="$HOME/Nextcloud/Linux/scripts/Other/test.sh"



#### kden
alias kden="$HOME/Nextcloud/Kden/scripts/kden_custom_launch.sh"
alias kdenProject="$HOME/Nextcloud/Kden/scripts/kden_project_template.sh"
alias kdenBKP="$HOME/Nextcloud/Kden/scripts/kden_temp_bkp.sh"
alias kdenUpd="$HOME/Nextcloud/Kden/scripts/kden_bkp_version_update.sh"

#### editing utilities
alias sub="python3 $PYscripts/subtitle.py"
alias yt="$HOME/Nextcloud/Kden/scripts/yt-dlp_downloader.sh"
alias editing="$LXscripts/Startup_Routine/Sessions.sh editing && kden"

#### Converters
alias convImg="python3 $PYscripts/FileModder/image_converter.py"
alias convWav="python3 $PYscripts/FileModder/wav_converter.py"
alias convMkv="python3 $PYscripts/FileModder/mkv_converter.py"
alias convMetric="python3 $PYscripts/measure_unit_converter.py"