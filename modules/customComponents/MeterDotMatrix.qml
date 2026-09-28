import QtQuick
import qs.modules.utils

Item {
    id: root

    property real value: 0
    property int rows: 3
    property real dot: Math.max(2, (root.height - root.gap * (root.rows - 1)) / Math.max(1, root.rows))
    property real gap: Math.max(1.5, root.height * 0.14)
    property color color: Colors.primary
    property color trackColor: Colors.surfaceContainerHighest

    readonly property int cols: Math.max(1, Math.floor((root.width + root.gap) / (root.dot + root.gap)))
    readonly property int litCols: Math.round(Math.max(0, Math.min(1, root.value)) * root.cols)
    readonly property real slack: (root.width - (root.cols * root.dot + (root.cols - 1) * root.gap)) / 2

    Repeater {
        model: root.cols * root.rows

        delegate: Rectangle {
            required property int index
            readonly property int c: Math.floor(index / root.rows)
            readonly property int r: index % root.rows

            x: root.slack + c * (root.dot + root.gap)
            y: r * (root.dot + root.gap)
            width: root.dot
            height: root.dot
            radius: width / 2
            color: c < root.litCols ? root.color : root.trackColor

            Behavior on color { EffectsColorAnim {} }
        }
    }
}
