import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "jpHaiku"
    tile: WidgetSizes.wide
    defaultPos: Qt.point(580, 100)

    readonly property var poem: ServiceJp.haiku

    component VLine: Column {
        id: line
        property string content: ""
        property color tone: Colors.surfaceText

        spacing: 5

        Repeater {
            model: line.content.split("")

            delegate: CustomText {
                required property var modelData
                width: 20
                horizontalAlignment: Text.AlignHCenter
                content: modelData
                size: 17
                weight: 500
                family: ServiceJp.serif
                renderType: Text.QtRendering
                customColor: line.tone
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: WidgetSizes.cardColor

        CustomText {
            x: 22
            y: 18
            content: "俳句"
            size: 13
            weight: 500
            family: ServiceJp.serif
            customColor: Colors.primary
        }

        Row {
            id: poemRow
            anchors.right: parent.right
            anchors.rightMargin: 26
            y: 20
            spacing: 12
            layoutDirection: Qt.RightToLeft

            VLine { content: root.poem.lines[0] }
            VLine { content: root.poem.lines[1] }
            VLine { content: root.poem.lines[2]; tone: Colors.primary }
        }

        Column {
            x: 22
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
            spacing: 2

            CustomText {
                content: root.poem.author
                size: 13
                weight: 500
                family: ServiceJp.serif
                customColor: Qt.alpha(Colors.surfaceText, 0.7)
            }

            CustomText {
                content: "季語 " + root.poem.kigo
                size: 10
                weight: 500
                family: ServiceJp.serif
                customColor: Qt.alpha(Colors.surfaceText, 0.4)
            }
        }
    }
}
