import QtQuick
import QtQuick.Layouts
import qs.services as Services
import "../colors" as ColorsModule

Item {
    id: root
    implicitHeight: 220

    property var c: ColorsModule.Colors
    function col(v,f){ return v || f }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            text: Services.Weather.location
            font.pixelSize: 16
            font.weight: Font.DemiBold
            color: col(c.on_surface,"#fff")
        }

	Flickable {
	    id: hourlyFlick
            Layout.fillWidth: true
            Layout.preferredHeight: 90
            contentWidth: hourlyRow.width
            clip: true

            Row {
                id: hourlyRow
                spacing: 10

                Repeater {
                    model: Services.Weather.hourly

                    Rectangle {
                        width: 64
                        height: 80
			radius: 10
			color: parseInt(modelData.time) === new Date().getHours()
                            ? col(c.surface_container_high, "#72333E") // aktywna godzina
                            : col(c.surface_container, "#222")    // pozostałe godziny

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: modelData.time
                                font.pixelSize: 11
                                color: col(c.on_surface,"#fff")
                            }

                            Text {
                                text: icon(modelData.code)
                                font.pixelSize: 18
                            }

                            Text {
                                text: modelData.temp + "°"
                                font.pixelSize: 13
                                color: col(c.on_surface,"#fff")
                            }
                        }
                    }
                }
	    }
            Component.onCompleted: {
                // znajdź indeks aktualnej godziny
                let nowHour = new Date().getHours();
                let idx = Services.Weather.hourly.findIndex(h => parseInt(h.time) === nowHour);
  
                if (idx >= 0) {
                    // wycentruj godzinę na środku Flickable
                    let targetX = hourlyRow.children[idx].x - (hourlyFlick.width - hourlyRow.children[idx].width)/2;
                    hourlyFlick.contentX = Math.max(0, targetX);
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: Services.Weather.daily

                Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    radius: 10
                    color: col(c.surface_container,"#222")

                    Column {
                        anchors.centerIn: parent

                        Text {
                            text: modelData.day
                            font.pixelSize: 11
                            color: col(c.on_surface,"#fff")
                        }

		        Text {
                            text: icon(modelData.code)
                            font.pixelSize: 18
                        }

                        Text {
                            text: modelData.min + "° / " + modelData.max + "°"
                            font.pixelSize: 11
                            color: col(c.on_surface,"#fff")
                        }
                    }
                }
            }
        }
    }

    function icon(code){
        if(code===0) return "☀️"
        if(code<=3) return "⛅"
        if(code<=48) return "☁️"
        if(code<=67) return "🌧"
        if(code<=77) return "❄️"
        if(code<=99) return "⛈"
        return ""
    }
}
