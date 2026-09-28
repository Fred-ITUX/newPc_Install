#!/bin/bash

###############################################################

#### This script is NOT intended to be run manually
#### It should be sourced and launched by setup.sh

###############################################################

#### Must be launched by setup.sh: it provides the environment and the helper functions
if [ "$EUID" -ne 0 ] || [ -z "${realUser:-}" ] || ! declare -F asUser >/dev/null; then
    echo "[CRITICAL ERROR] Launch through setup.sh: sudo ./setup.sh $(basename "$0")" >&2; exit 1
fi


#### Fix required when running the script using sudo
setTheme() {
    local type="$1"
    local gSet="$2"
    local name="$3"

    case "$type" in
        icon|cursor|theme) asUser gsettings set org.gnome.desktop.interface "${gSet}-theme" "$name" ;;

        *) sysLogger e "Invalid theme type: $type"; return 1 ;;
    esac
}




#### Make sure the folder exists
iconDir="$HOME/.local/share/icons"
themeDir="$HOME/.local/share/themes"
fontDir="$HOME/.local/share/fonts"
asUser mkdir -p "$iconDir" "$themeDir" "$fontDir"

gtkConfigFolder="$HOME/.config"


# sudo apt install -y adwaita gnome-themes-extra gnome-icon-theme hicolor-icon-theme humanity-icon-theme

sysLogger i "Installing themes & icons"
sudo apt-get install -y adwaita-icon-theme gnome-themes-extra \
	papirus-icon-theme breeze-cursor-theme \
	fonts-dejavu-core fonts-dejavu-extra fonts-comic-neue \


sysLogger i "Updating the cache for each theme"

# gtk-update-icon-cache /usr/share/icons/hicolor
timeout 20 gtk-update-icon-cache "/usr/share/icons/Adwaita"
timeout 20 gtk-update-icon-cache "/usr/share/icons/Papirus"
timeout 20 gtk-update-icon-cache "/usr/share/icons/Papirus-Dark"



sysLogger i "Creating symlinks into .local/share/ for flatpak ovverrides"



symLink(){
	sysLogger i "Creating symlking only if they do not already exist and if they are valid"
	local papirusDark="$HOME/.local/share/icons/Papirus-Dark"
	local breezeCursors="$HOME/.local/share/icons/breeze_cursors"
	local adwaita="$HOME/.local/share/icons/Adwaita"
	local adwaitaDark="$HOME/.local/share/themes/Adwaita-dark"
	local dejavu="$HOME/.local/share/fonts/dejavu"
	local comicNeue="$HOME/.local/share/fonts/comic-neue"

	if [ ! -e "$papirusDark" ] && [ ! -L "$papirusDark" ]; then asUser ln -s /usr/share/icons/Papirus-Dark "$papirusDark"; fi
	if [ ! -e "$breezeCursors" ] && [ ! -L "$breezeCursors" ]; then asUser ln -s /usr/share/icons/breeze_cursors "$breezeCursors"; fi
	if [ ! -e "$adwaita" ] && [ ! -L "$adwaita" ]; then asUser ln -s /usr/share/icons/Adwaita "$adwaita"; fi
	if [ ! -e "$adwaitaDark" ] && [ ! -L "$adwaitaDark" ]; then asUser ln -s /usr/share/themes/Adwaita-dark "$adwaitaDark"; fi
	if [ ! -e "$dejavu" ] && [ ! -L "$dejavu" ]; then asUser ln -s /usr/share/fonts/truetype/dejavu "$dejavu"; fi
	if [ ! -e "$comicNeue" ] && [ ! -L "$comicNeue" ]; then asUser ln -s /usr/share/fonts/truetype/comic-neue "$comicNeue"; fi
}

symLink

#### Automate setup - themes
sysLogger i "Enaging setTheme function"

####		type		gSet		name
setTheme	"icon"	  	"icon"  	"Papirus-Dark"
setTheme	"icon"	  	"cursor"	"breeze_cursors"
setTheme	"theme"	 	"gtk"	   	"Adwaita-dark"


# gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
# gsettings set org.gnome.desktop.interface cursor-theme "breeze_cursors"
# gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"

sysLogger i "setTheme function executed"





sysLogger i "Creating $gtkConfigFolder for both gtk 3 and 4"


sysLogger i "Creating and setting terminal padding"
read -r -d '' terminalPadding <<'EOF'
VteTerminal,
TerminalScreen,
vte-terminal {
	padding: 20px 20px 20px 20px;
	-VteTerminal-inner-border: 20px 20px 20px 20px;
}
EOF

atomicWrite "gtk.css" "$gtkConfigFolder/gtk-3.0" "$terminalPadding"
atomicWrite "gtk.css" "$gtkConfigFolder/gtk-4.0" "$terminalPadding"


sysLogger i "Force dark mode to avoid gtk compatibility issues"
echo -e "[Settings]\ngtk-application-prefer-dark-theme = true" > "$gtkConfigFolder/gtk-3.0/settings.ini"
echo -e "[Settings]\ngtk-application-prefer-dark-theme = true" > "$gtkConfigFolder/gtk-4.0/settings.ini"


sysLogger i "Set the background to a solid black across theme types"
# gsettings set org.gnome.desktop.background picture-uri-dark "$HOME/Nextcloud/Linux/SysThemes/Themes/black_Bg.png"
asUser gsettings set org.gnome.desktop.background picture-uri	  ''
asUser gsettings set org.gnome.desktop.background picture-uri-dark ''
asUser gsettings set org.gnome.desktop.background primary-color	'#000000'
asUser gsettings set org.gnome.desktop.background color-shading-type 'solid'   


#### Automate setup
interface="DejaVu Sans Condensed"
mono="DejaVu Sans Mono"
editors="DejaVu Sans Mono"

sysLogger i "Setup to be confirmed:
interface = $interface
mono = $mono
editors = $editors"


asUser fc-cache -fv > /dev/null

#### Main font GNOME Shell uses
asUser gsettings set org.gnome.desktop.interface font-name "$interface 11"

#### Gedit , LibreOffice (if they respect GTK rules)
asUser gsettings set org.gnome.desktop.interface document-font-name "$mono 12"

#### Anything requiring a mono-spaced font (GNOME Terminal, code editors...)
asUser gsettings set org.gnome.desktop.interface monospace-font-name "$editors 12"