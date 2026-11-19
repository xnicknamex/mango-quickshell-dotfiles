import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Volume control via PipeWire. Used by the bar and by mango keybinds:
// qs ipc call audio <volumeUp|volumeDown|toggleMute|toggleMicMute>
Scope {
    id: audio
    // Same cubic scale as wpctl, so 0.02 = "wpctl set-volume ... 2%+"
    readonly property real step: 0.02
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false
    // Same text as waybar: "{desc}: {volume}%" and "{node_name}"
    readonly property string sinkTooltip: sink ? `${sink.description || sink.name}: ${Math.round(volume * 100)}%` : ""
    readonly property string sourceTooltip: source?.name ?? ""

    // Values for the next volume notification
    property real notifyVolume: 0
    property bool notifyMuted: false

    // Node volume/mute are only valid while bound
    PwObjectTracker {
        objects: [audio.sink, audio.source]
    }

    // Bundles rapid changes (key repeat, slider drag): at most one notify-send
    // every 50ms, always with the latest value. Each one replaces the previous
    // popup via the sync hint, so only one volume notification is visible.
    Timer {
        id: notifyTimer
        interval: 50
        onTriggered: {
            const percent = Math.round(audio.notifyVolume * 100);
            Quickshell.execDetached([
                "notify-send", "-t", "1000", "-a", "wp-vol",
                "-h", "string:x-canonical-private-synchronous:volume",
                "-h", "int:value:" + percent,
                (audio.notifyMuted ? "Muted " : "Volume: ") + percent + "%"
            ]);
        }
    }

    function notify(volume, muted) {
        notifyVolume = volume;
        notifyMuted = muted;
        if (!notifyTimer.running)
            notifyTimer.start();
    }

    function setVolume(value) {
        if (!sink)
            return;
        const v = Math.max(0, value);
        sink.audio.volume = v;
        notify(v, muted);
    }

    function changeVolume(delta) {
        setVolume(volume + delta);
    }

    function toggleMute() {
        if (!sink)
            return;
        const m = !muted;
        sink.audio.muted = m;
        notify(volume, m);
    }

    function toggleMicMute() {
        if (source)
            source.audio.muted = !micMuted;
    }

    IpcHandler {
        target: "audio"

        function volumeUp(): void {
            audio.changeVolume(audio.step);
        }

        function volumeDown(): void {
            audio.changeVolume(-audio.step);
        }

        function toggleMute(): void {
            audio.toggleMute();
        }

        function toggleMicMute(): void {
            audio.toggleMicMute();
        }
    }
}
