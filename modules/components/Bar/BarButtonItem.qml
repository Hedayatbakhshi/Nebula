import QtQuick
import qs.modules.utils
import qs.modules.customComponents

Rectangle {
    id: root

    property Item host: null
    property string itemId: ""
    readonly property bool shown: true

    property string icon: ""
    property bool active: false
    property string label: ""
    property string tip: ""

    signal activated()

    readonly property bool showLabel: BarLayout.opt(root.itemId, "showLabel") === true
    readonly property color ink: hov.containsMouse ? Colors.primaryContainerText
                               : root.active ? Colors.primary : Colors.surfaceText
    readonly property bool iconSizable: true
    readonly property real hostIcon: root.host && root.host.iconSize ? root.host.iconSize : 0
    readonly property real defaultIcon: root.hostIcon > 0 ? Math.round(root.hostIcon * 0.69) : 18
    readonly property real defaultPlate: root.hostIcon > 0 ? root.hostIcon + 8 : 28
    readonly property real box: BarLayout.boxFor(root.itemId, root.host)
    readonly property real iconPx: BarLayout.iconPxFor(root.itemId, root.box, root.defaultIcon)
    readonly property real plate: BarLayout.platePxFor(root.box, root.iconPx,
                                                       root.defaultIcon, root.defaultPlate)
    readonly property color plateColor: hov.containsMouse ? Colors.primaryContainer
         : root.active ? Qt.alpha(Colors.primary, 0.18) : "transparent"
    readonly property bool plateless: BarLayout.chipHovers(root.itemId, root.implicitWidth,
                                                           root.implicitHeight)
    readonly property bool plateOn: root.plateColor.a > 0.01
    readonly property real labelPx: BarLayout.scaleFor(root.iconPx, root.defaultIcon, 12, 8)
    readonly property real gapPx: BarLayout.scaleFor(root.iconPx, root.defaultIcon, 6, 3)
    readonly property real padPx: BarLayout.scaleFor(root.iconPx, root.defaultIcon, 18, 8)

    implicitWidth: root.showLabel ? row.implicitWidth + root.padPx : root.plate
    implicitHeight: root.plate
    radius: root.plate / 2
    color: root.plateless ? "transparent" : root.plateColor
    Behavior on color { EffectsColorAnim {} }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.gapPx

        MaterialIconSymbol {
            anchors.verticalCenter: parent.verticalCenter
            content: root.icon
            iconSize: root.iconPx
            customColor: root.ink
        }

        CustomText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showLabel
            content: root.label
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
        onClicked: root.activated()
    }

    CustomToolTip {
        content: root.tip !== "" ? root.tip : root.label
        visible: hov.containsMouse && !root.showLabel
    }
}
