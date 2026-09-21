import QtQuick
import QtQuick.Layouts
import qs.modules.customComponents
import qs.modules.utils

ColumnLayout {
    id: root
    property Item panel: null
    readonly property real growRoom: 0
    spacing: 10

    readonly property int dayCount: root.panel
        ? Math.max(1, Math.min(root.panel.days.length - 1, Math.floor((root.width + 6) / 100))) : 0

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        Layout.topMargin: 4
        spacing: 14

        Row {
            Layout.alignment: Qt.AlignVCenter
            CustomText {
                content: root.panel ? String(root.panel.curTemp) : ""
                size: 84
                weight: 300
                renderType: Text.QtRendering
                font.letterSpacing: -3
            }
            CustomText {
                content: "°"
                size: 84
                weight: 300
                renderType: Text.QtRendering
                customColor: Colors.primary
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6
            CustomText {
                Layout.fillWidth: true
                content: root.panel ? root.panel.headline : ""
                size: 16
                weight: 700
                wrapMode: Text.WordWrap
                lineHeight: 1.15
            }
            CustomText {
                Layout.fillWidth: true
                content: root.panel ? root.panel.subline : ""
                size: 12
                wrapMode: Text.WordWrap
                customColor: Colors.outline
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 6

        Repeater {
            model: root.panel ? root.panel.stats.slice(0, root.width >= 460 ? 5 : 3) : []
            delegate: Rectangle {
                id: pill
                required property var modelData
                width: pillRow.implicitWidth + 24
                height: 34
                radius: 17
                color: Colors.surfaceContainerHigh
                RowLayout {
                    id: pillRow
                    anchors.centerIn: parent
                    spacing: 6
                    MaterialIconSymbol {
                        content: pill.modelData.icon
                        iconSize: 15
                        customColor: Colors.primary
                    }
                    CustomText {
                        content: pill.modelData.value + (pill.modelData.unit === "%" ? "%" : " " + pill.modelData.unit)
                        size: 12
                        weight: 600
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: root.panel ? root.panel.days.slice(1, 1 + root.dayCount) : []
            delegate: Rectangle {
                id: day
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.minimumWidth: 0
                Layout.maximumWidth: Number.POSITIVE_INFINITY
                Layout.preferredHeight: 58
                radius: 18
                color: Colors.surfaceContainer
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8
                    Image {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        source: root.panel.iconFor(root.panel.dayCode(day.modelData), false)
                        sourceSize.width: 22
                        sourceSize.height: 22
                        asynchronous: true
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        CustomText {
                            content: root.panel.dayShort(day.modelData.date, day.index + 1)
                            size: 11
                            customColor: Colors.outline
                        }
                        Row {
                            spacing: 4
                            CustomText { content: root.panel.dayHi(day.modelData) + "°"; size: 13; weight: 700 }
                            CustomText { content: root.panel.dayLo(day.modelData) + "°"; size: 13; customColor: Colors.outline }
                        }
                    }
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
