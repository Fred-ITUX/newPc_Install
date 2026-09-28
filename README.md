# Setup

Clone the repo

```bash
cloneRepo(){
    local repo="https://github.com/Fred-ITUX/newPc_Install"

    echo -e "\n\t > Starting "$(date "+%A %F %H:%M:%S")""

    echo -e "\nChecking internet connectivity, the script will abort if the systems results offline."
    
    timeout 10 getent hosts archive.ubuntu.com >/dev/null || { echo "[ERROR] No network. Aborting."; return 1; }

    echo -e "\nSystem online, continuing\n"


    #### Install git if not already present
    apt update || { echo "[ERROR] Apt update failed, not continuing with stale package index"; return 1; }
    apt install git -y || { echo "[ERROR] Git install failed. No point in keeping execution, exiting"; return 1; }


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

### Execute

```bash
cloneRepo || { echo "[ERROR] function terminated with an error"; }
```


<br>


# One launch setup

## Install 

```bash 
if [ -f "$HOME/Github/newPc_Install/newPc/setup.sh" ] && [ -f "$HOME/Github/newPc_Install/newPc/newPc_Install.sh" ] ; then 
    sudo "$HOME/Github/newPc_Install/newPc/setup.sh" "$HOME/Github/newPc_Install/newPc/newPc_Install.sh"; 
else 
    echo -e "Script(s) not found: \n"$HOME/Github/newPc_Install/newPc/setup.sh" \n"$HOME/Github/newPc_Install/newPc/newPc_Install.sh""
fi 
```

## Setup 

> After the initial setup terminated

```bash
if [ -f "$HOME/Github/newPc_Install/newPc/setup.sh" ] && [ -f "$HOME/Github/newPc_Install/newPc/newPc_Scripts.sh" ]  ; then
    sudo "$HOME/Github/newPc_Install/newPc/setup.sh" "newPc_Scripts.sh"; 
else 
    echo -e "Script(s) not found: \n$HOME/Github/newPc_Install/newPc/setup.sh \n"$HOME/Github/newPc_Install/newPc/newPc_Scripts.sh"\n"
fi 
```

