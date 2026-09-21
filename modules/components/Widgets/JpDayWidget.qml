import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "jpDay"
    tile: WidgetSizes.tall
    defaultPos: Qt.point(100, 100)

    readonly property var month: ServiceJp.monthName
    readonly property var sekki: ServiceJp.sekki

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: WidgetSizes.cardColor

        Row {
            id: header
            x: 22
            y: 20
            spacing: 8

            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                content: root.month.jp
                size: 16
                weight: 500
                family: ServiceJp.serif
                customColor: Colors.primary
            }

            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                content: root.month.romaji.toUpperCase()
                size: 9
                weight: 700
                font.letterSpacing: 2
                customColor: Qt.alpha(Colors.surfaceText, 0.45)
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -18
            spacing: 0

            CustomText {
                anchors.horizontalCenter: parent.horizontalCenter
                content: ServiceJp.dayKanji
                size: 74
                weight: 500
                family: ServiceJp.serif
                renderType: Text.QtRendering
                customColor: Colors.surfaceText
            }

            CustomText {
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 2
                content: "日"
                size: 19
                weight: 400
                family: ServiceJp.serif
                customColor: Qt.alpha(Colors.surfaceText, 0.45)
            }

            CustomText {
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 18
                content: ServiceJp.weekday
                size: 17
                weight: 500
                family: ServiceJp.serif
                customColor: Colors.primary
            }
        }

        Rectangle {
            id: rule
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: sekkiBlock.top
            anchors.bottomMargin: 14
            width: parent.width - 44
            height: 1
            color: Qt.alpha(Colors.surfaceText, 0.16)
        }

        Column {
            id: sekkiBlock
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            spacing: 3

            CustomText {
                anchors.horizontalCenter: parent.horizontalCenter
                content: root.sekki.jp + "  " + root.sekki.romaji
                size: 15
                weight: 500
                family: ServiceJp.serif
                customColor: Colors.surfaceText
            }

            CustomText {
                anchors.horizontalCenter: parent.horizontalCenter
                content: root.sekki.en
                size: 11
                weight: 500
                font.letterSpacing: 1.4
                customColor: Qt.alpha(Colors.surfaceText, 0.45)
            }
        }
    }
}
