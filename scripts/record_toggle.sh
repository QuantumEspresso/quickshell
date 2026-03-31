#!/usr/bin/env bash
DIR="$HOME/Videos/Recorded"
mkdir -p "$DIR"

PIDFILE="/tmp/wfrecorder.pid"
MODULEFILE="/tmp/wfrecorder.modules"
LOOP_SPEAKERS_FILE="/tmp/wfrecorder.loopback_speakers"
LOOP_MIC_FILE="/tmp/wfrecorder.loopback_mic"

# --- cleanup starych modułów jeśli istnieją ---
if [ -f "$MODULEFILE" ]; then
    echo "Czyszczenie starych modułów..."
    while read -r MOD; do
        pactl unload-module "$MOD" 2>/dev/null || true
    done < "$MODULEFILE"
    rm -f "$MODULEFILE"
fi

if [ -f "$LOOP_SPEAKERS_FILE" ]; then
    pactl unload-module "$(cat "$LOOP_SPEAKERS_FILE")" 2>/dev/null || true
    rm -f "$LOOP_SPEAKERS_FILE"
fi

if [ -f "$LOOP_MIC_FILE" ]; then
    pactl unload-module "$(cat "$LOOP_MIC_FILE")" 2>/dev/null || true
    rm -f "$LOOP_MIC_FILE"
fi

# jeśli PID istnieje → stop nagrywania
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    PID=$(cat "$PIDFILE")
    kill "$PID" 2>/dev/null || true
    rm -f "$PIDFILE"
    notify-send "Nagrywanie zakończone" "Plik zapisany"
    exit 0
fi

# default sink / mic
SINK=$(pactl get-default-sink)
MIC=$(pactl get-default-source)
SINK_VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}')

# monitor sink
AUDIO="${SINK}.monitor"

# monitor aktywnego okna
ACTIVE_MONITOR_ID=$(hyprctl activewindow -j | jq -r '.monitor')
MONITOR=$(hyprctl monitors -j | jq -r --arg id "$ACTIVE_MONITOR_ID" '.[] | select(.id|tostring==$id) | .name')

# utwórz combined + loopbacky
NULL_ID=$(pactl load-module module-null-sink sink_name=combined sink_properties=device.description=combined)
LOOP1=$(pactl load-module module-loopback source="$AUDIO" sink=combined latency_msec=1)
#wpctl set-volume combined "$SINK_VOL" !!!!!! need to find a way to control volume of loops feedback in combined sink
LOOP2=$(pactl load-module module-loopback source="$MIC" sink=combined latency_msec=1)

# zapisz ID modułów do plików
echo "$NULL_ID" > "$MODULEFILE"
echo "$LOOP1" > "$LOOP_SPEAKERS_FILE"
echo "$LOOP2" > "$LOOP_MIC_FILE"

# nazwa pliku
FILE="$DIR/record-$(date +%F-%H-%M-%S).mkv"

# start nagrywania
gpu-screen-recorder -w "$MONITOR" -f 60 -a combined.monitor -o "$FILE" &
PID=$!
echo "$PID" > "$PIDFILE"

notify-send "Nagrywanie rozpoczęte" "Monitor: $MONITOR"
