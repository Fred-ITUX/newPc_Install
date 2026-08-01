# ~/.bashrc: executed by bash(1) for non-login shells.

# Exit for non-interactive shells
case $- in
    *i*) ;;
      *) return;;
esac


#### History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=1000  

if [ -f "$HOME/.bash_functions" ]; then source "$HOME/.bash_functions"; else echo -e "[CRITICAL ERROR] Bash module not found: $HOME/.bash_functions"; fi
if [ -f "$HOME/.bash_common" ]; then source "$HOME/.bash_common"; else echo -e "[CRITICAL ERROR] Bash module not found: $HOME/.bash_common" ; fi

#### Enable bash completion if available
if [ -f /usr/share/bash-completion/bash_completion ]; then source /usr/share/bash-completion/bash_completion; fi


# Prompt components --- ANSI color codes
debian_chroot_part='${debian_chroot:+($debian_chroot)}'         #### Show chroot if applicable
user_color='\[\033[01;31m\]'                                    #### Bold red
host_color='\[\033[01;31m\]'                                    #### Bold red
# path_color='\[\033[01;34m\]'                                    #### Bold blue
path_color='\[\033[38;5;81m\]'                                  #### Cyan
# path_color='\[\033[38;5;71m\]'                                  #### Green
reset_color='\[\033[00m\]'                                      #### Reset to default color
prompt_char='\$'                                                #### '$' for regular users, '#' for root


#### host@user
#PS1="${debian_chroot_part}${user_color}\u@\h${reset_color}:${path_color}\w${reset_color}${prompt_char} "

#### host@os (lower os name)
# PS1="${debian_chroot_part}${user_color}\u@${osname}${reset_color}:${path_color}\w${reset_color}${prompt_char} "
# PS1='\[\033[38;5;208m\]\u\[\033[0m\]@\[\033[38;5;39m\]${osname}\[\033[0m\]:\[\033[38;5;118m\]\W\[\033[0m\]  '

PS1="${path_color}\w${reset_color} \[\033[38;5;240m\]>\[\033[0m\] "



##################################################
#### Aliases

#### Enable color support for ls and other commands
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'


#### Quality of life
alias c='clear'
alias e='exit'
alias addx='sudo chmod +x'

alias cp2="rsync -ah --progress -r"     #### Single-threaded copy with ETA
alias zip2="7z a -mmt=6"                #### Compress with limited cores


alias pswd="py $PYscripts/passwd_gen.py"

alias percentage="py $PYscripts/perc_calc.py"

alias math="py $PYscripts/Games/math_calc.py"

alias test-py="py $HOME/Nextcloud/Linux/scripts/Other/test.py"
alias test-sh="$HOME/Nextcloud/Linux/scripts/Other/test.sh"



#### kden
alias kden="$HOME/Nextcloud/Kden/scripts/kden_custom_launch.sh"
alias kdenProject="$HOME/Nextcloud/Kden/scripts/kden_project_template.sh"
alias kdenBKP="$HOME/Nextcloud/Kden/scripts/kden_temp_bkp.sh"
alias kdenUpd="$HOME/Nextcloud/Kden/scripts/kden_bkp_version_update.sh"

#### editing utilities
alias sub="py $PYscripts/subtitle.py"
alias yt="$HOME/Nextcloud/Kden/scripts/yt-dlp_downloader.sh"
alias editing="$LXscripts/Startup_Routine/Sessions.sh editing && kden"

#### Converters
alias convImg="py $PYscripts/FileModder/image_converter.py"
alias convWav="py $PYscripts/FileModder/wav_converter.py"
alias convMkv="py $PYscripts/FileModder/mkv_converter.py"
alias convMetric="py $PYscripts/measure_unit_converter.py"