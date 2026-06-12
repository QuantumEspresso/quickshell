import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../colors" as ColorsModule

Item {
    id: root

    property date currentDate: new Date()

    implicitWidth: 340
    implicitHeight: 360

    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate()
    }

    function firstDayOffset(y, m) {
        return (new Date(y, m, 1).getDay() + 6) % 7
    }

    function isToday(y, m, d) {
        const t = new Date()
        return t.getFullYear() === y &&
            t.getMonth() === m &&
            t.getDate() === d
    }

    function monthModel(monthOffset = 0) {
        // uwzględniamy monthOffset
        const date = new Date(currentDate.getFullYear(), currentDate.getMonth() + monthOffset, 1)
        const y = date.getFullYear()
        const m = date.getMonth()

        const offset = firstDayOffset(y, m)
        const total = daysInMonth(y, m)

        let arr = []

        for (let i = 0; i < offset; i++)
            arr.push({ day: 0 })

        for (let d = 1; d <= total; d++)
	    arr.push({ day: d })

	while (arr.length < 42)
            arr.push({ day: 0 })

        return arr
    }

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: ColorsModule.Colors.surface_container
        border.color: ColorsModule.Colors.outline_variant
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            RowLayout {
                Layout.fillWidth: true

                // =====================
                // YEAR BACK
                // =====================
                Rectangle {
                    width: 36
                    height: 32
                    radius: 8

                    property bool hover: false

                    color: hover
                        ? ColorsModule.Colors.surface_container_high
                        : ColorsModule.Colors.surface_container

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.pixelSize: 14
                        color: ColorsModule.Colors.on_surface
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: parent.hover = true
                        onExited: parent.hover = false

                        onClicked: {
                            root.currentDate =
                                new Date(root.currentDate.getFullYear() - 1,
                                         root.currentDate.getMonth(), 1)
                        }
                    }
                }

                // =====================
                // MONTH BACK
                // =====================
                Rectangle {
                    width: 36
                    height: 32
                    radius: 8

                    property bool hover: false

                    color: hover
                        ? ColorsModule.Colors.surface_container_high
                        : ColorsModule.Colors.surface_container

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.pixelSize: 14
                        color: ColorsModule.Colors.on_surface
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: parent.hover = true
                        onExited: parent.hover = false

                        onClicked: {
                            root.currentDate =
                                new Date(root.currentDate.getFullYear(),
                                         root.currentDate.getMonth() - 1, 1)
                        }
                    }
                }

                // =====================
                // CENTER TITLE (RESET TODAY)
                // =====================
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8

                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: Qt.formatDate(
                            new Date(root.currentDate.getFullYear(),
                                     root.currentDate.getMonth(), 1),
                            "MMMM yyyy"
                        )
                        font.bold: true
                        font.pixelSize: 15
                        color: ColorsModule.Colors.on_surface
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentDate = new Date()
                    }
                }

                // =====================
                // MONTH FORWARD
                // =====================
                Rectangle {
                    width: 36
                    height: 32
                    radius: 8

                    property bool hover: false

                    color: hover
                        ? ColorsModule.Colors.surface_container_high
                        : ColorsModule.Colors.surface_container

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.pixelSize: 14
                        color: ColorsModule.Colors.on_surface
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: parent.hover = true
                        onExited: parent.hover = false

                        onClicked: {
                            root.currentDate =
                                new Date(root.currentDate.getFullYear(),
                                         root.currentDate.getMonth() + 1, 1)
                        }
                    }
                }

                // =====================
                // YEAR FORWARD
                // =====================
                Rectangle {
                    width: 36
                    height: 32
                    radius: 8

                    property bool hover: false

                    color: hover
                        ? ColorsModule.Colors.surface_container_high
                        : ColorsModule.Colors.surface_container

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.pixelSize: 14
                        color: ColorsModule.Colors.on_surface
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: parent.hover = true
                        onExited: parent.hover = false

                        onClicked: {
                            root.currentDate =
                                new Date(root.currentDate.getFullYear() + 1,
                                         root.currentDate.getMonth(), 1)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                GridLayout {
                    columns: 7
                    columnSpacing: 6
                    rowSpacing: 6
 
                    Repeater {
                        model: ["M","T","W","T","F","S","S"]
                        Rectangle {
                            width: 40
                            height: 20
                            color: "transparent"
      
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 10
                                color: ColorsModule.Colors.on_surface_variant
                                opacity: 0.7
                            }
                        }
                    }
	            }

		        Rectangle { implicitWidth: 15 }

                GridLayout {
                    columns: 7
                    columnSpacing: 6
                    rowSpacing: 6
 
                    Repeater {
                        model: ["M","T","W","T","F","S","S"]
 
                        Rectangle {
                            width: 40
                            height: 20
                            color: "transparent"
      
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 10
                                color: ColorsModule.Colors.on_surface_variant
                                opacity: 0.7
                            }
                        }
                    }
	            }

		        Rectangle { implicitWidth: 15 }

                GridLayout {
                    columns: 7
                    columnSpacing: 6
                    rowSpacing: 6
 
                    Repeater {
                        model: ["M","T","W","T","F","S","S"]
 
                        Rectangle {
                            width: 40
                            height: 20
                            color: "transparent"
      
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 10
                                color: ColorsModule.Colors.on_surface_variant
                                opacity: 0.7
                            }
                        }
                    }
	            }
            }
 
            RowLayout {
		        Layout.fillWidth: true

                GridLayout {
                    columns: 7
                    columnSpacing: 6
                    rowSpacing: 6
                    Layout.fillWidth: true
 
                    Repeater {
                        model: root.monthModel(-1)
 
                        delegate: Rectangle {
                            width: 40
                            height: 36
                            radius: 10
 
                            property bool valid: modelData.day > 0
                            property bool today:
                                valid &&
                                root.isToday(
                                    new Date(root.currentDate.getFullYear(), root.currentDate.getMonth() - 1, 1).getFullYear(),
                                    new Date(root.currentDate.getFullYear(), root.currentDate.getMonth() - 1, 1).getMonth(),
                                    modelData.day
                                )
 
                            color:
                                today ? ColorsModule.Colors.primary :
                                    "transparent"
 
                            border.color:
                                valid ? ColorsModule.Colors.outline_variant :
                                    "transparent"
 
                            Text {
                                anchors.centerIn: parent
                                text: valid ? modelData.day : ""
                                font.pixelSize: 12
 
                                color:
                                    today ? ColorsModule.Colors.on_primary :
                                        ColorsModule.Colors.on_surface
                            }
                        }
                    }
	            }

		        Rectangle { implicitWidth: 15 }

                GridLayout {
                    columns: 7
                    columnSpacing: 6
                    rowSpacing: 6
                    Layout.fillWidth: true
 
                    Repeater {
                        model: root.monthModel(0)
 
                        delegate: Rectangle {
                            width: 40
                            height: 36
                            radius: 10
 
                            property bool valid: modelData.day > 0
                            property bool today:
                                valid &&
                                root.isToday(
                                    new Date(root.currentDate.getFullYear(), root.currentDate.getMonth(), 1).getFullYear(),
                                    new Date(root.currentDate.getFullYear(), root.currentDate.getMonth(), 1).getMonth(),
                                    modelData.day
                                )
 
                            color:
                                today ? ColorsModule.Colors.primary :
                                    "transparent"
 
                            border.color:
                                valid ? ColorsModule.Colors.outline_variant :
                                    "transparent"
 
                            Text {
                                anchors.centerIn: parent
                                text: valid ? modelData.day : ""
                                font.pixelSize: 12
 
                                color:
                                    today ? ColorsModule.Colors.on_primary :
                                        ColorsModule.Colors.on_surface
                            }
                        }
                    }
	            }

		        Rectangle { implicitWidth: 15 }

                GridLayout {
                    columns: 7
                    columnSpacing: 6
                    rowSpacing: 6
                    Layout.fillWidth: true
 
                    Repeater {
                        model: root.monthModel(1)
 
                        delegate: Rectangle {
                            width: 40
                            height: 36
                            radius: 10
 
                            property bool valid: modelData.day > 0
                            property bool today:
                                valid &&
                                root.isToday(
                                    new Date(root.currentDate.getFullYear(), root.currentDate.getMonth() + 1, 1).getFullYear(),
                                    new Date(root.currentDate.getFullYear(), root.currentDate.getMonth() + 1, 1).getMonth(),
                                    modelData.day
                                )
 
                            color:
                                today ? ColorsModule.Colors.primary :
                                    "transparent"
 
                            border.color:
                                valid ? ColorsModule.Colors.outline_variant :
                                    "transparent"
 
                            Text {
                                anchors.centerIn: parent
                                text: valid ? modelData.day : ""
                                font.pixelSize: 12
 
                                color:
                                    today ? ColorsModule.Colors.on_primary :
                                        ColorsModule.Colors.on_surface
                            }
                        }
                    }
	            }
            }
        }
    }
}
