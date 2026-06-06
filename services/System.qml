pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell
import qs.services

Singleton {
    id: stats

    property string username: ""
    property string os: ""
    property string kernel: ""
    property string wm: ""

    property real disk: 0
    property string uptime: "0h 0m"

    // CPU data
    property string cpuName: ""
    property real cpu: 0
    property real temp: 0
    property var cpuHistory: []
    property var topCpu: []
    readonly property string cpuColor: tempColor(temp)

    // Memory data
    property real ram: 0
    property string ramPretty: "0 / 0 GB"
    property real swap: 0
    property string swapPretty: "0 / 0 GB"
    property var topMem: []

    // GPU
    property real gpu: NaN
    property real gpuTemp: NaN
    readonly property string gpuColor: tempColor(gpuTemp)
    property var topGpu: []
    property real vram: 0
    property string vramPretty: "0 / 0 GB"
    property var gpuHistory: []
    property string gpuName: ""

    // NETWORK
    property string netInterface: ""
    property string localIp: ""
    property string externalIp: ""
    property string macAddress: ""

    property real downSpeed: 0
    property real upSpeed: 0

    property var downHistory: []
    property var upHistory: []

    property var topNet: []
    property var topNetDown: []
    property var topNetUp: []

    // Screen brightness control
    property bool canSetBrightness: brightness > 0 || false
    property int brightness: 0
    property int lastBrightness: -1
    property bool canSetKeyboardBacklight: keyboardMaxBrightness > 0
    property int keyboardBrightness: 0
    property int keyboardMaxBrightness: 0
    property int colorTemperature: 6500

    function tempColor(temp) {
        if (temp < 50) return "#89b4fa";   // niebieski
        if (temp < 75) return "#fab387";   // pomarańczowy
        return "#f38ba8";                  // czerwony
    }
    
    function setKeyboardBacklight(v) {
        const val = Math.round(v)

        setKeyboardProc.command = [
            "brightnessctl",
            "-d", "tpacpi::kbd_backlight",
            "set",
            val.toString()
        ]

        setKeyboardProc.running = true
        stats.keyboardBrightness = val
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
	    ramProc.running = true
            diskProc.running = true
            tempProc.running = true
	    uptimeProc.running = true
	    gpuProc.running = true
	    gpuTempProc.running = true
	    getTempProc.running = true
	    keyboardBrightnessProc.running = true
            keyboardMaxProc.running = true
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
	    brightnessProc.running = true
        }
    }

    Process {
        id: osProc
        command: ["bash","-c",
            "grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '\"'"
        ]
        running: true
 
        stdout: StdioCollector {
            onStreamFinished: stats.os = text.trim()
        }
    }

    Process {
        id: kernelProc
        command: ["uname","-r"]
        running: true
 
        stdout: StdioCollector {
            onStreamFinished: stats.kernel = text.trim()
        }
    }

    Process {
        id: wmProc
        command: ["bash","-c",
            "echo ${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-Hyprland}}"
        ]
        running: true
 
        stdout: StdioCollector {
            onStreamFinished: stats.wm = text.trim()
        }
    }


    Process {
       id: userProc
       command: ["whoami"]
       running: true
     
       stdout: StdioCollector {
           onStreamFinished: {
               username = text.trim()
           }
       }
    }

    Process {
        id: cpuProc
        command: ["bash","-c","top -bn1 | grep 'Cpu(s)' | awk '{print 100-$8}'"]
	stdout: StdioCollector {
	    onStreamFinished: {
                let val = parseFloat(text) || 0
                stats.cpu = val
   
                stats.cpuHistory.push(val)
                if (stats.cpuHistory.length > 60)
                    stats.cpuHistory.shift()
            }
        }
    }

    Process {
        id: ramProc
        command: ["bash","-c",
            "free -m | awk '/Mem:/ {printf \"%f %f %f\", $3/$2*100, $3/1024, $2/1024}'"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ")

                const perc = parseFloat(parts[0]) || 0
                const used = parseFloat(parts[1]) || 0
                const total = parseFloat(parts[2]) || 0

                stats.ram = perc
                stats.ramPretty = used.toFixed(1) + "/" + total.toFixed(1)
            }
        }
    }

    Process {
        id: gpuProc
        command: ["bash","-c",
            "cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null | head -n1"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(text.trim())
                stats.gpu = isNaN(val) ? NaN : val
            }
        }
    }

    Process {
        id: gpuTempProc
        command: ["bash","-c",
            "cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(text.trim())
                stats.gpuTemp = isNaN(val) ? NaN : Math.round(val / 1000)
            }
        }
    }

    Process {
        id: diskProc
        command: ["bash","-c","df -h / | awk 'NR==2 {print $5}' | sed 's/%//'"]
        stdout: StdioCollector {
            onStreamFinished: stats.disk = parseFloat(text) || 0
        }
    }

    Process {
        id: tempProc
        command: ["bash","-c",
            "sensors | awk '/CPU:/ {print $2}' | tr -d '+°C'"
        ]
        stdout: StdioCollector {
            onStreamFinished: stats.temp = parseFloat(text) || 0
        }
    }

    Process {
        id: uptimeProc
        command: ["bash","-c","cat /proc/uptime | awk '{print int($1)}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let seconds = parseInt(text) || 0
                let hours = Math.floor(seconds / 3600)
                let minutes = Math.floor((seconds % 3600) / 60)
                stats.uptime = hours + "h " + minutes + "m"
            }
        }
    }

    Process {
        id: brightnessProc
        command: [
            "bash","-c",
            "brightnessctl -m | cut -d, -f4 | tr -d '%'"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseInt(text) || 0
                stats.brightness = v
            }
        }
    }

    onBrightnessChanged: {
        if (lastBrightness !== -1 && brightness !== lastBrightness) {
            Osd.show("brightness", brightness)
        }
        lastBrightness = brightness
    }

    function setBrightness(v) {
        setBrightnessProc.command = ["brightnessctl","set", v + "%"]
        setBrightnessProc.running = true
        stats.brightness = v
        Osd.show("brightness", v)  // Show OSD when user changes brightness
    }

    Process { id: setBrightnessProc }
    
// =====================
// Keyboard backlight detection + control
// =====================

Process {
    id: keyboardBrightnessProc
    command: [
        "bash", "-c",
        "brightnessctl -d tpacpi::kbd_backlight get"
    ]

    stdout: StdioCollector {
        onStreamFinished: {
            let v = parseInt(text) || 0
            stats.keyboardBrightness = v
        }
    }
}

Process {
    id: keyboardMaxProc
    command: [
        "bash", "-c",
        "brightnessctl -d tpacpi::kbd_backlight max"
    ]

    stdout: StdioCollector {
        onStreamFinished: {
            let v = parseInt(text) || 0
            stats.keyboardMaxBrightness = v
        }
    }
}

Process { id: setKeyboardProc }

    Process {
        id: getTempProc
        command: ["hyprctl", "hyprsunset", "temperature"]
 
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.trim().match(/\d+/)
                if (match)
                    stats.colorTemperature = parseInt(match[0])
            }
        }
    }

    Process {
        id: setTempProc
    }

    function setColorTemperature(temp) {
        const t = Math.round(temp)
        stats.colorTemperature = t
        setTempProc.command = ["hyprctl", "hyprsunset", "temperature", String(t)]
	setTempProc.running = true
	getTempProc.stop()
        getTempProc.start()
    }


}
