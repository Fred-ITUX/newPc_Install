#!/bin/bash

dconf load /org/gnome/shell/extensions/ < $HOME/Nextcloud/Linux/scripts/New_Pc/gnome_extensions_settings_dump/gnome_extensions.conf
echo -e "Now restart the shell (reboot or logout)"