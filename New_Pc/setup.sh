#!/bin/bash
set -euo pipefail

kindLogger(){ 
    local logBody="${1:-}"

    if [ -z "$logBody" ]; then return 1; fi

    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $logBody" ; 
} 



exec > >(tee -a /var/log/$(date "+%Y-%m-%d_%H-%M-%S")_newpc-setup.log) 2>&1


user=${SUDO_USER:-$(whoami)}

repo="https://github.com/Fred-ITUX/newPc_Install"

[ "${SUDO_USER:-}" ] || { kindLogger "Run via sudo as your normal user, not as root" >&2; exit 1; }

user="$SUDO_USER"

[[ "$user" =~ ^[a-z_][a-z0-9_-]*$ ]] || { kindLogger "Unsafe username: $user" >&2; exit 1; }

id -- "$user" >/dev/null 2>&1 || { kindLogger "No such user: $user" >&2; exit 1; }

sudoers_file="/etc/sudoers.d/10-${user}-nopasswd"




cat <<EOF
The script is about to:
  • grant $user passwordless sudo for ALL commands (permanent)
  • clone Fred-ITUX/newPc_Install into $userHome
  • run newPc_Install.sh, which installs ~50 apt + 35 flatpak packages,
    purges ~65 packages, creates a swapfile, and REBOOTS
EOF
read -r -p "Type 'yes' to proceed: " ans
[ "$ans" = yes ] || exit 1




#### Check a candidate file in isolation, then install atomically
tmp=$(mktemp) || exit 1

printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$user" > "$tmp"

if visudo -cf "$tmp"; then
    install -m 0440 -o root -g root "$tmp" "$sudoers_file"
else
    kindLogger "Refusing to install invalid sudoers rule" >&2; rm -f "$tmp"; exit 1
fi

rm -f "$tmp"


timeout 10 getent hosts github.com >/dev/null || { kindLogger "No network / DNS. Aborting" >&2; exit 1; }


#### Install git if not already present
apt update || { kindLogger "Apt update failed, not continuing with stale package index"; exit 1; }
apt install git -y || { kindLogger "Git install failed. No point in keeping execution, exiting"; exit 1; }


#### Resolve the real user's home and run the installer as that user, escalating per-command
userHome=$(getent passwd "$user" | cut -d: -f6)

[ -d "$userHome" ] || { kindLogger "No home dir for $user" >&2; exit 1; }

#### Clone repo script && script exec 
sudo -u "$user" git clone --depth 1 "$repo" "$userHome/newPc_Install"

sudo -u "$user" find "$userHome/newPc_Install" -type f -name '*.sh' -exec chmod +x {} +

sudo -u "$user" "$userHome/newPc_Install/newPc_Install.sh"