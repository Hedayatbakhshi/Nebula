import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Item {
    id: root

    property color paper: "#f1d99a"
    property real radius: 16
    property real fold: 22
    property bool tape: false

    Shape {
        id: sheet
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.42)
            shadowBlur: 0.8
            shadowVerticalOffset: 6
            autoPaddingEnabled: true
        }

        ShapePath {
            strokeWidth: -1
            fillColor: root.paper
            startX: root.radius
            startY: 0
            PathLine { x: sheet.width - root.radius; y: 0 }
            PathArc { x: sheet.width; y: root.radius; radiusX: root.radius; radiusY: root.radius }
            PathLine { x: sheet.width; y: sheet.height - root.fold }
            PathLine { x: sheet.width - root.fold; y: sheet.height }
            PathLine { x: root.radius; y: sheet.height }
            PathArc { x: 0; y: sheet.height - root.radius; radiusX: root.radius; radiusY: root.radius }
            PathLine { x: 0; y: root.radius }
            PathArc { x: root.radius; y: 0; radiusX: root.radius; radiusY: root.radius }
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: Qt.darker(root.paper, 1.16)
            startX: sheet.width
            startY: sheet.height - root.fold
            PathLine { x: sheet.width - root.fold + 4; y: sheet.height - root.fold }
            PathQuad { x: sheet.width - root.fold; y: sheet.height - root.fold + 4; controlX: sheet.width - root.fold; controlY: sheet.height - root.fold }
            PathLine { x: sheet.width - root.fold; y: sheet.height }
            PathLine { x: sheet.width; y: sheet.height - root.fold }
        }
    }

    Rectangle {
        visible: root.tape
        width: 86
        height: 22
        x: (parent.width - width) / 2
        y: -10
        rotation: -3
        antialiasing: true
        color: Qt.rgba(1, 1, 1, 0.42)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.25)
    }
}
