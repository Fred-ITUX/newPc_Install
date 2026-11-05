#!/bin/bash

brokenEnv=false

if [ -s "$HOME/.bash_common" ]; then source "$HOME/.bash_common"; else echo "[CRITICAL ERROR] Bash module not found: $HOME/.bash_common"; brokenEnv=true; fi

if $brokenEnv; then
    echo "[CRITICAL ERROR] Enviroment degraded, functions disabled"
    return 1
fi

userCheck

##################################################

bashUpd(){
    if [ -z "$LXscripts" ]; then local LXscripts="$HOME/Nextcloud/Linux/scripts"; fi

    local modules=(
        "bash_common"
        "bash_completion"
        "bash_functions"
        "bash_profile"
        "bashrc"
    )

    for module in "${modules[@]}"; do

        #### echo -e "\nwould copy "$LXscripts"/bash/""$module".sh" "$HOME"/."$module" "
        #### echo -e "would source "$HOME"/."$module"\n"

        cp "$LXscripts"/bash/""$module".sh" "$HOME"/."$module" || { echo "[ERROR] Failed to copy $module"; return 1 ; }
        source "$HOME"/."$module" || { echo "[ERROR] Sourcing failed for $module" ; return 1; }

    done
    
    exec bash
}

##################################################

shutdown_routine(){
    "$LXscripts/Shortcuts/night_light.sh" off

    echo "$(date +"%Y-%m-%d");$(uptimeHMS)" >> "$PYscripts/UptimePlot/"$(date +%Y)"_uptime.csv"
    
    if [ -f "$HOME/.bash_history" ]; then rm "$HOME/.bash_history"; fi
    killp "15" "brave" &
    killp "15" "chrome" &
    sleep 1s

    if [ "$pc" == "$hostMain" ]; then
        local kdenBkpDir="$HOME/Videos/Edit/Kden/kdenFiles/data/kdenlive/.backup" #### rm kden bkp to avoid stacking

        #### Turn off the monitors
        #### 01 -- On   |   05 -- Off   |   04 -- Standby / Sleep
        #### ddcutil --sn "3CM3131PVV"      setvcp d6 04
        ddcutil --sn "H4ZN504596"      setvcp d6 04

        if [ -d "$kdenBkpDir" ]; then rm -rf "$kdenBkpDir"; fi; fi
}

shutdownBlockers(){
    #### Prints every app holding a "block" inhibitor on shutdown/reboot; empty = free to go
    #### --what= does not filter the list (tested), so the shutdown token is matched in the WHAT column
    systemd-inhibit --list --no-legend --mode=block | awk '{for(i=1;i<=NF;i++) if ($i ~ /(^|:)shutdown(:|$)/) {gsub(/ +/, " "); print; next}}'
}

#### Replace system commands by design; the pc must go through a routine before shutting down

shutdown(){
    #### Used for automatically shutdown when no user is around
    local blockers
    blockers="$(shutdownBlockers)"

    #### Refuse BEFORE the routine, so browsers / monitor / history stay untouched
    if [ -n "$blockers" ]; then
        sysLogger e "Shutdown refused, blocked by: $blockers"
        raiseAlarm "Shutdown refused, blocked by: $blockers"
        return 1
    fi

    shutdown_routine

    if ! systemctl poweroff; then
        raiseAlarm "Shutdown failed after the routine, the pc is still on"
        return 1
    fi
}


reboot(){
    local blockers
    read -r -p 'To reboot press enter'
    blockers="$(shutdownBlockers)"

    #### Refuse BEFORE the routine, so browsers / monitor / history stay untouched
    if [ -n "$blockers" ]; then
        sysLogger e "Reboot refused, blocked by: $blockers"
        raiseAlarm "Reboot refused, blocked by: $blockers"
        return 1
    fi

    shutdown_routine

    if ! systemctl reboot; then
        raiseAlarm "Reboot failed after the routine, the pc is still on"
        return 1
    fi
}


end(){
    read -r -p 'To shut down press enter'
    shutdown
}

##################################################

