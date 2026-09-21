import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "jpWeather"
    tile: WidgetSizes.small
    defaultPos: Qt.point(100, 440)

    readonly property var jp: ServiceJp.weatherFor(
        root.preview ? "Partly cloudy" : ServiceWeather.description)

    readonly property string tempRaw: root.preview ? "29°" : ServiceWeather.temperature
    readonly property string tempKanji: {
        const n = parseInt(root.tempRaw)
        return isNaN(n) ? "—" : ServiceJp.count(Math.abs(n))
    }

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: WidgetSizes.cardColor

        CustomText {
            x: 20
            y: 16
            content: "天気"
            size: 13
            weight: 500
            family: ServiceJp.serif
            customColor: Colors.primary
        }

        CustomText {
            id: condition
            x: 20
            y: 52
            width: parent.width - 40
            content: root.jp.jp
            size: root.jp.jp.length > 4 ? 21 : (root.jp.jp.length > 2 ? 27 : 34)
            weight: 500
            family: ServiceJp.serif
            renderType: Text.QtRendering
            customColor: Colors.surfaceText
        }

        CustomText {
            x: 20
            anchors.top: condition.bottom
            anchors.topMargin: 2
            content: root.jp.romaji
            size: 10
            weight: 500
            font.letterSpacing: 1.6
            customColor: Qt.alpha(Colors.surfaceText, 0.42)
        }

        Row {
            x: 20
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 22
            spacing: 4

            CustomText {
                anchors.baseline: parent.children[1].baseline
                content: root.tempKanji
                size: 30
                weight: 500
                family: ServiceJp.serif
                renderType: Text.QtRendering
                customColor: Colors.primary
            }

            CustomText {
                content: "度"
                size: 16
                weight: 400
                family: ServiceJp.serif
                customColor: Qt.alpha(Colors.surfaceText, 0.5)
            }
        }

        CustomText {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 26
            content: root.tempRaw
            size: 15
            weight: 600
            customColor: Qt.alpha(Colors.surfaceText, 0.55)
        }
    }
}
