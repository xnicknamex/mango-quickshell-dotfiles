pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property color turquoise: "#03fcf4"
    // Disabled buttons (same as mango's unfocused border)
    readonly property color purple: "#3F0685"
    readonly property string font: "monospace"
    readonly property int fontSize: 13

    // Screen frame and attached popups
    readonly property int frameWidth: 3
    // Frame corners and the bends where popups merge into the frame:
    // window radius 6 + gap 9 + frame 3 (mango's outer gap = gap + frame)
    readonly property int frameRadius: 18
    // Convex corners of attached popups (same as mango's border_radius)
    readonly property int cornerRadius: 6
    // Everything with a hover effect (except the rows in the modal)
    readonly property int hoverRadius: 4
}
