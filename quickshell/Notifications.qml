import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

// Notification popups modeled on mako's defaults:
// top right, newest on top, left click = default action, right click = dismiss.
// Overlay layer so they show above fullscreen windows. Not attached to the screen frame.
// Supported hints: "value" (progress bar), "x-canonical-private-synchronous" (replace by tag).
Scope {
    id: root
    readonly property int maxVisible: 10
    readonly property int popupWidth: 300
    readonly property int maxHeight: 100
    readonly property int padding: 5
    readonly property int borderSize: 2
    readonly property int margin: 10
    readonly property int iconSize: 64
    readonly property int progressHeight: 4
    readonly property string syncHint: "x-canonical-private-synchronous"

    // Notification image first, otherwise the app icon (like mako)
    function iconSource(n) {
        if (n.image !== "")
            return n.image;
        if (n.appIcon === "")
            return "";
        if (n.appIcon.startsWith("file:"))
            return n.appIcon;
        if (n.appIcon.startsWith("/"))
            return "file://" + n.appIcon;
        return Quickshell.iconPath(n.appIcon, true);
    }

    // mako's invoke-default-action: run the "default" action, dismiss if there is none
    function invokeDefault(n) {
        for (const action of n.actions) {
            if (action.identifier === "default") {
                action.invoke();
                return;
            }
        }
        n.dismiss();
    }

    NotificationServer {
        id: server
        imageSupported: true
        actionsSupported: true
        bodyMarkupSupported: true

        onNotification: n => {
            // A notification with a sync tag replaces older ones with the same tag
            const tag = n.hints[root.syncHint];
            const shown = [...server.trackedNotifications.values];
            if (tag !== undefined) {
                for (const old of shown) {
                    if (old.hints[root.syncHint] === tag)
                        old.dismiss();
                }
            }

            // Over the limit: drop the oldest before adding the new one
            const remaining = server.trackedNotifications.values;
            if (remaining.length >= root.maxVisible)
                remaining[0].dismiss();

            // Quickshell drops notifications that are not tracked
            n.tracked = true;
        }
    }

    PanelWindow {
        visible: server.trackedNotifications.values.length > 0
        anchors {
            top: true
            right: true
        }
        margins {
            top: root.margin
            right: root.margin
        }
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"
        implicitWidth: root.popupWidth
        implicitHeight: popups.implicitHeight

        Column {
            id: popups
            width: parent.width
            spacing: root.margin

            Repeater {
                // Newest on top
                model: ScriptModel {
                    values: [...server.trackedNotifications.values].reverse()
                }

                Rectangle {
                    id: popup
                    required property Notification modelData
                    readonly property int inset: root.borderSize + root.padding
                    readonly property var progress: modelData.hints.value
                    // The default action is the click on the popup itself
                    readonly property var actions: [...modelData.actions].filter(a => a.identifier !== "default")

                    width: popups.width
                    height: layout.implicitHeight + 2 * inset
                    color: "black"
                    border.color: Theme.turquoise
                    border.width: root.borderSize

                    // Only expires if the app asked for it (mako: default-timeout=0).
                    // expireTimeout is the raw D-Bus value in ms.
                    Timer {
                        interval: Math.max(popup.modelData.expireTimeout, 1)
                        running: popup.modelData.expireTimeout > 0
                        onTriggered: popup.modelData.expire()
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton)
                                popup.modelData.dismiss();
                            else
                                root.invokeDefault(popup.modelData);
                        }
                    }

                    Column {
                        id: layout
                        x: popup.inset
                        y: popup.inset
                        width: parent.width - 2 * popup.inset
                        spacing: root.padding

                        // Clips content taller than maxHeight; the action buttons stay visible below
                        Item {
                            width: parent.width
                            height: Math.min(content.implicitHeight, root.maxHeight - 2 * popup.inset)
                            clip: true

                            Row {
                                id: content
                                width: parent.width
                                spacing: root.padding

                                Image {
                                    id: icon
                                    source: root.iconSource(popup.modelData)
                                    visible: source != ""
                                    width: root.iconSize
                                    height: root.iconSize
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: root.iconSize
                                    sourceSize.height: root.iconSize
                                }

                                Column {
                                    width: content.width - (icon.visible ? root.iconSize + content.spacing : 0)
                                    spacing: root.padding

                                    StyledText {
                                        width: parent.width
                                        text: popup.modelData.summary
                                        font.bold: true
                                        wrapMode: Text.Wrap
                                        textFormat: Text.PlainText
                                    }

                                    StyledText {
                                        visible: text !== ""
                                        width: parent.width
                                        text: popup.modelData.body
                                        wrapMode: Text.Wrap
                                        textFormat: Text.StyledText
                                    }

                                    // Progress bar for the "value" hint (0-100, wider values are capped)
                                    Item {
                                        visible: popup.progress !== undefined
                                        width: parent.width
                                        height: root.progressHeight

                                        Rectangle {
                                            width: parent.width * Math.min(Math.max(popup.progress || 0, 0), 100) / 100
                                            height: parent.height
                                            color: Theme.turquoise
                                        }
                                    }
                                }
                            }
                        }

                        // Non-default actions as buttons. Left click runs the action; they only
                        // take the left button, so a right click falls through and dismisses.
                        Flow {
                            visible: popup.actions.length > 0
                            width: parent.width
                            spacing: root.padding

                            Repeater {
                                model: popup.actions

                                Rectangle {
                                    id: button
                                    required property NotificationAction modelData

                                    width: label.implicitWidth + 2 * root.padding
                                    height: label.implicitHeight + 2
                                    color: area.containsMouse ? Theme.turquoise : "black"
                                    border.color: Theme.turquoise
                                    border.width: 1

                                    StyledText {
                                        id: label
                                        anchors.centerIn: parent
                                        text: button.modelData.text
                                        color: area.containsMouse ? "black" : Theme.turquoise
                                    }

                                    MouseArea {
                                        id: area
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: button.modelData.invoke()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
