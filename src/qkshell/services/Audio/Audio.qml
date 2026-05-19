pragma Singleton

import Quickshell
import QtQuick
import Quickshell.Services.Pipewire
import "./scroll_volume.js" as JS

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property string sinkName: root.sink?.nickname ?? ""

    // readonly property bool sourceRunning: source?.audio.muted === PwLinkState
    readonly property bool sourceMuted: source?.audio?.muted ?? true

    readonly property bool muted: (sink?.ready ?? false) && (sink?.audio?.muted ?? false)
    readonly property real volume: (sink?.ready ?? false) && (sink?.audio?.volume ?? 0)

    function setSinkVolume(volume: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, volume));
        }
    }

    function bumpSinkVolume(delta): void {
        setSinkVolume(delta + root.volume)
    }

    function toggleMuteSink(): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = Boolean(root.muted ^ true);
        }
    } 

    function toggleMuteSource(): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = Boolean(root.source.audio.muted ^ true);
        }
    }

    function bumpVolumeFromMouseDelta(y): void {
        var delta = JS.processRaw(y)
        root.bumpSinkVolume(delta)
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }
}
