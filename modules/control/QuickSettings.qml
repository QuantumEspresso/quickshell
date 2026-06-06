import Quickshell
import qs.components
import QtQuick.Layouts
import Quickshell.Io
import QtQuick
import "../../colors" as ColorsModule
import qs.services as Services

ColumnLayout {
    id: quickSettings
    Layout.fillWidth: true
    Layout.leftMargin: 20
    Layout.rightMargin: 20
    Layout.topMargin: 20
    spacing: 14

    property bool dndEnabled: false
    property bool airplaneModeEnabled: false

    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: "Utilities"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            font.letterSpacing: 0.3
            color: ColorsModule.Colors.on_surface
        }

        Text {
            text: "󰒓"
            font.family: "Material Design Icons"
            font.pixelSize: 16
            color: ColorsModule.Colors.primary
            opacity: 0.6
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 5
        columnSpacing: 12
        rowSpacing: 12

        ToggleTile {
            label: "Screenshot"
            icon: ""
	    active: false
	    onClicked: run([
                "bash",
                "-c",
                "qs ipc call controlCenter changeVisible; (sleep 0.2; $HOME/.config/quickshell/scripts/screenshot.sh select) &"
            ])
        }

        ToggleTile {
            label: "Record"
	    icon: ""
	    active: Services.Recorder.recording
	    onClicked: Services.Recorder.toggle()
        }

        ToggleTile {
            label: "Pick Color"
            icon: ""
            active: false
	    onClicked: run([
                "bash",
                "-c",
                "qs ipc call controlCenter changeVisible; (sleep 0.2; hyprpicker | wl-copy) &"
            ])
        }

        ToggleTile {
            label: "Draw"
            icon: "󰃉"
            active: false
	    onClicked: run([
                "bash",
                "-c",
                "qs ipc call controlCenter changeVisible; (sleep 0.2; wayscriber --active) &"
            ])
        }

        ToggleTile {
            label: "View Stats"
            icon: ""
            active: systemPanel.opened
            onClicked: toggleConky.running = true
        }

        ToggleTile {
            label: "Airplane"
            icon: "󰀝"
            active: Services.AirplaneMode.enabled
            onClicked: Services.AirplaneMode.toggle()
        }

        ToggleTile {
            label: Services.KeyboardLayouts.current
            icon: "󰌏"
            active: false
	    onClicked:Services.KeyboardLayouts.rotateLayout()
	    Text {
                text: KeyboardLayouts.current.toUpperCase()
                anchors.centerIn: parent
                font.pixelSize: 12
            }
        }

        ToggleTile {
            label: "Notifs"
            icon: Services.Notification.enabled ? "" : "󰂛"
            active: Services.Notification.enabled
            onClicked: Services.Notification.toggle()
        }

        ToggleTile {
            label: "Opacity"
            icon: "󱡓"
            active: Services.Opacity.enabled
            onClicked: Services.Opacity.toggle()
        }

        ToggleTile {
	    label: Services.Theme.light ? "Light" : "Dark"
            icon: ""
            active: Services.Theme.light
	    onClicked: Services.Theme.toggle()
        }
    }

    Process {
        id: closeProc
        command: ["qs","ipc","call","controlCenter","changeVisible"]
    }

    Process {
        id: screenshotProc
    }

    Process {
        id: toggleConky
        command: ["qs","ipc","call","systemPanel","changeVisible"]
    }

    function startRecording() {
        run(["bash","-c",`
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
           
            echo "$NULL_ID $LOOP1 $LOOP2" > /tmp/qs_record_modules
           
            setsid gpu-screen-recorder -w "$MONITOR" -f 60 -a combined.monitor -o "$FILE" >/dev/null 2>&1 &
            echo $! > /tmp/qs_record_pid
            notify-send "Nagrywanie rozpoczęte"
        `])

        recording = true
    }

    function stopRecording() {
        run(["bash","-c",`
            if [ -f /tmp/qs_record_pid ]; then
                kill $(cat /tmp/qs_record_pid) 2>/dev/null
                rm -f /tmp/qs_record_pid
            fi
           
            if [ -f /tmp/qs_record_modules ]; then
                for m in $(cat /tmp/qs_record_modules); do
                    pactl unload-module $m 2>/dev/null
                done
                rm -f /tmp/qs_record_modules
            fi
           
            notify-send "Nagrywanie zakończone"
        `])

        recording = false
    }

}
