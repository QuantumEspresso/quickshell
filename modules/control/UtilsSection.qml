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
    Layout.leftMargin: 20
    Layout.rightMargin: 20
    Layout.topMargin: 20
    spacing: 14

    property int currentTab: 1

    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: "Widgets"
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
	columns: 4
        columnSpacing: 12
        rowSpacing: 12

        ToggleTile {
            label: "GitHub"
            icon: ""
	    active: currentTab === 1
	    onClicked: currentTab = 1
        }

        ToggleTile {
            label: "Weather"
	    icon: "󰖐"
	    active: currentTab === 2
	    onClicked: currentTab = 2
        }

        ToggleTile {
            label: "Timer"
            icon: "󰀠"
	    active: currentTab === 3
	    onClicked: currentTab = 3
        }

        ToggleTile {
            label: "Screens"
            icon: "󱋆"
	    active: currentTab === 4
	    onClicked: currentTab = 4
        }
    }

    Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        sourceComponent: {
            switch (currentTab) {
                case 1: return ghCalendar
                case 2: return weatherComponent
                case 3: return timerComponent
                case 4: return screenManager
                default: return ghCalendar
            }
        }
    }

    Component {
        id: ghCalendar
        GhCalendar {}
    }

    Component {
        id: weatherComponent
        WeatherComponent {}
    }

    Component {
        id: timerComponent
        TimerComponent {}
    }

    Component {
        id: screenManager
        ScreenManager {}
    }
}
