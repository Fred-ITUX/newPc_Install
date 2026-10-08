#!/bin/bash

brokenEnv=false

if [ -s "$HOME/.bash_common" ]; then source "$HOME/.bash_common"; else echo "[CRITICAL ERROR] Bash module not found: $HOME/.bash_common"; brokenEnv=true; fi

if $brokenEnv; then
    echo "[CRITICAL ERROR] Enviroment degraded, functions disabled"
    return 1
fi;

userCheck

##################################################

bashUpd(){
    if [ -z "$LXscripts" ]; then local LXscripts="$HOME/Nextcloud/Linux/scripts"; fi

    local modules=(
        "bashrc"
        "bash_functions"
        "bash_common"
    )

    for module in "${modules[@]}"; do

        #### echo -e "\nwould copy "$LXscripts"/bash/""$module".sh" "$HOME"/."$module" "
        #### echo -e "would source "$HOME"/."$module"\n"

        cp "$LXscripts"/bash/""$module".sh" "$HOME"/."$module" 
        source "$HOME"/."$module"

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


shutdown(){
    shutdown_routine
    systemctl poweroff
}


reboot(){
    read -r -p 'To reboot press enter'
    shutdown_routine
    systemctl reboot
}


end(){
    read -r -p 'To shut down press enter'
    shutdown
}

##################################################

sysUPD(){
    export DEBIAN_FRONTEND=noninteractive #### safety prompt avoid

    local UPD_path="${XDG_RUNTIME_DIR}/UPD_logs"

    if [ ! -d "$UPD_path" ]; then mkdir -p "$UPD_path" ; fi

    local outputLog="${1:-}"

    if [ -z "$outputLog" ]; then sysLogger e "sysUPD requires an output log path"; return 1; fi

    local fixPkg="$UPD_path/UPD_fixPkg.log"
    local update="$UPD_path/UPD_update.log"
    local upgrade="$UPD_path/UPD_upgrade.log"
    local flatpakUpdt="$UPD_path/UPD_flatpakUpdt.log"
    local cleanup="$UPD_path/UPD_cleanup.log"
    local completeLog="$UPD_path/UPD_completeLog.log"

    #### Retain full log
    local strtp_full="$(get_pathStartupUpdaterFull)"

    echo -n > "$fixPkg" ; echo -n > "$update" ; echo -n > "$upgrade" ; echo -n > "$flatpakUpdt" ; echo -n > "$cleanup" ; echo -n > "$completeLog"

    UPD_fix(){
        echo -e "\n• Fix broken pkg: \n"
        sudo -n /usr/bin/dpkg --configure -a
        sudo -n /usr/bin/apt-get --fix-broken install -y
    } > "$fixPkg"


    UPD_updater(){
        echo -e "\n• Update: \n"
        sudo -n /usr/bin/apt-get --fix-missing -q update
    } > "$update"


    UPD_upgrade(){
        echo -e "\n• Upgrade: \n"
        sudo -n /usr/bin/apt-get dist-upgrade -y
    } > "$upgrade"


    UPD_flatpak(){
        echo -e "\n• Flatpak update: \n" 
        flatpak update -y
    } > "$flatpakUpdt"


    UPD_cleanup(){
        echo -e "\n• Autoremove: \n"
        sudo -n /usr/bin/apt-get autoremove -y
        sudo -n /usr/bin/apt-get clean
    } > "$cleanup"


    #### If the content matches with the empty preset, that block does not get saved
    UPD_check(){

        if [ -n "$content_fixPkg" ] && [ -z "$content_update" ] && [ -n "$content_upgrade" ] && [ -n "$content_flatpakUpdt" ] && [ -n "$content_cleanup" ]; then
            echo -e "\n\t> Nothing to report" >> "$completeLog"; return 0
        fi

        if [ -n "$content_fixPkg" ]; then echo -n > "$fixPkg"
            else cat "$fixPkg" >> "$completeLog"
        fi

        #### Reverse logic -- the only useful output is in case of ERRORS / WARNINGS
        if [ -z "$content_update" ]; then echo -n > "$update"
            else cat "$update" >> "$completeLog"
        fi


        if [ -n "$content_upgrade" ]; then echo -n > "$upgrade"
            else cat "$upgrade" >> "$completeLog"
        fi


        if [ -n "$content_flatpakUpdt" ]; then echo -n > "$flatpakUpdt"
            else cat "$flatpakUpdt" >> "$completeLog"
        fi


        if [ -n "$content_cleanup" ]; then echo -n > "$cleanup"
            else cat "$cleanup" >> "$completeLog"
        fi
    }


    getSysInfoStart >> "$completeLog"
    getSysInfoStart >> "$strtp_full"


    UPD_fix
    UPD_updater
    UPD_upgrade
    UPD_flatpak
    UPD_cleanup


    #### Indent text to allow fold per-day
    sed 's/^/\t/' -i "$fixPkg"
    sed 's/^/\t/' -i "$update"
    sed 's/^/\t/' -i "$upgrade"
    sed 's/^/\t/' -i "$flatpakUpdt"
    sed 's/^/\t/' -i "$cleanup"


    cat "$fixPkg"       >> "$strtp_full" 
    cat "$update"       >> "$strtp_full" 
    cat "$upgrade"      >> "$strtp_full" 
    cat "$flatpakUpdt"  >> "$strtp_full" 
    cat "$cleanup"      >> "$strtp_full" 
    getSysInfoEnd       >> "$strtp_full"


    local content_fixPkg=$( cat "$fixPkg" | grep -iE "0 upgraded, 0 newly installed, 0 to remove" )
    local content_update=$( cat "$update" | grep -iE "WARN|ERR|ERROR|REMOVED" )
    local content_upgrade=$( cat "$upgrade" | grep -iE "0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded" )
    local content_flatpakUpdt=$( cat "$flatpakUpdt" | grep -iE "Nothing to do" )
    local content_cleanup=$( cat "$cleanup" | grep -iE "0 upgraded, 0 newly installed, 0 to remove" )

    UPD_check

    getSysInfoEnd >> "$completeLog"


    # echo "$completeLog" | py "$LXscripts/Startup_Routine/log_cleaner.py" || { sysLogger e "$LXscripts/Startup_Routine/log_cleaner.py failed, appending raw log"; }

    py "$LXscripts/Startup_Routine/log_cleaner.py" "$completeLog" || { sysLogger e "$LXscripts/Startup_Routine/log_cleaner.py failed, appending raw log"; }

    #### Collapses multiple newlines into 2 to keep spacing
    fileNewLineStrip "$strtp_full"
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
        zipFile="${XDG_RUNTIME_DIR}/"$(get_file_date)"_bkp_"$( basename "$source" )".zip"

        7z a -mmt=8 "$zipFile" "$source"

        mv "$zipFile" "$target" || { sysLogger e "Failed to move the archive" ; return 1; }
        sysLogger i "Created "$target"/$(basename "$zipFile")"
     
    fi
}


BKP_home(){
    if [ -z "$1" ]; then sysLogger e "Enter bkp destination path."
    
    elif [ -n "$1" ] && [ -d "$1" ]; then
        local zipFile="$1/bkp_home_$(get_file_date).zip"

        7z a -mmt=8 "$zipFile"  ""$HOME"/.config" ""$HOME"/.gnupg" ""$HOME"/.linuxmint" ""$HOME"/.local" ""$HOME"/.pki" ""$HOME"/.ssh" ""$HOME"/.gtkrc-2.0" ""$HOME"/.gtkrc-xfce" ""$HOME"/.lesshst" ""$HOME"/.profile" ""$HOME"/.wget-hsts" ""$HOME"/.Xauthority" ""$HOME"/.xsession-errors"
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
    [[ "$time" =~ ^[0-9]+$ ]] || { sysLogger e "Usage: alarm <minutes>"; return 1; }
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
	local pids=($(pgrep -f "$process")) #### Reads each PID into an indexed array, splitting on whitespace/newlines

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
    
    if [ ! -f "$mcFolder/launcher/TLauncher.jar" ]; then sysLogger e "TLauncher.jar not found"; fi

    nemo --tabs "$mcFolder/curseforge" "$mcFolder/curseforge/curse_minecraft/Instances" "$mcFolder/versions" "$HOME/Nextcloud/Games/Minecraft" &
    gamemoderun java -jar "$mcFolder/launcher/TLauncher.jar" 
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

allRepoPush(){
	shopt -s nullglob
	local script rc=0

		for script in "$LXscripts"/Github/*_update.sh; do
			sysLogger i "Running -- $(basename "$script")"
			if ! bash "$script"; then sysLogger e "$(basename "$script") failed"; rc=1; fi
		done
	shopt -u nullglob
	return "$rc"

	sysLogger i "Repo update done"
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
    
    if ps -p "$pid"; then
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
