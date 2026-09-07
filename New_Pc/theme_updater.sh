#!/bin/bash
set -euo pipefail

kindLogger(){ 
	local logBody="${1:-}"

	if [ -z "$logBody" ]; then return 1; fi

	echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $logBody" ; 
} 


setTheme(){
	local type="${1:-}"
	local gSet="${2:-}"
	local name="${3:-}"
	local workingFolder="$HOME/.local/share"

	if [ -z "$type" ] || [ -z "$name" ]; then kindLogger "No values inserted"; return 1; fi

	case "$type" in

		icon) ;;
		theme);;
		font)  ;;
		cursor) ;; #### Still falls under 'icons'
		gtk) ;;

		*) { kindLogger "Invalid option"; return 1 ; }

	esac

	#### Append the 's' so that the type can be used in the command too
	workingFolder="$workingFolder"/"$type"s
	
	if [ -d "$workingFolder"/"$name" ]; then
		kindLogger ""$workingFolder"/"$name" found. Setting it as default "$type""
		gsettings set org.gnome.desktop.interface "$gSet"-theme "$name"; return 0
	
	else 
		kindLogger ""$workingFolder"/"$name" NOT found. Nothing has been modified"; return 1
	fi
}


#### Make sure the folder exists
iconDir="$HOME/.local/share/icons"
themeDir="$HOME/.local/share/themes"
fontDir="$HOME/.local/share/fonts"
mkdir -p "$iconDir" "$themeDir" "$fontDir"

gtkConfigFolder="$HOME/.config"


# sudo apt install -y adwaita gnome-themes-extra gnome-icon-theme hicolor-icon-theme humanity-icon-theme

kindLogger "Installing themes & icons"
sudo apt-get install -y adwaita-icon-theme gnome-themes-extra \
	papirus-icon-theme breeze-cursor-theme \
	fonts-dejavu-core fonts-dejavu-extra fonts-comic-neue \


kindLogger "Updating the cache for each theme"

# gtk-update-icon-cache /usr/share/icons/hicolor
gtk-update-icon-cache /usr/share/icons/Adwaita
gtk-update-icon-cache /usr/share/icons/Papirus-Dark




#### Automate setup - themes
kindLogger "Enaging setTheme function"

####		type		gSet		name
setTheme	"icon"	  	"icon"  	"Papirus-Dark"
setTheme	"icon"	  	"cursor"	"breeze_cursors"
setTheme	"theme"	 	"gtk"	   	"Adwaita-dark"

kindLogger "setTheme function executed"


# gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
# gsettings set org.gnome.desktop.interface cursor-theme "breeze_cursors"
# gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"





kindLogger "Creating $gtkConfigFolder for both gtk 3 and 4"

mkdir -p "$gtkConfigFolder/gtk-4.0" 
mkdir -p "$gtkConfigFolder/gtk-3.0" 

kindLogger "Creating and setting terminal padding"
terminalPadding="VteTerminal,
TerminalScreen,
vte-terminal {
	padding: 20px 20px 20px 20px;
	-VteTerminal-inner-border: 20px 20px 20px 20px;}"
echo "$terminalPadding" > "$gtkConfigFolder/gtk-3.0/gtk.css"
echo "$terminalPadding" > "$gtkConfigFolder/gtk-4.0/gtk.css"


kindLogger "Force dark mode to avoid gtk compatibility issues"
echo -e "[Settings]\ngtk-application-prefer-dark-theme = true" > "$gtkConfigFolder/gtk-3.0/settings.ini"
echo -e "[Settings]\ngtk-application-prefer-dark-theme = true" > "$gtkConfigFolder/gtk-4.0/settings.ini"


kindLogger "Set the background to a solid black across theme types"
# gsettings set org.gnome.desktop.background picture-uri-dark "$HOME/Nextcloud/Linux/SysThemes/Themes/black_Bg.png"
gsettings set org.gnome.desktop.background picture-uri	  ''
gsettings set org.gnome.desktop.background picture-uri-dark ''
gsettings set org.gnome.desktop.background primary-color	'#000000'
gsettings set org.gnome.desktop.background color-shading-type 'solid'   


#### Automate setup
interface="DejaVu Sans Condensed"
mono="DejaVu Sans Mono"
editors="DejaVu Sans Mono"

kindLogger "Setup to be confirmed:
interface = $interface
mono = $mono
editors = $editors"

read -p ''

exit 0

fc-cache -fv > /dev/null

#### Main font GNOME Shell uses
gsettings set org.gnome.desktop.interface font-name "$interface 11"

#### Gedit , LibreOffice (if they respect GTK rules)
gsettings set org.gnome.desktop.interface document-font-name "$mono 12"

#### Anything requiring a mono-spaced font (GNOME Terminal, code editors...)
gsettings set org.gnome.desktop.interface monospace-font-name "$editors 12"