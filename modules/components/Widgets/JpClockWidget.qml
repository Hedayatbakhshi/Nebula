import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "jpClock"
    tile: WidgetSizes.tall
    defaultPos: Qt.point(340, 100)

    readonly property string hours: {
        let h = parseInt(ServiceClock.hour)
        if (h > 12) h -= 12; if (h === 0) h = 12
        return h < 10 ? "0" + h : h.toString()
    }

    component Numerals: CustomText {
        size: 46
        weight: 500
        family: "Noto Serif Display"
        renderType: Text.QtRendering
        horizontalAlignment: Text.AlignHCenter
    }

    component Particle: CustomText {
        size: 15
        weight: 400
        family: ServiceJp.serif
        horizontalAlignment: Text.AlignHCenter
        customColor: Qt.alpha(Colors.surfaceText, 0.5)
    }

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: WidgetSizes.cardColor

        Rectangle {
            id: spine
            x: 132
            y: 30
            width: 1
            height: parent.height - 60
            color: Qt.alpha(Colors.surfaceText, 0.14)
        }

        Column {
            id: stack
            x: 56
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Numerals {
                anchors.horizontalCenter: parent.horizontalCenter
                content: root.hours
                customColor: Colors.surfaceText
            }

            Particle {
                anchors.horizontalCenter: parent.horizontalCenter
                content: "時"
            }

            Numerals {
                anchors.horizontalCenter: parent.horizontalCenter
                content: ServiceClock.minute
                customColor: Colors.primary
            }

            Particle {
                anchors.horizontalCenter: parent.horizontalCenter
                content: "分"
            }
        }

        Column {
            x: 148
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7

            Repeater {
                model: ServiceJp.period.split("")

                delegate: CustomText {
                    required property var modelData
                    width: 18
                    horizontalAlignment: Text.AlignHCenter
                    content: modelData
                    size: 14
                    weight: 500
                    family: ServiceJp.serif
                    customColor: Qt.alpha(Colors.surfaceText, 0.55)
                }
            }
        }
    }
}
