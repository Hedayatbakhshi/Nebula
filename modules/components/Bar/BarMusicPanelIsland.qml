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

    Rectangle {
        anchors.fill: parent
        anchors.margins: 8
        radius: height / 2.6
        color: "#000000"

        MusicEmptyState {
            anchors.fill: parent
            visible: !root.hasTrack
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 18
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 16
            visible: root.hasTrack

            MusicArtwork {
                Layout.preferredWidth: 84
                Layout.preferredHeight: 84
                Layout.alignment: Qt.AlignVCenter
                cornerRadius: 22
                placeholderIconSize: 30
                interactive: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CustomMarqueeText {
                        Layout.fillWidth: true
                        content: (ServiceMusic.activeTrack?.title ?? "")
                            + ((ServiceMusic.activeTrack?.artist ?? "") !== "" ? "  ·  " + ServiceMusic.activeTrack.artist : "")
                        size: 15
                        weight: 700
                        customColor: "#ffffff"
                        scrolling: ServiceMusic.isPlaying
                    }

                    MusicEqualizer {
                        barWidth: 3
                        barColor: Colors.tertiary
                        active: ServiceMusic.isPlaying
                    }
                }

                MusicSeekBar { Layout.fillWidth: true }

                RowLayout {
                    Layout.fillWidth: true
                    CustomText {
                        content: ServiceMusic.formatTime(root.elapsed)
                        size: 10
                        customColor: Qt.rgba(1, 1, 1, 0.55)
                    }
                    Item { Layout.fillWidth: true }
                    CustomText {
                        content: ServiceMusic.formatTime(root.total)
                        size: 10
                        customColor: Qt.rgba(1, 1, 1, 0.55)
                    }
                }
            }

            MusicTransport {
                Layout.alignment: Qt.AlignVCenter
                playSize: 46
                sideSize: 36
                showToggles: false
            }
        }
    }
}
