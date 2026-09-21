import QtQuick
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "jpSeal"
    tile: WidgetSizes.small
    defaultPos: Qt.point(580, 440)

    readonly property string glyphs: SettingsConfig.widgets.sealText ?? "鋼"
    readonly property var chars: root.glyphs.split("")
    readonly property color ink: Qt.hsla(0.015, 0.68, 0.44, 1)
    readonly property color paper: Qt.hsla(0.05, 0.16, 0.95, 1)
    readonly property real block: 116
    readonly property real cell: root.chars.length > 2 ? root.block / 2 : root.block
    readonly property int cols: root.chars.length > 2 ? 2 : 1

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: WidgetSizes.cardColor

        CustomText {
            x: 20
            y: 16
            content: "印"
            size: 13
            weight: 500
            family: ServiceJp.serif
            customColor: Qt.alpha(Colors.surfaceText, 0.4)
        }

        Item {
            id: seal
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 8
            width: root.block
            height: root.block

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: root.ink
            }

            Grid {
                anchors.centerIn: parent
                columns: root.cols
                columnSpacing: 0
                rowSpacing: 0

                Repeater {
                    model: root.chars

                    delegate: CustomText {
                        required property var modelData

                        width: root.cell
                        height: root.cell
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        content: modelData
                        size: Math.round(root.cell * 0.74)
                        weight: 700
                        family: ServiceJp.serif
                        renderType: Text.QtRendering
                        customColor: root.paper
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 6
                radius: 4
                color: "transparent"
                border.width: 2
                border.color: root.paper
                opacity: 0.55
            }
        }
    }
}
