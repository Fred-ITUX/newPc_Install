# ~/.bashrc: executed by bash(1) for non-login shells.

# Exit for non-interactive shells
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

# Update terminal size
shopt -s checkwinsize


# Alias definitions.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Enable bash completion if available
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi


            ###################  
            ###             ###  
            ###    STYLE    ###
            ###             ###
            ###################


# Get the OS name dynamically
osname=$(cat /etc/os-release | grep -o "Mint" | head -n 1 | tr '[:upper:]' '[:lower:]')

# Prompt components --- ANSI color codes
debian_chroot_part='${debian_chroot:+($debian_chroot)}'     # Show chroot if applicable
user_color='\[\033[01;31m\]'                                # Bold red
host_color='\[\033[01;31m\]'                                # Bold red
path_color='\[\033[01;34m\]'                                # Bold blue
reset_color='\[\033[00m\]'                                  # Reset to default color
prompt_char='\$'                                            # '$' for regular users, '#' for root

# host@user
#PS1="${debian_chroot_part}${user_color}\u@\h${reset_color}:${path_color}\w${reset_color}${prompt_char} "

# host@os (lower os name)
PS1="${debian_chroot_part}${user_color}\u@${osname}${reset_color}:${path_color}\w${reset_color}${prompt_char} "


# Enable color support for ls and other commands
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

