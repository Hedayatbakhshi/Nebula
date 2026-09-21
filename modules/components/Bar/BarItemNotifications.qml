import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Rectangle {
    id: root

    property Item host: null
    property string itemId: ""
    readonly property bool shown: true
    readonly property bool iconSizable: true
    readonly property real box: BarLayout.boxFor(root.itemId, root.host)
    readonly property real iconPx: BarLayout.iconPxFor(root.itemId, root.box, 18)
    readonly property color plateColor: hov.containsMouse ? Colors.primaryContainer : "transparent"
    readonly property bool plateless: BarLayout.chipHovers(root.itemId, root.implicitWidth,
                                                           root.implicitHeight)
    readonly property bool plateOn: root.plateColor.a > 0.01
    readonly property real plate: BarLayout.platePxFor(root.box, root.iconPx, 18, 28)

    implicitWidth: root.plate
    implicitHeight: root.plate
    radius: root.plate / 2
    color: root.plateless ? "transparent" : root.plateColor
    Behavior on color { ColorAnimation { duration: 150 } }

    MaterialIconSymbol {
        anchors.centerIn: parent
        content: ServiceNotification.notificationsNumber > 0 ? "notifications_active" : "notifications"
        iconSize: root.iconPx
        customColor: hov.containsMouse ? Colors.primaryContainerText
                   : ServiceNotification.notificationsNumber > 0 ? Colors.primary : Colors.surfaceText
        Behavior on customColor { ColorAnimation { duration: 150 } }
    }

    Rectangle {
        visible: ServiceNotification.notificationsNumber > 0
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: -1
        anchors.rightMargin: -1
        width: badgeText.implicitWidth + 4
        height: 12
        radius: 6
        color: Colors.primary

        CustomText {
            id: badgeText
            anchors.centerIn: parent
            content: ServiceNotification.notificationsNumber > 9
                     ? "9+" : String(ServiceNotification.notificationsNumber)
            size: 8; weight: 700
            customColor: Colors.primaryText
        }
    }

    MouseArea {
        id: hov
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.host) root.host.openPanel("dashboard", root)
    }

    CustomToolTip {
        content: ServiceNotification.notificationsNumber + " notifications"
        visible: hov.containsMouse
    }
}
