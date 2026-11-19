import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

// Player chooser below the media entry: "Auto" plus one row per player with
// prev / play-pause / next buttons. Buttons act on that row's player and keep
// the popup open. Clicking the rest of a row pins that player (Auto unpins)
// and closes the popup. ● marks the current choice.
// Rows highlight on hover; hovering a button highlights only the button.
BarPopup {
    id: popup
    required property Media media
    readonly property int rowHeight: 22

    Column {
        id: content
        width: 398
        padding: 6
        spacing: 4

        // Auto
        Rectangle {
            width: content.width - 2 * content.padding
            height: popup.rowHeight
            color: autoHover.hovered ? Theme.turquoise : "black"

            HoverHandler {
                id: autoHover
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 6
                color: autoHover.hovered ? "black" : Theme.turquoise
                text: (popup.media.isPinned ? "  " : "● ") + "Auto"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    popup.media.pinned = null;
                    popup.visible = false;
                }
            }
        }

        Repeater {
            model: ScriptModel {
                values: popup.media.players
            }

            Rectangle {
                id: row
                required property MprisPlayer modelData
                // Row hover, except while one of its buttons is hovered
                readonly property bool highlighted: hover.hovered && !prev.hovered && !play.hovered && !next.hovered
                readonly property color fg: highlighted ? "black" : Theme.turquoise

                width: content.width - 2 * content.padding
                height: popup.rowHeight
                color: highlighted ? Theme.turquoise : "black"

                HoverHandler {
                    id: hover
                }

                // Row click: pin and close (buttons sit above and take their own clicks)
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        popup.media.pinned = row.modelData;
                        popup.visible = false;
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 8

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        color: row.fg
                        text: (popup.media.isPinned && popup.media.pinned === row.modelData ? "● " : "  ")
                            + popup.media.describe(row.modelData)
                    }

                    BarIcon {
                        id: prev
                        highlight: true
                        fg: row.fg
                        text: "󰒮"
                        disabled: !row.modelData.canGoPrevious
                        onClicked: popup.media.previous(row.modelData)
                    }

                    BarIcon {
                        id: play
                        highlight: true
                        fg: row.fg
                        text: row.modelData.isPlaying ? "󰏤" : "󰐊"
                        disabled: !row.modelData.canTogglePlaying
                        onClicked: popup.media.playPause(row.modelData)
                    }

                    BarIcon {
                        id: next
                        highlight: true
                        fg: row.fg
                        text: "󰒭"
                        disabled: !row.modelData.canGoNext
                        onClicked: popup.media.next(row.modelData)
                    }
                }
            }
        }
    }
}
