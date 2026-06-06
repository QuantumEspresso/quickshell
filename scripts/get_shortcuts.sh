#!/usr/bin/env bash

CONFIG="$HOME/.config/hypr/config/keybinding.conf"
OUTPUT="$HOME/.config/quickshell/keybindings.txt"

mkdir -p "$(dirname "$OUTPUT")"
> "$OUTPUT"

declare -A ICONS=(
    [SUPER]=""
    [ALT]="󰘵"
    [CTRL]="󰘴"
    [SHIFT]="󰘶"
    [RETURN]="󰌑"
    [PRINT]=""
    [DELETE]="Del"
    [XF86AUDIORAISEVOLUME]=""
    [XF86AUDIOLOWERVOLUME]=""
    [XF86AUDIOMUTE]=""
    [XF86AUDIOPLAY]="󰐎"
    [XF86AUDIONEXT]="󰒭"
    [XF86AUDIOPREV]="󰒮"
    [MOUSE_DOWN]="󱕒"
    [MOUSE_UP]="󱕒"
    [MOUSE:272]="LMB"
    [MOUSE:273]="RMB"
)

# zamiana modyfikatorów na ikony
mods_to_icons() {
    local raw="$1"
    local out=""
    # rozbij po literach / słowach (SUPER, ALT, CTRL, SHIFT)
    for m in SUPER ALT CTRL SHIFT; do
        # ignoruj wielkość liter
        if [[ "${raw^^}" == *"$m"* ]]; then
            [[ -n "$out" ]] && out+=" + "
            out+="${ICONS[$m]}"
        fi
    done
    echo "$out"
}

# parsowanie pliku
grep -E '^(bind|binde|bindm|bindle) =' "$CONFIG" | while IFS= read -r line; do
    # komentarz po #
    comment=""
    if [[ "$line" == *"#"* ]]; then
        comment="${line#*#}"
        comment="${comment#"${comment%%[![:space:]]*}"}"
    fi

    # usuń bind= i komentarz
    line="${line%%#*}"
    line="${line#*=}"
    IFS=',' read -r mod key cmd val <<<"$line"
    mod="${mod// /}"
    key="${key// /}"
    cmd="${cmd// /}"
    val="${val// /}"

    # ikonki modifierów
    icons="$(mods_to_icons "$mod")"
    [[ -n "$icons" ]] && icons+=" + "

    # zamiana key na ikonę jeśli jest w tabeli
    key_upper="${key^^}"
    key_icon="${ICONS[$key_upper]:-$key}"

    icons+="$key_icon"

    # opis akcji
    action="$cmd $val"
    [[ -n "$comment" ]] && action="$comment"

    printf "%-25s %s\n" "$icons" "$action" >> "$OUTPUT"
done

echo "Keybindings zapisane w $OUTPUT"
