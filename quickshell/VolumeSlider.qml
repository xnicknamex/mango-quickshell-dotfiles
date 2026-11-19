import QtQuick

// Volume slider: shows 0-100% (full when above), left drag emits moved(newValue)
// capped to 0..1, right click emits rightClicked()
// inverted: black on turquoise, for highlighted rows
Item {
    id: slider
    property real value: 0
    property bool inverted: false
    readonly property bool hovered: area.containsMouse

    signal moved(real newValue)
    signal rightClicked()

    implicitWidth: 60
    implicitHeight: 12

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        color: slider.inverted ? Theme.turquoise : "black"
        border.color: slider.inverted ? "black" : Theme.turquoise
        border.width: 1

        Rectangle {
            width: parent.width * Math.min(Math.max(slider.value, 0), 1)
            height: parent.height
            color: slider.inverted ? "black" : Theme.turquoise
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        function setFrom(x) {
            slider.moved(Math.min(Math.max(x / width, 0), 1));
        }

        onPressed: event => {
            if (event.button === Qt.RightButton)
                slider.rightClicked();
            else
                setFrom(event.x);
        }
        onPositionChanged: event => {
            if (pressedButtons & Qt.LeftButton)
                setFrom(event.x);
        }
    }
}
