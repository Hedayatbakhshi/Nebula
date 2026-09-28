import QtQuick
import qs.modules.utils

Item {
    id: root

    property real leftValue: 0
    property real rightValue: 0
    property real divider: Math.max(2, root.height * 0.2)
    property real gap: Math.max(2, root.height * 0.25)
    property color leftColor: Colors.tertiary
    property color rightColor: Colors.primary
    property color trackColor: Colors.surfaceContainerHighest
    property color dividerColor: Colors.outline

    property real l: Math.max(0, Math.min(1, root.leftValue))
    property real r: Math.max(0, Math.min(1, root.rightValue))

    Behavior on l { SpatialAnim {} }
    Behavior on r { SpatialAnim {} }

    readonly property real half: (root.width - root.divider - root.gap * 2) / 2
    readonly property real barH: root.height * 0.62

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: root.half
        height: root.barH
        radius: height / 2
        color: root.trackColor

        Rectangle {
            anchors.right: parent.right
            width: root.l <= 0.001 ? 0 : Math.max(height, parent.width * root.l)
            height: parent.height
            radius: height / 2
            color: root.leftColor
        }
    }

    Rectangle {
        x: root.half + root.gap
        width: root.divider
        height: root.height
        radius: width / 2
        color: root.dividerColor
    }

    Rectangle {
        x: root.half + root.gap * 2 + root.divider
        anchors.verticalCenter: parent.verticalCenter
        width: root.half
        height: root.barH
        radius: height / 2
        color: root.trackColor

        Rectangle {
            width: root.r <= 0.001 ? 0 : Math.max(height, parent.width * root.r)
            height: parent.height
            radius: height / 2
            color: root.rightColor
        }
    }
}
