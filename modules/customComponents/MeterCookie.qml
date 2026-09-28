import QtQuick
import qs.modules.utils
import "../MatrialShapes/" as MaterialShapes
import "../MatrialShapes/shape-library.js" as ShapeLibrary

Item {
    id: root

    property real value: 0
    property string shape: "cookie9"
    property real thickness: Math.max(2, root.size * 0.06)
    property color color: Colors.primary
    property color trackColor: Colors.surfaceContainerHighest
    property color faceColor: Colors.surfaceContainerHigh

    readonly property real size: Math.min(root.width, root.height)
    readonly property var polygon: ShapeLibrary.get(root.shape)
    property real shown: Math.max(0, Math.min(1, root.value))

    Behavior on shown { SpatialAnim {} }

    MaterialShapes.ShapeCanvas {
        anchors.centerIn: parent
        width: root.size - root.thickness
        height: width
        visible: root.faceColor.a > 0
        roundedPolygon: root.polygon
        color: root.faceColor
    }

    MaterialShapes.ShapeCanvas {
        anchors.centerIn: parent
        width: root.size
        height: root.size
        roundedPolygon: root.polygon
        strokeProgress: root.shown
        strokeWidth: root.thickness
        strokeColor: root.color
        strokeTrackColor: root.trackColor
    }
}
