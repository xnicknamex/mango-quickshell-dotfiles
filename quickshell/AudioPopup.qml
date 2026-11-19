import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Popup below `target`: devices (default, volume, mute) and a flat list of apps.
// sinks: true = outputs + playing apps, false = inputs + recording apps.
BarPopup {
    id: popup
    property bool sinks: true

    readonly property int deviceType: sinks ? PwNodeType.AudioSink : PwNodeType.AudioSource
    readonly property int streamType: sinks ? PwNodeType.AudioOutStream : PwNodeType.AudioInStream
    readonly property PwNode defaultNode: sinks ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource
    readonly property var devices: [...Pipewire.nodes.values].filter(n => n.type === deviceType)
    readonly property var streams: [...Pipewire.nodes.values].filter(n => n.type === streamType)
    readonly property var icons: sinks ? ["󰕾", "󰖁"] : ["󰍬", "󰍭"]

    function setDefault(node) {
        if (sinks)
            Pipewire.preferredDefaultAudioSink = node;
        else
            Pipewire.preferredDefaultAudioSource = node;
    }

    // Volume, mute and app names are only valid while bound; bind only while open
    PwObjectTracker {
        objects: popup.visible ? [...popup.devices, ...popup.streams] : []
    }

    Column {
        id: content
        width: 318
        padding: 6
        spacing: 4

        StyledText {
            leftPadding: 6
            text: popup.sinks ? "Outputs" : "Inputs"
            font.bold: true
        }

        Repeater {
            model: ScriptModel {
                values: popup.devices
            }

            VolumeRow {
                required property PwNode modelData
                node: modelData
                width: content.width - 2 * content.padding
                icons: popup.icons
                canBeDefault: true
                isDefault: modelData === popup.defaultNode
                onSetDefault: popup.setDefault(modelData)
            }
        }

        StyledText {
            visible: popup.streams.length > 0
            leftPadding: 6
            text: popup.sinks ? "Apps" : "Recording"
            font.bold: true
        }

        Repeater {
            model: ScriptModel {
                values: popup.streams
            }

            VolumeRow {
                required property PwNode modelData
                node: modelData
                width: content.width - 2 * content.padding
                icons: popup.icons
            }
        }
    }
}
