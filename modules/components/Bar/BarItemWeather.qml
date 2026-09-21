import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root

    property Item host: null
    property string itemId: ""
    readonly property bool shown: true
    readonly property bool iconSizable: true
    readonly property real box: BarLayout.boxFor(root.itemId, root.host)
    readonly property real iconPx: BarLayout.iconPxFor(root.itemId, root.box, 16)
    readonly property real plate: BarLayout.platePxFor(root.box, root.iconPx, 16, 26)
    readonly property bool clickable: SettingsConfig.general.barWeatherPanel ?? true

    implicitWidth: zone.width
    implicitHeight: root.plate

    Rectangle {
        id: zone
        anchors.verticalCenter: parent.verticalCenter
        width: weatherRow.implicitWidth + BarLayout.scaleFor(root.iconPx, 16, 18, 8)
        height: root.plate
        radius: root.plate / 2
        color: weatherHov.containsMouse ? Colors.primaryContainer : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: weatherRow
            anchors.centerIn: parent
            spacing: BarLayout.scaleFor(root.iconPx, 16, 7, 4)

            Image {
                visible: BarLayout.opt(root.itemId, "showIcon") !== false
                Layout.preferredWidth: root.iconPx
                Layout.preferredHeight: root.iconPx
                sourceSize.width: root.iconPx
                sourceSize.height: root.iconPx
                source: IconUtil.getSystemIcon(ServiceWeather.weatherIconPath.svg)
            }

            CustomText {
                content: ServiceWeather.temperature
                size: BarLayout.scaleFor(root.iconPx, 16, 13, 8); weight: 700
                customColor: weatherHov.containsMouse ? Colors.primaryContainerText : Colors.surfaceText
                Behavior on customColor { ColorAnimation { duration: 150 } }
            }
        }

        MouseArea {
            id: weatherHov
            anchors.fill: parent
            hoverEnabled: root.clickable
            cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (root.clickable && root.host) root.host.openPanel("weather", root)
        }
    }
}
