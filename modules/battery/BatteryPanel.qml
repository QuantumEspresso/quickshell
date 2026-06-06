import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.components
import Quickshell
import Quickshell.Io
import qs.services as Services
import "../../colors" as ColorsModule

Item {
    id: batteryPanel

    visible: true
    focus: true

    implicitWidth: 380
    implicitHeight: 600

    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.rightMargin: batteryPanel.opened ? 0 : -implicitWidth
    anchors.topMargin: 0

    property bool opened: false
    property int currentTab: 0

    Behavior on anchors.rightMargin {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }


    Rectangle {
        anchors.fill: parent
        color: ColorsModule.Colors.surface_container
        border.color: ColorsModule.Colors.outline_variant
	border.width: 1

	radius: 18
        clip: true

        layer.enabled: true
        layer.smooth: true
    }

    FocusScope {
        anchors.fill: parent
        focus: batteryPanel.opened

        Keys.onEscapePressed: {
            batteryPanel.opened = false
        }

        Item {
            id: contentWrapper
            anchors.fill: parent
            transformOrigin: Item.TopRight

            scale: batteryPanel.opened ? 1 : 0.88
            opacity: batteryPanel.opened ? 1 : 0

            Behavior on scale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            Item {
                anchors.fill: parent
                clip: true

                Item {
                    id: liquidContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top

                    height: batteryPanel.opened ? parent.height : 0

                    Behavior on height {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.2
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12
                        
                        Text {
                            Layout.fillWidth: true
                            text: "Energy Settings"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.3
                            color: ColorsModule.Colors.on_surface
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
                            from: 1
                    	valueSuffix: "%"
                    	visible: Services.System.canSetBrightness
                        }

                        // =====================
                        // Keyboard Backlight
                        // =====================
                        SliderRow {
                            icon: "󰌌 "
                            label: "Keyboard Backlight"
                            value: Services.System.keyboardBrightness
                            onMoved: Services.System.setKeyboardBacklight(value)
                            showValue: true
                    	    valueSuffix: ""
                    	    visible: Services.System.canSetKeyboardBacklight
                    	    from: 0
                            to: Services.System.keyboardMaxBrightness
                            stepSize: 1
                        }
                        // =====================
                        // Battery Stats
                        // =====================
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 14
                            color: ColorsModule.Colors.surface_container_high

                            implicitHeight: statsColumn.implicitHeight + 24

                            ColumnLayout {
                                id: statsColumn

                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                // =====================
                                // Header
                                // =====================
                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: Services.Battery.getIcon(
                                                  Services.Battery.percentage,
                                                  Services.Battery.charging,
                                                  true
                                              )

                                        font.family: "Material Design Icons"
                                        font.pixelSize: 22

                                        color: Services.Battery.getStateColor(
                                                   Services.Battery.percentage,
                                                   Services.Battery.charging,
                                                   Services.Battery.full
                                               )
                                    }

                                    Text {
                                        text: "Battery Information"

                                        font.pixelSize: 15
                                        font.bold: true

                                        color: ColorsModule.Colors.on_surface
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: Services.Battery.percentage + "%"

                                        font.pixelSize: 16
                                        font.bold: true

                                        color: Services.Battery.getStateColor(
                                                   Services.Battery.percentage,
                                                   Services.Battery.charging,
                                                   Services.Battery.full
                                               )
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: ColorsModule.Colors.outline_variant
                                    opacity: 0.5
                                }

                                // =====================
                                // Time Remaining
                                // =====================
                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: Services.Battery.charging
                                              ? "󱐋  Time to charge:"
                                              : "󰁹  Time to dry:"

                                        font.family: "Material Design Icons"
                                        font.pixelSize: 14

                                        color: ColorsModule.Colors.on_surface
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: Services.Battery.charging
                                              ? Services.Battery.formatTime(
                                                    Services.Battery.timeToFull
                                                )
                                              : Services.Battery.formatTime(
                                                    Services.Battery.timeToEmpty
                                                )

                                        font.pixelSize: 14
                                        font.bold: true

                                        color: ColorsModule.Colors.on_surface
                                    }
                                }

                                // =====================
                                // Cycle Count
                                // =====================
                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: "󰂄  Cycle count"

                                        font.family: "Material Design Icons"
                                        font.pixelSize: 14

                                        color: ColorsModule.Colors.on_surface
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: Services.Battery.cycleCount

                                        font.pixelSize: 14
                                        font.bold: true

                                        color: ColorsModule.Colors.on_surface
                                    }
                                }

                                // =====================
                                // Battery Condition
                                // =====================
                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: "󰓅  Battery condition"

                                        font.family: "Material Design Icons"
                                        font.pixelSize: 14

                                        color: ColorsModule.Colors.on_surface
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text:
                                            Services.Battery.wearLevel <= 10
                                                ? "Excellent"
                                            : Services.Battery.wearLevel <= 20
                                                ? "Good"
                                            : Services.Battery.wearLevel <= 35
                                                ? "Fair"
                                                : "Worn"

                                        font.pixelSize: 14
                                        font.bold: true

                                        color:
                                            Services.Battery.wearLevel <= 10
                                                ? "#a6e3a1"
                                            : Services.Battery.wearLevel <= 20
                                                ? "#89b4fa"
                                            : Services.Battery.wearLevel <= 35
                                                ? "#fab387"
                                                : "#f38ba8"
                                    }
                                }

                                // =====================
                                // Wear %
                                // =====================
                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: "󰄉  Wear level"

                                        font.family: "Material Design Icons"
                                        font.pixelSize: 14

                                        color: ColorsModule.Colors.on_surface
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: Services.Battery.wearLevel.toFixed(1) + "%"

                                        font.pixelSize: 14
                                        font.bold: true

                                        color: ColorsModule.Colors.on_surface
                                    }
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Power Profile"
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.3
                            color: ColorsModule.Colors.on_surface
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            columnSpacing: 12
                            rowSpacing: 12

                            ToggleTile {
                                label: "Performance"
                                icon: "󰓅"
                    	        active: Services.Battery.powerProfile === "performance"
                    	        onClicked: Services.Battery.setPowerProfile("performance")
                            }
                            ToggleTile {
                                label: "Balanced"
                                icon: ""
                    	        active: Services.Battery.powerProfile === "balanced"
                    	        onClicked: Services.Battery.setPowerProfile("balanced")
                            }
                            ToggleTile {
                                label: "Saving"
                                icon: "󰌪"
                    	        active: Services.Battery.powerProfile === "power-saver"
                    	        onClicked: Services.Battery.setPowerProfile("power-saver")
                            }
                        }
                    }
                }
            }
        }
    }
}
