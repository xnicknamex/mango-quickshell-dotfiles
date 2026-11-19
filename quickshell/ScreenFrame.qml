import QtQuick
import Quickshell
import Quickshell.Wayland

// Turquoise rounded frame around each screen, starting directly below the bar.
// Bottom layer: below windows; mango's outer gap (frame + 3px) keeps tiled
// windows inside it, fullscreen windows cover it. Click-through.
Variants {
    model: Quickshell.screens

    PanelWindow {
        required property ShellScreen modelData
        screen: modelData

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        // Respect the bar's reserved space, reserve nothing itself
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Bottom
        color: "transparent"
        // Empty input region: clicks and scrolling pass through
        mask: Region {}

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Theme.turquoise
            border.width: Theme.frameWidth
            radius: Theme.frameRadius
        }
    }
}
