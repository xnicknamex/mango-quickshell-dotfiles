import QtQuick
import Quickshell

// Icon column of the dock popups (Dock.qml); both popups show one of these.
// Normal: clicking an icon emits launched(entry).
// editing: a plus on top emits addRequested(), clicking an icon emits removed(entry),
//   dragging an icon reorders (the others make room), moved(from, to) on release.
// Hovered icons get a 1px turquoise border.
// Taller than maxHeight: the icons scroll with the mouse wheel (the plus stays), a thin
// bar on the left shows the visible part. The scroll position is kept by the owner
// (scrollY in, scrollRequested out) so both dock popups show the same position.
Column {
    id: icons
    property var entries: []
    property bool editing: false
    property int maxHeight: 100000
    property real scrollY: 0
    readonly property int cell: 36
    readonly property int slot: cell + spacing

    // Visible height of the icon list, and the clamped scroll position
    readonly property int viewHeight: Math.min(list.height, maxHeight - topPadding - bottomPadding - (editing ? slot : 0))
    readonly property real maxScroll: Math.max(0, list.height - viewHeight)
    readonly property real scroll: Math.max(0, Math.min(scrollY, maxScroll))

    signal launched(var entry)
    signal removed(var entry)
    signal moved(int from, int to)
    signal addRequested()
    signal scrollRequested(real y)

    padding: 4
    spacing: 2

    Rectangle {
        visible: icons.editing
        // Above the list, so icons scrolled under it do not take its clicks
        z: 1
        width: icons.cell
        height: icons.cell
        radius: Theme.hoverRadius
        color: "black"
        border.color: Theme.turquoise
        border.width: plusArea.containsMouse ? 1 : 0

        StyledText {
            anchors.centerIn: parent
            font.pixelSize: 24
            text: "󰐕"
        }

        MouseArea {
            id: plusArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: icons.addRequested()
        }
    }

    Item {
        visible: icons.entries.length > 0
        width: icons.cell
        height: icons.viewHeight

        // One wheel notch = one icon; touchpads scroll by pixels
        WheelHandler {
            onWheel: event => {
                const delta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y / 120 * icons.slot;
                icons.scrollRequested(Math.max(0, Math.min(icons.scroll - delta, icons.maxScroll)));
            }
        }

        // Scroll indicator in the padding left of the icons, only when scrollable
        Rectangle {
            visible: icons.maxScroll > 0
            x: -3
            y: icons.scroll / list.height * parent.height
            width: 2
            height: parent.height * parent.height / list.height
            radius: 1
            color: Theme.turquoise
        }

        Item {
            id: viewport
            anchors.fill: parent
            clip: true

            // Icons are placed by hand so the dragged one can float above the others
            Item {
                id: list
                y: -icons.scroll
                // Index being dragged and the slot it would drop into, -1 = no drag
                property int dragFrom: -1
                property int dragTo: -1
                // Set on a drop, so the release does not also count as a click
                property bool dropped: false

                width: icons.cell
                height: Math.max(0, icons.entries.length * icons.slot - icons.spacing)

                Repeater {
                    model: icons.entries

                    Rectangle {
                        id: tile
                        required property var modelData
                        required property int index
                        // Slot shown in: the others move up or down to make room for the dragged one
                        readonly property int slotIndex: {
                            const from = list.dragFrom, to = list.dragTo;
                            if (from < 0 || from === index)
                                return index;
                            if (from < index && index <= to)
                                return index - 1;
                            if (to <= index && index < from)
                                return index + 1;
                            return index;
                        }

                        z: list.dragFrom === index ? 1 : 0
                        y: slotIndex * icons.slot
                        width: icons.cell
                        height: icons.cell
                        radius: Theme.hoverRadius
                        color: "black"
                        border.color: Theme.turquoise
                        border.width: area.containsMouse ? 1 : 0

                        Image {
                            anchors.centerIn: parent
                            width: 32
                            height: 32
                            sourceSize.width: width
                            sourceSize.height: height
                            fillMode: Image.PreserveAspectFit
                            source: Quickshell.iconPath(tile.modelData.icon, "application-x-executable")
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            // Icons scrolled out of view take no mouse input
                            enabled: tile.y + list.y + icons.cell > 0 && tile.y + list.y < viewport.height
                            hoverEnabled: true
                            drag.target: icons.editing ? tile : null
                            drag.axis: Drag.YAxis
                            drag.minimumY: 0
                            drag.maximumY: list.height - icons.cell

                            onPressed: list.dropped = false
                            onPositionChanged: {
                                if (!drag.active)
                                    return;
                                list.dragFrom = tile.index;
                                list.dragTo = Math.max(0, Math.min(icons.entries.length - 1, Math.round(tile.y / icons.slot)));
                            }
                            onReleased: {
                                if (list.dragFrom < 0)
                                    return;
                                const from = list.dragFrom, to = list.dragTo;
                                list.dragFrom = -1;
                                list.dragTo = -1;
                                list.dropped = true;
                                // Dragging replaced the binding, put it back
                                tile.y = Qt.binding(() => tile.slotIndex * icons.slot);
                                if (from !== to)
                                    icons.moved(from, to);
                            }
                            onClicked: {
                                if (list.dropped)
                                    return;
                                if (icons.editing)
                                    icons.removed(tile.modelData);
                                else
                                    icons.launched(tile.modelData);
                            }
                        }
                    }
                }
            }
        }
    }
}
