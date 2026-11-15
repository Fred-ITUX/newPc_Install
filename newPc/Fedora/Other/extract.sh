#!/bin/bash
#### extract.sh: standalone, called by ~/.local/share/nemo/actions/extract_here.nemo_action
#### Exec=/bin/bash /home/federico/Nextcloud/Linux/scripts/Nemo_scripts/extract.sh %F
#### extracts each selected archive into a folder of its own with a zenity progress bar,
#### then moves the archive inside that folder ; needs 7z, unrar, tar, pv, zenity, notify-send
#### Fedora KDE version of Nemo_scripts/extract.sh: .rar goes through unrar (Fedora's 7z has no RAR support)

logFile="${XDG_STATE_HOME:-$HOME/.local/state}/nemo_extract.log"

exec </dev/null                                         #### no tty here: 7z must never be able to sit on an overwrite prompt

if ! mkdir -p -- "${logFile%/*}"; then
    notify-send -u critical -i dialog-error "Extract" "Cannot create ${logFile%/*}"
    exit 1
fi
exec >>"$logFile" 2>&1                                  #### no terminal: keep 7z/tar output somewhere readable
echo "==== $(date '+%F %T') ===="


################################################################################################
####                            Functions

#### sysLogger <i|e> <message>  ->  one line in $logFile
sysLogger(){
    echo "[$1] ${*:2}"
}

#### extractGui <tool> <archive> <folder>  ->  the extraction itself, with a zenity progress bar
#### 7z prints its own percentages ; tar has none, so pv reports how much of the archive has been read
extractGui(){
    local tool="$1"; local file="$2"; local dir="$3"; local mmt=8; local chunk; local rc
    local decompress=()
    local bar=( zenity --progress --auto-close --no-cancel --time-remaining --width=420 --title="Extracting" --text="${file##*/}" )

    if [[ "$tool" == "unrar" ]]; then
        #### unrar gives no machine-readable progress: the bar just pulses until it ends. -o- = never overwrite, -idq = quiet
        #### TO CONFIRM on Fedora: not tested with a real .rar archive
        unrar x -o- -idq -- "$file" "$dir/" | zenity --progress --pulsate --auto-close --no-cancel --width=420 --title="Extracting" --text="${file##*/}"
        rc=${PIPESTATUS[0]}
    elif [[ "$tool" == "7z" ]]; then
        7z x -bsp1 -bso0 -mmt="$mmt" -o"$dir" -- "$file" \
            | while IFS= read -r -d $'\b' chunk; do             #### 7z redraws its counter using backspaces
                  if [[ "$chunk" =~ ([0-9]+)% ]]; then
                      echo "${BASH_REMATCH[1]}"
                  fi
              done \
            | "${bar[@]}"
        rc=${PIPESTATUS[0]}
    else
        case "$file" in                                         #### tar can't detect compression on a pipe
            *.tar.gz|*.tgz)   decompress=( -z ) ;;
            *.tar.bz2|*.tbz2) decompress=( -j ) ;;
            *.tar.xz|*.txz)   decompress=( -J ) ;;
            *.tar.zst)        decompress=( --zstd ) ;;
        esac

        ( pv -n -i 0.5 "$file" 2>&3 | tar -x "${decompress[@]}" -f - -C "$dir" ) 3>&1 | "${bar[@]}"
        rc=${PIPESTATUS[0]}
    fi

    return "$rc"
}

#### extract <archive>  ->  <archive name without extension>/ with the archive moved inside it
extract(){
    local file="$1"; local dir; local tool

    if [[ ! -f "$file" ]]; then
        sysLogger e "No such file: $file"
        return 1
    fi

    dir="${file%.*}"
    if [[ "$dir" == *.tar ]]; then                              #### foo.tar.gz -> foo
        dir="${dir%.tar}"
    fi

    case "$file" in                                             #### zip/7z/rar first: foo.tar.zip is a zip, not a tar
        *.zip|*.7z)                       tool="7z"  ;;
        *.rar)                            tool="unrar" ;;
        *.tar|*.tar.*|*.tgz|*.tbz2|*.txz) tool="tar" ;;
        *)
            sysLogger e "Unsupported file type: $file"
            return 1
            ;;
    esac

    sysLogger i "Extracting: $file -> $dir/"

    if ! mkdir -p -- "$dir"; then
        sysLogger e "Cannot create folder: $dir"
        return 1
    fi

    if ! extractGui "$tool" "$file" "$dir"; then
        sysLogger e "Extraction failed: $file"
        rmdir -- "$dir" 2>/dev/null                             #### only succeeds if nothing landed in it
        return 1
    fi

    if [[ -e "$dir/${file##*/}" ]]; then                        #### the archive moves into its own folder
        sysLogger e "Archive not moved: $dir/${file##*/} already exists"
        return 1
    fi

    if ! mv -- "$file" "$dir/"; then
        sysLogger e "Archive not moved: $file"
        return 1
    fi

    return 0
}


################################################################################################
####                            Main

####                            What was right-clicked
declare -a targets=()
if [[ -n "${NEMO_SCRIPT_SELECTED_FILE_PATHS:-}" ]]; then
    mapfile -t targets < <(printf '%s' "$NEMO_SCRIPT_SELECTED_FILE_PATHS")
else
    targets=( "$@" )                                            #### %F from the action, or launched by hand
fi

if [[ ${#targets[@]} -eq 0 ]]; then
    sysLogger e "nothing selected"
    notify-send -i dialog-error "Extract" "Nothing selected"
    exit 1
fi

####                            Extract each selected archive in place
declare -i ok=0; declare -i failed=0
for target in "${targets[@]}"; do
    if [[ -z "$target" ]]; then
        continue
    fi

    if extract "$target"; then
        ok=$((ok+1))
    else
        failed=$((failed+1))
    fi
done

if [[ $((ok + failed)) -eq 0 ]]; then                            #### only blank paths arrived, e.g. %F expanded to ""
    sysLogger e "no usable path received"
    notify-send -i dialog-error "Extract" "No file path received from Nemo"
    exit 1
fi

####                            Tell the user
if [[ $failed -eq 0 ]]; then
    notify-send -i package-x-generic "Extract" "$ok archive(s) extracted"
else
    notify-send -u critical -i dialog-error "Extract" "$ok extracted, $failed failed - see $logFile"
fi

exit "$failed"