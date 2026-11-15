#!/bin/bash
set -euo pipefail

echo "Comment out the exit in the code. Sudoer change is not something that can be executed by mystake"; exit 0


#### Fedora KDE version of sudoer/enable_sudo_whitelist.sh: dnf and firewalld rules instead of apt and ufw
#### Installs the passwordless-sudo whitelist. Run ONCE, as root.
#### Usage: enableSudoWhitelist <username>
enableSudoWhitelist(){
    local user="$1"
    local target=/etc/sudoers.d/10-whitelist
    local media="/media/$user"
    local tmp

    id -u "$user" >/dev/null || return 1

    tmp=$(mktemp) || return 1
    cat > "$tmp" <<POLICY
#### Exact commands only. No wildcards: in sudoers '*' also matches '/' and '..'
#### Must match sysUPD (bash_functions) character by character
Cmnd_Alias UPDATE = /usr/bin/dnf upgrade --refresh -y, \\
                    /usr/bin/dnf autoremove -y, \\
                    /usr/bin/dnf clean packages

#### Must match firewalldStatusCheck (startup_common) character by character
#### Read-only queries, plus the two self-heal actions: start firewalld, put the strict zone back as default
Cmnd_Alias FIREWALL = /usr/bin/firewall-cmd --state, \\
                      /usr/bin/firewall-cmd --get-default-zone, \\
                      /usr/bin/firewall-cmd --get-active-zones, \\
                      /usr/bin/firewall-cmd --zone=block --list-services, \\
                      /usr/bin/firewall-cmd --zone=block --list-ports, \\
                      /usr/bin/firewall-cmd --zone=block --list-all, \\
                      /usr/bin/firewall-cmd --set-default-zone=block, \\
                      /usr/bin/systemctl enable --now firewalld


#### Any /dev/sdX or /dev/nvmeXnY, with -A and nothing else (sudoers regex: ^...$)
Cmnd_Alias SMART = /usr/sbin/smartctl ^-A /dev/(sd[a-z]|nvme[0-9]+n[0-9]+)$

Defaults!SMART !log_allowed, !pam_session
$user ALL=(root:root) NOPASSWD: UPDATE, FIREWALL, SMART
POLICY

    visudo -cf "$tmp" || { rm -f "$tmp"; return 1; }
    install -o root -g root -m 0440 "$tmp" "$target"
    rm -f "$tmp"
    visudo -c
}


#### Lets <username> drive the GPU fan WITHOUT sudo: a udev rule gives the user's group write access to
#### pwm1 / pwm1_enable every time amdgpu creates them, whatever the card/hwmon numbers are
#### Usage: enableGpuFanUdev <username>     (run as root, like enableSudoWhitelist)
enableGpuFanUdev(){
    local user="$1"
    local target=/etc/udev/rules.d/90-amdgpu-fan.rules
    local group tmp file found=0 failed=0

    group=$(id -gn "$user") || return 1

    tmp=$(mktemp) || return 1
    cat > "$tmp" <<RULE
#### amdgpu fan control for $user, no sudo needed (see enableGpuFanUdev in enable_sudo_whitelist.sh)
ACTION=="add", SUBSYSTEM=="hwmon", ATTR{name}=="amdgpu", \\
  RUN+="/usr/bin/chgrp $group %S%p/pwm1 %S%p/pwm1_enable", \\
  RUN+="/usr/bin/chmod g+w %S%p/pwm1 %S%p/pwm1_enable"
RULE

    #### 1. Syntax check before anything is installed
    if ! udevadm verify "$tmp"; then rm -f "$tmp"; return 1; fi

    install -o root -g root -m 0644 "$tmp" "$target"
    rm -f "$tmp"

    #### 2. Apply now instead of waiting for a reboot: re-run the rules for the amdgpu hwmon only
    udevadm control --reload
    udevadm trigger --action=add --subsystem-match=hwmon --attr-match=name=amdgpu
    udevadm settle

    #### 3. Validate: the user must now be able to write both files of every amdgpu hwmon
    for file in /sys/class/hwmon/hwmon*/pwm1 /sys/class/hwmon/hwmon*/pwm1_enable; do
        if [ "$(cat "${file%/*}/name" 2>/dev/null)" != "amdgpu" ]; then continue; fi
        found=1

        if sudo -u "$user" test -w "$file"; then
            echo "OK   writable by $user: $file"
        else
            echo "FAIL not writable by $user: $file" >&2
            failed=1
        fi
    done

    if [ "$found" -eq 0 ]; then echo "FAIL no amdgpu fan found under /sys/class/hwmon" >&2; failed=1; fi
    return "$failed"
}


user=${SUDO_USER:-$(whoami)}
[ "${SUDO_USER:-}" ] || { echo "$user, run via sudo as your normal user, not as root" >&2; exit 1; }


#### "$USER" gives `root` when launched with sudo

echo "Is $(logname) the user that you want to grant whitelisted sudo to?"

read -p 'Type `yes` to continue: ' ans

if [ "$ans" = 'yes' ]; then
    enableSudoWhitelist "$(logname)"
    enableGpuFanUdev "$(logname)"
else
    echo "Not granting any sudo permissions, exiting."
fi