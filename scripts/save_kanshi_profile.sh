#!/usr/bin/env bash

CONFIG="$HOME/.config/kanshi/config"
mkdir -p "$(dirname "$CONFIG")"
touch "$CONFIG"

TMP=$(mktemp)

JSON=$(hyprctl monitors -j)

# budujemy ID konfiguracji (description sorted)
ID=$(echo "$JSON" | jq -r '.[].description' | sort | tr '\n' '|' )

{
    echo "# QS_PROFILE:$ID"
    echo "profile auto {"

    echo "$JSON" | jq -c '.[]' | while read -r mon; do
        name=$(echo "$mon" | jq -r '.name')
        desc=$(echo "$mon" | jq -r '.description')
        width=$(echo "$mon" | jq -r '.width')
        height=$(echo "$mon" | jq -r '.height')
        x=$(echo "$mon" | jq -r '.x')
        y=$(echo "$mon" | jq -r '.y')
        scale=$(echo "$mon" | jq -r '.scale')
        disabled=$(echo "$mon" | jq -r '.disabled')

        if [[ "$desc" == "null" ]]; then
            output="$name"
        else
            output="\"$desc\""
        fi

        if [[ "$disabled" == "true" ]]; then
            echo "  output $output disable"
        else
            echo "  output $output mode ${width}x${height} position ${x},${y} scale ${scale}"
        fi
    done

    echo "}"
} > "$TMP.new"

# usuń istniejący profil z tym ID
awk -v id="$ID" '
BEGIN { skip=0 }
/^# QS_PROFILE:/ {
    if ($0 == "# QS_PROFILE:" id) {
        skip=1
        next
    }
}
skip && /^}/ { skip=0; next }
!skip { print }
' "$CONFIG" > "$TMP"

cat "$TMP.new" >> "$TMP"

mv "$TMP" "$CONFIG"
rm -f "$TMP.new"
