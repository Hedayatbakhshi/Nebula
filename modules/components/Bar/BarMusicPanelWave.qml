import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root
    anchors.fill: parent

    readonly property bool hasTrack: ServiceMusic.activePlayer !== null
    readonly property real elapsed: ServiceMusic.activePlayer?.position ?? 0
    readonly property real total: ServiceMusic.trackLength

    readonly property string subtitle: {
        const a = ServiceMusic.activeTrack?.artist ?? ""
        const b = ServiceMusic.activeTrack?.album ?? ""
        if (a !== "" && b !== "" && a !== b) return a + "  ·  " + b
        return a !== "" ? a : b
    }

    readonly property string playerName: ServiceMusic.activePlayer?.identity ?? ""

    readonly property var stream: {
        const id = root.playerName.toLowerCase()
        if (id === "")
            return null
        const word = id.split(/[\s.]/)[0]
        const list = ServicePipewire.playbacks.filter(n => n && n.audio)
        for (const n of list) {
            const p = n.properties ?? {}
            const name = String(p["application.name"] ?? "").toLowerCase()
            const bin = String(p["application.process.binary"] ?? "").toLowerCase()
            if ((name !== "" && (name.indexOf(word) >= 0 || id.indexOf(name) >= 0)) || (bin !== "" && bin.indexOf(word) >= 0))
                return n
        }
        return null
    }

    PwObjectTracker {
        objects: root.stream ? [root.stream] : []
    }

    readonly property real volume: root.stream ? (root.stream.audio?.volume ?? 0) : ServicePipewire.volume

    function setVolume(v) {
        if (root.stream && root.stream.audio)
            root.stream.audio.volume = Math.max(0, Math.min(1, v))
        else
            ServicePipewire.setVolume(v)
    }

    function nextSink() {
        const list = ServicePipewire.sinks
        if (list.length < 2)
            return
        const i = list.indexOf(ServicePipewire.sink)
        ServicePipewire.setAudioSink(list[(i + 1) % list.length])
    }

    MusicEmptyState {
        anchors.fill: parent
        visible: !root.hasTrack
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10
        visible: root.hasTrack

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            MusicArtwork {
                Layout.preferredWidth: 58
                Layout.preferredHeight: 58
                cornerRadius: 16
                placeholderIconSize: 24
                interactive: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                CustomMarqueeText {
                    Layout.fillWidth: true
                    content: ServiceMusic.activeTrack?.title ?? ""
                    size: 16
                    weight: 700
                    customColor: Colors.surfaceText
                    scrolling: ServiceMusic.isPlaying
                }

                CustomText {
                    Layout.fillWidth: true
                    content: root.subtitle
                    size: 12
                    customColor: Colors.outline
                }
            }

            MusicSourceChip {}
        }

        MusicWaveform {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            Layout.topMargin: 16
            stretch: true
            barWidth: 4
            gap: 2
            interactive: true
        }

        RowLayout {
            Layout.fillWidth: true

            CustomText {
                content: ServiceMusic.formatTime(root.elapsed)
                size: 11
                customColor: Colors.outline
            }
            Item { Layout.fillWidth: true }
            CustomText {
                content: ServiceMusic.formatTime(root.total)
                size: 11
                customColor: Colors.outline
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MusicTransport {
                playSize: 40
                sideSize: 32
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitHeight: 34
                implicitWidth: Math.min(140, sinkRow.implicitWidth + 24)
                radius: 17
                color: sinkArea.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh

                RowLayout {
                    id: sinkRow
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 12
                    spacing: 6

                    MaterialIconSymbol {
                        content: "headphones"
                        iconSize: 16
                        customColor: Colors.surfaceText
                    }
                    CustomText {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 100
                        content: ServicePipewire.sink?.description ?? "Output"
                        size: 11
                        weight: 500
                    }
                }

                MouseArea {
                    id: sinkArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.nextSink()
                }

                CustomToolTip {
                    content: ServicePipewire.sinks.length > 1 ? "Switch output" : "Only one output"
                    visible: sinkArea.containsMouse
                }
            }

            M3Slider {
                Layout.preferredWidth: 120
                Layout.preferredHeight: 28
                icon: "volume_up"
                progress: root.volume
                showValueLabel: false
                onMoved: v => root.setVolume(v)
            }
        }
    }
}
