pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io // <--- konieczne, żeby użyć Process
import qs.services as Services

Item {
    id: airplane

    property bool enabled: false
    property bool wifiBefore: true
    property bool bluetoothBefore: true

    function toggle() {
        enabled ? disable() : enable()
    }

    function enable() {
        wifiBefore = Services.Network.wifiEnabled
        bluetoothBefore = Services.Bluetooth.defaultAdapter?.enabled ?? false

        if (Services.Network.wifiEnabled)
            Services.Network.enableWifi(false)

        if (Services.Bluetooth.defaultAdapter?.enabled)
            Services.Bluetooth.defaultAdapter.enabled = false

        enabled = true
        runNotify("Airplane Mode enabled")
    }

    function disable() {
        Services.Network.enableWifi(wifiBefore)

        if (Services.Bluetooth.defaultAdapter)
            Services.Bluetooth.defaultAdapter.enabled = bluetoothBefore

        enabled = false
        runNotify("Airplane Mode disabled")
    }

    // pojedynczy Process do powiadomień
    Process {
        id: notifyProc
        command: []
        onExited: running = false
    }

    function runNotify(message) {
        notifyProc.command = ["notify-send", message]
        notifyProc.running = true
    }
}
