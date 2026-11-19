import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

// System tray like waybar: passive items hidden, left click activates
// (or opens the menu for menu-only items), middle click = secondary activate,
// right click = themed menu, scroll is forwarded to the app.
Row {
    spacing: 7

    Repeater {
        model: ScriptModel {
            values: [...SystemTray.items.values].filter(i => i.status !== Status.Passive)
        }

        Item {
            id: trayItem
            required property SystemTrayItem modelData
            // Collects touchpad scrolling until it adds up to one wheel notch (120)
            property real scrollRest: 0

            anchors.verticalCenter: parent.verticalCenter
            width: 13
            height: 13

            Image {
                anchors.fill: parent
                source: trayItem.modelData.icon
                sourceSize.width: width
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                onClicked: event => {
                    const item = trayItem.modelData;
                    if (event.button === Qt.MiddleButton)
                        item.secondaryActivate();
                    else if ((event.button === Qt.RightButton || item.onlyMenu) && item.hasMenu)
                        menu.visible = !menu.visible;
                    else if (event.button === Qt.LeftButton)
                        item.activate();
                }

                onWheel: event => {
                    trayItem.scrollRest += event.angleDelta.y;
                    const steps = Math.trunc(trayItem.scrollRest / 120);
                    if (steps !== 0) {
                        trayItem.scrollRest -= steps * 120;
                        trayItem.modelData.scroll(steps, false);
                    }
                }
            }

            Tooltip {
                target: trayItem
                shown: area.containsMouse
                // No tooltip while the menu is open
                text: menu.visible ? "" : [
                    trayItem.modelData.tooltipTitle || trayItem.modelData.title,
                    trayItem.modelData.tooltipDescription
                ].filter(l => l).join("\n")
            }

            TrayMenu {
                id: menu
                handle: trayItem.modelData.menu
                target: trayItem
            }
        }
    }
}
