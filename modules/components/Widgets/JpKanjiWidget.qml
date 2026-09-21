import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "jpKanji"
    tile: WidgetSizes.small
    defaultPos: Qt.point(340, 440)

    readonly property var entry: ServiceJp.kanji

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: WidgetSizes.cardColor

        CustomText {
            x: 20
            y: 16
            content: "今日の漢字"
            size: 12
            weight: 500
            family: ServiceJp.serif
            customColor: Colors.primary
        }

        CustomText {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 44
            content: root.entry.ch
            size: 76
            weight: 500
            family: ServiceJp.serif
            renderType: Text.QtRendering
            customColor: Colors.surfaceText
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
            spacing: 3

            CustomText {
                anchors.horizontalCenter: parent.horizontalCenter
                content: root.entry.on + "   " + root.entry.kun
                size: 12
                weight: 500
                family: ServiceJp.serif
                customColor: Qt.alpha(Colors.surfaceText, 0.6)
            }

            CustomText {
                anchors.horizontalCenter: parent.horizontalCenter
                content: root.entry.en
                size: 11
                weight: 500
                font.letterSpacing: 1.2
                customColor: Qt.alpha(Colors.surfaceText, 0.42)
            }
        }
    }
}
