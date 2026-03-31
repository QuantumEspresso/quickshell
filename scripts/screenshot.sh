#!/usr/bin/env bash

set -e

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

FILE="$DIR/screenshot-$(date +%F-%H-%M-%S).png"

get_focused_monitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused==true).name'
}

get_active_window_geometry() {
    hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

case "$1" in
    screen)
        grim -o "$(get_focused_monitor)" - | tee "$FILE" | wl-copy --type image/png
        ;;
    window)
        grim -g "$(get_active_window_geometry)" - | tee "$FILE" | wl-copy --type image/png
        ;;
    select)
        slurp | grim -g - - | tee "$FILE" | wl-copy --type image/png
        ;;
    full)
        grim - | tee "$FILE" | wl-copy --type image/png
        ;;
    *)
        echo "Użycie: $0 {screen|window|select|full}"
        exit 1
        ;;
esac

# Powiadomienie (jeśli masz notify-send)
if command -v notify-send &> /dev/null; then
    notify-send "Screenshot zapisany" "$FILE"
fi

echo "Zapisano: $FILE"
