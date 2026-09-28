#!/bin/bash
set -uo pipefail

kindLogger(){ 
    local logBody="${1:-}"

    if [ -z "$logBody" ]; then return 1; fi

    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $logBody" ; 
} 


exec > >(tee -a /var/log/$(date "+%Y-%m-%d_%H-%M-%S")_newpc-setup.log) 2>&1


user=${SUDO_USER:-$(whoami)}


[ "${SUDO_USER:-}" ] || { kindLogger "Run via sudo as your normal user, not as root" >&2; exit 1; }

user="$SUDO_USER"

[[ "$user" =~ ^[a-z_][a-z0-9_-]*$ ]] || { kindLogger "Unsafe username: $user" >&2; exit 1; }

id -- "$user" >/dev/null 2>&1 || { kindLogger "No such user: $user" >&2; exit 1; }


#### Resolve the real user's home and run the installer as that user, escalating per-command
userHome=$(getent passwd "$user" | cut -d: -f6)


cat <<EOF
The script is about to:
  • clone 'Fred-ITUX/newPc_Install' into $userHome
  • run 'newPc_Install.sh', which:
    > installs ~50 apt packages
    > installs ~35 flatpak
    > purges ~65 packages 
    and REBOOTS the system automatically at the end
EOF
read -r -p "Type 'yes' to proceed: " ans
[ "$ans" = yes ] || exit 1


timeout 10 getent hosts github.com >/dev/null || { kindLogger "No network / DNS. Aborting" >&2; exit 1; }


#### Install git if not already present
apt update || { kindLogger "Apt update failed, not continuing with stale package index"; exit 1; }
apt install git -y || { kindLogger "Git install failed. No point in keeping execution, exiting"; exit 1; }



[ -d "$userHome" ] || { kindLogger "No home dir for $user" >&2; exit 1; }

#### Clone repo script && script exec 
sudo -u "$user" git clone --depth 1 "$repo" "$userHome/newPc_Install"

sudo -u "$user" find "$userHome/newPc_Install" -type f -name '*.sh' -exec chmod +x {} +

sudo -u "$user" "$userHome/newPc_Install/newPc_Install.sh"