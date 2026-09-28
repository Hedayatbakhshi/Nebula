import QtQuick
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services

DashItem {
    id: root

    card: true

    Component.onCompleted: ServiceClaudeCode.retain()
    Component.onDestruction: ServiceClaudeCode.release()

    readonly property var days: ServiceClaudeCode.series.slice(-7)
    readonly property real peak: Math.max(1, ...root.days.map(d => d.tokens ?? 0))
    readonly property bool bars: root.height >= 140

    Item {
        anchors.fill: parent
        anchors.margins: 14

        Row {
            id: head
            spacing: 6
            MaterialIconSymbol {
                anchors.verticalCenter: parent.verticalCenter
                content: "terminal"
                iconSize: 16
                customColor: Colors.tertiary
            }
            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                content: ServiceClaudeCode.live ? "Claude Code · live" : "Claude Code"
                size: 12
                weight: 500
                customColor: Colors.surfaceVariantText
            }
        }

        Row {
            id: total
            anchors.top: head.bottom
            anchors.topMargin: 4
            spacing: 8
            CustomText {
                id: big
                content: ServiceClaudeCode.ready ? ServiceClaudeCode.formatTokens(ServiceClaudeCode.today.tokens) : "–"
                family: root.displayFont
                renderType: Text.QtRendering
                size: Math.min(30, Math.max(20, root.height * 0.16))
                weight: 400
                customColor: Colors.tertiary
            }
            CustomText {
                anchors.baseline: big.baseline
                content: "tokens today"
                size: 12
                weight: 500
                customColor: Colors.outline
            }
        }

        Row {
            id: chart
            visible: root.bars && root.days.length > 0
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.min(80, parent.height - total.y - total.height - 10)
            spacing: 6
            readonly property real barW: (width - (root.days.length - 1) * spacing) / Math.max(1, root.days.length)

            Repeater {
                model: root.days

                delegate: Column {
                    id: bar
                    required property var modelData
                    required property int index
                    readonly property bool last: bar.index === root.days.length - 1
                    width: chart.barW
                    height: chart.height
                    spacing: 4

                    Item {
                        width: parent.width
                        height: parent.height - 18

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(6, parent.height * (bar.modelData.tokens ?? 0) / root.peak)
                            radius: Math.min(8, width / 3)
                            color: bar.last ? Colors.tertiary : Colors.surfaceContainerHighest
                        }
                    }

                    CustomText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        content: bar.modelData.weekday ?? ""
                        size: 10
                        weight: 500
                        customColor: Colors.outline
                    }
                }
            }
        }

        CustomText {
            visible: !root.bars
            anchors.bottom: parent.bottom
            content: ServiceClaudeCode.today.messages + " messages · " + ServiceClaudeCode.today.sessions + " sessions"
            size: 12
            weight: 500
            customColor: Colors.surfaceVariantText
        }
    }
}
