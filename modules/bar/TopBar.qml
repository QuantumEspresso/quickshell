import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.bar.components
import "../../colors" as ColorsModule

Item {
    id: topBar

    implicitHeight: 42
    anchors.left: parent.left
    anchors.right: parent.right
    focus: true

    Item {
        anchors.fill: parent

        RowLayout {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            Rectangle { implicitWidth: 0 }
            spacing: 8
            Launcher {}
            Cpu {}
            Workspaces {}
        }

        MediaPill {
            anchors.centerIn: parent
        }

        RowLayout {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            spacing: 10
            SystemTray {}
            Volume {}
            Battery { Layout.preferredWidth: visible ? implicitWidth : 0 }
            Network {}
            Bluetooth {}
            Clock {}
	    Menu {}
            Rectangle { implicitWidth: 0 }
        }
    }
}
