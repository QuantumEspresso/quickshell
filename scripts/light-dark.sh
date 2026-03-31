#!/usr/bin/env bash

# odczyt obecnego trybu GTK
CURRENT=$(gsettings get org.gnome.desktop.interface color-scheme)
if [ "$CURRENT" = "'prefer-dark'" ]; then
    echo "Switching to LIGHT"

    # GTK
    gsettings set org.gnome.desktop.interface color-scheme default
    gsettings set org.gnome.desktop.interface gtk-theme Adwaita

    # Qt
    kvantummanager --set KvArc

else
    echo "Switching to DARK"

    # GTK
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark

    # Qt
    kvantummanager --set KvArcDark

fi

# restart portalu (electron apps)
systemctl --user restart xdg-desktop-portal 2>/dev/null
