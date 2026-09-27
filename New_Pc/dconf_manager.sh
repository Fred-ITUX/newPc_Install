#!/bin/bash
if [ -f "$HOME/.bash_common" ]; then source "$HOME/.bash_common"; else echo "[CRITICAL ERROR] Bash module not found: "$HOME/.bash_common"" ; exit 1; fi

set -euo pipefail

###############################################################

#### Enable test suite for the loader
# DEBUG=true

dateStamp="$(date "+%Y_%m_%d")"

newPcPath="$HOME/Nextcloud/Linux/log/newPc_history"


dump_tempLog="${XDG_RUNTIME_DIR}/tmp_dump_setup_dconf.log"
dump_dconfLog="$newPcPath/"$dateStamp"_dump_setup_dconf.log"



restore_tempLog="${XDG_RUNTIME_DIR}/tmp_restore_setup_dconf.log"
restore_dconfLog="$newPcPath/"$dateStamp"_restore_setup_dconf.log"



setup_dconf_dump(){

    local dateStamp="$(date "+%Y_%m_%d")"

    local dumpFolder="${XDG_RUNTIME_DIR}/setup_dconf_dump/$dateStamp"

    local destinationPath="$HOME/Nextcloud/Linux/scripts/New_Pc/dconf_dump"

    local finalFolder="$destinationPath/$dateStamp"



    if [ -d "$finalFolder" ]; then
        kindLogger "A folder appears to already be present under "$finalFolder". \nEither remove the folder or rename it."; return 1
    fi


    mkdir -p "$destinationPath" || { kindLogger "Unexpected error during folder creation: "$destinationPath", exiting"; return 1 ; }



    if [ ! -d "$dumpFolder" ]; then
        kindLogger "Creating folder $dumpFolder"
        mkdir -p "$dumpFolder" || { kindLogger "Unexpected error during folder creation: "$dumpFolder", exiting"; return 1 ; }
    else
        kindLogger "Folder "$dumpFolder" already present, exiting"; return 1
    fi



    if [ -d "$dumpFolder" ]; then
        kindLogger "Folder created: "$dumpFolder""
    else
        kindLogger "Folder creation failed "$dumpFolder", exiting"; return 1
    fi


    atomicWrite "media-keys.conf" "$dumpFolder" "$(dconf dump /org/gnome/settings-daemon/plugins/media-keys/)"

    atomicWrite "wm-keybindings.conf" "$dumpFolder" "$(dconf dump /org/gnome/desktop/wm/keybindings/)"

    atomicWrite "shell-keybindings.conf" "$dumpFolder" "$(dconf dump /org/gnome/shell/keybindings/)"

    atomicWrite "mutter-keybindings.conf" "$dumpFolder" "$(dconf dump /org/gnome/mutter/keybindings/ )"

    atomicWrite "gnome_extensions.conf" "$dumpFolder" "$(dconf dump /org/gnome/shell/extensions/)"


    #### Force resets the left Super button to be the home
    #### gsettings set org.gnome.mutter overlay-key 'Super_L'


    mv "$dumpFolder" "$destinationPath"

    kindLogger "\nDump folder content: \n$(ls "$finalFolder")"
} > "$dump_tempLog"




setup_dconf_restore(){
    local dumpPath newest newPath folderContents file filename

    if $DEBUG; then kindLogger "DEUBG=$DEBUG. Testing suite active."; fi

    dumpPath="$HOME/Nextcloud/Linux/scripts/New_Pc/dconf_dump"

    newest=$(find "$dumpPath" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' |
         grep -E '^[0-9]{4}_[0-9]{2}_[0-9]{2}$' |
         sort |
         tail -n1)


    newPath="$dumpPath/$newest"
    kindLogger "Newest folder's date: "$newPath""

    folderContents=( "$newPath"/* )


    #### Configs must match exactly 1:1
    for file in "$newPath"/*; do
        [[ -f "$file" ]] || continue

        case "$(basename "$file")" in
            gnome_extensions.conf|\
            media-keys.conf|\
            mutter-keybindings.conf|\
            shell-keybindings.conf|\
            wm-keybindings.conf)
                ;;
            *)
                kindLogger "ERROR: Unknown dconf file: $(basename "$file")"
                return 1
                ;;
        esac
    done


    for file in "$newPath"/*; do
        [[ -s "$file" ]] || continue

        filename=$(basename "$file")


        if $DEBUG; then

            case "$filename" in
                gnome_extensions.conf) kindLogger "Would load /org/gnome/shell/extensions/ < "$file" ";;

                media-keys.conf) kindLogger "Would load /org/gnome/settings-daemon/plugins/media-keys < "$file" " ;;

                mutter-keybindings.conf) kindLogger "Would load /org/gnome/mutter/keybindings/ < "$file" " ;;

                shell-keybindings.conf) kindLogger "Would load /org/gnome/shell/keybindings/ < "$file" " ;;

                wm-keybindings.conf) kindLogger "Would load /org/gnome/desktop/wm/keybindings/ < "$file" " ;;

                *) kindLogger "Ignoring unknown dconf backup: $filename" ;;
            esac

        else
            kindLogger "Started loading "$filename""

            case "$filename" in
                gnome_extensions.conf) dconf load /org/gnome/shell/extensions/ < "$file" || { kindLogger "ERROR: load failed for /org/gnome/shell/extensions/ " ; return 1;  } ;;

                media-keys.conf) dconf load /org/gnome/settings-daemon/plugins/media-keys/ < "$file" || { kindLogger "ERROR: load failed for /org/gnome/settings-daemon/plugins/media-keys/" ; return 1;  };;

                mutter-keybindings.conf) dconf load /org/gnome/mutter/keybindings/ < "$file" || { kindLogger "ERROR: load failed for /org/gnome/mutter/keybindings/" ; return 1;  } ;;

                shell-keybindings.conf) dconf load /org/gnome/shell/keybindings/ < "$file" || { kindLogger "ERROR: load failed for /org/gnome/shell/keybindings/" ; return 1;  } ;;

                wm-keybindings.conf) dconf load /org/gnome/desktop/wm/keybindings/ < "$file" || { kindLogger "ERROR: load failed for /org/gnome/desktop/wm/keybindings/" ; return 1;  } ;;

                *) kindLogger "Ignoring unknown dconf backup: $filename" ;;
            esac

            kindLogger "Finished loading "$filename""
        fi



    done
} > "$restore_tempLog"



launcher_setup_dconf_dump(){
    mkdir -p "$newPcPath"
    setup_dconf_dump || { kindLogger "Function 'setup_dconf_dump' terminated with an error"; }
    mv "$dump_tempLog" "$dump_dconfLog" || { kindLogger "Could not move \n"$dump_tempLog" \nto \n"$dump_dconfLog"" ; return 1;  }
    kindLogger "Correctly dumped all configs. Check the log here: "$dump_dconfLog""
}



launcher_setup_dconf_restore(){
    mkdir -p "$newPcPath"
    setup_dconf_restore || { kindLogger "Function 'setup_dconf_restore' terminated with an error";  }
    mv "$restore_tempLog" "$restore_dconfLog" || { kindLogger "Could not move \n"$restore_tempLog" \nto \n"$restore_dconfLog"" ; return 1;  }
    kindLogger "Correctly loaded all configs. Check the log here: "$restore_dconfLog""
    kindLogger "INFO: it is required to reboot the system to show changes"
}


