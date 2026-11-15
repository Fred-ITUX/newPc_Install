#!/bin/bash

################################################################################################
####
####    TEMPORARY REVIEW FILE -- Fedora KDE versions of functions from bash/bash_functions.sh
####
####    Not sourced by anything. Review each function, then replace the one with the same name
####    in bash_functions.sh (the rest of that file works on Fedora as it is).
####
####    Functions in this file:
####      > sysUPD       dnf instead of apt (3 steps instead of 5)
####      > systemInfo   rpm package count, KDE theme / icons / font / Plasma version
####      > BKP_home     KWallet instead of GNOME Keyring / GNOME extensions, missing folders skipped
####      > extract      .rar through unrar
####      > latexSET     Konsole instead of GNOME Terminal
####
####    No change needed (nemo, gedit and zenity are on the Fedora package list): updater, minecraft,
####    getFileInfo, shutdown / reboot, killp, rotateBackups, BKP_folder, jsPolicy*, and the rest.
####
################################################################################################


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
    #### dnf has no separate "update" (refresh the index) and no "fix broken" step:
    #### `dnf upgrade --refresh` downloads the index and upgrades in one go
    local steps=( 
            upgrade 
            flatpak 
            cleanup 
    )

    local -A title=( [upgrade]="Upgrade" [flatpak]="Flatpak update" [cleanup]="Autoremove" )


    #### A block is left out of the complete log when it shows nothing happened:
    #### quietIf  -> the output MATCHES the "nothing done" text
    ####             (dnf: "Nothing to do." ; flatpak: "Nothing to do." or, with no app installed, "Nothing to update.")
    #### problem  -> ... unless it ALSO shows a warning / error (e.g. a repository that could not be reached)
    ####             \berror\b = the whole word only: `dnf clean` always ends with "0 errors occurred", which must not count
    local -A quietIf=(
        [upgrade]="Nothing to do"
        [flatpak]="Nothing to (do|update)"
        [cleanup]="Nothing to do"
    )
    local problem='\berror\b|[1-9][0-9]* errors|fail|warning|cannot|could not|problem'


    UPD_run(){
        case "$1" in
            #### These three dnf command lines must match the UPDATE alias in enable_sudo_whitelist.sh character by character
            upgrade) sudo -n /usr/bin/dnf upgrade --refresh -y ;;
            flatpak) flatpak update -y ;;
            cleanup) sudo -n /usr/bin/dnf autoremove -y; sudo -n /usr/bin/dnf clean packages ;;
        esac
    }

    getSysInfoStart > "$completeLog"
    getSysInfoStart >> "$fullLog"

    for step in "${steps[@]}"; do
        stepLog="$updPath/UPD_$step.log"

        #### stderr too: dnf writes its errors there. Indented to allow fold per-day
        { echo -e "\n• ${title[$step]}: \n"; UPD_run "$step"; } 2>&1 | sed 's/^/\t/' > "$stepLog"

        cat "$stepLog" >> "$fullLog"

        if grep -qiE "${quietIf[$step]}" "$stepLog" && ! grep -qiE "$problem" "$stepLog"; then continue; fi

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

    #### KDE keeps these in ~/.config/kdeglobals (written by newPc/theme_updater.sh)
    get_gtk_theme() {
        kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage 2>/dev/null
    }
    get_icon_theme() {
        kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null
    }
    get_font_name() {
        #### "DejaVu Sans Condensed,11,-1,5,..." -> "DejaVu Sans Condensed 11"
        kreadconfig6 --file kdeglobals --group General --key font 2>/dev/null | awk -F',' '{print $1, $2}'
    }

    get_shell_version() {
        case "$SHELL" in
            */bash) bash --version | head -n1 ;;
            */zsh) zsh --version ;;
            */fish) fish --version ;;
            *) echo "$SHELL" ;;
        esac
    }

    get_de_version(){
        #### "plasmashell 6.8.2" -> "6.8.2"
        if [ "$XDG_CURRENT_DESKTOP" == "KDE" ]; then plasmashell --version 2>/dev/null | awk '{print $2}'; fi
    }



    infoArray=(
        $'\033[1mSystem Info:\033[0m ' "$(get_formatted_date)"
        "OS: $(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/*release | cut -d= -f2 | tr -d \")"
        "Kernel: $(uname -r)"
        "Uptime: $(uptime -p | sed 's/up //')"
        "Packages: $(rpm -qa 2>/dev/null | wc -l)"
        "Flatpak pkg: $(flatpak list | wc -l)"
        "Shell: $(get_shell_version)"
        "DE: ${XDG_CURRENT_DESKTOP:-Unknown} $(get_de_version)"
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


BKP_home(){
    #### App settings and saved passwords: the only parts of ~ not restored by Nextcloud or newPc
    #### Relative to $HOME so the archive mirrors the home layout: restore = unzip into ~
    #### TO CONFIRM on Fedora: .local/share/kwalletd is where KWallet keeps its wallets; keyrings only exists if an app still uses GNOME Keyring
    local candidates=( ".config" ".local/share/kwalletd" ".local/share/keyrings" )
    local paths=() candidate

    #### Only the folders that exist: 7z returns an error for a missing path (tested on Fedora 45), which would fail the whole backup
    for candidate in "${candidates[@]}"; do
        if [ -e "$HOME/$candidate" ]; then paths+=( "$candidate" ); fi
    done

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
            *.zip|*.7z)                       cmd=( 7z x -mmt="$mmt" -o"$dir" -- "$file" ) ;;
            *.rar)                            cmd=( unrar x -o- -- "$file" "$dir/" ) ;;     #### Fedora's 7z has no RAR support; -o- = never overwrite
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


latexSET(){
    nemo --tabs "$HOME/Nextcloud/Docker" "$HOME/Nextcloud/Latex" &
    
    #### TO CONFIRM on Fedora: Konsole in place of GNOME Terminal (--new-tab reuses an open Konsole window)
    konsole --new-tab --workdir "$HOME/Nextcloud/Latex"  &  

    konsole --new-tab --workdir "$HOME/Nextcloud/Docker/Containers/latex" & 
}
