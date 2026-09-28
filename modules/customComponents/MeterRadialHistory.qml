import QtQuick
import qs.modules.utils

Item {
    id: root

    property var history: []
    property int points: 40
    property real max: 1
    property real hotAt: 0.7
    property real inner: 0.46
    property real barWidth: Math.max(1.5, root.size * 0.024)
    property color color: Colors.primary
    property color dimColor: Qt.tint(Colors.surfaceContainerHighest, Qt.alpha(Colors.primary, 0.45))
    property color leadColor: Colors.tertiary
    property color trackColor: Colors.surfaceContainerHighest

    readonly property real size: Math.min(root.width, root.height)
    readonly property real r0: root.size / 2 * root.inner
    readonly property real span: root.size / 2 - root.r0
    readonly property var tail: {
        const h = root.history || []
        return h.length > root.points ? h.slice(h.length - root.points) : h
    }
    readonly property int offset: root.points - root.tail.length

    Repeater {
        model: root.points

        delegate: Item {
            id: bar
            required property int index
            readonly property int slot: bar.index - root.offset
            readonly property bool filled: bar.slot >= 0
            readonly property real v: bar.filled ? Math.max(0, Math.min(1, (Number(root.tail[bar.slot]) || 0) / Math.max(1e-9, root.max))) : 0
            readonly property bool newest: bar.slot === root.tail.length - 1

            anchors.centerIn: parent
            width: root.size
            height: root.size
            rotation: 360 * bar.index / root.points

            Rectangle {
                x: (parent.width - width) / 2
                width: root.barWidth
                height: Math.max(width, root.span * (bar.filled ? Math.max(0.12, bar.v) : 0.12))
                y: root.size / 2 - root.r0 - height
                radius: width / 2
                antialiasing: true
                color: !bar.filled ? root.trackColor
                     : bar.newest ? root.leadColor
                     : bar.v >= root.hotAt ? root.color : root.dimColor

                Behavior on height { SpatialAnim {} }
            }
        }
    }
}