sysUPD(){
    local outputLog="${1:-}"
    local updPath="${XDG_RUNTIME_DIR}/UPD_logs"
    local completeLog="$updPath/UPD_completeLog.log"
    local fullLog step stepLog
    local reported=0

    if [ -z "$outputLog" ]; then sysLogger e "sysUPD requires an output log path"; return 1; fi

    mkdir -p "$updPath" || { sysLogger e "Cannot create $updPath"; return 1; }

    
    fullLog="$(get_pathStartupUpdaterFull)" #### Retain full log


    #### Order of execution, and the title each block gets in the logs
    local steps=( 
            fixPkg 
            update 
            upgrade 
            flatpak 
            cleanup 
    )

    local -A title=( [fixPkg]="Fix broken pkg" [update]="Update" [upgrade]="Upgrade" [flatpak]="Flatpak update" [cleanup]="Autoremove" )


    #### A block is left out of the complete log when it shows nothing happened:
    #### quietIf  -> the output MATCHES the "nothing done" text
    #### reportIf -> reverse logic, the output does NOT match any warning / error
    local -A quietIf=(
        [fixPkg]="0 upgraded, 0 newly installed, 0 to remove"
        [upgrade]="0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded"
        [flatpak]="Nothing to do"
        [cleanup]="0 upgraded, 0 newly installed, 0 to remove"
    )
    local -A reportIf=( [update]='^\s*(W|E|Err):|WARN|ERROR|REMOVED' )


    UPD_run(){
        case "$1" in
            fixPkg)  sudo -n /usr/bin/dpkg --configure -a; sudo -n /usr/bin/apt-get --fix-broken install -y ;;
            update)  sudo -n /usr/bin/apt-get --fix-missing -q update ;;
            upgrade) sudo -n /usr/bin/apt-get dist-upgrade -y ;;
            flatpak) flatpak update -y ;;
            cleanup) sudo -n /usr/bin/apt-get autoremove -y; sudo -n /usr/bin/apt-get clean ;;
        esac
    }

    getSysInfoStart > "$completeLog"
    getSysInfoStart >> "$fullLog"

    for step in "${steps[@]}"; do
        stepLog="$updPath/UPD_$step.log"

        #### stderr too: apt writes its E: / W: lines there. Indented to allow fold per-day
        { echo -e "\n• ${title[$step]}: \n"; UPD_run "$step"; } 2>&1 | sed 's/^/\t/' > "$stepLog"

        cat "$stepLog" >> "$fullLog"

        if [ -n "${quietIf[$step]:-}" ]; then
            if grep -qiE "${quietIf[$step]}" "$stepLog"; then continue; fi
        else
            if ! grep -qiE "${reportIf[$step]}" "$stepLog"; then continue; fi
        fi

        cat "$stepLog" >> "$completeLog"
        reported=$((reported+1))
    done

    if [ "$reported" -eq 0 ]; then echo -e "\n\t> Nothing to report" >> "$completeLog"; fi

    getSysInfoEnd >> "$fullLog"
    getSysInfoEnd >> "$completeLog"

    py "$LXscripts/Startup_Routine/log_cleaner.py" "$completeLog" || { sysLogger e "$LXscripts/Startup_Routine/log_cleaner.py failed, appending raw log"; }

    #### Collapses multiple newlines into 2 to keep spacing
    fileNewLineStrip "$fullLog"
    fileNewLineStrip "$completeLog"

    cat "$completeLog" >> "$outputLog"
}


updater(){
    sysUPD "$pathManualUpd" 
    gedit "$pathManualUpd" &
}

##################################################

