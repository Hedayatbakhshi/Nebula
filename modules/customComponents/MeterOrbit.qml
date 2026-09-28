import QtQuick
import QtQuick.Shapes
import qs.modules.utils

Item {
    id: root

    property real value: 0
    property real thickness: Math.max(1.5, root.size * 0.022)
    property real planet: Math.max(4, root.size * 0.1)
    property color color: Colors.primary
    property color trackColor: Colors.surfaceContainerHighest
    property color coreColor: Colors.surfaceContainerHigh
    property real coreScale: 0.58

    readonly property real size: Math.min(root.width, root.height)
    readonly property real r: root.size / 2 - root.planet * 0.9
    property real shown: Math.max(0, Math.min(1, root.value))

    Behavior on shown { SpatialAnim {} }

    Rectangle {
        anchors.centerIn: parent
        width: root.size * root.coreScale
        height: width
        radius: width / 2
        visible: root.coreScale > 0
        color: root.coreColor
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.thickness
            fillColor: "transparent"
            strokeStyle: ShapePath.DashLine
            dashPattern: [0.6, 2.4]
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: root.width / 2; centerY: root.height / 2; radiusX: root.r; radiusY: root.r; startAngle: 0; sweepAngle: 360 }
        }

        ShapePath {
            strokeColor: root.shown > 0.004 ? root.color : "transparent"
            strokeWidth: root.thickness * 1.5
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: root.width / 2; centerY: root.height / 2; radiusX: root.r; radiusY: root.r; startAngle: -90; sweepAngle: Math.max(0.1, 360 * root.shown) }
        }
    }

    Item {
        anchors.centerIn: parent
        width: root.r * 2
        height: width
        rotation: 360 * root.shown

        Rectangle {
            x: (parent.width - width) / 2
            y: -height / 2
            width: root.planet * 1.8
            height: width
            radius: width / 2
            color: Qt.alpha(root.color, 0.2)

            Rectangle {
                anchors.centerIn: parent
                width: root.planet
                height: width
                radius: width / 2
                color: root.color
            }
        }
    }
}
