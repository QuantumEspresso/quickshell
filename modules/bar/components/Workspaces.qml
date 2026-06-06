import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services as Services
import "../../../colors" as ColorsModule

Rectangle {
    id: wsContainer

    required property string fontFamily
    required property int fontSize

    readonly property var hypr: Services.Hyprland
    readonly property int activeWs: hypr.focusedWorkspaceId
    readonly property int workspaceCount: Math.max(10, hypr.workspaceIds.length)
    readonly property bool isSpecialOpen: false

    readonly property int visibleCount: 5
    property int pageCount: Math.max(
        20,
        Math.ceil(workspaceCount / visibleCount),
        Math.ceil(activeWs / visibleCount)
    )

    readonly property var colors: ColorsModule.Colors

    // =========================
    // Funkcja zmiany workspace
    function changeWorkspace(id) {
        Services.Hyprland.changeWorkspace(id)
    }

    function changeWorkspaceRelative(delta) {
        changeWorkspace(activeWs + delta)
    }

    // =========================
    // Hardcodowana mapa nazw workspace'ów
    readonly property var workspaceNames: ({
        6: "六",
        7: "七",
        8: "八",
        9: "九",
        10: "十"
        // reszta workspace'ów pokaże numery jako fallback
    })

    // Funkcja pobrania nazwy workspace'a
function getWorkspaceName(wsId) {
    // 1. Najpierw custom nazwy
    if (workspaceNames[wsId])
        return workspaceNames[wsId]

    // 2. Potem konwersja na literę (A-Z)
    if (wsId >= 1 && wsId <= 26)
        return String.fromCharCode(64 + wsId)

    // 3. Fallback na numer
    return wsId
}

    Layout.preferredHeight: 26
    Layout.preferredWidth: visibleCount * 26 + (visibleCount - 1) * 4 + 4
    color: colors.surface_container
    radius: height / 2
    clip: true

    ListView {
        id: pager
        anchors.fill: parent

        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        interactive: false
        highlightMoveDuration: 400

        model: pageCount
        currentIndex: Math.floor((activeWs - 1) / visibleCount)

        delegate: Item {
            property int startWs: index * visibleCount + 1
            property var pageOccupiedRanges: []

            function updatePageOccupied() {
                const ranges = []
                let start = -1

                for (let i = 0; i < visibleCount; i++) {
                    let wsId = startWs + i
                    let occupied = hypr.isWorkspaceOccupied(wsId)

                    if (occupied) {
                        if (start === -1) start = i
                    } else if (start !== -1) {
                        ranges.push({ start, end: i - 1 })
                        start = -1
                    }
                }

                if (start !== -1)
                    ranges.push({ start, end: visibleCount - 1 })

                pageOccupiedRanges = ranges
            }

            width: wsContainer.width
            height: wsContainer.height

            Component.onCompleted: updatePageOccupied()

            Connections {
                target: hypr
                function onStateChanged() { updatePageOccupied() }
            }

            // Zachowujemy tylko tło dla zakresów zajętości
            Repeater {
                model: pageOccupiedRanges

                Rectangle {
                    height: 26
                    radius: 14
                    opacity: 0.8
                    color: colors.background

                    x: modelData.start * (26 + 4)
                    width: (modelData.end - modelData.start + 1) * 26 +
                        (modelData.end - modelData.start) * 4
                }
            }

            Rectangle {
                property int localIndex: activeWs - startWs
                visible: localIndex >= 0 && localIndex < visibleCount

                x: localIndex * (26 + 4) + 2
                width: 26
                height: 26
                radius: 13

                color: colors.primary
                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutSine } }
            }

            Row {
                anchors.fill: parent
                anchors.margins: 2
                spacing: 4

                Repeater {
                    model: visibleCount

                    Item {
                        property int wsId: startWs + index
                        property bool isActive: wsId === activeWs

                        width: 26
                        height: 26

                        // Wyświetlamy tylko nazwy workspace'ów
                        Text {
                            anchors.centerIn: parent
			    text: getWorkspaceName(wsId)
                            font.family: "Unown"
                            //font.family: fontFamily
                            font.bold: isActive
                            color: isActive ? colors.background : colors.secondary
                            font.pixelSize: 17
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: changeWorkspace(wsId)
                        }
                    }
                }
            }
        }
    }

    // Odświeżanie po zmianach w Hyprland
    Connections {
        target: hypr
        function onStateChanged() { pager.forceLayout() }
    }
}
