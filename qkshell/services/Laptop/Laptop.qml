pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    Scope {
        id: priv
        readonly property var dev: UPower.displayDevice
    }

    readonly property bool hasBattery: priv.dev.ready && priv.dev.isLaptopBattery
    readonly property bool charging:  priv.dev.ready ? (priv.dev?.state == UPowerDeviceState.Charging) : false
    readonly property real batteryPercent: priv.dev.ready ? priv.dev.percentage : NaN
}
