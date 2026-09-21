import QtQuick
import qs.modules.utils

Item {
    id: root

    property Item host: null
    property string itemId: ""
    readonly property bool shown: true

    readonly property real thickness: BarLayout.opt(root.itemId, "thickness") ?? 1

    implicitWidth: root.thickness + 8
    implicitHeight: 32

    Rectangle {
        anchors.centerIn: parent
        width: root.thickness
        height: BarLayout.opt(root.itemId, "height") ?? 18
        radius: width / 2
        color: Colors.outlineVariant
    }
}
