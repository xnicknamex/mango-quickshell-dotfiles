import QtQuick

// Tooltip below `target`, attached to the screen frame like the bar popups.
// Visible while `shown` is true and there is text.
BarPopup {
    id: tip
    property string text: ""
    property bool shown: false

    grab: false
    visible: shown && text !== ""

    StyledText {
        leftPadding: 6
        rightPadding: 6
        topPadding: 4
        bottomPadding: 4
        text: tip.text
    }
}
