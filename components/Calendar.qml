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

                ToolButton {
                    text: " "
                    onClicked: {
                        root.currentDate =
                            new Date(root.currentDate.getFullYear() - 1,
                                     root.currentDate.getMonth(), 1)
                    }
	        }

                ToolButton {
                    text: " "
                    onClicked: {
                        root.currentDate =
                            new Date(root.currentDate.getFullYear(),
                                root.currentDate.getMonth()-1, 1)
                    }
	        }


		Button {
                    Layout.fillWidth: true
                    onClicked: {
                        root.currentDate = new Date()
                    }
    
                    background: Rectangle {
                        color: "transparent"
                    }
    
                    contentItem: Text {
                        text: Qt.formatDate(
                            new Date(root.currentDate.getFullYear(), root.currentDate.getMonth(), 1),
                            "MMMM yyyy"
                        )
                        horizontalAlignment: Text.AlignHCenter
                        font.bold: true
                        font.pixelSize: 15
                        color: ColorsModule.Colors.on_surface
                    }
                }

                ToolButton {
                    text: " "
                    onClicked: {
                        root.currentDate =
                            new Date(root.currentDate.getFullYear(),
                                root.currentDate.getMonth()+1, 1)
                    }
	       }
	       
	       ToolButton {
                    text: " "
                    onClicked: {
                        root.currentDate =
                            new Date(root.currentDate.getFullYear() + 1,
                                     root.currentDate.getMonth(), 1)
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