systemInfo(){
    local infoArray

    get_wm(){
    if [ "$XDG_CURRENT_DESKTOP" == "GNOME" ]; then echo "Mutter"; elif [ "$XDG_CURRENT_DESKTOP" == "KDE" ]; then echo "KWin"
    else
        wm=$(xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | awk -F'#' '/^_NET_SUPPORTING_WM_CHECK/ {print $2}' | xargs -I{} xprop -id {} _NET_WM_NAME 2>/dev/null | cut -d '"' -f2)
        echo "${wm:-Unknown}" 
    fi 
    }
    get_compositor(){
        if pgrep -x picom > /dev/null; then
            echo "picom"
        elif pgrep -x compton > /dev/null; then
            echo "compton"
        elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
            echo "KWin (built-in)"
        elif [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
            echo "Mutter (built-in)"
        else
            echo "Unknown"
        fi
    }

    get_gtk_theme() {
        gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'"
    }
    get_icon_theme() {
        gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'"
    }
    get_font_name() {
        gsettings get org.gnome.desktop.interface font-name 2>/dev/null | tr -d "'"
    }

    get_shell_version() {
        case "$SHELL" in
            */bash) bash --version | head -n1 ;;
            */zsh) zsh --version ;;
            */fish) fish --version ;;
            *) echo "$SHELL" ;;
        esac
    }

    get_gnome_version(){
        local isGnome=$(echo "$XDG_CURRENT_DESKTOP")
        if [ "$isGnome" == "GNOME" ]; then printOut=$(echo -e "$(gnome-shell --version 2>/dev/null | cut -d' ' -f3)"); else printOut=""; fi
        echo "$printOut"
    }



    infoArray=(
        $'\033[1mSystem Info:\033[0m ' "$(get_formatted_date)"
        "OS: $(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/*release | cut -d= -f2 | tr -d \")"
        "Kernel: $(uname -r)"
        "Uptime: $(uptime -p | sed 's/up //')"
        "Packages: $(dpkg-query -f '.\n' -W 2>/dev/null | wc -l)"
        "Flatpak pkg: $(flatpak list | wc -l)"
        "Shell: $(get_shell_version)"
        "DE: ${XDG_CURRENT_DESKTOP:-Unknown} $(get_gnome_version)"
        "Session: ${XDG_SESSION_TYPE:-unknown}"
        "WM: $(get_wm)"
        "Compositor: $(get_compositor)"
        "Theme: $(get_gtk_theme)"
        "Icons: $(get_icon_theme)"
        "Font: $(get_font_name)"
        "CPU: $(lscpu | grep 'Model name' | sed 's/Model name:\s*//')"
        "GPU: $(lspci | grep VGA | cut -d: -f3 | xargs)"
        "RAM: $(free -h | awk '/Mem:/ {print $3 " / " $2}')"
        "SWAP: $(free -h | awk '/Swap:/ {print $3 " / " $2}')"
    )


    printf '%s\n' "${infoArray[@]}"
}

##################################################


BKP_folder(){
    local source="${1:-}" target="${2:-}"
    local zipFile

    if [ -z "$source" ] || [ -z "$target" ]; then echo "Usage: BKP_folder <folder-to-bkp> <save-path>"; return 1; fi
    
    if [ -d "$source" ]; then
        zipFile="$target/"$(get_file_date)"_bkp_"$( basename "$source" )".zip"

        zip2 "$zipFile" "$source" || { sysLogger e "Failed to create archive $zipFile" ; return 1; }

        sysLogger i "Created "$target"/$(basename "$zipFile")"

    else
        sysLogger e "Folder not found "$source""
    fi
}


BKP_home(){
    #### App settings, saved passwords and GNOME extensions: the only parts of ~ not restored by Nextcloud or newPc
    #### Relative to $HOME so the archive mirrors the home layout: restore = unzip into ~
    local paths=( ".config" ".local/share/keyrings" ".local/share/gnome-shell/extensions" )

    #### Re-downloadable modpacks; path as stored in the archive, so only this exact folder is skipped
    local excludes=( '-x!.config/CurseForge' )

    if [ -z "$1" ]; then sysLogger e "Enter bkp destination path."

    elif [ -n "$1" ] && [ -d "$1" ]; then
        #### Absolute, since 7z runs from $HOME
        local zipFile
        zipFile="$(realpath "$1")/bkp_home_$(get_file_date).zip"

        #### 7z directly: zip2 takes a single file and no options. Subshell, so the caller's folder doesn't change
        #### -snl: store symlinks as links, a dangling one (e.g. old pulse runtime) no longer fails the run
        ( cd "$HOME" && 7z a -mmt="$(nproc)" -snl "${excludes[@]}" "$zipFile" "${paths[@]}" ) || { sysLogger e "Failed to backup folders"; return 1; }
        sysLogger i "Created $zipFile"
        
    else sysLogger e "Not a valid path: $1"; fi
}

##################################################

