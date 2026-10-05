#!/bin/bash


dumpCurrent(){
    local bkpFolder="$HOME/Nextcloud/Linux/scripts/newPc/DE_configs/$(date "+%Y_%m_%d")"

    mkdir -p "$bkpFolder" || { echo "[ERROR] -> Failed to create the folder $bkpFolder"; return 1; }
    cp "$HOME/.config/mimeapps.list" "$bkpFolder"
}



restoreSaved(){
    local newest file
    local basePath="$HOME/Nextcloud/Linux/scripts/newPc/DE_configs"

    newest=$(find "$basePath" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' |
         grep -E '^[0-9]{4}_[0-9]{2}_[0-9]{2}$' |
         sort |
         tail -n1)

    [ -n "$newest" ] || { echo "[ERROR] -> No dated dump folder found in $basePath"; return 1; }

    file="$basePath"/"$newest"/mimeapps.list

    if [ -s "$file" ]; then    
        
        echo "Restoring from "$file""
        cp "$file" "$HOME/.config/mimeapps.list"
    
    else
        echo "[ERROR] -> No file found "$file""
    fi

}


# dumpCurrent  || { echo "Function 'dumpCurrent' terminated with an [ERROR]" ; }
restoreSaved || { echo "Function 'restoreSaved' terminated with an [ERROR]" ; }