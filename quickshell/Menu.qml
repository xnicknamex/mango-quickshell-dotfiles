import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Generic modal menu with search.
// Toggle with: qs ipc call <name> toggle
// items: [{ label: string, image: optional file path, secondary: optional glyph, ...anything }]
// Selecting an item emits activated(item). Clicking its secondary glyph (or Delete
// on the highlighted row) emits secondaryActivated(item).
// Optional input mode: ask(prompt, password) shows a prompt instead of the list;
// Enter emits submitted(text), Escape emits backRequested(). showList() returns.
Scope {
    id: menu
    required property string name
    property var items: []
    property bool open: false
    // Where long labels get cut off (Text.ElideRight / Text.ElideLeft)
    property int elide: Text.ElideRight
    // false: stay open after a selection (multi-step menus)
    property bool closeOnSelect: true
    // Status line below the list (errors, progress), hidden when empty
    property string message: ""

    property bool inputMode: false
    property string prompt: ""
    property bool password: false

    readonly property int rowHeight: 24
    readonly property int imageRowHeight: 72
    readonly property int maxHeight: 10 * rowHeight

    signal opened()
    signal activated(var item)
    signal secondaryActivated(var item)
    signal submitted(string text)
    signal backRequested()

    function show() {
        message = "";
        showList();
        open = true;
        search.forceActiveFocus();
        opened();
    }

    function hide() {
        open = false;
    }

    function select(item) {
        if (item)
            activated(item);
        if (closeOnSelect)
            hide();
    }

    function ask(promptText, isPassword) {
        prompt = promptText;
        password = isPassword;
        inputMode = true;
        search.text = "";
    }

    function showList() {
        inputMode = false;
        prompt = "";
        password = false;
        search.text = "";
        list.currentIndex = 0;
    }

    IpcHandler {
        target: menu.name
        function toggle(): void {
            menu.open ? menu.hide() : menu.show();
        }
    }

    // Transparent fullscreen layer: keeps sloppy focus from stealing focus
    // and makes the box modal
    PanelWindow {
        visible: menu.open
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        focusable: true
        color: "transparent"

        // Close when another window gets keyboard focus
        Item {
            property bool windowActive: Window.active
            onWindowActiveChanged: if (!windowActive) menu.hide()
        }

        // Click outside the box closes
        MouseArea {
            anchors.fill: parent
            onClicked: menu.hide()
        }

        Rectangle {
            anchors.centerIn: parent
            width: 400
            height: content.implicitHeight + 2
            color: "black"
            border.color: Theme.turquoise
            border.width: 1

            // Swallow clicks inside the box
            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: content
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 1
                }

                // Prompt label (input mode only)
                StyledText {
                    visible: menu.inputMode && menu.prompt !== ""
                    width: parent.width
                    height: menu.rowHeight
                    leftPadding: 6
                    rightPadding: 6
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    font.bold: true
                    text: menu.prompt
                }

                TextInput {
                    id: search
                    width: parent.width
                    height: menu.rowHeight
                    leftPadding: 6
                    rightPadding: 6
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.turquoise
                    selectionColor: Theme.turquoise
                    selectedTextColor: "black"
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    echoMode: menu.password ? TextInput.Password : TextInput.Normal

                    onTextChanged: list.currentIndex = 0

                    Keys.onPressed: event => {
                        const current = list.currentItem ? list.currentItem.modelData : null;
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (menu.inputMode)
                                menu.submitted(search.text);
                            else
                                menu.select(current);
                        } else if (event.key === Qt.Key_Escape) {
                            if (menu.inputMode)
                                menu.backRequested();
                            else
                                menu.hide();
                        } else if (event.key === Qt.Key_Down && !menu.inputMode) {
                            list.incrementCurrentIndex();
                        } else if (event.key === Qt.Key_Up && !menu.inputMode) {
                            list.decrementCurrentIndex();
                        } else if (event.key === Qt.Key_Delete && !menu.inputMode
                                   && current && current.secondary
                                   && search.cursorPosition === search.text.length) {
                            // Delete only acts on the row when it would not delete text
                            menu.secondaryActivated(current);
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }
                }

                ListView {
                    id: list
                    visible: !menu.inputMode
                    width: parent.width
                    // Shrinks with fewer results, capped at maxHeight
                    height: visible ? Math.min(contentHeight, menu.maxHeight) : 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    model: ScriptModel {
                        values: menu.inputMode ? [] : menu.items.filter(i => i.label.toLowerCase().includes(search.text.toLowerCase()))
                    }

                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool hasImage: !!modelData.image
                        readonly property bool hasSecondary: !!modelData.secondary
                        readonly property color fg: ListView.isCurrentItem ? "black" : Theme.turquoise

                        width: list.width
                        height: hasImage ? menu.imageRowHeight : menu.rowHeight
                        color: ListView.isCurrentItem ? Theme.turquoise : "black"

                        StyledText {
                            visible: !row.hasImage
                            anchors.verticalCenter: parent.verticalCenter
                            x: 6
                            width: parent.width - 12 - (row.hasSecondary ? secondary.width + 6 : 0)
                            elide: menu.elide
                            text: row.modelData.label
                            color: row.fg
                        }

                        Image {
                            visible: row.hasImage
                            x: 6
                            y: 3
                            width: parent.width - 12
                            height: parent.height - 6
                            source: row.hasImage ? "file://" + row.modelData.image : ""
                            fillMode: Image.PreserveAspectFit
                            horizontalAlignment: Image.AlignLeft
                            sourceSize.height: height
                            asynchronous: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: list.currentIndex = row.index
                            onClicked: menu.select(row.modelData)
                        }

                        // Secondary action glyph (above the row's MouseArea, takes its clicks)
                        StyledText {
                            id: secondary
                            visible: row.hasSecondary
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            text: row.modelData.secondary ?? ""
                            color: row.fg

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                onClicked: menu.secondaryActivated(row.modelData)
                            }
                        }
                    }
                }

                // Status line
                StyledText {
                    visible: menu.message !== ""
                    width: parent.width
                    leftPadding: 6
                    rightPadding: 6
                    topPadding: 4
                    bottomPadding: 4
                    wrapMode: Text.Wrap
                    text: menu.message
                }
            }
        }
    }
}
