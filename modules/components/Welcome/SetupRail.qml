import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

Rectangle {
    id: rail

    property var steps: []
    property int current: 0
    property var noteFor: function(i) { return "" }

    signal stepClicked(int index)
    signal skipClicked

    readonly property string wallpaperPath: Colors.wallpaper ?? ""

    color: Colors.surfaceContainerLow
    topLeftRadius: 26
    bottomLeftRadius: 26

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 26
        anchors.bottomMargin: 18
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 14

        RowLayout {
            Layout.leftMargin: 8
            spacing: 10

            NebulaLogo {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                color: Colors.primary
            }

            ColumnLayout {
                spacing: 2

                CustomText {
                    content: "Nebula"
                    size: 22
                    weight: Font.Normal
                    family: SettingsConfig.general.displayFont ?? "Titan One"
                }

                CustomText {
                    content: "First-run setup"
                    size: 12
                    weight: 400
                    customColor: Colors.outline
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: rail.steps

                Rectangle {
                    id: stepItem

                    required property var modelData
                    required property int index

                    readonly property bool isCurrent: stepItem.index === rail.current
                    readonly property bool isDone: stepItem.index < rail.current

                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 16
                    color: stepItem.isCurrent ? Colors.secondaryContainer
                         : stepHover.containsMouse ? Qt.alpha(Colors.surfaceText, 0.06) : "transparent"

                    Behavior on color { ColorAnimation { duration: M3Motion.effects.fastDuration } }

                    MouseArea {
                        id: stepHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rail.stepClicked(stepItem.index)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 14
                            color: stepItem.isDone ? Colors.primary
                                 : stepItem.isCurrent ? Colors.secondaryContainerText : "transparent"
                            border.width: stepItem.isDone || stepItem.isCurrent ? 0 : 2
                            border.color: Colors.outlineVariant

                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                visible: stepItem.isDone
                                content: "check"
                                iconSize: 18
                                customColor: Colors.primaryText
                            }

                            CustomText {
                                anchors.centerIn: parent
                                visible: !stepItem.isDone
                                content: String(stepItem.index + 1)
                                size: 13
                                weight: 600
                                customColor: stepItem.isCurrent ? Colors.secondaryContainer : Colors.surfaceVariantText
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            CustomText {
                                Layout.fillWidth: true
                                content: stepItem.modelData.label
                                size: 15
                                weight: 500
                                customColor: stepItem.isCurrent ? Colors.secondaryContainerText : Colors.surfaceText
                            }

                            CustomText {
                                Layout.fillWidth: true
                                readonly property string note: rail.noteFor(stepItem.index)
                                visible: note !== ""
                                content: note
                                size: 12
                                weight: 400
                                customColor: stepItem.isCurrent ? Qt.alpha(Colors.secondaryContainerText, 0.8) : Colors.outline
                                elide: Text.ElideRight
                            }
                        }

                        MaterialIconSymbol {
                            visible: stepItem.isCurrent
                            content: "chevron_right"
                            iconSize: 20
                            customColor: Colors.secondaryContainerText
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: paletteCol.implicitHeight + 20
            radius: 20
            color: Colors.surfaceContainer

            ColumnLayout {
                id: paletteCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 10

                ClippingRectangle {
                    Layout.fillWidth: true
                    implicitHeight: 70
                    radius: 12
                    color: Colors.surfaceContainerHighest

                    Image {
                        anchors.fill: parent
                        visible: rail.wallpaperPath !== ""
                        source: rail.wallpaperPath !== "" ? "file://" + rail.wallpaperPath : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(480, 270)
                    }
                }

                Row {
                    Layout.leftMargin: 4
                    spacing: 6

                    Repeater {
                        model: [Colors.primary, Colors.primaryContainer, Colors.secondaryContainer,
                                Colors.tertiary, Colors.surfaceContainerHighest]

                        Rectangle {
                            required property var modelData
                            width: 22
                            height: 22
                            radius: 11
                            color: modelData
                            border.width: 1
                            border.color: Qt.alpha(Colors.outline, 0.3)

                            Behavior on color { ColorAnimation { duration: 260 } }
                        }
                    }
                }

                CustomText {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    content: "This palette is what your apps get"
                    size: 12
                    weight: 400
                    customColor: Colors.outline
                    wrapMode: Text.WordWrap
                }
            }
        }

        M3Button {
            Layout.fillWidth: true
            size: "small"
            variant: "text"
            label: "Skip setup"
            onClicked: rail.skipClicked()
        }
    }
}
