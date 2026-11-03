#!/bin/bash
#### bash_completion.sh -> deployed by bashUpd as ~/.bash_completion
#### Loaded automatically by /usr/share/bash-completion/bash_completion (sourced in bashrc), after the system completions

##################################################

#### Word lists, key = "command,position"   e.g.   _posWords[gitman,2]="fetch pull commit push"
declare -gA _posWords

_posComplete(){
    #### Called by bash on Tab: $1 = command name, COMP_CWORD = position of the word under the cursor
    local cmd="$1" cur="${COMP_WORDS[COMP_CWORD]}"
    local words="${_posWords[$cmd,$COMP_CWORD]:-}"

    #### No list for this position = no suggestions
    if [ -n "$words" ]; then
        COMPREPLY=( $(compgen -W "$words" -- "$cur") )
    fi
}

posComplete(){
    #### Usage: posComplete <command> "<words for arg 1>" "<words for arg 2>" ...
    #### An empty "" skips a position (no suggestions there)
    local cmd="$1" list i=1
    shift

    for list in "$@"; do
        _posWords[$cmd,$i]="$list"
        i=$((i+1))
    done

    complete -F _posComplete "$cmd"
}

##################################################

#### Lists MUST match the case statements of each script

#### Linux/scripts/Github/git_manager.sh
posComplete gitman \
    "codiumSync All_Scripts editingUT newPc_Install Games HelperScripts all" \
    "fetchPull commitPush"
