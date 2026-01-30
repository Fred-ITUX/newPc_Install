#!/bin/bash


#### Remove other themes
# sudo rm -rf /usr/share/icons/*
# sudo rm -rf /usr/share/themes/*


themesFolder="$HOME/Nextcloud/Linux/SysThemes"

#### Unzip the cursor and icons into /usr/share/icons (-d = destination folder)
sudo unzip -o $themesFolder/Icons/Breeze-Cursors.zip -d /usr/share/icons
sudo unzip -o $themesFolder/Icons/Papirus.zip -d /usr/share/icons
sudo unzip -o $themesFolder/Icons/Papirus-Light.zip -d /usr/share/icons
sudo unzip -o $themesFolder/Icons/Papirus-Dark.zip -d /usr/share/icons
sudo cp $themesFolder/Icons/Gnome-icons/* /usr/share/icons


#### Unzip the themes 
# sudo unzip $themesFolder/Themes/Adwaita.zip -d /usr/share/themes
# sudo unzip $themesFolder/Themes/Adwaita-dark.zip -d /usr/share/themes

unzip -o $themesFolder/Themes/Adwaita.zip -d $HOME/.themes
unzip -o $themesFolder/Themes/Adwaita-dark.zip -d $HOME/.themes

sudo apt install adwaita* gnome-themes-extra gnome-icon-theme hicolor-icon-theme humanity-icon-theme -y

sudo gtk-update-icon-cache /usr/share/icons/hicolor
sudo gtk-update-icon-cache /usr/share/icons/Adwaita



sudo chmod -R a+rw /usr/share/themes/*
sudo chmod -R a+rw /usr/share/icons/*


#### Automate setup - themes
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
gsettings set org.gnome.desktop.interface cursor-theme "breeze_cursors"
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"


#### Fonts
mkdir $HOME/.fonts
unzip -o $themesFolder/Fonts/Kanit.zip -d $HOME/.fonts/Kanit
unzip -o $themesFolder/Fonts/Comic_Neue.zip -d $HOME/.fonts/Comic_Neue
unzip -o $themesFolder/Fonts/Dejavu.zip -d $HOME/.fonts/Dejavu.zip




#### Automate setup  
interface="DejaVu Sans Condensed"
mono="DejaVu Sans Mono"
editors="DejaVu Sans Mono"


fc-cache -fv > /dev/null
#### Main font GNOME Shell uses
gsettings set org.gnome.desktop.interface font-name "$interface 11.5"

#### Gedit , LibreOffice (if they respect GTK rules)
gsettings set org.gnome.desktop.interface document-font-name "$mono 14"

#### Anything requiring a mono-spaced font (GNOME Terminal, code editors...)
gsettings set org.gnome.desktop.interface monospace-font-name "$editors  14"


