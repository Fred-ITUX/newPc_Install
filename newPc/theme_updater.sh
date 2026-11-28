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
#### Needs a running plasmashell, so it only works from a logged-in Plasma session
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












##################################################################

####            PANELS
####    Sectors: helpers (panelKscreen, panelMainScreen, panelEval) | panelsSetup (top panel + bottom docks + taskbar) | clockSetup (clock widget)
####    Everything runs through plasmashell's scripting, so it needs a logged-in Plasma session (a failed call only warns, the rest of the script goes on)


panelKscreen(){
    #### Prints the screens as kscreen sees them (JSON)
    #### sudo strips WAYLAND_DISPLAY and kscreen-doctor needs the compositor socket: take its name from the user's runtime dir
    local waylandSocket
    waylandSocket=$(find "$userRuntime" -maxdepth 1 -name 'wayland-[0-9]*' ! -name '*.lock' -printf '%f\n' 2>/dev/null | head -1)
    if [ -z "$waylandSocket" ]; then sysLogger e "Wayland socket not found in $userRuntime" >&2; return 1; fi
    asUser env WAYLAND_DISPLAY="$waylandSocket" kscreen-doctor -j
}


panelMainScreen(){
    #### Prints the connector name of the main screen (the output with priority 1 in kscreen)
    panelKscreen | jq -r '.outputs[] | select(.priority==1) | .name'
}


panelEval(){
    #### panelEval <what> <javascript>: runs a Plasma scripting snippet in plasmashell as the real user
    local what="$1" script="$2"
    asUser qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" > /dev/null 2>&1 || { sysLogger w "$what not changed (plasmashell not reachable): re-run from a Plasma session"; return 1; }
}


panelsSetup(){
    #### TOP panel on the main screen: executor left | spacer | CLOCK | spacer | executor right | tray | show desktop
    ####    > the two flexible spacers share the free space, so the clock is centered when both sides take about the same width
    ####    > launcher, taskbar and separator live in the bottom docks; the Virtual Desktops widget (pager) is removed everywhere
    #### BOTTOM docks, one per screen (both screens at all times): launcher with the Fedora logo + taskbar with the pinned apps and every desktop's windows
    ####    > floating (detached from the edge), only as wide as its icons and centered, translucent, hidden only when a window covers it ("dodgewindows")
    ####      and shown again when the cursor reaches the edge. Values are the lowercase names of the shell's own enums
    ####    > icons are about the panel height minus its margins: tune bottomHeight if they come out smaller or bigger
    ####    > created once per screen, reused on later runs
    local mainScreen screenNames topHeight=30 bottomHeight=58 topScript bottomScript app launchers=""
    #### Pinned apps, left to right (desktop file ids, checked in /usr/share/applications and the Flatpak exports)
    local pinnedApps=("org.kde.kwrite.desktop" "com.vscodium.codium.desktop" "nemo.desktop" "com.brave.Browser.desktop" "com.google.Chrome.desktop" "org.kde.konsole.desktop" "org.pulseaudio.pavucontrol.desktop")

    mainScreen=$(panelMainScreen) || { sysLogger e "Main screen not found"; return 1; }
    screenNames=$(panelKscreen | jq -c '[.outputs[] | select(.enabled) | .name]') || { sysLogger e "Screens not found"; return 1; }
    if [ -z "$mainScreen" ] || [ -z "$screenNames" ]; then sysLogger e "No screen found (kscreen-doctor)"; return 1; fi

    #### "launchers" is a StringList in the widget's schema: Plasma scripting needs a real JS array, not a comma separated string
    for app in "${pinnedApps[@]}"; do launchers+="\"applications:$app\","; done
    launchers="${launchers%,}"
    sysLogger i "Panels: top ${topHeight}px on $mainScreen, bottom docks ${bottomHeight}px on $screenNames, pinned: $launchers"

    #### Top first: on a fresh deploy it turns the default (bottom) panel into the top one, then the docks are created as new panels
    read -r -d '' topScript <<EOF
const screenId = screenForConnector("$mainScreen");
const t = panels().find(p => p.location === "top") || panels()[0];
t.location = "top";
t.screen = screenId;
t.height = $topHeight;
for (const p of panels()) { for (const w of p.widgets()) { if (w.type === "org.kde.plasma.pager") { w.remove(); } } }
for (const w of t.widgets()) { if (["org.kde.plasma.kickoff", "org.kde.plasma.icontasks", "org.kde.plasma.marginsseparator"].includes(w.type)) { w.remove(); } }
function byType(ty) { return t.widgets().filter(w => w.type === ty); }
function byCmd(name) { return t.widgets().filter(w => { if (w.type !== "local.executor") { return false; } w.currentConfigGroup = ["General"]; return String(w.readConfig("command")).indexOf(name) >= 0; }); }
while (byType("org.kde.plasma.panelspacer").length < 2) { t.addWidget("org.kde.plasma.panelspacer"); }
const spacers = byType("org.kde.plasma.panelspacer");
const order = [].concat(byCmd("left_idx.sh"), [spacers[0]], byType("org.kde.plasma.digitalclock"), [spacers[1]], byCmd("right_idx.sh"), byType("org.kde.plasma.systemtray"), byType("org.kde.plasma.showdesktop"));
order.forEach((w, i) => { w.index = i; });
EOF
    panelEval "Top panel" "$topScript" || return 1

    read -r -d '' bottomScript <<EOF
for (const name of $screenNames) {
    const screenId = screenForConnector(name);
    let b = panels().find(p => p.location === "bottom" && p.screen === screenId);
    if (!b) { b = new Panel(); b.location = "bottom"; }
    b.screen = (screenId === 0) ? 1 : 0;
    b.screen = screenId;
    b.height = $bottomHeight;
    b.floating = true;
    b.lengthMode = "fit";
    b.alignment = "center";
    b.opacity = "translucent";
    b.hiding = "dodgewindows";
    const has = ty => b.widgets().some(w => w.type === ty);
    if (!has("org.kde.plasma.kickoff")) { b.addWidget("org.kde.plasma.kickoff"); }
    if (!has("org.kde.plasma.icontasks")) { b.addWidget("org.kde.plasma.icontasks"); }
    for (const w of b.widgets()) {
        if (w.type === "org.kde.plasma.kickoff") { w.currentConfigGroup = ["General"]; w.writeConfig("icon", "fedora-logo-icon"); }
        if (w.type === "org.kde.plasma.icontasks") { w.currentConfigGroup = ["General"]; w.writeConfig("launchers", [$launchers]); w.writeConfig("showOnlyCurrentDesktop", false); }
    }
}
EOF
    panelEval "Bottom docks" "$bottomScript" || return 1
}


