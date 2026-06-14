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

if [ -f "$HOME/.bash_aliases"   ]; then . "$HOME/.bash_aliases"  ; else echo -e "[CRITICAL ERROR] Bash module not found: $HOME/.bash_aliases"  ; fi
if [ -f "$HOME/.bash_functions" ]; then . "$HOME/.bash_functions"; else echo -e "[CRITICAL ERROR] Bash module not found: $HOME/.bash_functions"; fi
if [ -f "$HOME/.bash_UT"        ]; then . "$HOME/.bash_UT"       ; else echo -e "[CRITICAL ERROR] Bash module not found: $HOME/.bash_UT"       ; fi

#### Enable bash completion if available
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi


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
PS1="${path_color}\w${reset_color} \[\033[38;5;240m\]>\[\033[0m\] "
# PS1='\[\033[38;5;208m\]\u\[\033[0m\]@\[\033[38;5;39m\]${osname}\[\033[0m\]:\[\033[38;5;118m\]\W\[\033[0m\]  '


#### Enable color support for ls and other commands
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'