import QtQuick
import qs.modules.utils

Item {
    id: root

    property var history: []
    property int points: 40
    property real max: 1
    property real gap: Math.max(1, root.width * 0.005)
    property real radius: -1
    property bool bars: false
    property color color: Colors.primary
    property color leadColor: Colors.tertiary
    property color trackColor: Colors.surfaceContainerHighest

    readonly property var tail: {
        const h = root.history || []
        return h.length > root.points ? h.slice(h.length - root.points) : h
    }
    readonly property int offset: root.points - root.tail.length
    readonly property real cell: (root.width - root.gap * (root.points - 1)) / Math.max(1, root.points)

    Repeater {
        model: root.points

        delegate: Item {
            id: c
            required property int index
            readonly property int slot: c.index - root.offset
            readonly property bool filled: c.slot >= 0
            readonly property real v: c.filled ? Math.max(0, Math.min(1, (Number(root.tail[c.slot]) || 0) / Math.max(1e-9, root.max))) : 0
            readonly property bool newest: c.slot === root.tail.length - 1

            x: c.index * (root.cell + root.gap)
            width: root.cell
            height: root.height

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: root.bars && c.filled ? Math.max(width, parent.height * Math.max(0.08, c.v)) : parent.height
                radius: root.radius >= 0 ? root.radius : Math.min(width / 2, 5)
                color: !c.filled ? root.trackColor : c.newest ? root.leadColor : root.color
                opacity: !c.filled || c.newest ? 1 : root.bars ? (c.v >= 0.7 ? 1 : 0.5) : 0.12 + 0.88 * c.v

                Behavior on height { SpatialAnim {} }
            }
        }
    }
}
