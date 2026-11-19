import QtQuick

// Glyph with a hover tooltip; emits clicked() on left and rightClicked() on right click
// highlight: hover effect for buttons in popups (bar icons have none)
// fg: glyph color when not hovered (black on a highlighted row)
StyledText {
    id: icon
    property string tooltip: ""
    property bool highlight: false
    property color fg: Theme.turquoise
    readonly property bool hovered: area.containsMouse
    signal clicked()
    signal rightClicked()

    color: highlight && hovered ? "black" : fg

    Rectangle {
        z: -1
        visible: icon.highlight && icon.hovered
        anchors.fill: parent
        anchors.margins: -2
        color: Theme.turquoise
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton)
                icon.rightClicked();
            else
                icon.clicked();
        }
    }

    Tooltip {
        target: icon
        text: icon.tooltip
        shown: area.containsMouse
    }
}
