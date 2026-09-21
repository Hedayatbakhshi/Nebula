import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root
    anchors.fill: parent

    readonly property bool hasTrack: ServiceMusic.activePlayer !== null
    readonly property string artUrl: ServiceMusic.activeTrack?.artUrl ?? ""
    readonly property real elapsed: ServiceMusic.activePlayer?.position ?? 0
    readonly property real total: ServiceMusic.trackLength

    readonly property string subtitle: {
        const a = ServiceMusic.activeTrack?.artist ?? ""
        const b = ServiceMusic.activeTrack?.album ?? ""
        if (a !== "" && b !== "" && a !== b) return a + "  ·  " + b
        return a !== "" ? a : b
    }

    MusicEmptyState {
        anchors.fill: parent
        visible: !root.hasTrack
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        visible: root.hasTrack

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                id: heroMask
                anchors.fill: parent
                radius: 18
                visible: false
                layer.enabled: true
            }

            Item {
                id: heroBg
                anchors.fill: parent
                visible: false
                layer.enabled: true

                Rectangle {
                    anchors.fill: parent
                    color: Colors.surfaceContainerHigh
                }

                Image {
                    id: bgArt
                    anchors.fill: parent
                    anchors.margins: -24
                    source: root.artUrl
                    sourceSize.width: 160
                    sourceSize.height: 160
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }

                MultiEffect {
                    anchors.fill: bgArt
                    source: bgArt
                    visible: root.artUrl !== ""
                    blurEnabled: true
                    blur: 1.0
                    blurMax: 48
                    saturation: 0.2
                    opacity: 0.8
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.alpha(Colors.surface, 0.15) }
                        GradientStop { position: 1.0; color: Qt.alpha(Colors.surface, 0.9) }
                    }
                }
            }

            MultiEffect {
                anchors.fill: parent
                source: heroBg
                maskEnabled: true
                maskSource: heroMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 14
                spacing: 14

                MusicArtwork {
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    cornerRadius: 16
                    placeholderIconSize: 28
                    interactive: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignBottom
                    spacing: 0

                    MusicSourceChip { Layout.bottomMargin: 5 }

                    CustomMarqueeText {
                        Layout.fillWidth: true
                        content: ServiceMusic.activeTrack?.title ?? ""
                        size: 17
                        weight: 700
                        customColor: Colors.surfaceText
                        scrolling: ServiceMusic.isPlaying
                    }

                    CustomText {
                        Layout.fillWidth: true
                        Layout.topMargin: 1
                        content: root.subtitle
                        size: 12
                        customColor: Colors.surfaceText
                        opacity: 0.8
                        elide: Text.ElideRight
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CustomText {
                Layout.preferredWidth: 38
                content: ServiceMusic.formatTime(root.elapsed)
                size: 11
                customColor: Colors.outline
            }

            MusicSeekBar { Layout.fillWidth: true }

            CustomText {
                Layout.preferredWidth: 38
                content: ServiceMusic.formatTime(root.total)
                size: 11
                customColor: Colors.outline
                horizontalAlignment: Text.AlignRight
            }
        }

        MusicTransport {
            Layout.fillWidth: true
            playSize: 42
            sideSize: 34
        }
    }
}
