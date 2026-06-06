import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.services as Services
import "../colors" as ColorsModule

Item {
    id: root
    anchors.fill: parent
    focus: true

    property var c: ColorsModule.Colors
    function col(v,f){ return v || f }

    property int selectedIndex: 0

    ListModel {
        id: calculatorHistoryModel
    }

    function notifyCopy(text) {
    Qt.createQmlObject(`
        import Quickshell.Io
        Process {
            command: ["wl-copy", "${text.replace(/"/g, '\\"')}"]
            running: true
        }
    `, root)
}

    function evaluateExpression(expr) {
        try {
            let safeExpr = expr.replace(/\^/g, "**").replace(/sqrt\(/g, "Math.sqrt(")
            if (/[^0-9+\-*/%^().\sMathsqrt]/.test(safeExpr)) throw "Invalid characters"
            return Function('"use strict"; return (' + safeExpr + ')')()
        } catch(e) {
            return "Error"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            text: "Calculator"
            font.pixelSize: 16
            font.weight: Font.DemiBold
            color: col(c.on_surface, "#ffffff")
        }

        // --- Pole wprowadzania działania ---
        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "Type expression..."
            placeholderTextColor: col(c.on_surface_variant, "#888")
            color: col(c.on_surface, "#ffffff")

            onActiveFocusChanged: {
                if (activeFocus) {
                    text = ""
                    root.selectedIndex = 0
                }
            }

            onVisibleChanged: {
                if (visible) forceActiveFocus()
            }

            Keys.onReturnPressed: {
                if (text.trim() === "") return
                const result = evaluateExpression(text)
                calculatorHistoryModel.insert(0, { expr: text, result: result.toString() })
                text = ""
                root.selectedIndex = 0
            }

            background: Rectangle {
                radius: 10
                color: col(c.surface_container, "#222")
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: col(c.surface_container, "#1c1c1c")

            ListView {
                id: list
                anchors.fill: parent
                anchors.margins: 6
                model: calculatorHistoryModel
                spacing: 4
                clip: true
                currentIndex: root.selectedIndex

                delegate: Rectangle {
                    width: list.width
                    height: contentColumn.implicitHeight + 16
                    radius: 8
                    color: hovered ? col(c.primary_container, "#333") : "transparent"

                    property bool hovered: false

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: hovered = true
                        onExited: hovered = false
                        onClicked: notifyCopy(model.result)
                    }

                    RowLayout {
                        id: contentColumn
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

                        Text {
                            text: model.expr
                            color: col(c.on_surface, "#fff")
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "= " + model.result
                            color: col(c.primary, "#0af")
                        }
                    }
                }

                onCurrentIndexChanged: {
                    root.selectedIndex = currentIndex
                }
            }
        }
    }

    Component.onCompleted: searchField.forceActiveFocus()
}