clockSetup(){
    #### Clock widget: European date and 24h time, without touching the system locale
    ####    > keys from the widget's own config schema (group Appearance): dateFormat "custom" uses customDateFormat, use24hFormat 2 = force 24h
    ####    > dateDisplayFormat: 0 = adaptive (default), 1 = date beside the time, 2 = date below the time
    ####    > same look as the old GNOME bar (Exec/middle_idx.sh: date "+ %a %d | %H:%M "): "Sat 28 | 17:01", the date part is "ddd dd |"
    sysLogger i "Clock widget: date 'ddd dd |' beside the time, 24h time"

    local clockScript clockKeys
    read -r -d '' clockScript <<'EOF'
for (const p of panels()) {
    for (const w of p.widgets()) {
        if (w.type === "org.kde.plasma.digitalclock") {
            w.currentConfigGroup = ["Appearance"];
            w.writeConfig("dateFormat", "custom");
            w.writeConfig("customDateFormat", "ddd dd |");
            w.writeConfig("use24hFormat", 2);
            w.writeConfig("dateDisplayFormat", 1);
        }
    }
}
EOF
    panelEval "Clock format" "$clockScript" || return 1

    #### Plasma writes the applet file a moment after the change: read the keys back to prove it stuck
    sleep 2
    clockKeys=$(asUser grep -E "^(dateFormat|customDateFormat|use24hFormat|dateDisplayFormat)=" "$userHome/.config/plasma-org.kde.plasma.desktop-appletsrc")
    if [ -z "$clockKeys" ]; then sysLogger w "Clock keys not found in plasma-org.kde.plasma.desktop-appletsrc (not written yet, or no clock widget)"; return 1; fi
    sysLogger i "Clock keys now in the applet file: $(echo "$clockKeys" | tr '\n' ' ')"
}


panelDodgeSetup(){
    #### Panel Dodge (KWin script, Plasma 6): moves the top panel to the other monitor while a window is fullscreen on the main screen, back afterwards
    ####    > cloned next to the other repos in ~/Github, built with its Makefile and installed for the user
    ####    > its own "make install" ends with qdbus6, which does not exist on Fedora (qdbus-qt6): install and reload are done here instead
    ####    > config keys read from its own config/main.xml: MainOutput (connector of the main screen), PanelId (the top panel), SideScreen (-1 = the other screen)
    local repoDir="$userHome/Github/panel-dodge" tool mainScreen topPanelId archive
    for tool in git make zip kpackagetool6; do
        if ! command -v "$tool" > /dev/null 2>&1; then sysLogger e "$tool is not installed (packages go in newPc_Install.sh)"; return 1; fi
    done

    if [ -d "$repoDir/.git" ]; then
        sysLogger i "Panel Dodge already cloned, updating"
        asUser git -C "$repoDir" pull --ff-only || { sysLogger e "Panel Dodge update failed"; return 1; }
    else
        sysLogger i "Cloning Panel Dodge into $repoDir"
        asUser git clone https://github.com/iacosta3994/panel-dodge "$repoDir" || { sysLogger e "Panel Dodge clone failed"; return 1; }
    fi

    asUser make -C "$repoDir" build > /dev/null || { sysLogger e "Panel Dodge build failed"; return 1; }
    archive=$(ls "$repoDir"/panel-dodge-*.kwinscript 2>/dev/null | head -1)
    if [ -z "$archive" ]; then sysLogger e "Panel Dodge archive not found in $repoDir"; return 1; fi
    asUser kpackagetool6 --type=KWin/Script -i "$archive" > /dev/null 2>&1 || asUser kpackagetool6 --type=KWin/Script -u "$archive" > /dev/null || { sysLogger e "Panel Dodge install failed"; return 1; }

    mainScreen=$(panelMainScreen) || { sysLogger e "Main screen not found"; return 1; }
    topPanelId=$(asUser qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'print(panels().find(p => p.location === "top").id)' 2>/dev/null)
    if [ -z "$topPanelId" ]; then sysLogger e "Top panel not found (plasmashell not reachable)"; return 1; fi
    sysLogger i "Panel Dodge: panel $topPanelId, main screen $mainScreen"

    asUser kwriteconfig6 --file kwinrc --group Script-panel-dodge --key MainOutput "$mainScreen"
    asUser kwriteconfig6 --file kwinrc --group Script-panel-dodge --key PanelId "$topPanelId"
    asUser kwriteconfig6 --file kwinrc --group Plugins --key panel-dodgeEnabled true
    asUser qdbus-qt6 org.kde.KWin /KWin reconfigure > /dev/null 2>&1 || { sysLogger w "KWin not reachable: Panel Dodge starts at the next login"; return 1; }
    sysLogger i "Panel Dodge installed and enabled"
}




