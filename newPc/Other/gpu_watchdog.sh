#!/bin/bash


####        Monitors

#### Entries matching GPU/DRM-related
#### journalctl -f | grep -iE 'amdgpu|drm|gpu'

#### Kernel-specific messages
#### journalctl -kf | grep -iE 'amdgpu|drm|gpu'

#### Broader monitoring
#### journalctl -kf | grep -iE 'amdgpu|drm|pwm|hwmon'


################################################################

fanSpeedSet(){
    speedSet="${1:-100}"

    for hw in "$hwmonPath"/hwmon*; do
        if grep -q "amdgpu" "$hw/name"; then pathSource="$hw" ; break ; fi
    done
    
    fanFile="$pathSource/pwm1"

    if [ -z "$pathSource" ] ; then echo "[ERROR] $(date "+%Y-%m-%d %H:%M:%S") - GPU fan speed issue: missing path pathSource=$pathSource." >> "$gpuErrorLog"; return 1
    else  currentMode=$(cat "$pathSource/pwm1_enable"); fi


    if [ -z "$currentMode" ] ; then echo "[ERROR] $(date "+%Y-%m-%d %H:%M:%S") - GPU fan speed issue missing mode currentMode=$currentMode. Fallback to 100% speed" >> "$gpuErrorLog"; return 1 ;fi



    #### Check whether manual is set, if not give it time to apply -- 1 MANUAL / 2 AUTO / 0 OFF
    #### Writable without sudo thanks to the udev rule (enableGpuFanUdev in enable_sudo_whitelist.sh)
    if [ "$currentMode" != "1" ]; then
        if ! echo 1 > "$pathSource/pwm1_enable"; then
            echo "[ERROR] $(date "+%Y-%m-%d %H:%M:%S") - GPU fan: cannot set manual mode on $pathSource/pwm1_enable" >> "$gpuErrorLog"
            return 1
        fi
        sleep 3
    fi


    #### PWM ≈ percentage × 2.58
    case "$speedSet" in 
        
        30) speedSet="80";;
        35) speedSet="92";;
        40) speedSet="105";;
        45) speedSet="116";;
        50) speedSet="129";;
        55) speedSet="142";;
        60) speedSet="155";;
        65) speedSet="168";;
        70) speedSet="181";;
        75) speedSet="193";;
        80) speedSet="206";;
        85) speedSet="220";;
        90) speedSet="232";;
        95) speedSet="245";;
        100) speedSet="255";;

        *) speedSet="255";; 
    esac

    if ! echo "$speedSet" > "$pathSource/pwm1"; then
        echo "[ERROR] $(date "+%Y-%m-%d %H:%M:%S") - GPU fan: cannot write $pathSource/pwm1" >> "$gpuErrorLog"
        return 1
    fi
}


gpuErrorLog="$HOME/Nextcloud/Linux/log/GPU_ERROR.log"

#### Fedora KDE version of Hardware_Info/gpu_watchdog.sh: only this block differs.
#### The amdgpu fan folder is found by name: "card1" depends on the order the kernel finds the GPUs, and can be card0 on another kernel
#### /sys/class/hwmon/hwmonN is a link into the GPU's own device folder: its parent is the same folder the old fixed path pointed to
hwmonPath=""
for hw in /sys/class/hwmon/hwmon*; do
    if [ "$(cat "$hw/name" 2>/dev/null)" = "amdgpu" ]; then
        hwmonPath="$(dirname "$(readlink -f "$hw")")"
        break
    fi
done

if [ -z "$hwmonPath" ]; then
    echo "[ERROR] $(date "+%Y-%m-%d %H:%M:%S") - GPU watchdog: no amdgpu fan found under /sys/class/hwmon" >> "$gpuErrorLog"
fi

#### File that the feeds the reader for the top bar
gpuFanSpeed="${XDG_RUNTIME_DIR}/out_gpuFanSpeed.txt"



sysInfoCache="${XDG_RUNTIME_DIR}/sysInfo.cache"
if [ -s "$sysInfoCache" ]; then
    source "$sysInfoCache" || { echo "[ERROR] Sourcing file "$sysInfoCache" failed" >> "$gpuErrorLog" ; }
else
    echo -e "[CRITICAL ERROR] Cache config missing: "$sysInfoCache"" >> "$gpuErrorLog"
    echo "?" > "$gpuFanSpeed"
fi




tempRangeMid=55
tempRangeMax=70

# currentSpeed="$(( $(cat "$hwmonPath/$(ls "$hwmonPath"/ | grep "hwmon")"/pwm1) * 100 / 255 ))"

#### Invalid guard -- only numbers are valid; else currentSpeed remains empty and triggers the alarm later
currentSpeed=""
pwmRaw=$(cat "$hwmonPath"/hwmon*/pwm1 2>/dev/null)

if [[ "$pwmRaw" =~ ^[0-9]+$ ]]; then
    currentSpeed=$(( pwmRaw * 100 / 255 ))
fi


gpuTemp=$(sensors | awk '/edge/ {gsub(/[^0-9.]/,"",$2); split($2,a,"."); print a[1]}')

if [ -z "$currentSpeed" ]; then echo "[ERROR] $(date "+%Y-%m-%d %H:%M:%S") - GPU watchdog issue: current speed missing. Fallback to 90% speed" >> "$gpuErrorLog"; fanSpeedSet 90 ; echo "?" > "$gpuFanSpeed" ; sleep 60 ; exit 0 ; fi

if [ -z "$gpuTemp" ]; then echo "[ERROR] $(date "+%Y-%m-%d %H:%M:%S") - GPU watchdog issue: current gpu temp missing. Fallback to 90% speed" >> "$gpuErrorLog"; fanSpeedSet 90 ; echo "?" > "$gpuFanSpeed" ; sleep 60  ; exit 0 ; fi


override=""
speedMin="35"
speedMid="75"
speedMax="100"


# override="90"
# override="75"


if [ -n "$override" ]; then speedMin="$override" ; speedMid="$override" ; fi


if [ "$gpuTemp" -ge "$tempRangeMax" ]; then 
    if [ "$currentSpeed" != "$speedMax" ]; then
        if ! fanSpeedSet "$speedMax"; then exit 1; fi
    fi


elif [ "$gpuTemp" -le "$tempRangeMid" ]; then 
    if  [ "$currentSpeed" != "$speedMin" ]; then
        if ! fanSpeedSet "$speedMin"; then exit 1; fi
    fi
    

elif [ "$gpuTemp" -lt "$tempRangeMax" ] && [ "$gpuTemp" -ge "$tempRangeMid" ]; then
    if [ "$currentSpeed" != "$speedMid" ]; then
        if ! fanSpeedSet "$speedMid"; then exit 1; fi
    fi

fi


# echo "$currentSpeed" > "$gpuFanSpeed"

#### Run only if the cache has been correctly read
#### A failed write only affects the top bar: log it, never fail the script (the fan is already set)
if declare -F atomicWrite >/dev/null; then
    if ! atomicWrite "out_gpuFanSpeed.txt" "${XDG_RUNTIME_DIR}" "$currentSpeed"; then
        echo "[ERROR] $(date "+%Y-%m-%d %H:%M:%S") - GPU watchdog: top bar file not updated (atomicWrite failed, is ${XDG_RUNTIME_DIR} full?)" >> "$gpuErrorLog"
    fi
fi