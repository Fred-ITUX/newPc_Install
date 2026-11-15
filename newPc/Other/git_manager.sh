#!/bin/bash
# gitReposUT="$HOME/Nextcloud/Linux/scripts/Github/configs/github_source.sh"
# if [ -f "$gitReposUT" ]; then source "$gitReposUT"; else exit 1; fi
set -uo pipefail

if [ -f "$HOME/.bash_common" ]; then source "$HOME/.bash_common"; else echo "[CRITICAL ERROR] Bash module not found: "$HOME/.bash_common"" ; exit 1; fi

gitClonePath="$HOME/Github"
readmePath="$HOME/Nextcloud/Linux/scripts/Github/README"

#### If the github folder is not already present, creating it
#### only creates more issues as those would NOT be git folders
if [ ! -d "$gitClonePath" ] || [ ! -d "$readmePath" ]; then
    sysLogger e "The folder required are not present"; exit 1
fi

#############################################################

readmeCopy(){
    if [ -f "$readme" ]; then
        rsync -a "$readme" ""$destPath"/README.md" || { sysLogger e "Failed to copy README "$readme""; return 1; }
    else
        sysLogger e "File not found: "$readme""

    fi
}


repoRootMirror(){
    #### Mirrors the CONTENTS of a folder into a repo's ROOT, deletions included, without touching the
    #### repo's own files: /.git* (.git, .gitignore, .gitattributes, .github) and /README.md (set by readmeCopy)
    #### Leading "/" = top level only: nested README.md / .gitignore files from the source are still mirrored
    #### Use it for any repo filled at its root (like Games); repos filled into subfolders use plain rsync -a --delete
    #### Args: $1 = source folder   $2 = repo folder
    local source="${1:-}" repo="${2:-}"

    #### Refuse unless the target really is a repo: --delete on a wrong folder would empty it
    if [ ! -d "$source" ] || [ ! -d "$repo/.git" ]; then
        sysLogger e "repoRootMirror: source or repo missing ($source -> $repo)"
        return 1
    fi

    rsync -a --delete --exclude='/.git*' --exclude=/README.md "$source/" "$repo"
}


fetchPull(){
    local repo="$1"

    sysLogger i "Fetching repo: $repo"
    if ! git -C "$repo" fetch -q; then
        sysLogger e "Fetch failed: $repo"
        raiseAlarm "git fetch failed: ${repo##*/}"
        return 1
    fi

    #### A failed pull (diverged history, conflict) must stop this repo: copying and pushing on top would fail anyway
    sysLogger i "Pulling repo: $repo"
    if ! git -C "$repo" pull -q; then
        sysLogger e "Pull failed: $repo"
        raiseAlarm "git pull failed: ${repo##*/} (diverged or conflict, needs a manual look)"
        return 1
    fi

    sysLogger i "Repo status: $repo"
    git -C "$repo" status
}



commitPush(){
    local repo="$1"
    local commitMessage="Auto patch $(date "+%F %T")"
    local ahead

    sysLogger i "Updating local repo with remove"
    fetchPull "$repo"

    sysLogger i "Adding mods to repo: $repo"
    git -C "$repo" add -A

    #### No changes is not an error: git commit would fail with "nothing to commit"
    if [ -n "$(git -C "$repo" status --porcelain)" ]; then
        sysLogger i "Committing to repo: $repo"
        if ! git -C "$repo" commit -q -m "$commitMessage"; then
            sysLogger e "Commit failed: $repo"
            raiseAlarm "git commit failed: ${repo##*/}"
            return 1
        fi
    fi

    #### Push whenever local is ahead, so a commit left by a failed push is retried on the next run
    ahead="$(git -C "$repo" rev-list --count '@{u}..HEAD' 2>/dev/null)"
    if [ "${ahead:-1}" -eq 0 ]; then
        sysLogger i "Nothing to push: $repo"
        return 0
    fi

    sysLogger i "Pushing to repo: $repo"
    if ! git -C "$repo" push -q; then
        sysLogger e "Push failed: $repo"
        raiseAlarm "git push failed: ${repo##*/} (commit kept locally, retried next run)"
        return 1
    fi
}


#############################################################


codiumSync(){
    local item file
    
    local destPath="$gitClonePath/codiumSync"
    local appPath="$HOME/.var/app/com.vscodium.codium/config/VSCodium/User"
    local readme=""$readmePath"/codiumSync.md"

    local sources=(
        "settings.json"
        #### "keybindings.json" #### Not in use
    )

    for item in "${sources[@]}"; do
        file=""$appPath"/"$item

        if [ -f "$file" ]; then
            rsync -a "$file" "$destPath" || { sysLogger e "Failed copying file "$file""; return 1; }
        else
            sysLogger e "File not found: "$file""        
        fi
    done
    
    if [ -d ""$appPath"/snippets" ]; then
        rsync -a --delete ""$appPath"/snippets" "$destPath" || { sysLogger e "Failed copying snippets folder"; return 1; }
    else
        sysLogger e "Snippets folder not found: ""$appPath"/snippets""
    fi

    readmeCopy
}



