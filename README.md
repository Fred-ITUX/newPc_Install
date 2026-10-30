# 🖥️ newPc_Install

![Bash](https://img.shields.io/badge/bash-5-4EAA25?logo=gnubash&logoColor=white)
![Distro](https://img.shields.io/badge/distro-Linux%20Mint%2022.1-87CF3E?logo=linuxmint&logoColor=white)
![Desktop](https://img.shields.io/badge/desktop-GNOME-4A86CF?logo=gnome&logoColor=white)

**Date**: 2026_10_29

Turns a fresh Linux Mint install into the full desktop in two runs: packages first, then scripts, bash modules, GNOME settings and theme.

```text
newPc_Install/
├── 🚀 newPc/setup.sh            launch platform: the ONLY place where sudo is typed
├── 📦 newPc/newPc_Install.sh    run 1: packages, one at a time, failures recorded
├── ⚙️ newPc/newPc_Scripts.sh    run 2: user scripts, configs and services
├── 🎨 newPc/theme_updater.sh    theme, sourced by setup.sh
├── 🧩 newPc/dconf_manager.sh    GNOME keybindings and extensions, sourced by newPc_Scripts.sh
├── 🗂️ newPc/configs.sh          config file bodies, written atomically
├── 💾 newPc/dconf_dump/         dated dconf exports (keybindings, media keys, extensions)
├── 💾 newPc/DE_configs/         dated desktop-environment config snapshots
└── 🐚 bash/                     bash_common, bash_functions, bash_profile, bashrc
```

## 📥 Clone

```bash
cloneRepo(){
    local repo="https://github.com/Fred-ITUX/newPc_Install"

    echo -e "\n\t > Starting "$(date "+%A %F %H:%M:%S")""

    echo -e "\nChecking internet connectivity, the script will abort if the systems results offline."
    
    timeout 10 getent hosts archive.ubuntu.com >/dev/null || { echo "[ERROR] No network. Aborting."; return 1; }

    echo -e "\nSystem online, continuing\n"


    #### Install git if not already present
    command -v git >/dev/null || { sudo apt update && sudo apt install -y git; } || { echo "[ERROR] Git install failed"; return 1; }


    #### Clone repo script && script exec
    repoPath=""$HOME"/Github/newPc_Install"

    if [ -d "$repoPath" ]; then
        echo -e "[WARNING]: folder "$repoPath" already present. \n\nChoose what to do now? \n\t'yes'\t> use it as is \n\t'no'\t> stop execution  \n\t'pull'\t> update the local folder \n\t'rm'\t> purge the current folder and re-clone\n"
        read -p "Answer: " ans


        ans=$( printf '%s' "$ans" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]' )

        case "$ans" in 

            "yes"|"y") echo "Continuing with local version" ;;
            "no"|"n") echo "Aborting execution"; return 0 ;;
            
            "pull") echo "Updating local folder";
                        git -C "$repoPath" fetch || { echo "[ERROR] git failed to execute fetch, exiting"; return 1; } 
                        git -C "$repoPath" pull  || { echo "[ERROR] git failed to execute pull, exiting"; return 1; }
                        ;;
            
            "rm") echo "Removing local version and cloning";
                        rm -rf "$repoPath" || { echo "[ERROR] failed to remove the folder "$repoPath""; return 1; }
                        git clone "$repo" --depth 1 "$repoPath" || { echo "[ERROR] failed to clone the repo" ; return 1; }
                        ;;

            *) echo "Not a valid option selected, exiting"; return 1 ;;
        esac
    

    else
        mkdir -p ""$HOME"/Github"
        echo "Cloning the repo:  "$repoPath"/"$repo""
        git clone --depth 1 "$repo" "$repoPath"  || { echo "[ERROR] failed to clone the repo" ; return 1; }
        
        echo "Adding exec to all .sh scripts in the repo folder"
        find "$repoPath" -type f -name '*.sh' -exec chmod +x {} +  || { echo "[ERROR] failed to grant exec to .sh scripts" ; return 1; }

    fi


    echo -e "\n > Function terminated correctly\n"
}
```

```bash
cloneRepo || { echo "[ERROR] function terminated with an error"; }
```

## 📦 Run 1: install

```bash 
if [ -f "$HOME/Github/newPc_Install/newPc/setup.sh" ] && [ -f "$HOME/Github/newPc_Install/newPc/newPc_Install.sh" ] ; then 
    sudo "$HOME/Github/newPc_Install/newPc/setup.sh" "newPc_Install.sh"; 
else 
    echo -e "Script(s) not found: \n"$HOME/Github/newPc_Install/newPc/setup.sh" \n"$HOME/Github/newPc_Install/newPc/newPc_Install.sh""
fi 
```

## ⚙️ Run 2: setup

Launch it after run 1 has finished.

```bash
if [ -f "$HOME/Github/newPc_Install/newPc/setup.sh" ] && [ -f "$HOME/Github/newPc_Install/newPc/newPc_Scripts.sh" ]  ; then
    sudo "$HOME/Github/newPc_Install/newPc/setup.sh" "newPc_Scripts.sh"; 
else 
    echo -e "Script(s) not found: \n$HOME/Github/newPc_Install/newPc/setup.sh \n"$HOME/Github/newPc_Install/newPc/newPc_Scripts.sh"\n"
fi 
```

## 🔐 Privilege model

- **One sudo.** `sudo ./setup.sh <script.sh>` is the only elevated call. `setup.sh` and the child script run as root, so there are no further password prompts.
- **Root stays out of the user's home.** Root keeps its own `HOME` and environment; anything that touches the user's home or GNOME session goes through `asUser`.
- **No manual runs.** `newPc_Install.sh`, `newPc_Scripts.sh`, `theme_updater.sh` and `dconf_manager.sh` expect the environment and helper functions that `setup.sh` exports.
