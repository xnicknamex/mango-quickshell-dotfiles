import QtQuick
import Quickshell

// Shared popup for the bar. Content goes inside and sizes the popup.
// attached (default): hangs from the screen frame's top line directly under the bar,
//   centered under `target`; if that does not fit between the frame's rounded
//   corners, it snaps into the corner and also merges into the side line.
// normal (attached: false): plain box right of `target` (tray submenus).
// grab (default): closes on click outside (native popup grab) or Escape.
PopupWindow {
    id: popup
    property Item target: null
    property bool attached: true
    property bool grab: true
    default property alias content: inner.data

    function toggle() {
        visible = !visible;
    }

    // Window the target lives in (the bar, or the parent menu for submenus)
    readonly property var hostWindow: target ? target.QsWindow.window : null
    // Target position in that window, refreshed whenever the popup opens
    readonly property rect targetRect: (visible && hostWindow) ? hostWindow.itemRect(target) : Qt.rect(0, 0, 0, 0)

    readonly property int contentWidth: Math.ceil(inner.childrenRect.width)
    readonly property int contentHeight: Math.ceil(inner.childrenRect.height)

    // Attached placement: centered, or into a corner when centered does not fit
    readonly property int topWidth: contentWidth + Theme.frameWidth + 2 * Theme.frameRadius
    readonly property int centeredX: Math.round(targetRect.x + targetRect.width / 2 - topWidth / 2)
    readonly property int edgeLimit: Theme.frameRadius + Theme.frameWidth
    readonly property int screenWidth: hostWindow ? hostWindow.width : 0
    readonly property string side: centeredX < edgeLimit ? "left"
        : centeredX + topWidth > screenWidth - edgeLimit ? "right"
        : "top"
    readonly property int attachedX: side === "left" ? 0
        : side === "right" ? screenWidth - outline.windowWidth
        : centeredX

    anchor.window: hostWindow
    anchor.rect.x: attached ? attachedX : targetRect.x
    anchor.rect.y: attached ? (hostWindow ? hostWindow.height : 0) : targetRect.y
    anchor.rect.width: attached ? 0 : targetRect.width
    anchor.rect.height: attached ? 0 : targetRect.height
    anchor.edges: attached ? (Edges.Top | Edges.Left) : (Edges.Right | Edges.Top)
    anchor.gravity: attached ? (Edges.Bottom | Edges.Right) : (Edges.Right | Edges.Bottom)
    anchor.adjustment: attached ? PopupAdjustment.None : (PopupAdjustment.FlipX | PopupAdjustment.Slide)

    grabFocus: grab
    color: "transparent"
    implicitWidth: attached ? outline.windowWidth : contentWidth + 2
    implicitHeight: attached ? outline.windowHeight : contentHeight + 2

    onVisibleChanged: if (visible && grab) keys.forceActiveFocus()

    AttachedOutline {
        id: outline
        z: -1
        visible: popup.attached
        side: popup.side
        contentWidth: popup.contentWidth
        contentHeight: popup.contentHeight
    }

    // Normal mode: plain box
    Rectangle {
        z: -1
        visible: !popup.attached
        anchors.fill: parent
        color: "black"
        border.color: Theme.turquoise
        border.width: 1
    }

    Item {
        id: inner
        x: popup.attached ? outline.contentX : 1
        y: popup.attached ? outline.contentY : 1
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: popup.visible = false
    }
}
