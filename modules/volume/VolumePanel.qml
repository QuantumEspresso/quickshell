import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../colors" as ColorsModule
import qs.components

Item {
    id: volumePanel

    visible: true
    focus: true

    implicitWidth: 380
    implicitHeight: 600

    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.rightMargin: volumePanel.opened ? 0 : -implicitWidth
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
        focus: volumePanel.opened

        Keys.onEscapePressed: {
            volumePanel.opened = false
        }

        Item {
            id: contentWrapper
            anchors.fill: parent
            transformOrigin: Item.TopRight

            scale: volumePanel.opened ? 1 : 0.88
            opacity: volumePanel.opened ? 1 : 0

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

                    height: volumePanel.opened ? parent.height : 0

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

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            radius: 10
                            color: ColorsModule.Colors.surface_container_high

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 4

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 8

                                    color: currentTab === 0
                                        ? ColorsModule.Colors.primary
                                        : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰕾   Sink"
                                        font.family: "Material Design Icons"
                                        color: currentTab === 0
                                            ? ColorsModule.Colors.on_primary
                                            : ColorsModule.Colors.on_surface
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: currentTab = 0
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 8

                                    color: currentTab === 1
                                        ? ColorsModule.Colors.primary
                                        : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "  Source"
                                        font.family: "Material Design Icons"
                                        color: currentTab === 1
                                            ? ColorsModule.Colors.on_primary
                                            : ColorsModule.Colors.on_surface
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: currentTab = 1
                                    }
                                }
                            }
                        }

                        Loader {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            sourceComponent: currentTab === 0
                                ? sinkComponent
                                : sourceComponent
                        }
                    }
                }
            }
        }
    }

    Component {
        id: sinkComponent
        SinkPanel { }
    }

    Component {
        id: sourceComponent
        SourcePanel { }
    }

}
