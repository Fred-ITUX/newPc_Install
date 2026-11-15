#!/bin/bash

#### Must be launched by setup.sh: it provides the environment and the helper functions
if [ "$EUID" -ne 0 ] || [ -z "${realUser:-}" ] || ! declare -F asUser >/dev/null; then
    echo "[CRITICAL ERROR] Launch through setup.sh: sudo ./setup.sh $(basename "$0")" >&2; exit 1
fi


start_time=$(date '+%d-%m-%Y___%H-%M-%S')

StartDiskSpace=$(df -h)
diskSpace_before=$(df -BG / | awk 'NR==2 {gsub("G","",$4); print $4}')


# pathFile="$HOME/newPc_$start_time.log"
pathFile="$userHome/newPc_"$start_time".log"



###########################################################################################



safetyUpdateCheck(){
	local rc=0
	#### --refresh: re-download the package index first (apt update + full-upgrade in one step)
	sudo dnf upgrade --refresh -y     || rc=1
	sudo dnf autoremove -y            || rc=1
	sudo dnf clean packages
	return "$rc"
}



#### Installs one package at a time on purpose, dependencies are checked for each package and failures are recorded
installLoop(){
    local kind="$1"
    local -n pkgList="$2"

    local total="${#pkgList[@]}"
    local failed=()
    local n=0
    local pkg rc

    if [ "$kind" != dnf ] && [ "$kind" != flatpak ]; then
        kindLogger "[FAILED] installLoop: unknown installer '$kind'\n"
        return 1
    fi

    for pkg in "${pkgList[@]}"; do
        n=$(( n + 1 ))
        kindLogger "• [$n/$total] Installing $pkg\n"

        rc=0
        case "$kind" in
            dnf)     sudo dnf install -y "$pkg"        || rc=$? ;;
            flatpak) flatpak install flathub -y "$pkg" || rc=$? ;;
        esac

        if [ "$rc" -eq 0 ]; then
            kindLogger "[DONE] $pkg\n"
        else
            kindLogger "[FAILED]: $pkg (exit $rc)\n"
            failed+=( "$pkg" )
        fi
    done



	#### Retain all summaries to print them in one block at the end
    summary+=$(
        printf '\n\n\t+----------------------------------------------+\n\n'
        printf '\t\t  %s: %d/%d installed, %d failed\n' \
            "$kind" \
            "$(( total - ${#failed[@]} ))" \
            "$total" \
            "${#failed[@]}"
        if [ "${#failed[@]}" -gt 0 ]; then
            printf '\t\t[FAILED] %s\n' "${failed[@]}"
        fi
        printf '\n\t+----------------------------------------------+\n\n'
    )

    #### Uncomment to print the block at the end of the install loop
    #### {
    ####     echo -e "\n\n\t+-------------------------------------------+"
    ####     echo -e "\t  $kind: $(( total - ${#failed[@]} ))/$total installed, ${#failed[@]} failed"
    ####     if [ "${#failed[@]}" -gt 0 ]; then printf '\t[FAILED] %s\n' "${failed[@]}"; fi
    ####     echo -e "\t+-------------------------------------------+\n"
    #### } 

	kindLogger "Loop executed for kind "$kind""
    return "${#failed[@]}"
}



