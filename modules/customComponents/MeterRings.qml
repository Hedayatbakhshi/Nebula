import QtQuick
import QtQuick.Shapes
import qs.modules.utils

Item {
    id: root

    property var values: []
    property var colors: []
    property real thickness: Math.max(2, root.size * 0.075)
    property real gap: root.thickness * 0.4
    property real sweep: 270
    property color trackColor: Colors.surfaceContainerHighest

    readonly property real size: Math.min(root.width, root.height)
    readonly property real startAngle: 90 + (360 - root.sweep) / 2

    Repeater {
        model: root.values.length

        delegate: Shape {
            id: ring
            required property int index
            readonly property real r: root.size / 2 - root.thickness / 2 - ring.index * (root.thickness + root.gap)
            readonly property real target: Math.max(0, Math.min(1, Number(root.values[ring.index]) || 0))
            property real shown: ring.target

            Behavior on shown { SpatialAnim {} }

            anchors.fill: parent
            visible: ring.r > root.thickness / 2
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: root.trackColor
                strokeWidth: root.thickness
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: root.width / 2
                    centerY: root.height / 2
                    radiusX: ring.r
                    radiusY: ring.r
                    startAngle: root.startAngle
                    sweepAngle: root.sweep
                }
            }

            ShapePath {
                strokeColor: ring.shown > 0.004 ? (root.colors[ring.index] ?? Colors.primary) : "transparent"
                strokeWidth: root.thickness
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: root.width / 2
                    centerY: root.height / 2
                    radiusX: ring.r
                    radiusY: ring.r
                    startAngle: root.startAngle
                    sweepAngle: Math.max(0.1, root.sweep * ring.shown)
                }
            }
        }
    }
}
