pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property var workspaces: Hyprland.workspaces
    readonly property var activeToplevel: Hyprland.activeToplevel
    readonly property string activeTitle: {
        var title = activeToplevel?.title ?? ""
        var shortT = title.slice(0, 30)
        return shortT + (title.length == shortT.length ? "" : "...")
    }


    function isWsOnMonitor(ws, monitorName) {
        return ws.monitor?.name === monitorName
    }

    function focusWorkspace(ws, monitorName, mouseX, mouseY) {
        ws.activate()
        Hyprland.dispatch("focusmonitor " + monitorName)
        Hyprland.dispatch("movecursor " + mouseX + " " + mouseY)
    }
}
