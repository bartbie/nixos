pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
// {
//         id: priv
//         property var screenCaptures: []
//
//         Process {
//             id: pollProc
//             command: ["pw-dump"]
//             stdout: StdioCollector {
//                 onStreamFinished: {
//                     let data
//                     try { data = JSON.parse(this.text) } catch(e) { priv.screenCaptures = []; return }
//
//                     const nodes = {}
//                     for (const obj of data) {
//                         if (obj.type === "PipeWire:Interface:Node")
//                             nodes[obj.id] = obj
//                     }
//
//                     const links = data.filter(o => o.type === "PipeWire:Interface:Link")
//
//                     const screenApps = []
//                     for (const node of Object.values(nodes)) {
//                         if ((node.info?.props?.["media.class"] ?? "") !== "Video/Source") continue
//                         for (const link of links) {
//                             if (link.info?.["output-node-id"] !== node.id) continue
//                             const consumer = nodes[link.info["input-node-id"]]
//                             if (!consumer) continue
//                             const p = consumer.info?.props ?? {}
//                             const name = p["application.name"] ?? p["application.process.binary"] ?? p["node.name"]
//                             if (name) screenApps.push(name)
//                         }
//                     }
//
//                     priv.screenCaptures = screenApps
//                 }
//             }
//         }
//
//         Timer {
//             interval: 2000
//             running: true
//             repeat: true
//             onTriggered: if (!pollProc.running) pollProc.running = true
//         }
//
//         Component.onCompleted: pollProc.running = true
//     }

Singleton {
    id: root

    readonly property var screenCaptures: {
        var captures = []
        for (let i = 0; i < Pipewire.linkGroups.count; i++) {
            var lg = Pipewire.linkGroups.peekAt(i)
            if (!lg?.source || !lg?.target) continue
            if ((lg.source.properties?.["media.class"] ?? "") !== "Video/Source") continue
            var p = lg.target.properties ?? {}
            var name = p["application.name"] ?? p["application.process.binary"] ?? p["node.name"]
            if (name) captures.push(name)
        }
        return captures
    }

    PwObjectTracker {
        objects: {
            return [
                ...Pipewire.nodes,
                ...Pipewire.linkGroups,
            ]
        }
        
    }
}
