import QtQuick
import Quickshell.Services.Pipewire

// One audio node: [default marker] name, mute icon, slider, percent.
// Device rows (canBeDefault): the whole row is clickable and makes the device the
// default (emits setDefault()); the mute icon and the slider keep their own clicks.
// The row is highlighted on hover, except while the mute icon or slider is hovered.
Rectangle {
    id: row
    required property PwNode node
    property var icons: ["󰕾", "󰖁"]
    property bool canBeDefault: false
    property bool isDefault: false

    signal setDefault()

    readonly property real volume: node.audio?.volume ?? 0
    readonly property bool muted: node.audio?.muted ?? false
    // Apps: application name, devices: human readable description
    readonly property string label: node.isStream
        ? (node.properties?.["application.name"] || node.description || node.name)
        : (node.description || node.name)
    readonly property bool highlighted: canBeDefault && hover.hovered && !mute.hovered && !slider.hovered
    readonly property color fg: highlighted ? "black" : Theme.turquoise

    implicitHeight: layout.implicitHeight + 4
    radius: Theme.hoverRadius
    color: highlighted ? Theme.turquoise : "black"

    HoverHandler {
        id: hover
        enabled: row.canBeDefault
    }

    MouseArea {
        anchors.fill: parent
        enabled: row.canBeDefault
        onClicked: row.setDefault()
    }

    Row {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        StyledText {
            width: layout.width - mute.width - slider.width - percent.width - 3 * layout.spacing
            elide: Text.ElideRight
            color: row.fg
            text: (row.canBeDefault ? (row.isDefault ? "● " : "○ ") : "") + row.label
        }

        BarIcon {
            id: mute
            highlight: true
            fg: row.fg
            text: row.muted ? row.icons[1] : row.icons[0]
            onClicked: row.node.audio.muted = !row.muted
        }

        VolumeSlider {
            id: slider
            anchors.verticalCenter: parent.verticalCenter
            inverted: row.highlighted
            value: row.volume
            onMoved: newValue => row.node.audio.volume = newValue
        }

        StyledText {
            id: percent
            width: 40
            horizontalAlignment: Text.AlignRight
            color: row.fg
            text: Math.round(row.volume * 100) + "%"
        }
    }
}
