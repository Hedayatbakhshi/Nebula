import QtQuick
import QtQuick.Shapes
import qs.modules.utils

Item {
    id: root

    property real value: 0
    property var zones: [0.7, 0.9]
    property var zoneColors: [Colors.tertiary, Colors.primary, Colors.error]
    property real barHeight: Math.max(3, root.height * 0.24)
    property int ticks: 8
    property bool showTicks: true
    property real gap: Math.max(1.5, root.barHeight * 0.4)
    property color markerColor: Colors.surfaceText
    property color tickColor: Colors.outlineVariant

    readonly property real marker: Math.max(5, root.barHeight * 1.5)
    readonly property real barY: root.marker + Math.max(1, root.barHeight * 0.3)
    readonly property var bounds: [0].concat(root.zones).concat([1])
    property real shown: Math.max(0, Math.min(1, root.value))

    Behavior on shown { SpatialAnim {} }

    implicitHeight: root.barY + root.barHeight + (root.showTicks ? root.barHeight * 1.6 : 0)

    Repeater {
        model: root.bounds.length - 1

        delegate: Rectangle {
            required property int index
            readonly property real a: root.bounds[index]
            readonly property real b: root.bounds[index + 1]
            readonly property real usable: root.width - root.gap * (root.bounds.length - 2)
            readonly property bool first: index === 0
            readonly property bool last: index === root.bounds.length - 2

            x: a * usable + index * root.gap
            y: root.barY
            width: Math.max(0, (b - a) * usable)
            height: root.barHeight
            color: root.zoneColors[index] ?? Colors.primary
            topLeftRadius: first ? height / 2 : height * 0.25
            bottomLeftRadius: topLeftRadius
            topRightRadius: last ? height / 2 : height * 0.25
            bottomRightRadius: topRightRadius
        }
    }

    Repeater {
        model: root.showTicks ? root.ticks : 0

        delegate: Rectangle {
            required property int index
            x: Math.min(root.width - width, (root.width - width) * index / Math.max(1, root.ticks - 1))
            y: root.barY + root.barHeight * 1.5
            width: Math.max(1, root.barHeight * 0.25)
            height: index % 2 === 0 ? root.barHeight : root.barHeight * 0.6
            radius: width / 2
            color: root.tickColor
        }
    }

    Shape {
        x: root.shown * root.width - root.marker / 2
        y: 0
        width: root.marker
        height: root.marker * 0.75
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.markerColor
            strokeColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            startX: 0; startY: 0
            PathLine { x: root.marker; y: 0 }
            PathLine { x: root.marker / 2; y: root.marker * 0.75 }
            PathLine { x: 0; y: 0 }
        }
    }
}
