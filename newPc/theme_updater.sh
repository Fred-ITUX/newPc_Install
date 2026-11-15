#!/bin/bash

###############################################################

#### This script is NOT intended to be run manually
#### It is executed by themeSetup (newPc_Scripts.sh), which runs under setup.sh

###############################################################

#### Must be launched by setup.sh: it provides the environment and the helper functions
if [ "$EUID" -ne 0 ] || [ -z "${realUser:-}" ] || ! declare -F asUser >/dev/null; then
    echo "[CRITICAL ERROR] Launch through setup.sh: sudo ./setup.sh $(basename "$0")" >&2; exit 1
fi


#### setTheme <key> <name>: icon | cursor | gtk  ->  org.gnome.desktop.interface <key>-theme
setTheme() {
    local key="$1"
    local name="$2"

    case "$key" in
        icon|cursor|gtk) asUser gsettings set org.gnome.desktop.interface "${key}-theme" "$name" ;;
        *) sysLogger e "Invalid theme key: $key"; return 1 ;;
    esac
}




#### Make sure the folder exists
iconDir="$userHome/.local/share/icons"
themeDir="$userHome/.local/share/themes"
fontDir="$userHome/.local/share/fonts"
asUser mkdir -p "$iconDir" "$themeDir" "$fontDir"

gtkConfigFolder="$userHome/.config"


#### Themes & fonts installed by newPc_Install.sh, linked into ~/.local/share for the flatpak overrides
#### "<system folder> <link name under ~/.local/share>": add a theme here, nowhere else
themeLinks=(
	"/usr/share/icons/Papirus-Dark          icons/Papirus-Dark"
	"/usr/share/icons/breeze_cursors        icons/breeze_cursors"
	"/usr/share/icons/Adwaita               icons/Adwaita"
	"/usr/share/themes/Adwaita-dark         themes/Adwaita-dark"
	"/usr/share/fonts/truetype/dejavu       fonts/dejavu"
	"/usr/share/fonts/opentype/comic-neue   fonts/comic-neue"
)


sysLogger i "Checking themes & fonts installed by newPc_Install.sh"
for entry in "${themeLinks[@]}"; do
    read -r themePath _ <<< "$entry"
    if [ ! -d "$themePath" ]; then sysLogger e "Missing $themePath: run newPc_Install.sh first, exiting"; exit 1; fi
done


sysLogger i "Updating the cache for each theme"

timeout 20 gtk-update-icon-cache "/usr/share/icons/Adwaita"
timeout 20 gtk-update-icon-cache "/usr/share/icons/Papirus"
timeout 20 gtk-update-icon-cache "/usr/share/icons/Papirus-Dark"


symLink(){
	local entry target link

	sysLogger i "Creating symlinks only if they do not already exist"

	for entry in "${themeLinks[@]}"; do
		read -r target link <<< "$entry"
		link="$userHome/.local/share/$link"

		if [ ! -e "$link" ] && [ ! -L "$link" ]; then
			asUser ln -s "$target" "$link" || { sysLogger e "Symlink failed: $link -> $target"; return 1; }
		fi
	done
}

symLink || { sysLogger e "Symlink creation failed" ; exit 1; }

#### Automate setup - themes
sysLogger i "Engaging setTheme function"

####		key			name
setTheme	"icon"		"Papirus-Dark"   || { sysLogger e "setTheme failed for Papirus-Dark" ; exit 1; }
setTheme	"cursor"	"breeze_cursors" || { sysLogger e "setTheme failed for breeze_cursors" ; exit 1; }
setTheme	"gtk"		"Adwaita-dark"   || { sysLogger e "setTheme failed for Adwaita-dark" ; exit 1; }

sysLogger i "setTheme function executed"


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
atomicWrite "settings.ini" "$gtkConfigFolder/gtk-3.0" "$(printf '[Settings]\ngtk-application-prefer-dark-theme = true')"
atomicWrite "settings.ini" "$gtkConfigFolder/gtk-4.0" "$(printf '[Settings]\ngtk-application-prefer-dark-theme = true')"


sysLogger i "Set the background to a solid black across theme types"
asUser gsettings set org.gnome.desktop.background picture-uri	  ''
asUser gsettings set org.gnome.desktop.background picture-uri-dark ''
asUser gsettings set org.gnome.desktop.background primary-color	'#000000'
asUser gsettings set org.gnome.desktop.background color-shading-type 'solid'   


#### Fonts installed by newPc_Install.sh (fonts-dejavu-*)
interface="DejaVu Sans Condensed"
mono="DejaVu Sans Mono"
editors="DejaVu Sans Mono"

sysLogger i "Fonts:
interface = $interface
mono = $mono
editors = $editors"


asUser fc-cache -fv > /dev/null || { sysLogger e "fc-cache failed, exiting" ; exit 1; }

#### gsettings accepts any font name, even a missing one: check that fontconfig actually knows each font
for font in "$interface" "$mono" "$editors"; do
    if ! asUser fc-list : family | grep -qiF "$font"; then sysLogger e "Font not found by fontconfig: $font, exiting"; exit 1; fi
done

#### Main font GNOME Shell uses
asUser gsettings set org.gnome.desktop.interface font-name "$interface 11"          || { sysLogger e "Failed to set font-name" ; exit 1; }

#### Gedit , LibreOffice (if they respect GTK rules)
asUser gsettings set org.gnome.desktop.interface document-font-name "$mono 12"      || { sysLogger e "Failed to set document-font-name" ; exit 1; }

#### Anything requiring a mono-spaced font (GNOME Terminal, code editors...)
asUser gsettings set org.gnome.desktop.interface monospace-font-name "$editors 12"  || { sysLogger e "Failed to set monospace-font-name" ; exit 1; }