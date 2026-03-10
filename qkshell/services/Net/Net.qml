pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property list<NetworkDevice> devices: Networking.devices.values

    readonly property list<WifiDevice> wifiDevices: devices.filter(d => d.type === DeviceType.Wifi)

    readonly property list<NetworkDevice> connectedDevices: devices.filter(d => d.connected)

    readonly property list<NetworkDevice> connectedWifiDevices: wifiDevices.filter(d => d.connected)

    readonly property list<WifiNetwork> allWifiNetworks: flatten(wifiDevices.map(d => d.networks.values))

    readonly property list<WifiNetwork> connectedWifiNetworks: allWifiNetworks.filter(n => n.connected)


    function deviceStateStr(device) {
        if (Networking.backend === NetworkBackendType.NetworkManager)
            return NMDeviceState.toString(device.nmState)
        return DeviceConnectionState.toString(device.state)
    }

    // Component.onCompleted: {
    //     // for (var d of wifiDevices) d.scannerEnabled = true
    // }


    function flatten(lists) {
        var result = []
        for (var l of lists) {
            for (var e of l) {
                result.push(e)
            }
        }
        return result
    }
}
