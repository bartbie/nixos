pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    // yeah hardcoded
    readonly property string city: "Szczecin"
    readonly property string unit: "°C"
    readonly property real temperature: priv.temp

    Scope {
        id: priv
        property real lat: 0
        property real lon: 0
        property real temp: NaN

        // Step 1: geocode city name to coords
        Process {
            id: geoProc
            command: ["curl", "-s", "https://geocoding-api.open-meteo.com/v1/search?name=" + root.city + "&count=1"]
            stdout: StdioCollector {
                onStreamFinished: {
                    let json = JSON.parse(this.text)
                    if (json && json.results && json.results.length > 0) {
                        priv.lat = json.results[0].latitude
                        priv.lon = json.results[0].longitude
                        weatherProc.running = true
                    }
                }
            }
        }

        // Step 2: fetch weather with coords
        Process {
            id: weatherProc
            command: ["curl", "-s", "https://api.open-meteo.com/v1/forecast?latitude=" + priv.lat + "&longitude=" + priv.lon + "&current_weather=true"]
            stdout: StdioCollector {
                onStreamFinished: {
                    let json = JSON.parse(this.text)
                    priv.temp = json.current_weather.temperature
                }
            }
        }

        Timer {
            property int intervalDyn: (3*600000) // 30 min
            interval: intervalDyn
            running: priv.lat !== 0
            repeat: true
            onTriggered: {
                intervalDyn = isNaN(priv.temp)
                ? 10000 // 10 sec
                : (3*600000) // 30 min
                weatherProc.running = true
            }
        }

        Component.onCompleted: geoProc.running = true
    }
}
