#!/bin/sh
#### bash_profile.sh -> deployed by bashUpd as ~/.bash_profile ONLY
####   ~/.profile is deliberately NOT created: when both exist bash reads ~/.bash_profile and skips ~/.profile
#### Who reads it: every bash LOGIN shell
####   - tty and ssh logins
####   - the graphical login: GDM starts /usr/bin/gnome-session, which re-runs itself through "bash -l"
#### Rules, because GNOME's session starts through this file and a broken one can lock you out of the graphical login:
####   - POSIX sh only: no [[ ]], no arrays, no local, no bashisms
####   - never exit, never print to stdout, never set -e / set -u
####   - no dependencies (no .bash_common, no Nextcloud paths)

#### Prepend a directory to PATH only if it exists and is not already in it
pathPrepend(){
    if [ ! -d "$1" ]; then return 0; fi

    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

pathPrepend "$HOME/bin"
pathPrepend "$HOME/.local/bin"
export PATH
unset -f pathPrepend

#### Load .bashrc only for INTERACTIVE bash; non-interactive login shells (GNOME session) skip it
if [ -n "$BASH_VERSION" ]; then
    case $- in
        *i*) if [ -r "$HOME/.bashrc" ]; then . "$HOME/.bashrc"; fi ;;
    esac
fi