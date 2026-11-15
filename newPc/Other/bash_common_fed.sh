#!/bin/bash

################################################################################################
####
####    TEMPORARY REVIEW FILE -- Fedora KDE versions of functions from bash/bash_common.sh
####
####    Not sourced by anything. Review each function, then replace the one with the same name
####    in bash_common.sh (the rest of that file works on Fedora as it is).
####
####    Functions in this file:
####      > get_osname     drops the "(... Edition)" part of Fedora's PRETTY_NAME
####      > sysInfoCache   writes every value shell-quoted (fixes the status bar scripts on Fedora)
####
####    Checked, no change needed: createVenv works on Fedora (venv is part of python3 there);
####    only its hint "is python3-venv installed?" is Debian wording.
####
################################################################################################


get_osname(){
    source /etc/os-release
    local sourcedName="${PRETTY_NAME,,}"

    #### Fedora: PRETTY_NAME ends with the edition in parentheses, e.g. "Fedora Linux 45 (KDE Plasma Desktop Edition)".
    #### Dropped here, so osname stays short ("fedora_45") and has no shell special characters
    sourcedName="${sourcedName%% (*}"
    
    local o=$( stringNormalizeLow "$sourcedName" | sed 's/linux//' )
    osname=$( stringNormalizeNoBlanks "$o" )
}


sysInfoCache(){ #### Caches system info to avoid multiple executions of the same functions
    local user osName hostPc lxPath pyPath
    local body=() 

    userCheck  || { echo "userCheck failed" ; return 1;  }
    get_osname || { echo "get_osname failed" ; return 1;  }

    hostPc="$pc"
    osName="$osname"
    user=$(whoami)
    
    lxPath="$LXscripts"
    pyPath="$PYscripts"

    #### Names of the variables written to the cache. Each value goes through printf %q (shell-quoted),
    #### so a value with spaces, parentheses or other special characters can never break the `source` of the cache.
    #### (On Fedora the old unquoted osName=fedora_45_(...) made every reader of the cache fail with a syntax error)
    local vars=( 
        hostPc 
        hostMain 
        osName 
        user 
        lxPath
        pyPath 
        pid_log_file
        )
    local name line
    
    local functionsToCache=( 
        "fileReader"
        "sysLogger"
        "get_formatted_date"
        "get_date_comparison"
        "get_file_date"
        "get_logger_date"
        "raiseAlarm"
        "atomicWrite"
        )

    for name in "${vars[@]}"; do 
        printf -v line '%s=%q' "$name" "${!name}"       #### ${!name} = value of the variable called $name
        body+=$( echo -e "\n$line\n" )  
    done


    for func in "${functionsToCache[@]}"; do
        body+=$( echo -e "\n\n$(typeset -fp $func)\n\n" )  
    done

    atomicWrite "sysInfo.cache" "${XDG_RUNTIME_DIR}" "$body" || { echo "ERROR - atomicWrite failed" ; return 1 ; }
}
