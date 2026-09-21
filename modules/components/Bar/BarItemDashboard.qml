import QtQuick
import qs.modules.utils
import qs.modules.customComponents

Rectangle {
    id: root

    property Item host: null
    property string itemId: ""
    readonly property bool shown: true
    readonly property bool iconSizable: true
    readonly property real box: BarLayout.boxFor(root.itemId, root.host)
    readonly property real iconPx: BarLayout.iconPxFor(root.itemId, root.box, 18)
    readonly property color plateColor: hov.containsMouse ? Colors.primary : "transparent"
    readonly property bool plateless: BarLayout.chipHovers(root.itemId, root.implicitWidth,
                                                           root.implicitHeight)
    readonly property bool plateOn: root.plateColor.a > 0.01
    readonly property real plate: BarLayout.platePxFor(root.box, root.iconPx, 18, 30)

    implicitWidth: root.plate
    implicitHeight: root.plate
    radius: root.plate / 2
    color: root.plateless ? "transparent" : root.plateColor
    Behavior on color { ColorAnimation { duration: 150 } }

    MaterialIconSymbol {
        anchors.centerIn: parent
        content: "dashboard"
        iconSize: root.iconPx
        customColor: hov.containsMouse ? Colors.primaryContainer : Colors.surfaceText
        Behavior on customColor { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: hov
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.host) root.host.openPanel("dashboard", root)
    }

    CustomToolTip { content: "Dashboard"; visible: hov.containsMouse }
}
