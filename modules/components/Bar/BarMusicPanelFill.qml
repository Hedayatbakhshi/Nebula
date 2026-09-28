import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root
    anchors.fill: parent

    readonly property bool hasTrack: ServiceMusic.activePlayer !== null
    readonly property real elapsed: ServiceMusic.activePlayer?.position ?? 0
    readonly property real total: ServiceMusic.trackLength

    MusicEmptyState {
        anchors.fill: parent
        visible: !root.hasTrack
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12
        visible: root.hasTrack

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            MusicArtwork {
                Layout.preferredWidth: 104
                Layout.preferredHeight: 104
                cornerRadius: 26
                interactive: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                MusicSourceChip {
                    Layout.bottomMargin: 6
                }

                CustomMarqueeText {
                    Layout.fillWidth: true
                    content: ServiceMusic.activeTrack?.title ?? ""
                    size: 19
                    weight: 600
                    customColor: Colors.surfaceText
                    scrolling: ServiceMusic.isPlaying
                }

                CustomText {
                    Layout.fillWidth: true
                    content: ServiceMusic.activeTrack?.artist ?? ""
                    size: 13
                    customColor: Colors.surfaceVariantText
                    elide: Text.ElideRight
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            MusicSeekBar {
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                CustomText {
                    content: ServiceMusic.formatTime(root.elapsed)
                    size: 10
                    customColor: Colors.outline
                }
                Item { Layout.fillWidth: true }
                CustomText {
                    content: ServiceMusic.formatTime(root.total)
                    size: 10
                    customColor: Colors.outline
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Toggle {
                icon: "shuffle"
                on: ServiceMusic.hasShuffle
                usable: ServiceMusic.shuffleSupported
                onTapped: ServiceMusic.setShuffle(!ServiceMusic.hasShuffle)
            }

            Item { Layout.fillWidth: true }

            Round {
                icon: "skip_previous"
                usable: ServiceMusic.canGoPrevious
                onTapped: ServiceMusic.previous()
            }

            Rectangle {
                id: play
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                radius: ServiceMusic.isPlaying ? 20 : 32
                color: playArea.containsMouse ? Qt.lighter(Colors.primary, 1.08) : Colors.primary
                Behavior on radius { SpatialAnim { speed: "fast" } }
                Behavior on color { EffectsColorAnim {} }

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: ServiceMusic.isPlaying ? "pause" : "play_arrow"
                    iconSize: 30
                    fill: 1
                    customColor: Colors.primaryText
                }

                MouseArea {
                    id: playArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ServiceMusic.togglePlaying()
                }
            }

            Round {
                icon: "skip_next"
                usable: ServiceMusic.canGoNext
                onTapped: ServiceMusic.next()
            }

            Item { Layout.fillWidth: true }

            Toggle {
                icon: ServiceMusic.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                on: ServiceMusic.loopState !== MprisLoopState.None
                usable: ServiceMusic.loopSupported
                onTapped: {
                    const s = ServiceMusic.loopState
                    ServiceMusic.setLoopState(s === MprisLoopState.None ? MprisLoopState.Playlist
                                            : s === MprisLoopState.Playlist ? MprisLoopState.Track
                                            : MprisLoopState.None)
                }
            }
        }
    }

    component Round: Rectangle {
        id: rb
        property string icon: ""
        property bool usable: true
        signal tapped

        Layout.preferredWidth: 48
        Layout.preferredHeight: 48
        radius: 24
        opacity: rb.usable ? 1 : 0.4
        color: rbArea.containsMouse && rb.usable ? Qt.lighter(Colors.secondaryContainer, 1.15) : Colors.secondaryContainer
        Behavior on color { EffectsColorAnim {} }

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: rb.icon
            iconSize: 22
            fill: 1
            customColor: Colors.secondaryContainerText
        }

        MouseArea {
            id: rbArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: rb.usable
            cursorShape: Qt.PointingHandCursor
            onClicked: rb.tapped()
        }
    }

    component Toggle: Rectangle {
        id: tg
        property string icon: ""
        property bool on: false
        property bool usable: true
        signal tapped

        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        radius: 18
        opacity: tg.usable ? 1 : 0.3
        color: tg.on ? Qt.alpha(Colors.primary, 0.16) : tgArea.containsMouse ? Colors.surfaceContainerHigh : "transparent"
        Behavior on color { EffectsColorAnim {} }

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: tg.icon
            iconSize: 19
            customColor: tg.on ? Colors.primary : Colors.surfaceVariantText
        }

        MouseArea {
            id: tgArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: tg.usable
            cursorShape: Qt.PointingHandCursor
            onClicked: tg.tapped()
        }
    }
}
