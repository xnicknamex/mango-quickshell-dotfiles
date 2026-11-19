import QtQuick
import QtQuick.Shapes

// Outline of a popup attached to the screen frame (used by BarPopup.qml).
// The popup window's top edge is the top edge of the frame's top line.
// side: "top"   = hangs from the top line, concave bends left and right
//       "left"  = top-left corner, also merges into the frame's left line
//       "right" = top-right corner, also merges into the frame's right line
// The black fill covers the frame line (and corner) wherever the popup replaces it.
Shape {
    id: outline
    property string side: "top"
    property int contentWidth: 0
    property int contentHeight: 0

    readonly property int t: Theme.frameWidth
    readonly property int b: Theme.frameRadius
    readonly property int c: Theme.cornerRadius
    // Center of the frame line's stroke
    readonly property real h: t / 2
    // Room for at least the top bend plus the bottom corner
    readonly property int ch: Math.max(contentHeight, b + c - t)
    // Center of the bottom line's stroke
    readonly property real yB: t + ch + h

    readonly property int contentX: side === "left" ? t : b + h
    readonly property int contentY: t
    readonly property int windowWidth: side === "top" ? contentWidth + t + 2 * b
        : side === "right" ? b + h + contentWidth + t
        : t + contentWidth + h + b
    readonly property int windowHeight: side === "top" ? t + ch + t : t + ch + h + b

    // Stroke: from where it leaves the frame line to where it rejoins it
    readonly property string strokePath: {
        const W = windowWidth;
        const bend = (x, y) => `A ${b} ${b} 0 0 1 ${x} ${y}`;
        const corner = (x, y) => `A ${c} ${c} 0 0 0 ${x} ${y}`;
        if (side === "left") {
            const xR = t + contentWidth + h;
            return `M ${h} ${yB + b} ${bend(h + b, yB)} L ${xR - c} ${yB} ${corner(xR, yB - c)} `
                + `L ${xR} ${h + b} ${bend(W, h)}`;
        }
        const start = `M 0 ${h} ${bend(b, h + b)} L ${b} ${yB - c} ${corner(b + c, yB)}`;
        if (side === "right") {
            const xr = W - h;
            return `${start} L ${xr - b} ${yB} ${bend(xr, yB + b)}`;
        }
        const xR = W - b;
        return `${start} L ${xR - c} ${yB} ${corner(xR, yB - c)} L ${xR} ${h + b} ${bend(W, h)}`;
    }

    // Fill: the stroke's shape closed along the window edges that touch the frame
    readonly property string fillPath: {
        const W = windowWidth;
        const rest = strokePath.replace(/^M /, "L ");
        if (side === "left")
            return `M 0 0 L 0 ${yB + b} ${rest} L ${W} 0 Z`;
        if (side === "right")
            return `M 0 0 ${rest} L ${W} ${yB + b} L ${W} 0 Z`;
        return `M 0 0 ${rest} L ${W} 0 Z`;
    }

    width: windowWidth
    height: windowHeight
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: "black"
        strokeColor: "transparent"
        strokeWidth: -1
        PathSvg {
            path: outline.fillPath
        }
    }

    ShapePath {
        fillColor: "transparent"
        strokeColor: Theme.turquoise
        strokeWidth: outline.t
        capStyle: ShapePath.FlatCap
        PathSvg {
            path: outline.strokePath
        }
    }
}
