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
    readonly property real plate: BarLayout.platePxFor(root.box, root.iconPx, 18, 28)
    readonly property color plateColor: hov.containsMouse ? Colors.primaryContainer
         : root.low ? Qt.alpha(Colors.error, 0.15) : "transparent"
    readonly property bool plateless: BarLayout.chipHovers(root.itemId, root.implicitWidth,
                                                           root.implicitHeight)
    readonly property bool plateOn: root.plateColor.a > 0.01
    readonly property real labelPx: BarLayout.scaleFor(root.iconPx, 18, 13, 8)
    readonly property real gapPx: BarLayout.scaleFor(root.iconPx, 18, 4, 2)
    readonly property real padPx: BarLayout.scaleFor(root.iconPx, 18, 16, 8)
    readonly property bool low: ServiceUPower.powerLevel < 0.2 && !ServiceUPower.isCharging
    readonly property bool showPercent: BarLayout.opt(root.itemId, "showPercent") === true
    readonly property color ink: hov.containsMouse ? Colors.primaryContainerText
                               : root.low ? Colors.error : Colors.surfaceText

    implicitWidth: root.showPercent ? battRow.implicitWidth + root.padPx : root.plate
    implicitHeight: root.plate
    radius: root.plate / 2
    color: root.plateless ? "transparent" : root.plateColor
    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
        id: battRow
        anchors.centerIn: parent
        spacing: root.gapPx

        MaterialIconSymbol {
            anchors.verticalCenter: parent.verticalCenter
            content: {
                if (ServiceUPower.isCharging) return "battery_android_bolt"
                const l = ServiceUPower.powerLevel
                if (l === 1)  return "battery_android_full"
                if (l > 0.9)  return "battery_android_6"
                if (l > 0.7)  return "battery_android_5"
                if (l > 0.5)  return "battery_android_4"
                if (l > 0.3)  return "battery_android_3"
                if (l > 0.2)  return "battery_android_2"
                if (l > 0.0)  return "battery_android_1"
                return "battery_android_0"
            }
            iconSize: root.iconPx
            customColor: root.ink
        }

        CustomText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showPercent
            content: Math.round(ServiceUPower.powerLevel * 100) + "%"
            size: root.labelPx
            weight: 700
            customColor: root.ink
        }
    }

    MouseArea {
        id: hov
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }

    CustomToolTip {
        content: (ServiceUPower.isCharging ? "Charging · " : "")
               + Math.round(ServiceUPower.powerLevel * 100) + "%"
        visible: hov.containsMouse
    }
}
