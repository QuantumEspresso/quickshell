#!/usr/bin/env bash
shopt -s nullglob

ICON_DIRS=(
  "$HOME/.local/share/icons"
  "/usr/share/icons"
  "/usr/share/pixmaps"
)

desktop_files=(
  /usr/share/applications/*.desktop
  ~/.local/share/applications/*.desktop
)

find_icon() {
  local icon_name="$1"
  [[ -f "$icon_name" ]] && echo "$icon_name" && return
  for dir in "${ICON_DIRS[@]}"; do
    match=$(find "$dir" -type f \( -name "${icon_name}.png" -o -name "${icon_name}.svg" -o -name "${icon_name}.xpm" \) 2>/dev/null | head -n1)
    [[ -n "$match" ]] && echo "$match" && return
  done
  echo ""
}

for file in "${desktop_files[@]}"; do
  name=$(grep -m1 '^Name=' "$file" | cut -d= -f2-)
  exec=$(grep -m1 '^Exec=' "$file" | cut -d= -f2- | sed 's/ *%[fFuUdDnNickvm]//g')
  icon_name=$(grep -m1 '^Icon=' "$file" | cut -d= -f2-)
  term=$(grep -m1 '^Terminal=' "$file" | cut -d= -f2-)

  [[ -z "$name" || -z "$exec" ]] && continue
  [[ -z "$term" ]] && term="false"

  icon_path=$(find_icon "$icon_name")

  printf '%s|%s|%s|%s\n' "$name" "$icon_path" "$exec" "$term"
done
