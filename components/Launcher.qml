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

    property string searchText: ""
    property int selectedIndex: 0

    readonly property var filteredApps: {
        if (!searchText || searchText === "")
            return Services.Apps.apps

        const s = searchText.toLowerCase()
        return Services.Apps.apps.filter(a =>
            a.name.toLowerCase().includes(s)
        )
    }

    // zamykanie utilities menu
    Process {
        id: toggleProc
        command: ["qs","ipc","call","utilitiesMenu","changeVisible"]
    }

    function launch(app) {
        if (!app) return

        if (app.terminal) {
            Qt.createQmlObject(`
                import Quickshell.Io
                Process {
                    command: ["foot","-e","${app.exec}"]
                    running: true
                }
            `, root)
        } else {
            Qt.createQmlObject(`
                import Quickshell.Io
                Process {
                    command: ["${app.exec}"]
                    running: true
                }
            `, root)
        }

        toggleProc.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            text: "Launcher"
            font.pixelSize: 16
            font.weight: Font.DemiBold
            color: col(c.on_surface, "#ffffff")
        }

        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "Search application..."
            placeholderTextColor: col(c.on_surface_variant, "#888")
	    color: col(c.on_surface, "#ffffff")

	    onActiveFocusChanged: {
                if (activeFocus) {
                    text = ""
                    root.searchText = ""
                    root.selectedIndex = 0
                }
	    }
	    
	    onVisibleChanged: {
                if (visible) {
                    forceActiveFocus()
                }
            }

            onTextChanged: {
                root.searchText = text
                root.selectedIndex = 0
                list.currentIndex = 0
            }

            Keys.onDownPressed: {
                if (root.selectedIndex < root.filteredApps.length - 1)
                    root.selectedIndex++
                list.currentIndex = root.selectedIndex
                list.positionViewAtIndex(root.selectedIndex, ListView.Contain)
            }

            Keys.onUpPressed: {
                if (root.selectedIndex > 0)
                    root.selectedIndex--
                list.currentIndex = root.selectedIndex
                list.positionViewAtIndex(root.selectedIndex, ListView.Contain)
            }

            Keys.onReturnPressed: {
                launch(root.filteredApps[root.selectedIndex])
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
                model: root.filteredApps
                spacing: 4
                clip: true
                currentIndex: root.selectedIndex

                delegate: Rectangle {
                    width: list.width
                    height: 40
		    radius: 8

                    required property var modelData
                    property bool hovered: false

                    color: (ListView.isCurrentItem || hovered)
                        ? col(c.primary_container, "#333")
                        : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

			Image {
                            width: 22
                            height: 22
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            source: {
                                if (modelData.icon && modelData.icon.length > 0) {
                                    // Spróbuj pobrać ikonę systemową
                                    const iconPath = "/usr/share/icons/hicolor/48x48/apps/" + modelData.icon + ".png"
                                    return iconPath
                                } else {
                                    // fallback do lokalnej ikony
                                    return "components/assets/app-fallback.png"
                                }
                            }
                        }

                        Text {
                            text: modelData.name
                            color: col(c.on_surface, "#fff")
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onEntered: {
                            hovered = true
                            root.selectedIndex = index
                            list.currentIndex = index
                        }
                        onExited: hovered = false
                        onClicked: launch(modelData)
                    }
                }

                onCountChanged: {
                    root.selectedIndex = 0
                    currentIndex = 0
                }
            }
        }
    }

    Component.onCompleted: searchField.forceActiveFocus()
}
