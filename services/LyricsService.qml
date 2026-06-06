pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.services as Services

QtObject {
    id: root

    property var lines: []
    property bool loaded: false
    property string status
    property string trackid

    // Poll Spotify status every 2 seconds
    property Timer statusPoller: Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: checkSpotify.running = true
    }

    property Process checkSpotify: Process {
        command: ["playerctl", "-p", "spotify", "status"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.status = text.trim()
                if (root.status === "Playing")
                    getTrackId.running = true
            }
        }
    }

    property Process getTrackId: Process {
        command: ["playerctl", "-p", "spotify", "metadata", "mpris:trackid"]

        stdout: StdioCollector {
            onStreamFinished: {
                let raw = text.trim()
                let parts = raw.split("/")
                let id = parts[parts.length - 1]

                if (root.trackid !== id) {
                    root.trackid = id
                    root.loaded = false
                    root.fetchLyrics(id)
                    console.log("Track ID:", id)
                }
            }
        }
    }

    function fetchLyrics(trackId) {
        let artist = encodeURIComponent(Services.Media.artist)
        let title  = encodeURIComponent(Services.Media.title)

        if (!artist || !title)
            return

        let xhr = new XMLHttpRequest()
        xhr.open("GET",
            "https://lrclib.net/api/get?artist_name=" + artist + "&track_name=" + title
        )

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        let data = JSON.parse(xhr.responseText)

                        // Wybieramy najpierw synchronizowane napisy, jeśli są
                        if (data.syncedLyrics) {
                            root.lines = parseLRC(data.syncedLyrics)
                        } else if (data.plainLyrics) {
                            // fallback na zwykłe napisy
                            root.lines = [{
                                startTimeMs: "0",
                                words: data.plainLyrics.replace(/\n/g, " ")
                            }]
                        } else {
                            root.lines = []
                        }

                        root.loaded = true
                    } catch(e) {
                        root.lines = []
                        root.loaded = true
                        console.error("Error parsing lyrics:", e)
                    }
                } else {
                    root.lines = []
                    root.loaded = true
                    console.error("Lyrics fetch failed:", xhr.status)
                }
            }
        }

        xhr.send()
    }

    function parseLRC(lrc) {
        let result = []
        let lines = lrc.split("\n")

        for (let line of lines) {
            let match = line.match(/\[(\d+):(\d+\.\d+)\](.*)/)
            if (!match)
                continue

            let min = parseInt(match[1])
            let sec = parseFloat(match[2])
            let text = match[3].trim()

            result.push({
                startTimeMs: Math.floor((min * 60 + sec) * 1000).toString(),
                words: text
            })
        }

        return result
    }

    function currentLine(positionSeconds) {
        if (!lines || lines.length === 0)
            return ""

        let posMs = positionSeconds * 1000

        for (let i = lines.length - 1; i >= 0; i--) {
            if (posMs >= parseInt(lines[i].startTimeMs))
                return lines[i].words
        }

        return ""
    }
}