purgeLoop(){
	local kind="$1"
	local -n pkgList="$2"

	local total="${#pkgList[@]}"
	local failed=()
	local n=0
	local pkg rc

	for pkg in "${pkgList[@]}"; do
		n=$(( n + 1 ))
		kindLogger "• [$n/$total] Purging $pkg\n"

		rc=0
		case "$kind" in
			dnf)	 sudo dnf remove -y "$pkg"		   || rc=$? ;;
		esac

		if [ "$rc" -eq 0 ]; then
			kindLogger "[DONE] $pkg\n"
		else
			kindLogger "[FAILED]: $pkg (exit $rc)\n"
			failed+=( "$pkg" )
		fi
	done



	#### Retain all summaries to print them in one block at the end
    summary+=$(
        printf '\n\n\t+----------------------------------------------+\n\n'
        printf '\t\t  %s: %d/%d purged, %d failed\n' \
            "$kind" \
            "$(( total - ${#failed[@]} ))" \
            "$total" \
            "${#failed[@]}"
        if [ "${#failed[@]}" -gt 0 ]; then
            printf '\t\t[FAILED] %s\n' "${failed[@]}"
        fi
        printf '\n\t+----------------------------------------------+\n\n'
    )

    #### Uncomment to print the block at the end of the purge loop
	#### {
	#### 	echo -e "\n\n\t+-------------------------------------------+"
	#### 	echo -e "\t  $kind: $(( total - ${#failed[@]} ))/$total purged, ${#failed[@]} failed"
	#### 	if [ "${#failed[@]}" -gt 0 ]; then printf '\t[FAILED] %s\n' "${failed[@]}"; fi
	#### 	echo -e "\t+-------------------------------------------+\n"
	#### } 


	kindLogger "Loop executed"
	return "${#failed[@]}"
}



kindLogger(){ 
    local logBody="${1:-}"

    if [ -z "$logBody" ]; then return 1; fi

    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $logBody" ; 
} 



###########################################################################################


#### Check if available disk space is enough (based on an estimate over the last run)
AVG_GB_NEEDED=20
avail=$(df --output=avail -BG / | tail -1 | tr -dc '0-9')
[ "${avail:-0}" -ge "$AVG_GB_NEEDED" ] || { kindLogger "ERROR - Need "$AVG_GB_NEEDED"GB free on /, have ${avail}GB"; exit 1; }



#### Fedora KDE version of newPc/newPc_Install.sh: dnf + RPM Fusion instead of apt, KDE Plasma is already installed


echo -e "\n\n
	+--------------------------+ 

			REQUIREMENTS

	+--------------------------+

    > An average of "$AVG_GB_NEEDED"GB gonna be used
    > The system passed the network check, online status confirmed
    > A big set of dnf and flatpak apps will be installed
	> The system will automatically reboot at the end \n"

read -r -p "Press Enter to continue..."
kindLogger "Continuing..."



asUser touch "$pathFile"

if [ ! -f "$pathFile" ]; then
	kindLogger "File creation failed $pathFile\nAvoiding deploy without a log, aborting."; exit 1
fi

kindLogger "Setup complete"




#### No desktop install step: the Fedora KDE edition already ships Plasma and its login manager
#### No DEBIAN_FRONTEND either: dnf never prompts when called with -y

kindLogger "\n\nFrom now on the script is automatic.\n > To monitor the status check:\n$pathFile"


