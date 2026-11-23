import QtQuick
import QtQuick.Layouts
import Quickshell

// Themed menu for a tray item, built from QsMenuOpener.
// First level: attached to the screen frame below `target`.
// Submenus (submenu: true): plain box right of their entry.
// Submenus open on hover; triggering an entry closes the whole menu tree.
// Closes on click outside (native popup grab); Escape closes this level.
BarPopup {
    id: menu
    property QsMenuHandle handle: null
    property bool submenu: false
    // Index of the entry whose submenu is open, -1 = none
    property int openIndex: -1
    readonly property int rowHeight: 22
    readonly property int iconSize: 16
    readonly property int menuWidth: 220

    // Emitted when an entry was triggered, so parent menus close too
    signal done()

    function close() {
        visible = false;
        done();
    }

    attached: !submenu

    onVisibleChanged: if (!visible) openIndex = -1

    QsMenuOpener {
        id: opener
        menu: menu.handle
    }

    Column {
        id: entries
        width: menu.menuWidth

        Repeater {
            model: opener.children

            Item {
                id: row
                required property QsMenuEntry modelData
                required property int index
                readonly property bool subOpen: menu.openIndex === index
                readonly property bool highlighted: modelData.enabled && (area.containsMouse || subOpen)
                readonly property color fg: highlighted ? "black" : Theme.turquoise

                width: entries.width
                height: modelData.isSeparator ? 7 : menu.rowHeight

                // Separator
                Rectangle {
                    visible: row.modelData.isSeparator
                    anchors.verticalCenter: parent.verticalCenter
                    x: 6
                    width: parent.width - 12
                    height: 1
                    color: Theme.turquoise
                }

                // Entry
                Rectangle {
                    visible: !row.modelData.isSeparator
                    anchors.fill: parent
                    radius: Theme.hoverRadius
                    color: row.highlighted ? Theme.turquoise : "black"
                    opacity: row.modelData.enabled ? 1 : 0.5

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 6

                        StyledText {
                            visible: row.modelData.buttonType !== QsMenuButtonType.None
                            color: row.fg
                            text: {
                                const checked = row.modelData.checkState === Qt.Checked;
                                if (row.modelData.buttonType === QsMenuButtonType.RadioButton)
                                    return checked ? "●" : "○";
                                return checked ? "✓" : " ";
                            }
                        }

                        Image {
                            visible: row.modelData.icon !== ""
                            source: row.modelData.icon
                            Layout.preferredWidth: menu.iconSize
                            Layout.preferredHeight: menu.iconSize
                            sourceSize.width: menu.iconSize
                            sourceSize.height: menu.iconSize
                            fillMode: Image.PreserveAspectFit
                        }

                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            color: row.fg
                            text: row.modelData.text
                        }

                        StyledText {
                            visible: row.modelData.hasChildren
                            color: row.fg
                            text: "›"
                        }
                    }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !row.modelData.isSeparator && row.modelData.enabled

                    onEntered: menu.openIndex = row.modelData.hasChildren ? row.index : -1
                    onClicked: {
                        if (row.modelData.hasChildren) {
                            menu.openIndex = row.index;
                        } else {
                            row.modelData.triggered();
                            menu.close();
                        }
                    }
                }

                // Submenu (via Loader, QML forbids direct self-instantiation)
                Loader {
                    active: row.subOpen
                    source: "TrayMenu.qml"
                    onLoaded: {
                        item.handle = row.modelData;
                        item.target = row;
                        item.submenu = true;
                        item.done.connect(menu.close);
                        // Submenu closed on its own (Escape, grab) -> allow reopening by hover
                        item.visibleChanged.connect(() => {
                            if (!item.visible && menu.openIndex === row.index)
                                menu.openIndex = -1;
                        });
                        item.visible = true;
                    }
                }
            }
        }
    }
}
