#!/bin/bash

###############################################################

#### This script is NOT intended to be run manually
#### It is executed by themeSetup (newPc_Scripts.sh), which runs under setup.sh
####
#### Fedora KDE version of newPc/theme_updater.sh:
####    > Breeze Dark (ships with Plasma) instead of Papirus / Adwaita: no theme packages needed
####    > kwriteconfig6 / plasma-apply-* instead of gsettings
####    > terminal padding moved to the Konsole profile (newPc_Scripts.sh, KDE_global_settings)

###############################################################

#### Must be launched by setup.sh: it provides the environment and the helper functions
if [ "$EUID" -ne 0 ] || [ -z "${realUser:-}" ] || ! declare -F asUser >/dev/null; then
    echo "[CRITICAL ERROR] Launch through setup.sh: sudo ./setup.sh $(basename "$0")" >&2; exit 1
fi


#### plasmaTool <command> [args]: runs a plasma-apply-* tool as the real user
#### QT_QPA_PLATFORM=offscreen: these are Qt programs and sudo strips the display variables;
#### offscreen lets them run anyway (tested on Fedora 45 without any session)
plasmaTool() {
    asUser env QT_QPA_PLATFORM=offscreen "$@"
}


#### Make sure the folder exists
iconDir="$userHome/.local/share/icons"
themeDir="$userHome/.local/share/themes"
fontDir="$userHome/.local/share/fonts"
asUser mkdir -p "$iconDir" "$themeDir" "$fontDir"


#### Themes & fonts linked into ~/.local/share for the flatpak overrides (roThemes in newPc_Scripts.sh)
#### "<system folder> <link name under ~/.local/share>": add a theme here, nowhere else
#### Paths checked on Fedora 45 with the packages from newPc_Install.sh
#### TO CONFIRM on Fedora: whether Flatpak apps need these links at all (see WIP.md, theme_updater.sh note 2)
themeLinks=(
	"/usr/share/icons/breeze-dark               icons/breeze-dark"
	"/usr/share/icons/breeze_cursors            icons/breeze_cursors"
	"/usr/share/themes/Breeze-Dark              themes/Breeze-Dark"
	"/usr/share/fonts/dejavu-sans-fonts         fonts/dejavu-sans-fonts"
	"/usr/share/fonts/dejavu-sans-mono-fonts    fonts/dejavu-sans-mono-fonts"
	"/usr/share/fonts/comic-neue                fonts/comic-neue"
)


sysLogger i "Checking themes & fonts installed by Plasma and newPc_Install.sh"
for entry in "${themeLinks[@]}"; do
    read -r themePath _ <<< "$entry"
    if [ ! -d "$themePath" ]; then sysLogger e "Missing $themePath: run newPc_Install.sh first, exiting"; exit 1; fi
done


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


#### Global theme: Fedora's default is Breeze LIGHT (checked on Fedora 45), so the dark one is applied here
#### It sets colors, Plasma style, icons (breeze-dark) and cursors (breeze_cursors) in one go
lookAndFeel="org.kde.breezedark.desktop"

sysLogger i "Applying global theme $lookAndFeel"

if [ ! -d "/usr/share/plasma/look-and-feel/$lookAndFeel" ]; then sysLogger e "Global theme not installed: $lookAndFeel, exiting"; exit 1; fi

plasmaTool plasma-apply-lookandfeel -a "$lookAndFeel" || { sysLogger e "Global theme not applied: $lookAndFeel" ; exit 1; }

#### Without a running Plasma session the command above only recorded the theme name (tested on Fedora 45),
#### so colors and icons are also set explicitly: both are harmless when the global theme already applied them
#### TO CONFIRM on Fedora: after the next login everything (panel, windows, icons, cursor) must be dark
plasmaTool plasma-apply-colorscheme BreezeDark > /dev/null || { sysLogger e "Color scheme BreezeDark not applied" ; exit 1; }
asUser kwriteconfig6 --file kdeglobals --group Icons --key Theme "breeze-dark" || { sysLogger e "Icon theme breeze-dark not set" ; exit 1; }

sysLogger i "Global theme applied"


#### GTK apps: kde-gtk-config follows the Plasma theme and writes ~/.config/gtk-3.0 and gtk-4.0 itself,
#### so the gtk.css / settings.ini files of the Mint version are not written here (they would be overwritten)


#### Set the background to a solid black
#### TO CONFIRM on Fedora: needs a running plasmashell, so it only works from a logged-in Plasma session
sysLogger i "Set the background to a solid black"
read -r -d '' wallpaperScript <<'EOF'
for (const d of desktops()) {
    d.wallpaperPlugin = "org.kde.color";
    d.currentConfigGroup = ["Wallpaper", "org.kde.color", "General"];
    d.writeConfig("Color", "#000000");
}
EOF

asUser qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$wallpaperScript" > /dev/null 2>&1 \
    || sysLogger w "Background not changed (plasmashell not reachable): set it by hand or re-run from a Plasma session"


#### Fonts installed by newPc_Install.sh (dejavu-sans-fonts, dejavu-sans-mono-fonts)
interface="DejaVu Sans Condensed"
mono="DejaVu Sans Mono"

sysLogger i "Fonts:
interface = $interface
mono = $mono"


asUser fc-cache -fv > /dev/null || { sysLogger e "fc-cache failed, exiting" ; exit 1; }

#### kwriteconfig6 accepts any font name, even a missing one: check that fontconfig actually knows each font
for font in "$interface" "$mono"; do
    if ! asUser fc-list : family | grep -qiF "$font"; then sysLogger e "Font not found by fontconfig: $font, exiting"; exit 1; fi
done

#### Qt font description: family,point size,then the default style fields
#### TO CONFIRM on Fedora: open System Settings > Fonts after the first login and check all six entries
fontTail="-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

#### Key names found in KDE's schema file (fontssettings.kcfg) on Fedora 45
setFont() {
    local group="$1"
    local key="$2"
    local value="$3"

    asUser kwriteconfig6 --file kdeglobals --group "$group" --key "$key" "$value" || { sysLogger e "Failed to set font $group/$key" ; return 1; }
}

####        group       key                     value
setFont     "General"   "font"                  "$interface,11,$fontTail"   || exit 1    #### Main interface font
setFont     "General"   "menuFont"              "$interface,11,$fontTail"   || exit 1
setFont     "General"   "toolBarFont"           "$interface,11,$fontTail"   || exit 1
setFont     "General"   "smallestReadableFont"  "$interface,9,$fontTail"    || exit 1
setFont     "WM"        "activeFont"            "$interface,11,$fontTail"   || exit 1    #### Window titles
setFont     "General"   "fixed"                 "$mono,12,$fontTail"        || exit 1    #### Anything requiring a mono-spaced font (Konsole, code editors...)

sysLogger i "Fonts set: they apply to newly started apps, fully after the next login"
