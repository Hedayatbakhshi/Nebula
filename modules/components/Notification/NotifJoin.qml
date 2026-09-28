import QtQuick
import QtQuick.Shapes

Item {
    id: join

    property string side: "top"
    property real r: 22
    property color color: "transparent"

    readonly property bool across: join.side === "left" || join.side === "right"

    component Flare: Shape {
        id: flare
        property bool fillRight: false
        property bool fillBottom: false
        readonly property real cx: flare.fillRight ? join.r : 0
        readonly property real cy: flare.fillBottom ? join.r : 0
        readonly property real ox: join.r - flare.cx
        readonly property real oy: join.r - flare.cy
        readonly property int sweep: (flare.cx - flare.ox) * (flare.cy - flare.oy) > 0 ? 1 : 0
        width: join.r
        height: join.r
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: join.color
            PathSvg {
                path: "M " + flare.ox + " " + flare.cy + " L " + flare.cx + " " + flare.cy + " L " + flare.cx + " " + flare.oy
                    + " A " + join.r + " " + join.r + " 0 0 " + flare.sweep + " " + flare.ox + " " + flare.cy + " Z"
            }
        }
    }

    Flare {
        x: join.across ? (join.side === "left" ? 0 : join.width - join.r) : -join.r
        y: join.across ? -join.r : (join.side === "top" ? 0 : join.height - join.r)
        fillRight: join.across ? join.side === "right" : true
        fillBottom: join.across ? true : join.side === "bottom"
    }

    Flare {
        x: join.across ? (join.side === "left" ? 0 : join.width - join.r) : join.width
        y: join.across ? join.height : (join.side === "top" ? 0 : join.height - join.r)
        fillRight: join.across ? join.side === "right" : false
        fillBottom: join.across ? false : join.side === "bottom"
    }
}
