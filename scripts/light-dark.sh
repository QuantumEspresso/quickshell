#!/usr/bin/env bash

# sprawdzenie argumentu
MODE="$1"
IMAGE="$2"

if [ -z "$MODE" ]; then
    echo "Usage: $0 [theme|wallpaper]"
    exit 1
fi

# odczyt obecnego trybu GTK
CURRENT=$(gsettings get org.gnome.desktop.interface color-scheme)

# monitor z quickshell
MONITOR=$(hyprctl -j layers | jq -r '
to_entries[]
| select(.value.levels | tostring | test("quickshell"))
| .key
')

# aktualna tapeta z awww
if [ -n "$IMAGE" ]; then
    WALLPAPER="$IMAGE"
else
    WALLPAPER=$(strings ~/.cache/awww/*/"$MONITOR" 2>/dev/null \
      | grep -E '^/.+\.[^/]+$' \
      | head -n1)
fi

if [ "$MODE" = "theme" ]; then

    if [ "$CURRENT" = "'prefer-dark'" ]; then
        echo "Switching to LIGHT"

        matugen image $WALLPAPER -m light --source-color-index 0
        # GTK
        gsettings set org.gnome.desktop.interface color-scheme default
        gsettings set org.gnome.desktop.interface gtk-theme Adwaita
 
        # Qt
        kvantummanager --set KvArc


    else
        echo "Switching to DARK"

        matugen image $WALLPAPER -m dark --source-color-index 0
        # GTK
        gsettings set org.gnome.desktop.interface color-scheme prefer-dark
        gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
 
        # Qt
        kvantummanager --set KvArcDark
        

    fi

elif [ "$MODE" = "wallpaper" ]; then

    if [ "$CURRENT" = "'prefer-dark'" ]; then
        echo "New wallpaper DARK"

        matugen image $WALLPAPER -m dark --source-color-index 0
        # GTK
        gsettings set org.gnome.desktop.interface color-scheme prefer-dark
        gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
 
        # Qt
        kvantummanager --set KvArcDark
    else
        echo "New wallpaper LIGHT"

        matugen image $WALLPAPER -m light --source-color-index 0
        # GTK
        gsettings set org.gnome.desktop.interface color-scheme default
        gsettings set org.gnome.desktop.interface gtk-theme Adwaita
 
        # Qt
        kvantummanager --set KvArc
    fi
    

else
    echo "Unknown argument: $MODE"
    echo "Usage: $0 [theme|wallpaper]"
    exit 1
fi

# restart portalu (electron apps)
systemctl --user restart xdg-desktop-portal 2>/dev/null
