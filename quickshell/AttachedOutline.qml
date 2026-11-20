import QtQuick
import QtQuick.Shapes

// Outline of a popup attached to the screen frame (used by BarPopup.qml).
// The popup window's top edge is the top edge of the frame's top line
// (for "east": its right edge is the right edge of the frame's right line).
// side: "top"   = hangs from the top line, concave bends left and right
//       "left"  = top-left corner, also merges into the frame's left line
//       "right" = top-right corner, also merges into the frame's right line
//       "east"  = grows left out of the right line, concave bends above and below
//                 ("top" turned 90°: u runs down the line, v leads away from it)
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
    readonly property bool east: side === "east"
    // Content size along the frame line and away from it
    readonly property int along: east ? contentHeight : contentWidth
    // Room for at least the first bend plus the far corner
    readonly property int ch: Math.max(east ? contentWidth : contentHeight, b + c - t)
    // Center of the far line's stroke (distance from the frame's outer edge)
    readonly property real yB: t + ch + h

    // "top" size: u along the line, v away from it
    readonly property int uSize: along + t + 2 * b
    readonly property int vSize: t + ch + t

    readonly property int contentX: east ? t + ch - contentWidth : side === "left" ? t : b + h
    readonly property int contentY: east ? b + h : t
    readonly property int windowWidth: east ? vSize
        : side === "top" ? uSize
        : side === "right" ? b + h + contentWidth + t
        : t + contentWidth + h + b
    readonly property int windowHeight: east ? uSize : side === "top" ? vSize : t + ch + h + b

    // Point in window coordinates: "east" turns (u, v) by 90°, the rest use it as (x, y)
    function p(u, v) {
        return east ? `${windowWidth - v} ${u}` : `${u} ${v}`;
    }

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
        if (east) {
            const U = uSize;
            const xR = U - b;
            return `M ${p(0, h)} A ${b} ${b} 0 0 1 ${p(b, h + b)} L ${p(b, yB - c)} A ${c} ${c} 0 0 0 ${p(b + c, yB)} `
                + `L ${p(xR - c, yB)} A ${c} ${c} 0 0 0 ${p(xR, yB - c)} L ${p(xR, h + b)} A ${b} ${b} 0 0 1 ${p(U, h)}`;
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
        if (east)
            return `M ${p(0, 0)} ${rest} L ${p(uSize, 0)} Z`;
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