extract(){
    local file="${1:-}"; local mmt=8; local dir; local failed=0
    local files=(); local cmd=(); local -A seen=(); local globState

    if [[ -z "$file" ]]; then
        sysLogger e "Usage: extract <archive> | extract a"      #### a = every archive in the current folder
        return 1
    fi

    if [[ "$file" == "a" ]]; then
        globState="$(shopt -p nullglob)"                        #### remember the caller's setting
        shopt -s nullglob                                       #### unmatched patterns vanish instead of staying literal
        files=( *.zip *.7z *.rar *.tar *.tar.* *.tgz *.tbz2 *.txz )
        eval "$globState"
    else
        if [[ ! -f "$file" ]]; then
            sysLogger e "No such file: $file"
            return 1
        fi
        files=( "$file" )
    fi

    for file in "${files[@]}"; do
        if [[ ! -f "$file" ]]; then
            continue
        fi

        if [[ -n "${seen[$file]:-}" ]]; then                    #### patterns overlap, e.g. foo.tar.zip
            continue
        fi
        seen["$file"]=1

        dir="${file%.*}"
        if [[ "$dir" == *.tar ]]; then                          #### foo.tar.gz -> foo
            dir="${dir%.tar}"
        fi

        case "$file" in                                         #### zip/7z/rar first: foo.tar.zip is a zip, not a tar
            *.zip|*.7z|*.rar)                 cmd=( 7z x -mmt="$mmt" -o"$dir" -- "$file" ) ;;
            *.tar|*.tar.*|*.tgz|*.tbz2|*.txz) cmd=( tar -xf "$file" -C "$dir" ) ;;
            *)
                sysLogger e "Unsupported file type: $file"
                failed=$((failed+1))
                continue
                ;;
        esac

        sysLogger i "Extracting: $file -> $dir/"

        if ! mkdir -p -- "$dir"; then
            sysLogger e "Cannot create folder: $dir"
            failed=$((failed+1))
            continue
        fi

        if ! "${cmd[@]}"; then
            sysLogger e "Extraction failed: $file"
            rmdir -- "$dir" 2>/dev/null                         #### only succeeds if nothing landed in it
            failed=$((failed+1))
            continue
        fi

        if [[ -e "$dir/${file##*/}" ]]; then                    #### the archive moves into its own folder
            sysLogger e "Archive not moved: $dir/${file##*/} already exists"
            failed=$((failed+1))
        elif ! mv -- "$file" "$dir/"; then
            sysLogger e "Archive not moved: $file"
            failed=$((failed+1))
        fi
    done

    return "$failed"
}

##################################################