commandMenuSetup(){
    #### Shortcuts menu in the top bar (replaces the GNOME Custom Command List): the "Command Menu" Plasma 6 widget, right after the RIGHT executor (before the tray)
    ####    > repo cloned next to the other repos in ~/Github, installed for the user with its own install.sh (plugin id com.github.tesla.plasmacommandmenu)
    ####    > the menu is ~/.commands.json, a copy of Shortcuts/commands.json (single source of truth); the widget re-reads it every time the menu opens
    ####    > replaces the Quick Launch attempt: its widget and its hidden shortcut-N.desktop launchers are removed
    local repoDir="$userHome/Github/plasma-command-menu" menuFile="$userHome/Nextcloud/Linux/scripts/Shortcuts/commands.json" appsDir="$userHome/.local/share/applications"
    local tool menuScript
    for tool in git jq kpackagetool6; do
        if ! command -v "$tool" > /dev/null 2>&1; then sysLogger e "$tool is not installed (packages go in newPc_Install.sh)"; return 1; fi
    done
    if [ ! -f "$menuFile" ]; then sysLogger e "commands.json not found: $menuFile"; return 1; fi
    jq -e . "$menuFile" > /dev/null 2>&1 || { sysLogger e "$menuFile is not valid JSON"; return 1; }

    if [ -d "$repoDir/.git" ]; then
        sysLogger i "Command Menu already cloned, updating"
        asUser git -C "$repoDir" pull --ff-only || { sysLogger e "Command Menu update failed"; return 1; }
    else
        sysLogger i "Cloning Command Menu into $repoDir"
        asUser git clone https://github.com/willheisenberg/plasma-command-menu "$repoDir" || { sysLogger e "Command Menu clone failed"; return 1; }
    fi
    asUser bash "$repoDir/install.sh" > /dev/null || { sysLogger e "Command Menu install failed"; return 1; }

    #### Shortcuts/commands.json -> ~/.commands.json: the widget reads its menu from there (it expands "~" but not "$HOME" in that path, and runs every command through sh -c, so $HOME inside a command works)
    atomicWrite ".commands.json" "$userHome" "$(cat "$menuFile")" || { sysLogger e "~/.commands.json not written"; return 1; }
    sysLogger i "Command Menu: $(jq '.menu | length' "$menuFile") entries copied to $userHome/.commands.json"

    asUser rm -f "$appsDir"/shortcut-[0-9]*.desktop

    read -r -d '' menuScript <<'EOF'
const t = panels().find(p => p.location === "top");
for (const w of t.widgets()) { if (w.type === "org.kde.plasma.quicklaunch") { w.remove(); } }
let m = t.widgets().find(w => w.type === "com.github.tesla.plasmacommandmenu");
if (!m) { m = t.addWidget("com.github.tesla.plasmacommandmenu"); }
const right = t.widgets().find(w => { if (w.type !== "local.executor") { return false; } w.currentConfigGroup = ["General"]; return String(w.readConfig("command")).indexOf("right_idx.sh") >= 0; });
if (right) { m.index = right.index + 1; }
EOF

    asUser qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$menuScript" > /dev/null 2>&1 || { sysLogger w "Command Menu widget not added (plasmashell not reachable, or it does not know the widget yet: systemctl --user restart plasma-plasmashell.service)"; return 1; }
}





panelsSetup || { sysLogger e "Failed to set up the panels"; }
clockSetup  || { sysLogger e "Failed to apply format to clock"; }
panelDodgeSetup || { sysLogger e "Failed to set up Panel Dodge"; }
commandMenuSetup || { sysLogger e "Failed to set up the shortcuts menu"; }




