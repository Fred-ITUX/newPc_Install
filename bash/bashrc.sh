# ~/.bashrc: executed by bash(1) for non-login shells.

# Exit for non-interactive shells
case $- in
    *i*) ;;
      *) return ;; #### NEVER change it to an `exit`, bashrc gets sourced at GUI startup
esac


#### History settings
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=10000
HISTTIMEFORMAT='%F %T  '
shopt -s histappend
shopt -s checkwinsize

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

export EDITOR="${EDITOR:-nano}"
export VISUAL="$EDITOR"


brokenEnv=false
helpersPresence=false

if [ -s "$HOME/.bash_common" ]; then source "$HOME/.bash_common"; else echo -e "[CRITICAL ERROR] Bash module not found: $HOME/.bash_common"; brokenEnv=true; fi
if [ -s "$HOME/.bash_functions" ]; then source "$HOME/.bash_functions"; else echo -e "[CRITICAL ERROR] Bash module not found: $HOME/.bash_functions"; brokenEnv=true; fi

#### Enable bash completion if available
if [ -f /usr/share/bash-completion/bash_completion ]; then source /usr/share/bash-completion/bash_completion; fi

#### Disable the aliases if the repo is not cloned 
if [ -d "$HOME/Github/HelperScripts" ]; then helpersPresence=true; fi


#### Prompt components --- ANSI color codes
path_color='\[\033[38;5;81m\]'
reset_color='\[\033[00m\]'
grey_color='\[\033[38;5;240m\]'
parse_git_branch(){ git branch --show-current 2>/dev/null | sed 's/.*/ (&)/'; }

# PS1="${path_color}\w${reset_color} ${grey_color}>${reset_color} "
PS1="${path_color}\w\[\033[38;5;178m\]\$(parse_git_branch)${grey_color} >${reset_color} "

if $brokenEnv; then PS1="\[\033[41m\][DEGRADED]\[\033[0m\] $PS1 "; fi


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
alias addx='chmod +x'

# alias cp2="rsync -ah --progress"     	#### Single-threaded copy with ETA
# alias zip2="7z a -mmt=8"                #### Compress with limited cores



if $brokenEnv; then
    echo -e "[CRITICAL ERROR] Enviroment degraded, path-dependent aliases disabled"

else

	alias pswd="py $PYscripts/passwd_gen.py"

	alias test-sh="$HOME/Nextcloud/Linux/scripts/TestSuite/test.sh"
	alias test-py="py $HOME/Nextcloud/Linux/scripts/TestSuite/test.py"

    alias minecraftRecipe="py $HOME/Nextcloud/Games/Minecraft/Recipes/recipe_maker/recipe_maker.py"

	# alias kden="$HOME/Nextcloud/Kden/scripts/kden_custom_launch.sh"
	alias kdenProject="$HOME/Nextcloud/Kden/scripts/kden_project_template.sh"
	alias kdenBkp="$HOME/Nextcloud/Kden/scripts/kden_temp_bkp.sh"
	alias kdenUpd="$HOME/Nextcloud/Kden/scripts/kden_bkp_version_update.sh"

    if $helpersPresence; then
        
        alias calc="$HOME/Github/HelperScripts/Python/Py_calculator_assistant/calculator_assistant.sh"
        alias txt="$HOME/Github/HelperScripts/Python/Py_text_formatter/text_formatter.sh"
        alias conv="$HOME/Github/HelperScripts/Python/Py_converter_files/converter_files.sh"

    else 
        echo "[WARNING] HelperScripts not found; aliases disabled"
    fi

fi