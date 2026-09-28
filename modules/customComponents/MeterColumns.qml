import QtQuick
import qs.modules.utils

Item {
    id: root

    property var values: []
    property int minCount: 0
    property real gap: Math.max(1, root.width * 0.008)
    property real hotAt: 0.9
    property real radius: -1
    property color color: Colors.primary
    property color hotColor: Colors.error
    property color trackColor: Colors.surfaceContainerHighest

    readonly property int count: Math.max(root.minCount, root.values.length)
    readonly property int offset: root.count - root.values.length
    readonly property real col: (root.width - root.gap * Math.max(0, root.count - 1)) / Math.max(1, root.count)

    Repeater {
        model: root.count

        delegate: Rectangle {
            id: c
            required property int index
            readonly property real v: c.index < root.offset ? 0 : Math.max(0, Math.min(1, Number(root.values[c.index - root.offset]) || 0))
            readonly property real rr: root.radius >= 0 ? root.radius : Math.min(root.col / 2, 6)

            x: c.index * (root.col + root.gap)
            width: root.col
            height: root.height
            radius: c.rr
            color: root.trackColor

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: c.v <= 0.001 ? 0 : Math.max(c.rr * 2, parent.height * c.v)
                radius: c.rr
                color: c.v >= root.hotAt ? root.hotColor : root.color

                Behavior on height { SpatialAnim {} }
            }
        }
    }
}