rotateBackups(){
    #### rotateBackups <folder> <keep> [glob]   -> keeps the <keep> newest files, deletes the rest
    local dir="${1:-}"; local keep="${2:-}"; local pattern="${3:-*.zip}"
    local backups=(); local victim; local removed=0; local failed=0


    [[ -d "$dir" ]] || { sysLogger e "Not a folder $dir"; return 1; }

    [[ "$keep" =~ ^[0-9]+$ ]] && (( keep > 0 )) || { sysLogger e "<keep> must be a positive integer, current '$keep'"; return 1; }

    #### list the backups, NEWEST first
    #### %T@ = mtime as a number ; NUL-separated so spaces/newlines in names are safe
    mapfile -d '' -t backups < <( find "$dir" -maxdepth 1 -type f -name "$pattern" -printf '%T@\t%p\0' | sort -z -rn | cut -z -f2- )


    #### glob defaults to *.zip ; only the folder itself is touched, never subfolders
    if (( ${#backups[@]} <= keep )); then
        sysLogger DEBUG "${#backups[@]}/$keep backups in $dir, nothing to rotate"
        return 0
    fi

    for victim in "${backups[@]:keep}"; do
        if rm -f -- "$victim"; then
            sysLogger i "Removed ${victim##*/}"
            removed=$((removed+1))
        else
            sysLogger e "could not remove $victim"
            failed=$((failed+1))
        fi
    done

    sysLogger DEBUG "$removed removed, $keep kept in $dir"
    return "$failed"
}

##################################################

stopwatch(){
    local time="0"
    local mins secs
    echo -e "⏰ Starting stopwatch: $(get_formatted_date)\n"

    while true; do
        mins=$(( time / 60 ))
        secs=$(( time % 60 ))

        printf "\r⏳ Time: %02d:%02d" "$mins" "$secs"
        sleep 1s
        (( time++ ))
    done
}

##################################################

killp(){
    local sig="${1:-15}"; local process="${2:-}"

	#### Reads each PID into an indexed array, splitting on whitespace/newlines
    #### pgrep -f = matches whole command lines
    #### pgrep -x = matches the program name only
    local pids=($(pgrep -x "$process")) 

    if [ -n "$process" ]; then
        for pid in "${pids[@]}"; do
            sysLogger i "Killing process - $process: $pid"
            kill -"$sig" "$pid"
        done    
    else sysLogger e "No process passed"; fi    
}

##################################################

latexSET(){
    nemo --tabs "$HOME/Nextcloud/Docker" "$HOME/Nextcloud/Latex" &
    
    gnome-terminal --tab --working-directory="$HOME/Nextcloud/Latex"  &  

    gnome-terminal --tab --working-directory="$HOME/Nextcloud/Docker/Containers/latex" & 
}

latexUPD(){
    local latexFile="${1:-}"

    if [ ! -f "$latexFile" ]; then echo -e "No file selected"; return 1; fi

    cd "$(dirname "$latexFile")"       ####  LaTeX dumps the files to the current working directory
    
    local latexPdf=$(echo -e "$latexFile" | awk '{$1=$1; gsub(/\.tex/, "") ; print}' )
    flatpak run org.kde.okular "$latexPdf.pdf" &
    
    check(){
        stat -c "%Y" "$latexFile"    #### check file update
    }

    local ver1=$(check)
    
    while true; do
        sleep 1s
        local ver2=$(check)
        if [ "$ver1" != "$ver2" ]; then
            local ver1=$(check)
            xelatex -shell-escape "$latexFile" #### Shell escape is required for minted package
        fi
    done
}

##################################################

minecraft(){
    local mcFolder="/media/federico/SSD1TB/minecraft"
    
    if [ ! -f "$mcFolder/launcher/TLauncher.jar" ]; then sysLogger e "TLauncher.jar not found"; return 1; fi

    nemo --tabs "$mcFolder/curseforge" "$mcFolder/curseforge/curse_minecraft/Instances" "$mcFolder/versions" "$HOME/Nextcloud/Games/Minecraft" &
    gamemoderun java -jar "$mcFolder/launcher/TLauncher.jar" 
}


minecraftRecipe(){
    local script=""$HOME"/Nextcloud/Games/Minecraft/Recipes/recipe_maker/recipe_maker.py"
    
    if [ -f "$script" ]; then
        py "$script" || { sysLogger e "Failed to launch "$script"" ; return 1 ; }
    else        
        sysLogger e "File not found "$script""
    fi
}


##################################################

pizza(){
    echo "$(date +"%Y-%m-%d")" >> "$PYscripts/PizzaPlot/pizza_data.csv"
    py "$PYscripts/PizzaPlot/pizza.py"
    echo "🍕 Pizza 🍕"
    flatpak run org.nomacs.ImageLounge "$PYscripts/PizzaPlot/PizzaPlot.png" > /dev/null &
}

##################################################

orion-install(){
    flatpak install app/com.ktechpit.orion/x86_64/stable -y
    flatpak run com.ktechpit.orion/x86_64/stable &
}

orion-uninstall(){
    flatpak uninstall app/com.ktechpit.orion/x86_64/stable -y
    rm -rf "$HOME/.var/app/com.ktechpit.orion"
    rm "$HOME/Downloads/.Orion.id"
    rm -rf "$HOME/Downloads/Orion"
}

##################################################

getFileInfo(){
    for file in "$@"; do

        mediainfo --Output=$'General;File Name: %FileName%\\r\\nBit Rate: %BitRate/String%\\r\\nDuration: %Duration/String3%\\r\\nFPS: %FrameRate%\\r\\nSize: %FileSize/String%\nVideo;\\r\\nDimensions: %Width%x%Height%\\r\\n' "$file"

    done | zenity --text-info --width=500 --height=300 --title="Video Info"
}

##################################################

wireplumberDevicesExport(){
    export LC_ALL=C

    echo "=== CARDS ==="
    pactl list cards | awk '/^Card #/ {print "---"} /^\tName: / {print} /^\t\tdevice\.description = / {print} /^\tActive Profile: / {print}'
    echo "=== SINKS ==="
    pactl list sinks | awk '/^\tName: / {n=$2} /^\tDescription: / {sub(/^\tDescription: /, ""); print n "  |  " $0}'
    echo "=== SOURCES ==="
    pactl list sources | awk '/^\tName: / {n=$2} /^\tDescription: / {sub(/^\tDescription: /, ""); if (n !~ /\.monitor$/) print n "  |  " $0}'
}

##################################################

lockedBgFunction(){
    local lockName="${1:-}"
    local func="${2:-}"

    if [ -z "$lockName" ]; then PID_sysLogger e "No lock name provided: $lockName"; return 1; fi
    if [ -z "$func" ]; then PID_sysLogger e "No function provided: $func"; return 1; fi

    lockManager "$lockName" || return 1

    PID_debugLogger "Launching function "$func" in background"

    "$func" &
    local pid=$!

    #### Give it a second: a function that dies right away is caught instead of logged as started
    #### kill -0 = sends no signal, only checks the PID exists; builtin, so no fork and no output
    sleep 1
    if kill -0 "$pid" 2>/dev/null; then
        PID_sysLogger i "$func started with PID=$pid"
    
    else 
        PID_sysLogger e "$func tried to start with PID=$pid"
    fi
}

##################################################

metaDateMod(){
    #### Modifies the metadata dates of the files in the folder

    local date="${1:-}"
    local folder="${2:-}"

    if [ -z "$date" ] || [ -z "$folder" ]; then
        echo "Usage: metaDateMod <date (yyyy-mm-dd)> <folder> | . (pwd)"
        return 1
    fi

    if [ "$folder" == "."  ]; then folder=$( pwd ) ; fi

    date=""$date" 00:00:00" #### append the timestamp

    echo -e "Set "$date" for all files in \n  $folder"


    #### All filetypes
    find "$folder" -type f -exec touch -d "$date" {} +

    #### All specified filetypes
    #### find "$folder" -type f -exec exiftool \
    ####     "-CreateDate=$date" \
    ####     "-ModifyDate=$date" \
    ####     "-MediaCreateDate=$date" \
    ####     "-MediaModifyDate=$date" \
    ####     "-TrackCreateDate=$date" \
    ####     "-TrackModifyDate=$date" \
    ####     "-FileModifyDate=$date" \
    ####     {} +
}

##################################################

steam_idToName(){
    local name d id
    local SC="/media/federico/SSD1TB/steam/steamapps/compatdata"
    local STEAMAPPS
    STEAMAPPS=$(dirname "$SC")

    printf '\tSTEAM-ID\tNAME\n\t-------------------------------\n'

    for d in "$SC"/*/; do
        id=$(basename "$d")
        name=$(grep -m1 '"name"' "$STEAMAPPS/appmanifest_$id.acf" 2>/dev/null | cut -d'"' -f4)
        printf '\t%s\t\t%s\n' "$id" "${name:-unknown (non-Steam shortcut or uninstalled)}"
    done | sort -n -k1,1
}

##################################################

jsPolicyRoot(){
    #### Root-level task: writes to /etc, so it runs as root, not through asUser
    local userHome="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
        
    local file="${1:-}"
    local targetDir="${2:-}"

    if [ -z "$file" ] || [ -z "$targetDir" ] ; then echo "Usage: jsPolicyRoot <file> <target dir>"; return 1 ;fi

    local policySrc="$userHome/Nextcloud/Stuff/BrowserStuff/Policy/"$file""


    if [ ! -s "$policySrc" ]; then echo "JSON not found: $policySrc"; return 1; fi
    if ! python3 -m json.tool "$policySrc" > /dev/null; then echo "JS policy backup is not valid JSON: $policySrc"; return 1; fi

    #### 644: the Flatpak sandboxes read it as the normal user
    if install -D -m 644 "$policySrc" "$targetDir/$file"; then
        echo "JS policy installed: $targetDir/$file"
    else
        echo "Cannot install the JS policy in $targetDir"; return 1
    fi
}


#### Wrappers for the function above that requires running via sudo

jsPolicy(){
    sudo bash -c "$(declare -f jsPolicyRoot ); jsPolicyRoot 'jsPolicy.json' '/etc/brave/policies/managed'"
    sudo bash -c "$(declare -f jsPolicyRoot  ); jsPolicyRoot 'jsPolicy.json' '/etc/opt/chrome/policies/managed'"
}

jsPolicyChromium(){
    #### Chromium has no /etc/ access
    local chromiumPath="/var/lib/flatpak/extension/org.chromium.Chromium.Policy.system-policies/x86_64/1/policies/managed"
    sudo bash -c "$(declare -f jsPolicyRoot ); jsPolicyRoot 'jsPolicy_Chormium.json' "$chromiumPath""
}


##################################################


