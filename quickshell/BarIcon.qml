import QtQuick

// Glyph with a hover tooltip; emits clicked() on left and rightClicked() on right click
// highlight: hover effect for buttons in popups (bar icons have none)
// fg: glyph color when not hovered (black on a highlighted row)
// disabled: purple glyph, no hover effect, clicks do nothing
StyledText {
    id: icon
    property string tooltip: ""
    property bool highlight: false
    property color fg: Theme.turquoise
    property bool disabled: false
    readonly property bool hovered: area.containsMouse
    signal clicked()
    signal rightClicked()

    color: disabled ? Theme.purple : highlight && hovered ? "black" : fg

    Rectangle {
        z: -1
        visible: icon.highlight && icon.hovered && !icon.disabled
        anchors.fill: parent
        anchors.margins: -2
        radius: Theme.hoverRadius
        color: Theme.turquoise
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        // Still takes the clicks while disabled, so they do not reach the row below
        onClicked: event => {
            if (icon.disabled)
                return;
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
