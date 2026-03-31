import QtQuick 2.15
import QtQuick.Layouts 1.15
import qs.components
import qs.services as Services

ColumnLayout {
    Layout.fillWidth: true
    Layout.leftMargin: 20
    Layout.rightMargin: 20
    Layout.topMargin: 8
    spacing: 14

    // =====================
    // Volume
    // =====================
    SliderRow {
        label: "Volume"
        icon: "󰕾 "
        showValue: true
        valueSuffix: "%"
        value: Services.Volume.volume*100
	onMoved: Services.Volume.setVolume(value / 100)
	visible: false
    }

    // =====================
    // Screen Brightness
    // =====================
    SliderRow {
        icon: "󰃞 "
        label: "Screen Brightness"
        value: Services.System.brightness
        onMoved: Services.System.setBrightness(value)
        showValue: true
	valueSuffix: "%"
	visible: Services.System.canSetBrightness
    }

    // =====================
    // Keyboard Backlight
    // =====================
    SliderRow {
        icon: "󰌌 "
        label: "Keyboard Backlight"
        value: Services.System.backlight
        onMoved: Services.System.setBacklight(value)
        showValue: true
	valueSuffix: "%"
	visible: Services.System.canSetBacklight
    }

    // =====================
    // Color Temperature
    // =====================
    RowLayout {
        spacing: 10
        Layout.fillWidth: true

        SliderRow {
            id: blueSlider
            icon: "󰖔 "
            label: "Night Light"
	    value: Services.System.colorTemperature
	    from:2000
	    to: 9000
            valueSuffix: "K"
            showValue: true
            Layout.fillWidth: true

            onMoved: {
                Services.System.setColorTemperature(value)
            }
        }

        // ===== Button "Default" =====
        Rectangle {
            width: 40
            height: 40
            radius: 6
            color: "#666"
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "󰁯 "
                font.pixelSize: 14
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Services.System.setColorTemperature(6500)
                }
            }
        }
    }
}
