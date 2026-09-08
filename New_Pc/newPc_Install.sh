#!/bin/bash

start_time=$(date '+%d-%m-%Y___%H-%M-%S')

StartDiskSpace=$(df -h)

pathFile="$HOME/newPC_$start_time.txt"


###########################################################################################



safetyUpdateCheck(){
	sudo dpkg --configure -a 
	sudo apt --fix-broken install -y  
	sudo apt update
	sudo apt full-upgrade -y 
	sudo apt autoremove -y 
	sudo apt clean
}



#### Installs one package at a time on purpose, dependencies are checked for each package and failures are recorded
installLoop(){
    local kind="$1"
    local -n pkgList="$2"

    local total="${#pkgList[@]}"
    local failed=()
    local n=0
    local pkg rc

    if [ "$kind" != apt ] && [ "$kind" != flatpak ]; then
        kindLogger "[FAILED] installLoop: unknown installer '$kind'\n"
        return 1
    fi

    for pkg in "${pkgList[@]}"; do
        n=$(( n + 1 ))
        kindLogger "• [$n/$total] Installing $pkg\n"

        rc=0
        case "$kind" in
            apt)     sudo apt-get install -y "$pkg"    || rc=$? ;;
            flatpak) flatpak install flathub -y "$pkg" || rc=$? ;;
        esac

        if [ "$rc" -eq 0 ]; then
            kindLogger "[DONE] $pkg\n"
        else
            kindLogger "[FAILED]: $pkg (exit $rc)\n"
            failed+=( "$pkg" )
        fi
    done


    {
        echo -e "\n\n\t+-------------------------------------------+"
        echo -e "\t  $kind: $(( total - ${#failed[@]} ))/$total installed, ${#failed[@]} failed"
        if [ "${#failed[@]}" -gt 0 ]; then printf '\t[FAILED] %s\n' "${failed[@]}"; fi
        echo -e "\t+-------------------------------------------+\n"
    } 

	kindLogger "Loop executed"
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
			apt)	 sudo apt purge -y "$pkg"		   || rc=$? ;;
		esac

		if [ "$rc" -eq 0 ]; then
			kindLogger "[DONE] $pkg\n"
		else
			kindLogger "[FAILED]: $pkg (exit $rc)\n"
			failed+=( "$pkg" )
		fi
	done


	{
		echo -e "\n\n\t+-------------------------------------------+"
		echo -e "\t  $kind: $(( total - ${#failed[@]} ))/$total purged, ${#failed[@]} failed"
		if [ "${#failed[@]}" -gt 0 ]; then printf '\t[FAILED] %s\n' "${failed[@]}"; fi
		echo -e "\t+-------------------------------------------+\n"
	} 

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
AVG_GB_NEEDED=40
avail=$(df --output=avail -BG / | tail -1 | tr -dc '0-9')
[ "${avail:-0}" -ge "$AVG_GB_NEEDED" ] || { kindLogger "ERROR - Need "$AVG_GB_NEEDED"GB free on /, have ${avail}GB"; exit 1; }


kindLogger "Checking internet connectivity, the script will abort if the systems results offline."
timeout 10 getent hosts archive.ubuntu.com >/dev/null || { kindLogger "ERROR - No network. Aborting."; exit 1; }



echo -e "\n\n
	+--------------------------+ 

			REQUIREMENTS

	+--------------------------+

    > An average of "$AVG_GB_NEEDED"GB gonna be used
    > The system passed the network check, online status confirmed
    > A big set of apt and flatpak apps will be installed
    > Cinnamon* will be purged along with most gnome pre-installed apps
	> The system will automatically reboot at the end \n"

read -r -p "Press Enter to continue..."
kindLogger "Continuing..."



touch "$pathFile"

if [ ! -f "$pathFile" ]; then
	kindLogger "File creation failed $pathFile\nAvoiding deploy without a log, aborting."; exit 1
fi

kindLogger "Setup complete"




kindLogger "Starting gnome install, expect prompts"

sudo apt-get install gnome -y || { kindLogger "ERROR - Gnome installation failed, exiting" ; exit 1; } 



