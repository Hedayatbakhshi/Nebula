import QtQuick
import QtQuick.Shapes
import qs.modules.utils

Item {
    id: root

    property color color: Colors.surfaceText

    implicitWidth: 48
    implicitHeight: 48

    Shape {
        width: 100
        height: 100
        scale: Math.min(root.width, root.height) / 100
        transformOrigin: Item.TopLeft
        x: (root.width - Math.min(root.width, root.height)) / 2
        y: (root.height - Math.min(root.width, root.height)) / 2
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: 7
            PathRectangle { x: 8; y: 14; width: 84; height: 72; radius: 16 }
        }

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            strokeWidth: 0
            PathSvg { path: "M8 30 L8 26 Q8 14 20 14 L80 14 Q92 14 92 26 L92 30 L66 30 Q60 30 60 36 Q60 42 54 42 L46 42 Q40 42 40 36 Q40 30 34 30 Z" }
        }

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            strokeWidth: 0
            PathRectangle { x: 34; y: 68; width: 32; height: 9; radius: 4.5 }
        }

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            strokeWidth: 0
            PathSvg { path: "M50 49 Q52 56 59 57 Q52 58 50 65 Q48 58 41 57 Q48 56 50 49 Z" }
        }
    }
}
