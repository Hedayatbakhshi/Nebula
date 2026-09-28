import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "terminalStats"
    tile: WidgetSizes.small
    resizable: true
    minSpan: Qt.size(2, 2)
    maxSpan: Qt.size(3, 3)
    defaultPos: Qt.point(915, 165)

    readonly property var cmds: root.preview ? [["cd", 682], ["ls", 483], ["git", 273], ["nvim", 166], ["cargo", 109]] : (ServicePersonal.shell.top ?? [])
    readonly property int total: root.preview ? 3428 : (ServicePersonal.shell.total ?? 0)
    readonly property int shown: Math.max(3, Math.min(root.cmds.length, Math.floor((root.height - 96) / 20)))
    readonly property real peak: root.cmds.length > 0 ? root.cmds[0][1] : 1

    WidgetCard {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: parent.pad
            spacing: 6

            WidgetTitle {
                Layout.fillWidth: true
                icon: "terminal"
                title: "Terminal"
            }

            RowLayout {
                spacing: 6
                CustomText {
                    content: root.total.toLocaleString(Qt.locale("en_US"), "f", 0)
                    size: 24
                    weight: 600
                    family: "Fira Code"
                }
                CustomText {
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 4
                    content: "commands"
                    size: 11
                    customColor: Colors.outline
                }
            }

            Item { Layout.fillHeight: true }

            Repeater {
                model: root.cmds.slice(0, root.shown)
                delegate: RowLayout {
                    id: bar
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 6
                    CustomText {
                        Layout.preferredWidth: 46
                        content: bar.modelData[0]
                        size: 11
                        family: "Fira Code"
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        radius: 4
                        color: Colors.surfaceContainerHigh
                        Rectangle {
                            width: parent.width * bar.modelData[1] / root.peak
                            height: parent.height
                            radius: 4
                            color: Colors.tertiary
                        }
                    }
                    CustomText {
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignRight
                        content: bar.modelData[1]
                        size: 11
                        family: "Fira Code"
                        customColor: Colors.outline
                    }
                }
            }
        }
    }
}
