pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string location: "Loading..."
    property var hourly: []
    property var daily: []
    property bool ready: false

    property real lat: 0
    property real lon: 0

    function refreshGeo() {
	geoProc.running = false
        geoProc.running = true
    }

    function refreshWeather() {
        if (!lat || !lon) return
	weatherProc.running = false
        weatherProc.running = true
    }

    Process {
        id: geoProc
        command: ["/usr/bin/curl","-s","https://ipapi.co/json"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const json = JSON.parse(text)

                    if (json.latitude === root.lat &&
                        json.longitude === root.lon)
                        return

                    root.lat = json.latitude
                    root.lon = json.longitude
                    root.location = json.city

                    refreshWeather()

                } catch(e) {
                    console.log("Weather GEO parse error:", e)
                }
            }
        }
    }

    Process {
        id: weatherProc

        command: [
            "/usr/bin/curl","-s",
            "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + root.lat
            + "&longitude=" + root.lon
            + "&hourly=temperature_2m,weathercode"
            + "&daily=temperature_2m_max,temperature_2m_min,weathercode"
            + "&timezone=auto"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const json = JSON.parse(text)

                    let now = new Date();
                    let currentHourStr = now.toISOString().slice(0,13); // "YYYY-MM-DDTHH"
                    let h = [];
                   
                    for (let i = 0; i < json.hourly.time.length; i++) {
                        if (json.hourly.time[i].startsWith(currentHourStr) || 
                            json.hourly.time[i] > currentHourStr) {
                            h.push({
                                time: json.hourly.time[i].split("T")[1].slice(0,5),
                                temp: Math.round(json.hourly.temperature_2m[i]),
                                code: json.hourly.weathercode[i]
                            });
                            if (h.length >= 24) break; // tylko następne 24 godziny
                        }
                    }

                    let d = []
                    const names = ["Yesterday","Today","Tomorrow"]

                    for (let i = 0; i < 3; i++) {
                        d.push({
                            day: names[i],
                            min: Math.round(json.daily.temperature_2m_min[i]),
			    max: Math.round(json.daily.temperature_2m_max[i]),
			    code: json.daily.weathercode[i]
                        })
                    }

                    root.hourly = h
                    root.daily = d
                    root.ready = true

                } catch(e) {
                    console.log("Weather parse error:", e)
                }
            }
        }
    }

    // refresh weather co 10 min
    Timer {
        interval: 600000
        running: true
        repeat: true
        onTriggered: refreshWeather()
    }

    // sprawdź IP co 30 min
    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: refreshGeo()
    }

    Component.onCompleted: refreshGeo()
}
