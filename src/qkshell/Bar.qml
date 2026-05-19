pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import Quickshell.Networking
import Quickshell.Services.Pipewire

import qs.services.Net
import qs.services.Time
import qs.services.Audio
import qs.services.Resources
import qs.services.Geo
import qs.services.Laptop
import qs.services.Wm
import qs.services.CaptureMonitor
import qs.globals.Theme

Variants {
    id: root
    model: Quickshell.screens

    function toPercentString(i) {
         return Math.round(i*100) + "%"
    }

    function inParamsString(x) {
         return "(" + x + ")"
    }

    function roundRam(x) {
         return x.toFixed(1)
    }

    PanelWindow {
        id: bar
        required property var modelData
        readonly property string monitorName: modelData.name;
        screen: modelData
        color: "transparent"
        implicitHeight: 35

        anchors {
            top: true
            left: true
            right: true
        }

        Item {
            id: allWings
            anchors.fill: parent

            component Wing: WrapperItem {
                id: wing
                // property var alignment;
                required property var direction;
                property int spacing: 6;
                default property alias children: layout.children;


                implicitWidth: layout.implicitWidth
                implicitHeight: bar.height

                anchors.top: parent.top
                anchors.bottom: parent.bottom

                RowLayout {
                    id: layout
                    anchors.fill: parent
                    layoutDirection: wing.direction;
                    // Layout.alignment: wing.alignment;
                    // Layout.fillWidth: true
                    spacing: wing.spacing;
                }
            }
        
            component Island: Rectangle {
                id: island
                Layout.fillHeight: true

                readonly property int insideWidth: container.width == 0 ? 0 : container.width + 25

                Layout.preferredWidth: insideWidth
                Layout.minimumWidth: 20 // for debug

                radius: 20
                color: Theme.islandBg
                border.width: 1
                border.color: Theme.islandBorder

                default property alias children: container.children

                WrapperItem {
                    id: container
                    anchors.centerIn: island
                }
            }

            component IslandText: Text {
                font.pointSize: Theme.islandPointSize
                color: Theme.fontColor
            }

            Wing {
                // alignment: Qt.AlignLeft
                direction: Qt.LeftToRight
                anchors.left: parent.left;

                Island {
                    RowLayout {
                        Repeater {
                            model: Wm.workspaces
                            IslandText {
                                id: wsField
                                required property var modelData;
                                readonly property var ws: modelData;
                                readonly property bool isOnMonitor: Wm.isWsOnMonitor(ws, bar.monitorName);

                                text: modelData.name
                                color:
                                modelData.focused ?
                                (wsField.isOnMonitor ? Theme.wsFocusedOnThisMonitor : Theme.wsFocusedOnOtherMonitor)
                                : modelData.active ? Theme.wsActive: Theme.wsInactive;
                                font {
                                    pointSize: modelData.id <= 10 ? Theme.selectedPointSize : Theme.islandPointSize;
                                }

                                MouseArea {
                                    id: wsButton
                                    anchors.fill: parent
                                    onClicked: {
                                        var mousePos = mapToGlobal(wsButton.mouseX, wsButton.mouseY)
                                        Wm.focusWorkspace(ws, bar.monitorName, mousePos.x, mousePos.y)
                                    }
                                }
                            }
                        }
                    }
                }

                Island {
                    IslandText {
                        property bool muted: Audio.sourceMuted
                        font.bold: true
                        text: "R"
                        color: muted ? Theme.micMutedColor : Theme.micActiveColor
                    }
                }

                Island {
                    visible: CaptureMonitor.screenCaptures.length > 0
                    RowLayout {
                        Repeater {
                            model: CaptureMonitor.screenCaptures
                            RowLayout {
                                required property string modelData
                                IslandText {
                                    text: "REC:"
                                    color: Theme.screencastColor
                                    font.bold: true
                                }
                                IslandText {
                                    text: modelData
                                }
                            }
                        }
                    }
                }

                Island {
                    id: titleIsland
                    readonly property var win: Wm.activeToplevel
                    visible: win != null && (win.monitor?.name == bar.monitorName)
                    IslandText {
                        text: Wm.activeTitle
                    }
                }

            }
            Wing {
                // alignment: Qt.AlignHCenter
                direction: Qt.LeftToRight
                anchors.centerIn: parent;

                Island {
                    IslandText {
                        text: Time.time_ss;
                        font {
                            // bold: true
                            pointSize: Theme.clockPointSize
                        }
                    }
                }

            }
            Wing {
                // alignment: Qt.AlignRight
                direction: Qt.LeftToRight
                anchors.right: parent.right;

                Island {
                    WrapperMouseArea {
                        onWheel: event => {
                            Audio.bumpVolumeFromMouseDelta(event.angleDelta.y)
                        }
                        RowLayout {
                            id: audioRoot
                            IslandText {
                                text: Audio.sinkName
                                color: Theme.audioColor
                                font.bold: true
                            }
                            Text {
                                font.pointSize: Theme.islandPointSize
                                color: Theme.fontColor
                                textFormat: Text.RichText
                                text: `<span style="color:${Theme.dimColor}">(</span>${toPercentString(Audio.volume)}${Audio.muted ? " muted" : ""}<span style="color:${Theme.dimColor}">)</span>`
                            }

                        }
                    }
                }

                Island {
                    RowLayout {
                        Repeater {
                            model: Net.connectedWifiNetworks
                            RowLayout {
                                id: network
                                required property var modelData;

                                IslandText {
                                    text: modelData.name
                                    color: Theme.wifiColor
                                    font.bold: true
                                }
                                // IslandText {
                                //     text: NetworkState.toString(modelData.state)
                                // }
                                Text {
                                    font.pointSize: Theme.islandPointSize
                                    color: Theme.fontColor
                                    textFormat: Text.RichText
                                    text: `<span style="color:${Theme.dimColor}">(</span>${toPercentString(modelData.signalStrength)}<span style="color:${Theme.dimColor}">)</span>`
                                }
                            }
                        }
                    }
                }

                Island {
                    RowLayout {
                        IslandText {
                            text: "CPU:"
                            color: Theme.cpuColor
                            font.bold: true
                        }
                        IslandText {
                            text: `${Math.round(Resources.cpuUsage)}%`
                        }
                    }
                }

                Island {
                    RowLayout {
                        IslandText {
                            text: "RAM:"
                            color: Theme.ramColor
                            font.bold: true
                        }
                        Text {
                            font.pointSize: Theme.islandPointSize
                            color: Theme.fontColor
                            textFormat: Text.RichText
                            text: `${roundRam(Resources.usedRamGiB)}/${roundRam(Resources.totalRamGiB)}Gb <span style="color:${Theme.dimColor}">(</span>${Math.round(Resources.ramUsage)}%<span style="color:${Theme.dimColor}">)</span>`
                        }
                    }
                }

                Island {
                    visible: Laptop.hasBattery
                    RowLayout {
                        IslandText {
                            text: "BAT:"
                            color: Theme.batteryColor
                            font.bold: true
                        }
                        IslandText {
                            text: `${Math.round(Laptop.batteryPercent)}%${Laptop.charging ? " +" : ""}`
                        }
                    }
                }

                Island {
                    RowLayout {
                        IslandText {
                            text: Geo.city
                            color: Theme.weatherColor
                            font.bold: true
                        }
                        IslandText {
                            text: `${Geo.temperature}${Geo.unit}`
                        }
                    }
                }

            }
        }
    }
}