All_Scripts(){
    local destPath="$gitClonePath/All_Scripts"
    local readme=""$readmePath"/All_Scripts.md"

    local sources=(
        "$HOME/Nextcloud/Python"
        "$HOME/Nextcloud/Linux"
    )

    for item in "${sources[@]}"; do

        if [ -d "$item" ]; then
            rsync -a --delete "$item" "$destPath" || { sysLogger e "Failed copying "$item""; return 1; }
        else
            sysLogger e "Folder not found: "$item""
        fi
    done

    readmeCopy
}



editingUT(){
    local destPath="$gitClonePath/editingUT"
    local readme="$readmePath/editingUT.md"
    local kdenPath="$HOME/Nextcloud/Kden"
    local item folder

    #### Each folder is mirrored into the repo: rsync only copies what changed, --delete drops what was removed
    local kdenSources=(
        "EditingUT"
        "MusicForEditing"
        "Other"
        "Layout"
        "scripts"
        "Effects"
    )

    for item in "${kdenSources[@]}"; do
        folder="$kdenPath/$item"

        if [ -d "$folder" ]; then
            rsync -a --delete "$folder" "$destPath" || { sysLogger e "Failed copying folder: $folder"; return 1; }
        else
            sysLogger e "Folder not found: $folder"
        fi
    done

    #### Fedora KDE version: the window-layout file of the GNOME extension "Another Window Session Manager" is no longer copied
    #### (the extension does not exist on KDE). The copy already in the repo stays there until removed by hand.

    readmeCopy
}



newPc_Install(){
    local destPath="$gitClonePath/newPc_Install"
    local readme=""$readmePath"/newPc_Install.md"

    local sources=(
        "$HOME/Nextcloud/Linux/scripts/bash"
        "$HOME/Nextcloud/Linux/scripts/newPc"
    )

    for item in "${sources[@]}"; do

        if [ -d "$item" ]; then
            rsync -a --delete "$item" "$destPath" || { sysLogger e "Failed copying "$item""; return 1; }
        else
            sysLogger e "Folder not found: "$item""
        fi
    done

    readmeCopy
}


Games(){
    local destPath="$gitClonePath/Games"
    local readme=""$readmePath"/Games.md"

    local sources=(
        "$HOME/Nextcloud/Games"
    )

    for item in "${sources[@]}"; do

        if [ -d "$item" ]; then
            #### Copies INTO the repo root: repoRootMirror keeps .git*, README.md safe from --delete
            repoRootMirror "$item" "$destPath" || { sysLogger e "Failed copying "$item""; return 1; }
        else
            sysLogger e "Folder not found: "$item""
        fi

    done

    readmeCopy
}


HelperScripts(){
    local destPath="$gitClonePath/HelperScripts"
    
    fetchPull "$destPath" || { sysLogger e "fetchPull failed for "$destPath"" ; return 1; } 
}

#############################################################


main(){
    local pRepo fRepo

    #### Nextcloud contents always wins over git's
    #### To avoid creating confusion, function and repo name MUST match 
    local pushRepo=(
        codiumSync
        All_Scripts
        editingUT
        newPc_Install
        Games
    )

    #### Keep local up to date with git's
    local fetchRepo=(
        HelperScripts
    )


    for pRepo in "${pushRepo[@]}"; do
        local path="$gitClonePath/$pRepo"

        if ! fetchPull "$path"; then
            sysLogger w "Skipping $pRepo: not in sync with GitHub"
            continue
        fi
        
            "$pRepo" || { sysLogger e "Function failed: "$pRepo"" ; return 1; }
        
        commitPush "$path"

    done 


    sysLogger i "Fetch-pull only repos"
    for fRepo in "${fetchRepo[@]}"; do
        sysLogger i "Updating "$fRepo""
        "$fRepo" || { sysLogger e "Function failed: "$fRepo"" ; return 1; }
    done
}





arg="${1:-}"

action="${2:-}"

if [ -z "$arg" ]; then
    sysLogger w "No arguments passed, exiting"; exit 1
fi

case "$arg" in
    codiumSync) func=codiumSync ;;
    All_Scripts) func=All_Scripts ;;
    editingUT) func=editingUT ;;
    newPc_Install) func=newPc_Install ;;
    Games) func=Games ;;
    HelperScripts) func=HelperScripts ;;
    
    all|main) func=main ;;

    *) sysLogger e "Invalid repo selected"; exit 1 ;;
esac

if [ -n "$action" ]; then
    
    case "$action" in 

        fetchPull|fetch|pull) action="fetchPull" ;;
        commitPush|commit|push) action="commitPush" ;;

        *) sysLogger e "Invalid action passed, ignoring"; action="" ;;

    esac

fi

#### The actions are already bundled into main
if [ "$func" == 'main' ] || [ -z "$action" ]; then
    sysLogger i "Executing $func" 
    "$func" || { sysLogger e "$func failed"; exit 1 ; }
else
    sysLogger i "Executing "$action" "$gitClonePath/$func"" 
    "$action" "$gitClonePath/$func" || { sysLogger e ""$func" failed"; exit 1 ; }
fi