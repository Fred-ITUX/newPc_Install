#!/bin/bash
# Restore GNOME shortcuts from the dump
# INFILE="${1:-shortcuts.txt}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Save in a subfolder relative to the script
INFILE="$SCRIPT_DIR/../gnome_shortcut_dump/shortcuts.txt"


while IFS='|' read -r schema key value; do
    # Skip overlay-key to preserve Super
    if [[ "$key" == "overlay-key" ]]; then
        continue
    fi
    # Pass the value literally to gsettings
    gsettings set "$schema" "$key" "$value"
done < "$INFILE"

gsettings set org.gnome.mutter overlay-key 'Super_L'

echo "Restore complete."




