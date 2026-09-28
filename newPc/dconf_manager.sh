#!/bin/bash

###############################################################


#### This script is NOT intended to be run manually
#### It should be sourced and launched by newPc_Scripts.sh


###############################################################

local_user="${SUDO_USER:-$(whoami)}"
export XDG_RUNTIME_DIR="/run/user/$(id -u "$local_user")"
export HOME="$(getent passwd "$local_user" | cut -d: -f6)"


#### Enable test suite for the loader
DEBUG=true

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
        sysLogger e "A folder appears to already be present under "$finalFolder". \nEither remove the folder or rename it."; return 1
    fi


    mkdir -p "$destinationPath" || { sysLogger e "Unexpected error during folder creation: "$destinationPath", exiting"; return 1 ; }



    if [ ! -d "$dumpFolder" ]; then
        sysLogger i "Creating folder $dumpFolder"
        mkdir -p "$dumpFolder" || { sysLogger e "Unexpected error during folder creation: "$dumpFolder", exiting"; return 1 ; }
    else
        sysLogger e "Folder "$dumpFolder" already present, exiting"; return 1
    fi



    if [ -d "$dumpFolder" ]; then
        sysLogger i "Folder created: "$dumpFolder""
    else
        sysLogger e "Folder creation failed "$dumpFolder", exiting"; return 1
    fi


    atomicWrite "media-keys.conf" "$dumpFolder" "$(dconf dump /org/gnome/settings-daemon/plugins/media-keys/)"

    atomicWrite "wm-keybindings.conf" "$dumpFolder" "$(dconf dump /org/gnome/desktop/wm/keybindings/)"

    atomicWrite "shell-keybindings.conf" "$dumpFolder" "$(dconf dump /org/gnome/shell/keybindings/)"

    atomicWrite "mutter-keybindings.conf" "$dumpFolder" "$(dconf dump /org/gnome/mutter/keybindings/ )"

    atomicWrite "gnome_extensions.conf" "$dumpFolder" "$(dconf dump /org/gnome/shell/extensions/)"


    #### Force resets the left Super button to be the home
    #### gsettings set org.gnome.mutter overlay-key 'Super_L'


    mv "$dumpFolder" "$destinationPath"

    sysLogger i "\nDump folder content: \n$(ls "$finalFolder")"
} > "$dump_tempLog"




setup_dconf_restore(){
    local dumpPath newest newPath folderContents file filename

    if $DEBUG; then sysLogger DEBUG "DEBUG=$DEBUG. Testing suite active."; fi

    dumpPath="$HOME/Nextcloud/Linux/scripts/New_Pc/dconf_dump"

    newest=$(find "$dumpPath" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' |
         grep -E '^[0-9]{4}_[0-9]{2}_[0-9]{2}$' |
         sort |
         tail -n1)


    newPath="$dumpPath/$newest"
    sysLogger i "Newest folder's date: "$newPath""

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
                sysLogger e "Unknown dconf file: $(basename "$file")"
                return 1
                ;;
        esac
    done


    for file in "$newPath"/*; do
        [[ -s "$file" ]] || continue

        filename=$(basename "$file")


        if $DEBUG; then

            case "$filename" in
                gnome_extensions.conf) sysLogger DEBUG "Would load /org/gnome/shell/extensions/ < "$file" ";;

                media-keys.conf) sysLogger DEBUG "Would load /org/gnome/settings-daemon/plugins/media-keys < "$file" " ;;

                mutter-keybindings.conf) sysLogger DEBUG "Would load /org/gnome/mutter/keybindings/ < "$file" " ;;

                shell-keybindings.conf) sysLogger DEBUG "Would load /org/gnome/shell/keybindings/ < "$file" " ;;

                wm-keybindings.conf) sysLogger DEBUG "Would load /org/gnome/desktop/wm/keybindings/ < "$file" " ;;

                *) sysLogger DEBUG "Ignoring unknown dconf backup: $filename" ;;
            esac

        else
            sysLogger i "Started loading "$filename""

            case "$filename" in
                gnome_extensions.conf) dconf load /org/gnome/shell/extensions/ < "$file" || { sysLogger e "load failed for /org/gnome/shell/extensions/ " ; return 1;  } ;;

                media-keys.conf) dconf load /org/gnome/settings-daemon/plugins/media-keys/ < "$file" || { sysLogger e "load failed for /org/gnome/settings-daemon/plugins/media-keys/" ; return 1;  };;

                mutter-keybindings.conf) dconf load /org/gnome/mutter/keybindings/ < "$file" || { sysLogger e "load failed for /org/gnome/mutter/keybindings/" ; return 1;  } ;;

                shell-keybindings.conf) dconf load /org/gnome/shell/keybindings/ < "$file" || { sysLogger e "load failed for /org/gnome/shell/keybindings/" ; return 1;  } ;;

                wm-keybindings.conf) dconf load /org/gnome/desktop/wm/keybindings/ < "$file" || { sysLogger e "load failed for /org/gnome/desktop/wm/keybindings/" ; return 1;  } ;;

                *) sysLogger e "Ignoring unknown dconf backup: $filename" ;;
            esac

            sysLogger i "Finished loading "$filename""
        fi



    done
} > "$restore_tempLog"



launcher_setup_dconf_dump(){
    mkdir -p "$newPcPath"
    setup_dconf_dump || { sysLogger e "Function 'setup_dconf_dump' terminated with an error"; }
    mv "$dump_tempLog" "$dump_dconfLog" || { sysLogger e "Could not move \n"$dump_tempLog" \nto \n"$dump_dconfLog"" ; return 1;  }
    sysLogger i "Correctly dumped all configs. Check the log here: "$dump_dconfLog""
}



launcher_setup_dconf_restore(){
    mkdir -p "$newPcPath"
    setup_dconf_restore || { sysLogger e "Function 'setup_dconf_restore' terminated with an error";  }
    mv "$restore_tempLog" "$restore_dconfLog" || { sysLogger e "Could not move \n"$restore_tempLog" \nto \n"$restore_dconfLog"" ; return 1;  }
    sysLogger i "Correctly loaded all configs. Check the log here: "$restore_dconfLog""
    sysLogger i "Is required to reboot the system to show changes"
}


