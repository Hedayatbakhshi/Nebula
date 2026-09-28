import QtQuick
import qs.modules.utils

Item {
    id: root

    property var values: []
    property var colors: []
    property real gap: Math.max(1.5, root.height * 0.18)
    property color trackColor: Colors.surfaceContainerHighest

    readonly property real outer: root.height / 2
    readonly property real inner: Math.max(1, root.height * 0.22)
    readonly property var parts: {
        const out = []
        let used = 0
        for (let i = 0; i < root.values.length; i++) {
            const v = Math.max(0, Math.min(1 - used, Number(root.values[i]) || 0))
            if (v > 0.002)
                out.push({ v: v, c: root.colors[i] ?? Colors.primary })
            used += v
        }
        if (used < 0.998)
            out.push({ v: 1 - used, c: root.trackColor })
        return out
    }
    readonly property real usable: root.width - root.gap * Math.max(0, root.parts.length - 1)

    Row {
        anchors.fill: parent
        spacing: root.gap

        Repeater {
            model: root.parts

            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool first: index === 0
                readonly property bool last: index === root.parts.length - 1

                width: Math.max(root.inner * 2, root.usable * modelData.v)
                height: root.height
                color: modelData.c
                topLeftRadius: first ? root.outer : root.inner
                bottomLeftRadius: first ? root.outer : root.inner
                topRightRadius: last ? root.outer : root.inner
                bottomRightRadius: last ? root.outer : root.inner

                Behavior on width { SpatialAnim {} }
            }
        }
    }
}
