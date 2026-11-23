import QtQuick
import Quickshell
import Quickshell.Io

// App dock on the right frame line: a 200px strip (vertically centered below the
// bar) is purple; it turns turquoise while a popup is open.
// Hover: popup with the app icons, click starts an app. Stays open while the mouse
//   is on the strip or the popup, closes 300ms after it left both.
// Right click: the same popup in edit mode, a normal popup (outside click, Escape
//   or another right click closes it). Plus: pick an app in the launcher to add it,
//   click removes, drag reorders.
// Too many icons for the screen: the list scrolls with the mouse wheel.
// The apps are listed in ./dock, one desktop entry id per line in dock order.
Scope {
    id: dock
    required property Launcher launcher

    FileView {
        id: file
        path: Quickshell.shellPath("dock")
        watchChanges: true
        onFileChanged: reload()
    }

    // Installed apps of the list, in order; unknown ids and duplicates are skipped
    readonly property var entries: {
        DesktopEntries.applications.values; // re-evaluate when apps are installed or removed
        const ids = file.text().split("\n").map(l => l.trim()).filter((l, i, all) => l !== "" && all.indexOf(l) === i);
        return ids.map(id => DesktopEntries.byId(id)).filter(e => e);
    }

    function save(list) {
        file.setText(list.map(e => e.id).join("\n") + (list.length > 0 ? "\n" : ""));
    }

    function add(id) {
        if (!entries.some(e => e.id === id))
            file.setText(entries.map(e => e.id).concat([id]).join("\n") + "\n");
    }

    function remove(entry) {
        save(entries.filter(e => e !== entry));
    }

    function move(from, to) {
        const list = entries.slice();
        list.splice(to, 0, list.splice(from, 1)[0]);
        save(list);
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenDock
            required property ShellScreen modelData

            // closed
            // hover:   loose popup (no grab), normal icons
            // edit:    grabbing popup, edit icons
            // picking: loose popup with edit icons while the launcher is open
            //          (a grabbing popup would keep the keyboard from the launcher)
            // Switching popups shows the new one first and hides the old one a
            // moment later, so the swap is not visible.
            property string mode: "closed"

            // Scroll position of the icon list, shared by both popups so a swap does
            // not jump; top when opened from closed, the icons clamp it to the end
            property real scrollY: 0
            // Icon column height that keeps the popup (with its bends) clear of the
            // frame corners: free height below the bar minus a corner above and below
            readonly property int maxIconsHeight: modelData.height - Theme.barHeight
                - 4 * Theme.frameRadius - Theme.frameWidth

            // From closed, hover or picking
            function openEdit() {
                if (mode === "closed")
                    scrollY = 0;
                mode = "edit";
                grabbed.visible = true;
                if (loose.visible)
                    hideLoose.start();
            }

            function startPick() {
                mode = "picking";
                loose.visible = true;
                hideGrabbed.start();
            }

            Connections {
                target: dock.launcher

                function onPicked(id) {
                    if (screenDock.mode === "picking") {
                        dock.add(id);
                        // Show the new app at the end
                        screenDock.scrollY = Number.MAX_SAFE_INTEGER;
                    }
                }

                function onPickFinished() {
                    if (screenDock.mode === "picking")
                        screenDock.openEdit();
                }
            }

            // After a switch away from the loose popup
            Timer {
                id: hideLoose
                interval: 100
                onTriggered: if (screenDock.mode === "edit" || screenDock.mode === "closed") loose.visible = false
            }

            // After the switch to the loose popup; the launcher opens once the grab is gone
            Timer {
                id: hideGrabbed
                interval: 100
                onTriggered: {
                    grabbed.visible = false;
                    dock.launcher.pick();
                }
            }

            // Hover mode closes 300ms after the mouse left the strip and the popup
            Timer {
                interval: 300
                running: screenDock.mode === "hover" && !stripHover.hovered && !loose.hovered
                onTriggered: {
                    screenDock.mode = "closed";
                    loose.visible = false;
                }
            }

            PanelWindow {
                id: strip
                screen: screenDock.modelData
                anchors.right: true
                // Respect the bar, reserve nothing; one anchor = centered vertically
                exclusionMode: ExclusionMode.Normal
                implicitWidth: Theme.frameWidth
                implicitHeight: 200
                color: screenDock.mode === "closed" ? Theme.purple : Theme.turquoise

                // Hover opens the normal popup, right click toggles edit mode
                Item {
                    id: stripItem
                    anchors.fill: parent

                    HoverHandler {
                        id: stripHover
                        onHoveredChanged: {
                            if (hovered && screenDock.mode === "closed" && dock.entries.length > 0) {
                                screenDock.scrollY = 0;
                                screenDock.mode = "hover";
                                loose.visible = true;
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: {
                            if (screenDock.mode === "edit")
                                grabbed.visible = false;
                            else if (screenDock.mode !== "picking")
                                screenDock.openEdit();
                        }
                    }
                }
            }

            // Hover mode, and the stand-in for edit mode while picking
            BarPopup {
                id: loose
                target: stripItem
                east: true
                grab: false

                DockIcons {
                    entries: dock.entries
                    editing: screenDock.mode === "picking"
                    maxHeight: screenDock.maxIconsHeight
                    scrollY: screenDock.scrollY
                    onScrollRequested: y => screenDock.scrollY = y
                    onLaunched: entry => {
                        screenDock.mode = "closed";
                        loose.visible = false;
                        dock.launcher.launch(entry);
                    }
                }
            }

            // Edit mode
            BarPopup {
                id: grabbed
                target: stripItem
                east: true

                // Closed from outside (click, Escape); hiding it for a pick is not a close
                onVisibleChanged: if (!visible && screenDock.mode === "edit") screenDock.mode = "closed"

                DockIcons {
                    entries: dock.entries
                    editing: true
                    maxHeight: screenDock.maxIconsHeight
                    scrollY: screenDock.scrollY
                    onScrollRequested: y => screenDock.scrollY = y
                    onRemoved: entry => dock.remove(entry)
                    onMoved: (from, to) => dock.move(from, to)
                    onAddRequested: screenDock.startPick()
                }
            }
        }
    }
}
