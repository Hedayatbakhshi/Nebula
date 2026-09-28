import QtQuick
import qs.modules.utils

Item {
    id: root

    property real value: 0
    property int count: 20
    property real gap: Math.max(1, root.width * 0.006)
    property bool rising: false
    property real radius: -1
    property color color: Colors.primary
    property color leadColor: Colors.tertiary
    property color trackColor: Colors.surfaceContainerHighest

    readonly property int lit: Math.round(Math.max(0, Math.min(1, root.value)) * root.count)
    readonly property real cell: (root.width - root.gap * (root.count - 1)) / Math.max(1, root.count)

    Repeater {
        model: root.count

        delegate: Rectangle {
            required property int index
            x: index * (root.cell + root.gap)
            width: root.cell
            height: root.rising ? root.height * (0.45 + 0.55 * index / Math.max(1, root.count - 1)) : root.height
            y: root.height - height
            radius: root.radius >= 0 ? root.radius : Math.min(width, height) / 2
            color: index >= root.lit ? root.trackColor : index === root.lit - 1 ? root.leadColor : root.color

            Behavior on color { EffectsColorAnim {} }
        }
    }
}