export DEBIAN_FRONTEND=noninteractive #### prompt avoid

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
	safetyUpdateCheck || { kindLogger "ERROR - first updater failed, aborting before continuing" ; return 1 ; }
	echo -e "\n\n\n
	+---------------------------------------------------------+ 

			END UPDATE, FULL UPGRADE AND CHECK INSTALLS

	+---------------------------------------------------------+\n\n\n"



	##################################################################
	##################################################################



	echo -e "\n\n\n
			+------------------------------------------+ 

					REPOSITORY && APT APPS BEGIN

			+------------------------------------------+\n\n\n"


	appPackages=(
		#### Devtools
		python3-psutil						  #### required for scripts
		wget 
		curl 
		git 
		gh									  #### github https session login
		jq									  #### lightweight, flexible command-line JSON processor
		docker.io 
		docker-compose

		#### Utilities
		flatpak
		smartmontools						   #### temp check
		gufw									#### firewall
		htop									#### task manager
		redshift								#### brightness and night light -- X11
		xdotool								 #### X11 -- window / keyboard utilities
		ddcutil								 #### change monitors brightness
		fzf									 #### terminal interactive selection
		vlc
		gedit 
		piper								   #### logitech mouse software
		gparted								 #### disk utility
		nemo									#### file explorer
		moreutils							   #### ts command and other ut
		rar
		p7zip-full 
		p7zip-rar
		tree									#### ls tree
		wine
		bluez 
		bluez-tools
		font-manager

		#### Audio
		pulseaudio
		pavucontrol 
		# pulseeffects
		pulseaudio-module-bluetooth 

		#### Editing
		ffmpeg
		mediainfo 
		mkvtoolnix 
		mpv 

		#### Gaming
		steam-devices
		vainfo 
		mesa-utils
		gamemode
		zram-tools 
		cpufrequtils 
		radeontop
		default-jre
	)


	kindLogger "Wine architecture safety setup for i386"
	sudo dpkg --add-architecture i386 && sudo apt update || { kindLogger "ERROR - wine architecture" ; return 1; } 


	kindLogger "Engaging installLoop: apt"

	installLoop apt appPackages



	echo -e "\n\n\n
			+----------------------------------------+ 

					REPOSITORY && APT APPS END

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
		
		#### Utilities
		com.github.tchx84.Flatseal/x86_64/stable					#### flatseal - flatpak permissions
		app/com.mattjakeman.ExtensionManager/x86_64/stable		  #### GNOME - Extension Manager
		app/com.vscodium.codium/x86_64/stable					   #### VS Codium
		com.nextcloud.desktopclient.nextcloud					   #### Nextcloud desktop client
		app/com.usebottles.bottles/x86_64/stable					#### Bottles - WINE client
		app/net.christianbeier.Gromit-MPX/x86_64/stable			 #### draw on screen
		page.codeberg.libre_menu_editor.LibreMenuEditor			 #### app info and editor
		app/com.github.hluk.copyq/x86_64/stable					 #### Clipboard manager
		
		#### Editing
		com.obsproject.Studio									   #### OBS
		org.audacityteam.Audacity								   #### Audacity
		org.nomacs.ImageLounge									  #### Photo viewer / light editor
		org.gimp.GIMP/x86_64/stable								 #### Gimp
		# app/org.musescore.MuseScore/x86_64/stable				   #### music sheet editor
		
		#### Apps	
		app/org.kde.okular/x86_64/stable							#### Pdf reader / highlight
		app/com.discordapp.Discord/x86_64/stable
		app/org.keepassxc.KeePassXC/x86_64/stable				   #### Database DB
		org.libreoffice.LibreOffice 
		org.onlyoffice.desktopeditors/x86_64/stable				 
		
		#### Gaming
		com.valvesoftware.Steam 
		com.valvesoftware.Steam.CompatibilityTool.Proton-GE
		# net.pcsx2.PCSX2											 #### Ps2
		# org.ppsspp.PPSSPP										   #### PsP
		# net.kuribo64.melonDS/x86_64/stable						  #### Ds
		# app/io.mgba.mGBA/x86_64/stable							  #### Gba
	)

	kindLogger "Flathub remote check"
	sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || { kindLogger "ERROR - Flatpak 'remote-add flathub' failed, exiting"; return 1; }


	kindLogger "\nEngaging installLoop: flatpak"

	installLoop flatpak flatpakAppPackages




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


	sudo apt purge "cinnamon*" -y || { kindLogger "ERROR - apt purge cinnamon" ; return 1; }

	appToPurge=(
			"thunderbird*" 
			"libreoffice*"
			cheese 
			hypnotix 
			rhythmbox 
			aisleriot 
			celluloid  
			hexchat 
			onboard 
			mahjongg 
			pix 
			remmina 
			five-or-more 
			four-in-a-row 
			drawing 
			xed 
			lightsoff 
			hitori 
			quadrapassel 
			shotwell 
			swell-foop
			avahi-daemon 
			tali 
			evolution 
			evince 
			iagno 
			warpinator
			mintchat
			baobab
			xreader
			totem
			eog
			postfix
			"timeshift*"
			mintinstall
			mintwelcome
			"mintupdate*" 
			mintmenu 
			mintreport
			blueman
			transmission-gtk 
			webapp-manager
			simple-scan
			system-config-printer
			gnome-software
			gnome-system-monitor
			gnome-calendar
			gnome-mahjongg 
			gnome-mines 
			gnome-sudoku 
			gnome-todo 
			gnome-chess 
			gnome-2048 
			gnome-contacts 
			gnome-maps 
			gnome-tetravex 
			gnome-music 
			gnome-nibbles 
			gnome-klotski 
			gnome-robots 
			gnome-weather 
			gnome-remote-desktop 
			gnome-taquin 
	)

	purgeLoop apt appToPurge

	sudo apt-get install nemo -y  || { kindLogger "ERROR - nemo install failed" ; return 1; } #### It gets removed from the cinnamon purge

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


	end_time=$(date '+%d-%m-%Y___%H-%M-%S')
	

	EndDiskSpace=$(df -h)


	echo -e "\n\n
					+------------------+ 

							INFO

					+------------------+\n\n"

	echo -e "Start time:\t$start_time"
	echo -e "End time  :\t$end_time"

	echo -e "\n\nStart disk space:\n$StartDiskSpace"
	echo -e "End disk space	  :\n$EndDiskSpace \n\n"


} >> "$pathFile" 2>&1 


sync || { kindLogger "ERROR - Sync failed" ; } #### Synchronize cached writes to persistent storage


if [ "${#failedApt[@]}" -eq 0 ] && [ "${#failedFlatpak[@]}" -eq 0 ]; then

	autoRebootDelay=10
	while ((autoRebootDelay >= 0)); do

		printf "\rAll operations succeeded, rebooting in "%02d"s" "$autoRebootDelay"
		sleep 1s
		(( autoRebootDelay-- ))
	done

	echo -e "\nRebooting..."; reboot

else
    echo "Completed with failures — review $pathFile"
    read -r -p "Reboot anyway? y/n " sendReboot; 
	
	if [ "$sendReboot" != "y" ]; then
		reboot	

	else echo -e "Not rebooting"
	fi
	
	[ "$a" = y ] && reboot
fi