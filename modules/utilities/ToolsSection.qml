import Quickshell
import qs.components
import QtQuick.Layouts
import Quickshell.Io
import QtQuick
import "../../colors" as ColorsModule
import qs.services as Services

ColumnLayout {
    id: quickSettings
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.leftMargin: 20
    Layout.rightMargin: 20
    Layout.topMargin: 20
    spacing: 14

    property int currentTab: 1

    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: "Tools"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            font.letterSpacing: 0.3
            color: ColorsModule.Colors.on_surface
        }

        Text {
            text: "󰒓"
            font.family: "Material Design Icons"
            font.pixelSize: 16
            color: ColorsModule.Colors.primary
            opacity: 0.6
        }
    }

    GridLayout {
        Layout.fillWidth: true
	columns: 3
        columnSpacing: 12
        rowSpacing: 12

        ToggleTile {
            label: "Launcher"
            icon: "󰍉"
	    active: currentTab === 1
	    onClicked: currentTab = 1
        }

        ToggleTile {
            label: "Calculator"
	    icon: "󱖦"
	    active: currentTab === 2
	    onClicked: currentTab = 2
        }

        ToggleTile {
            label: "Clipboard"
            icon: ""
	    active: currentTab === 3
	    onClicked: currentTab = 3
        }

        ToggleTile {
            label: "Notifications"
            icon: ""
	    active: currentTab === 4
	    onClicked: currentTab = 4
        }

        ToggleTile {
            label: "Quick Notes"
	    icon: ""
	    active: currentTab === 5
	    onClicked: currentTab = 5
        }

        ToggleTile {
            label: "Keybindings"
            icon: "󰌓"
	    active: currentTab === 6
	    onClicked: currentTab = 6
        }
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: currentTab - 1
   
        Launcher {}
        Calculator {}
        ClipHistory {}
        Notifier {}
        Notes {}
        Keybindings {}
    }
}
