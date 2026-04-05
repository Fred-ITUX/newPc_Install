#!/bin/bash

#### Dump GNOME shortcuts preserving literal GVariant arrays
# OUTFILE="${1:-shortcuts.txt}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Save in a subfolder relative to the script
OUTFILE="$SCRIPT_DIR/../gnome_shortcut_dump/shortcuts.txt"

rm -f "$OUTFILE"

for schema in org.gnome.settings-daemon.plugins.media-keys org.gnome.desktop.wm.keybindings; do
    for key in $(gsettings list-keys "$schema"); do
        value=$(gsettings get "$schema" "$key")
        echo "$schema|$key|$value" >> "$OUTFILE"
    done
done

echo "Dump complete: $OUTFILE"
