pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property real cpuUsage: priv._cpuUsage
    readonly property real ramUsage: priv._ramUsage

    readonly property real totalRamGiB: priv.totalRam
    readonly property real availRamGiB: priv.availRam
    readonly property real usedRamGiB: priv.totalRam - priv.availRam

    Scope {
        id: priv
        property real _cpuUsage: 0
        property real _ramUsage: 0

        property real totalRam: 0
        property real availRam: 0

        property var _prevCpu: ({idle: 0, total: 0})

        Process {
            id: cpuProc
            command: ["head", "-1", "/proc/stat"]
            stdout: StdioCollector {
                onStreamFinished: {
                    console.log("CPU raw text:", JSON.stringify(this.text))
                    var cpu = this.text.trim().split("\n")[0].split(/\s+/).slice(1).map(i => Number.parseInt(i))
                    var idle = cpu[3] + cpu[4]
                    var total = cpu.reduce((acc, e) => acc + e, 0)

                    var dIdle = idle - priv._prevCpu.idle
                    var dTotal = total - priv._prevCpu.total

                    if (dTotal > 0)
                        priv._cpuUsage = 100 * (1 - dIdle / dTotal)
                    priv._prevCpu = {idle: idle, total: total}
                }
            }
        }

        Process {
            id: ramProc
            command: ["head", "-3", "/proc/meminfo"]
            stdout: StdioCollector {
                function getVal(line) {
                    // label: NN kB
                    return Number.parseInt(line.split(/\s+/)[1])
                }
                onStreamFinished: {
                    console.log("RAM raw text:", JSON.stringify(this.text))
                    var lines = this.text.trim().split("\n")
                    var total = getVal(lines[0])
                    var avail = getVal(lines[2])

                    priv.totalRam = total / (1024 ** 2)
                    priv.availRam = avail / (1024 ** 2)
                    priv._ramUsage = 100 * (1 - avail / total)
                }
            }
        }

        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: {
                cpuProc.running = true
                ramProc.running = true
            }
        }

        Component.onCompleted: {
            cpuProc.running = true
            ramProc.running = true
        }

    }

}
