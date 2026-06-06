import QtQuick
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: root

    property real percentage: 0
    property bool charging: false
    property bool full: percentage >= 100

    property bool hasBattery: false

    // =========================
    // NEW BATTERY STATS
    // =========================
    property real timeToEmpty: 0
    property real timeToFull: 0
    property int cycleCount: 0

    property real energyNow: 0
    property real energyFull: 0
    property real energyFullDesign: 0

    property real wearLevel: 0   // % zużycia baterii

    // =========================================================
    // DETECT BATTERY
    // =========================================================
    Process {
        id: detectBattery
        running: true
        command: ["bash", "-c",
            "for d in /sys/class/power_supply/BAT*; do [ -d \"$d\" ] && echo 1 && exit; done; echo 0"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.hasBattery = text.trim() === "1"
            }
        }
    }

    // =========================================================
    // MAIN BAT STATUS
    // =========================================================
    Process {
        id: batProc

        command: [
            "bash", "-c",
            "echo $(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null) $(cat /sys/class/power_supply/BAT0/status 2>/dev/null)"
        ]

        stdout: SplitParser {
            onRead: (data) => {
                const parts = data.trim().split(" ");
                if (parts.length >= 2) {
                    percentage = parseInt(parts[0]) || 0;
                    charging = parts[1] === "Charging";
                }
            }
        }
    }

    // =========================================================
    // ADVANCED BATTERY METRICS
    // =========================================================
    Process {
        id: batStatsProc

        command: [
            "bash", "-c",
            `
            BAT=/sys/class/power_supply/BAT0

            if [ ! -d "$BAT" ]; then
                echo "0 0 0 0 0 0"
                exit 0
            fi

            cap_now=$(cat $BAT/energy_now 2>/dev/null || cat $BAT/charge_now 2>/dev/null || echo 0)
            cap_full=$(cat $BAT/energy_full 2>/dev/null || cat $BAT/charge_full 2>/dev/null || echo 0)
            cap_design=$(cat $BAT/energy_full_design 2>/dev/null || cat $BAT/charge_full_design 2>/dev/null || echo 0)

            cycle=$(cat $BAT/cycle_count 2>/dev/null || echo 0)

            status=$(cat $BAT/status 2>/dev/null)

            # power draw / charge rate
            power_now=$(cat $BAT/power_now 2>/dev/null || echo 0)

            # fallback guard
            if [ -z "$power_now" ]; then power_now=0; fi

            # time estimation (µWh / µW = hours)
            if [ "$power_now" -gt 0 ]; then
                if [ "$status" = "Discharging" ]; then
                    time_empty=$(awk "BEGIN {print ($cap_now / $power_now) * 3600}")
                    time_full=0
                elif [ "$status" = "Charging" ]; then
                    time_full=$(awk "BEGIN {print (($cap_full - $cap_now) / $power_now) * 3600}")
                    time_empty=0
                else
                    time_empty=0
                    time_full=0
                fi
            else
                time_empty=0
                time_full=0
            fi

            echo "$cap_now $cap_full $cap_design $cycle $time_empty $time_full"
            `
        ]

        stdout: SplitParser {
            onRead: (data) => {
                const parts = data.trim().split(" ");
                if (parts.length >= 6) {

                    energyNow = parseFloat(parts[0]) || 0;
                    energyFull = parseFloat(parts[1]) || 0;
                    energyFullDesign = parseFloat(parts[2]) || 0;

                    cycleCount = parseInt(parts[3]) || 0;

                    timeToEmpty = parseFloat(parts[4]) || 0;
                    timeToFull = parseFloat(parts[5]) || 0;

                    // wear level (%)
                    if (energyFullDesign > 0 && energyFull > 0) {
                        wearLevel = Math.max(0, 100 - (energyFull / energyFullDesign) * 100);
                    }
                }
            }
        }
    }

    // =========================
    // POWER PROFILE
    // =========================
    property string powerProfile: "balanced"

    Process {
        id: powerProfileProc
        running: true

        command: ["bash", "-c", "powerprofilesctl get 2>/dev/null || echo balanced"]

        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p.length > 0)
                    root.powerProfile = p
            }
        }
    }

    function refreshPowerProfile() {
        powerProfileProc.running = true
    }

    function setPowerProfile(profile) {
        let cmd = ""

        if (profile === "performance")
            cmd = "powerprofilesctl set performance"
        else if (profile === "balanced")
            cmd = "powerprofilesctl set balanced"
        else if (profile === "power-saver")
            cmd = "powerprofilesctl set power-saver"

        if (cmd.length === 0)
            return

        powerProfileSetProc.command = ["bash", "-c", cmd]
        powerProfileSetProc.running = true
    }
    
    Process {
        id: powerProfileSetProc
        running: false
    }

    // =========================================================
    // TIMER
    // =========================================================
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            batProc.running = true
            batStatsProc.running = true
            powerProfileProc.running = true
        }
    }

    // =========================
    // UI HELPERS
    // =========================
    function getIcon(percent, charging, isReady) {
        if (!isReady)
            return Icons.batteryUnknown;

        if (charging)
            return Icons.batteryCharging;

        const p = Math.round(percent);
        if (p >= 90) return Icons.battery100;
        if (p >= 80) return Icons.battery90;
        if (p >= 70) return Icons.battery80;
        if (p >= 60) return Icons.battery70;
        if (p >= 50) return Icons.battery60;
        if (p >= 40) return Icons.battery50;
        if (p >= 30) return Icons.battery40;
        if (p >= 20) return Icons.battery30;
        if (p >= 10) return Icons.battery20;
        return Icons.battery10;
    }

    function getStateColor(percent, charging, full) {
        if (charging)
            return "#a6e3a1";
        if (full)
            return "#89b4fa";
        if (percent <= 20)
            return "#f38ba8";
        if (percent <= 40)
            return "#fab387";
        return "#cdd6f4";
    }

    function formatTime(seconds) {
        if (seconds <= 0)
            return "";

        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);

        if (hours > 0)
            return hours + "h " + minutes + "m";

        return minutes + "m";
    }
}
