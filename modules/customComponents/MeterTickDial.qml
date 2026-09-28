import QtQuick
import qs.modules.utils

Item {
    id: root

    property real value: 0
    property real peak: -1
    property int ticks: 36
    property int majorEvery: 6
    property real sweep: 270
    property real tickWidth: Math.max(1.5, root.size * 0.022)
    property real tickLength: Math.max(2, root.size * 0.06)
    property real majorLength: root.tickLength * 1.45
    property color color: Colors.primary
    property color trackColor: Colors.surfaceContainerHighest
    property color peakColor: Colors.tertiary

    readonly property real size: Math.min(root.width, root.height)
    readonly property int lit: Math.round(Math.max(0, Math.min(1, root.value)) * root.ticks)

    function angleFor(f) {
        return -root.sweep / 2 + root.sweep * f
    }

    Repeater {
        model: root.ticks

        delegate: Item {
            id: tick
            required property int index
            readonly property bool major: root.majorEvery > 0 && tick.index % root.majorEvery === 0

            anchors.centerIn: parent
            width: root.size
            height: root.size
            rotation: root.angleFor(tick.index / Math.max(1, root.ticks - 1))

            Rectangle {
                x: (parent.width - width) / 2
                y: tick.major ? 0 : root.majorLength - root.tickLength
                width: root.tickWidth
                height: tick.major ? root.majorLength : root.tickLength
                radius: width / 2
                antialiasing: true
                color: tick.index < root.lit ? root.color : root.trackColor

                Behavior on color { EffectsColorAnim {} }
            }
        }
    }

    Item {
        anchors.centerIn: parent
        width: root.size
        height: root.size
        visible: root.peak >= 0
        rotation: root.angleFor(Math.max(0, Math.min(1, root.peak)))

        Behavior on rotation { SpatialAnim {} }

        Rectangle {
            x: (parent.width - width) / 2
            y: root.majorLength + Math.max(2, root.size * 0.03)
            width: Math.max(3, root.size * 0.05)
            height: width
            radius: width / 2
            color: root.peakColor
        }
    }
}
