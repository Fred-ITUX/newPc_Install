#!/bin/sh
#### bash_profile.sh -> linked as BOTH ~/.bash_profile and ~/.profile
####   ~/.bash_profile : read by bash login shells (tty, ssh, GNOME's "bash -l" session wrapper)
####   ~/.profile      : read by sh/dash login shells and display managers (e.g. LightDM's Xsession)
#### Rules, because a broken profile can lock you out of the graphical login:
####   - POSIX sh only: no [[ ]], no arrays, no local, no bashisms
####   - never exit, never print to stdout, never set -e / set -u
####   - no dependencies (no .bash_common, no Nextcloud paths)

#### Prepend a directory to PATH only if it exists and is not already in it
pathPrepend(){
    [ -d "$1" ] || return 0
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