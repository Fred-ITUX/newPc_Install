#!/bin/bash

if [ -f "$(dirname "$0")/configs.sh" ]; then source "$(dirname "$0")/configs.sh"; else echo "[CRITICAL ERROR] Could not load "$(dirname "$0")/configs" module"; exit 1 ; fi


enviromentCheck

echo -e "\n\t > Starting "$(date "+%Y-%m-%d %H:%M:%S")""


repo="https://github.com/Fred-ITUX/newPc_Install"

runningScript="${1:-}"

if [ -z "$runningScript" ]; then
    echo "No scripts to execute given, exiting"; exit 1
fi

user=${SUDO_USER:-$(whoami)}


[ "${SUDO_USER:-}" ] || { echo "[ERROR] Run via sudo as your normal user, not as root" >&2; exit 1; }

user="$SUDO_USER"

[[ "$user" =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo "[ERROR] Unsafe username: $user" >&2; exit 1; }

id -- "$user" >/dev/null 2>&1 || { echo "[ERROR] No such user: $user" >&2; exit 1; }


#### Resolve the real user's home and run the installer as that user, escalating per-command
userHome=$(getent passwd "$user" | cut -d: -f6)


[ -d "$userHome" ] || { echo "[ERROR] No home dir for $user" >&2; exit 1; }




echo -e "\nChecking internet connectivity, the script will abort if the systems results offline."

timeout 10 getent hosts archive.ubuntu.com >/dev/null || { echo "[ERROR] No network. Aborting."; exit 1; }

echo -e "\nSystem online, continuing\n"


#### Install git if not already present
apt update || { echo "[ERROR] Apt update failed, not continuing with stale package index"; exit 1; }
apt install git -y || { echo "[ERROR] Git install failed. No point in keeping execution, exiting"; exit 1; }


#### Clone repo script && script exec
repoPath=""$userHome"/Github/newPc_Install"

echo -e "\n\t > Script to execute: "$runningScript""


if [ -d "$repoPath" ]; then
    echo -e "[WARNING]: folder "$repoPath" already present. \n\nChoose what to do now? \n\t'yes'\t> use it as is \n\t'no'\t> stop execution  \n\t'pull'\t> update the local folder \n\t'rm'\t> purge the current folder and re-clone\n"
    read -p "Answer: " ans


    ans=$( printf '%s' "$ans" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]' )

    case "$ans" in 

        "yes"|"y") echo "Continuing with local version" ;;
        "no"|"n") echo "Aborting execution"; exit 0 ;;
        
        "pull") echo "Updating local folder";
                    git -C "$repoPath" fetch || { echo "[ERROR] git failed to execute fetch, exiting"; exit 1; } 
                    git -C "$repoPath" pull  || { echo "[ERROR] git failed to execute pull, exiting"; exit 1; }
                    ;;
        
        "rm") echo "Removing local version and cloning";
                    rm -rf "$repoPath" || { echo "[ERROR] failed to remove the folder "$repoPath""; exit 1; }
                    sudo -u "$user" git clone "$repo" --depth 1 "$repoPath" || { echo "[ERROR] failed to clone the repo" ; exit 1; }
                    ;;

        *) echo "Not a valid option selected, exiting"; exit 1 ;;

    esac


else
    echo "Cloning the repo:  "$repoPath"/"$repo""
    sudo -u "$user" git clone --depth 1 "$repo" "$repoPath"  || { echo "[ERROR] failed to clone the repo" ; exit 1; }
    
    echo "Adding exec to all .sh scripts in the repo folder"
    sudo -u "$user" find "$repoPath" -type f -name '*.sh' -exec chmod +x {} +  || { echo "[ERROR] failed to grant exec to .sh scripts" ; exit 1; }

fi




echo "Checking for script to run: "$runningScript""

if [ -f ""$repoPath"/newPc/"$runningScript"" ]; then
    echo -e "\n\nScript found, executing now...\n"
    sudo -u "$user" ""$repoPath"/newPc/"$runningScript""   || { echo "[ERROR] failed to execute ""$repoPath"/newPc/"$runningScript""" ; exit 1; }

else
    echo "[ERROR] ""$repoPath"/newPc/"$runningScript"""
    exit 1
fi

echo -e "\n > Function terminated correctly\n"