{

	echo -e "\n\n
			+------------------------+ 

					CODE START

			+------------------------+\n\n"

    kindLogger "Main code block initialized"
    

	echo -e "\n\n\n
	+-----------------------------------------------------------+ 

			START UPDATE, FULL UPGRADE AND CHECK INSTALLS

	+-----------------------------------------------------------+\n\n\n"
	safetyUpdateCheck || { kindLogger "ERROR - first updater failed, aborting before continuing" ; exit 1; }
	echo -e "\n\n\n
	+---------------------------------------------------------+ 

			END UPDATE, FULL UPGRADE AND CHECK INSTALLS

	+---------------------------------------------------------+\n\n\n"



	##################################################################
	##################################################################



	echo -e "\n\n\n
			+------------------------------------------+ 

					REPOSITORY && DNF APPS BEGIN

			+------------------------------------------+\n\n\n"


	#### RPM Fusion: needed for the full ffmpeg (Fedora's own ffmpeg-free lacks codecs) and for unrar
	kindLogger "Enabling RPM Fusion (free + nonfree)"
	fedoraVersion="$(rpm -E %fedora)"
	sudo dnf install -y \
		"https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedoraVersion}.noarch.rpm" \
		"https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedoraVersion}.noarch.rpm" \
		|| { kindLogger "ERROR - RPM Fusion setup failed, aborting (ffmpeg / unrar would fail later)" ; exit 1; }


	appPackages=(
		#### Devtools
		python3-psutil						  #### required for scripts
		wget2-wget							  #### provides /usr/bin/wget ("wget" alone is not a package on Fedora)
		curl 
		git 
		gh									  #### github https session login
		jq									  #### lightweight, flexible command-line JSON processor
        podman
        podman-compose
        podman-docker
        nmap                                    #### Network scanner
        inotify-tools                           #### Event driven file monitor

		#### Utilities
		flatpak
		smartmontools						   #### temp check
		firewalld							   #### firewall (Fedora default, configured by newPc_Scripts.sh firewallSetup)
		firewall-config						 #### firewall GUI (replaces gufw, not packaged on Fedora)
		grubby								  #### kernel command line editing (newPc_Scripts.sh grubSetup)
		htop									#### task manager
		ddcutil								 #### change monitors brightness
		lm_sensors							  #### `sensors`: gpu_watchdog.sh, pc_usage.py
		fzf									 #### terminal interactive selection
		gedit 
		piper								   #### logitech mouse software
		gparted								 #### disk utility
		nemo									#### file explorer (dolphin gets purged below)
		zenity								  #### dialogs used by the Nemo actions
		libnotify							   #### `notify-send`: raiseAlarm, Nemo actions
		moreutils							   #### ts command and other ut
		7zip									#### provides /usr/bin/7z (p7zip-full on Debian)
		unrar								   #### Fedora's 7z cannot open .rar (p7zip-rar on Debian) -- RPM Fusion nonfree
        pv
		tree									#### ls tree
		wine
		bluez 
		bluez-tools
		bluez-deprecated						#### hciconfig / hcitool (bluetoothDongleInfo)

		#### Audio
		pavucontrol 
		pulseaudio-utils						#### `pactl`: micStatus.sh, right_idx.sh

		#### Editing
		mediainfo 
		mkvtoolnix 

		#### Gaming
		steam-devices
		libva-utils							 #### vainfo
		glx-utils							   #### glxinfo (mesa-utils on Debian)
		gamemode
		kernel-tools							#### cpupower (cpufrequtils on Debian)
		radeontop
		java-25-openjdk						 #### default-jre on Debian

		#### Fonts (used by theme_updater.sh)
		dejavu-sans-fonts					   #### includes DejaVu Sans Condensed
		dejavu-sans-mono-fonts
		comic-neue-fonts
	)

	#### Dropped from the Mint list:
	####    redshift, xdotool        -> X11 only (KDE has Night Light built in)
	####    gufw, font-manager, rar  -> not packaged on Fedora
	####    zram-tools               -> Fedora already sets up zram swap (zram-generator-defaults)
	####    theme packages           -> Breeze Dark ships with Plasma

	#### Full ffmpeg from RPM Fusion. Fedora installs ffmpeg-free by default and the two conflict:
	#### `dnf swap` replaces one with the other in a single transaction
	kindLogger "Installing ffmpeg from RPM Fusion"
	ffmpegFailures=0
	if rpm -q ffmpeg-free >/dev/null 2>&1; then
		sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing || { kindLogger "[FAILED]: ffmpeg swap\n" ; ffmpegFailures=1; }
	else
		sudo dnf install -y ffmpeg --allowerasing || { kindLogger "[FAILED]: ffmpeg install\n" ; ffmpegFailures=1; }
	fi


	kindLogger "Engaging installLoop: dnf"

	installLoop dnf appPackages; dnfFailures=$?



	echo -e "\n\n\n
			+----------------------------------------+ 

					REPOSITORY && DNF APPS END

			+----------------------------------------+\n\n\n"



	##################################################################
	##################################################################



	echo -e "\n\n\n
			+--------------------------------+ 

					FLATPAK APPS BEGIN

			+--------------------------------+\n\n\n"


	flatpakAppPackages=(
		#### Browsers
		com.brave.Browser
		app/com.google.Chrome/x86_64/stable
		org.torproject.torbrowser-launcher
		app/org.chromium.Chromium/x86_64/stable

		#### Utilities
		com.github.tchx84.Flatseal/x86_64/stable					#### flatseal - flatpak permissions
		app/com.vscodium.codium/x86_64/stable					   #### VS Codium
		com.nextcloud.desktopclient.nextcloud					   #### Nextcloud desktop client
		#### app/com.usebottles.bottles/x86_64/stable					#### Bottles - WINE client
		#### app/net.christianbeier.Gromit-MPX/x86_64/stable			 #### draw on screen
		#### page.codeberg.libre_menu_editor.LibreMenuEditor			 #### app info and editor
		app/com.github.hluk.copyq/x86_64/stable					 #### Clipboard manager  -- TO CONFIRM on Fedora: clipboard access is limited on Wayland, KDE has Klipper built in
		app/org.videolan.VLC/x86_64/stable

		#### Editing
		com.obsproject.Studio									   #### OBS
		org.audacityteam.Audacity								   #### Audacity
		org.nomacs.ImageLounge									  #### Photo viewer / light editor
		org.gimp.GIMP/x86_64/stable								 #### Gimp
		#### app/org.musescore.MuseScore/x86_64/stable				   #### music sheet editor
		
		#### Apps	
		app/org.kde.okular/x86_64/stable							#### Pdf reader / highlight
		app/com.discordapp.Discord/x86_64/stable
		app/org.keepassxc.KeePassXC/x86_64/stable				   #### Database DB
        app/org.cryptomator.Cryptomator/x86_64/stable               #### Document encrypt synced by Nextcloud
		#### org.libreoffice.LibreOffice 
		org.onlyoffice.desktopeditors/x86_64/stable				 
        app/org.kde.kdenlive/x86_64/stable                         #### Video and audio editor

		
		#### Gaming
		com.valvesoftware.Steam 
		com.valvesoftware.Steam.CompatibilityTool.Proton-GE
		#### net.pcsx2.PCSX2											 #### Ps2
		#### org.ppsspp.PPSSPP										   #### PsP
		#### net.kuribo64.melonDS/x86_64/stable						  #### Ds
		#### app/io.mgba.mGBA/x86_64/stable							  #### Gba
	)

	kindLogger "Flathub remote check"
	sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || { kindLogger "ERROR - Flatpak 'remote-add flathub' failed, exiting"; exit 1; }


	kindLogger "\nEngaging installLoop: flatpak"

	# installLoop flatpak flatpakAppPackages
    installLoop flatpak flatpakAppPackages; flatpakFailures=$?



	echo -e "\n\n\n
				+------------------------------+ 

						FLATPAK APPS END

				+------------------------------+\n\n\n"



	##################################################################
	##################################################################



	echo -e "\n\n\n
				+--------------------------------------------+ 

						START PRE-INSTALLED APPS PURGE

				+--------------------------------------------+\n\n\n"


	#### TO CONFIRM on Fedora: review this list on the installed machine before the first run
	####    dnf list --installed | less        -> what is really there
	####    dnf remove --assumeno <package>    -> what a removal would drag out
	#### Checked on Fedora 45 (container, full KDE environment installed): none of these removes
	#### plasma-desktop, plasma-workspace, kwin or the login manager
	appToPurge=(
			dolphin					 #### replaced by nemo
			dolphin-plugins
			firefox					 #### Brave / Chrome / Chromium flatpaks are used instead
			"libreoffice*"			  #### OnlyOffice flatpak is used instead
			kmahjongg
			kmines
			kpat
			"kmail*"					#### KDE mail / PIM suite, unused. Dry run on Fedora 45 (real machine): these six remove 50 packages,
			kontact					 ####    none from Plasma; kleopatra and kdepim-addons go with them as dependents
			korganizer
			ktnef
			pim-sieve-editor
			akregator
			cups						#### no printer (same choice as on Mint). Also removes plasma-print-manager, hplip, gutenprint,
										####    ImageMagick and python3-pillow as unused dependencies (27 packages on Fedora 45)
			localsearch				 #### GNOME's file indexer (the old "tracker"): installed and autostarted on KDE too, nothing requires it
	)

	#### NEVER add avahi here: on Fedora 45 `dnf remove avahi` also removes plasma-desktop and plasma-workspace (90 packages).
	#### It is disabled instead (newPc_Scripts.sh, deamonsPurge)
	####
	#### Other pre-installed apps that can be removed without touching Plasma (dry run on Fedora 45, add the ones you want):
	####    kaddressbook (or the whole PIM stack at once: akonadi-server, 89 packages)
	####    elisa-player dragon k3b kamoso kolourpaint digikam krusader ktorrent neochat krdc krfb krdp kmouth skanpage qrca
	####    plasma-welcome plasma-discover abrt-desktop kde-connect kwrite

	purgeLoop dnf appToPurge


	echo -e "\n\n\n
				+------------------------------------------+ 

						END PRE-INSTALLED APPS PURGE

				+------------------------------------------+\n\n\n"



	###############################################################

	##########		DON'T ADD CODE AFTER THIS		  ##########

	###############################################################



	echo -e "\n\n\n
	+------------------------------------------------------------+ 

			START FINAL UPDATE, UPGRADE, CHECKS && CLEANUP

	+------------------------------------------------------------+\n\n\n"
    safetyUpdateCheck || { kindLogger "ERROR - second updater triggered an error"; }
	echo -e "\n\n\n
	+----------------------------------------------------------+ 

			END FINAL UPDATE, UPGRADE, CHECKS && CLEANUP

	+----------------------------------------------------------+\n\n\n"



	echo -e "\n\n\n\n\n\n
				+----------------------+ 

						END CODE

				+----------------------+\n\n\n"
    
    echo "${summary[@]}"


	end_time=$(date '+%d-%m-%Y___%H-%M-%S')
	

	EndDiskSpace=$(df -h)
	diskSpace_after=$(df -BG / | awk 'NR==2 {gsub("G","",$4); print $4}')


	echo -e "\n\n
					+------------------+ 

							INFO

					+------------------+\n\n"

	echo -e "> Start time:\t$start_time"
	echo -e "> End time  :\t$end_time"

	echo -e "\n\nStart disk space:\n$StartDiskSpace"
	echo -e "End disk space	  :\n$EndDiskSpace \n\n"


	echo "diskSpace_before: ${diskSpace_before} GB"
	echo "diskSpace_after:  ${diskSpace_after} GB"
	echo "diskSpace_used:   $((diskSpace_before - diskSpace_after)) GB"



} >> "$pathFile" 2>&1 


sync || { kindLogger "ERROR - Sync failed" ; } #### Synchronize cached writes to persistent storage


if [ "${dnfFailures:-1}" -eq 0 ] && [ "${ffmpegFailures:-1}" -eq 0 ] && [ "${flatpakFailures:-1}" -eq 0 ]; then

	autoRebootDelay=15
	while ((autoRebootDelay >= 0)); do

		printf "\rAll operations succeeded, rebooting in "%02d"s" "$autoRebootDelay"
		sleep 1s
		(( autoRebootDelay-- ))
	done

	echo -e "\nRebooting..."; reboot

else
    echo "Completed with failures — review $pathFile"
    read -r -p "Reboot anyway? y/n " sendReboot; 
	
	if [ "$sendReboot" = "y" ]; then
		reboot	

	else 
        echo -e "Not rebooting"
	fi
	
fi