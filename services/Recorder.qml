pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: recorder

    property bool recording: false

    function start() {
        if (recording) return
        recordProcess.running = true
        recording = true
    }

    function stop() {
        if (!recording) return
        stopProcess.running = true
        recording = false
    }

    function toggle() {
        recording ? stop() : start()
    }

    Process {
        id: recordProcess

        command: [
            "bash",
            "-c",
	    `
	        pgrep gpu-screen-recorder && exit 0
                DIR="$HOME/Videos/Recorded"
                mkdir -p "$DIR"
               
                FILE="$DIR/record-$(date +%F-%H-%M-%S).mkv"
               
                SINK=$(pactl get-default-sink)
                MIC=$(pactl get-default-source)
                AUDIO="$SINK.monitor"
               
                ACTIVE_MONITOR_ID=$(hyprctl activewindow -j | jq -r '.monitor')
                MONITOR=$(hyprctl monitors -j | jq -r --arg id "$ACTIVE_MONITOR_ID" '.[] | select(.id|tostring==$id) | .name')
               
                NULL_ID=$(pactl load-module module-null-sink sink_name=combined sink_properties=device.description=combined)
                LOOP1=$(pactl load-module module-loopback source="$AUDIO" sink=combined latency_msec=1)
                LOOP2=$(pactl load-module module-loopback source="$MIC" sink=combined latency_msec=1)
               
                cleanup() {
                    pactl unload-module "$LOOP1" 2>/dev/null
                    pactl unload-module "$LOOP2" 2>/dev/null
                    pactl unload-module "$NULL_ID" 2>/dev/null
                }
               
                trap cleanup EXIT
               
                notify-send "Nagrywanie rozpoczęte"
               
                setsid gpu-screen-recorder -w "$MONITOR" -f 60 -a combined.monitor -o "$FILE" >/dev/null 2>&1 &
                echo $! > /tmp/qs_rec_pid
            `
        ]
    }

    Process {
        id: stopProcess

        command: [
            "bash",
            "-c",
            `
                if [ -f /tmp/qs_rec_pid ]; then
                    kill $(cat /tmp/qs_rec_pid) 2>/dev/null
                    rm -f /tmp/qs_rec_pid
                fi
               
                notify-send "Nagrywanie zakończone"
            `
        ]
    }
}
