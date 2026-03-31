import QtQuick
import qs.services as Services
import "../../../colors" as ColorsModule
import qs.Core

Rectangle {
    radius: 13
    color: ColorsModule.Colors.surface_container
    implicitHeight: 28
    implicitWidth: battery.implicitWidth + 16

    // 🔥 KLUCZ
    visible: Services.Battery.hasBattery

    Text {
        id: battery
        anchors.centerIn: parent

        font.pixelSize: 17
        color: ColorsModule.Colors.on_surface

        text: Services.Battery.getIcon(
                  Services.Battery.percentage,
                  Services.Battery.charging,
                  Services.Battery.hasBattery
              ) + " " + Services.Battery.percentage + "%"
    }
}
