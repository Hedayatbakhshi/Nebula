import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "musicStrip"
    tile: WidgetSizes.strip
    resizable: true
    minSpan: Qt.size(3, 1.5)
    maxSpan: Qt.size(6, 2)
    defaultPos: Qt.point(460, 780)

    readonly property string artUrl: ServiceMusic.activeTrack?.artUrl ?? ""
    readonly property bool hasArt: artUrl !== ""
    readonly property bool hasTrack: ServiceMusic.activePlayer !== null
    readonly property real trackLength: ServiceMusic.trackLength
    readonly property real elapsed: ServiceMusic.activePlayer?.position ?? 0

    readonly property real progress: trackLength > 0
        ? Math.max(0, Math.min(1, elapsed / trackLength))
        : 0

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: WidgetSizes.cardColor

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            y: 14
            spacing: 6

            CustomText { content: "Now Playing"; size: 13; customColor: Colors.primary }

            Item { Layout.fillWidth: true }

            MaterialIconSymbol {
                content: ServiceMusic.isPlaying ? "equalizer" : "pause"
                iconSize: 13
                customColor: Colors.outline
            }

            CustomText {
                content: root.hasTrack ? (ServiceMusic.activeTrack?.identity ?? "") : ""
                size: 12
                customColor: Colors.outline
            }
        }

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -4
            spacing: 12

            ClippingRectangle {
                Layout.preferredWidth: Math.min(60, root.height - 97)
                Layout.preferredHeight: Math.min(60, root.height - 97)
                radius: 14
                color: Colors.surfaceContainerHigh

                Image {
                    anchors.fill: parent
                    source: root.artUrl
                    visible: root.hasArt
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 120
                    sourceSize.height: 120
                    asynchronous: true
                }

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "music_note"
                    iconSize: 22
                    customColor: Colors.outline
                    visible: !root.hasArt
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                CustomMarqueeText {
                    Layout.fillWidth: true
                    content: root.hasTrack
                        ? (ServiceMusic.activeTrack?.title ?? "Unknown Title")
                        : "Nothing playing"
                    size: 14
                    weight: 700
                    scrolling: !root.preview
                }

                CustomText {
                    Layout.fillWidth: true
                    content: root.hasTrack
                        ? (ServiceMusic.activeTrack?.artist ?? "Unknown Artist")
                        : "—"
                    size: 12
                    elide: Text.ElideRight
                    customColor: Colors.outline
                }
            }

            M3IconButton {
                implicitWidth: 26
                implicitHeight: 26
                icon: "skip_previous"
                iconSize: 15
                enabledButton: ServiceMusic.canGoPrevious
                onClicked: ServiceMusic.previous()
            }

            M3IconButton {
                implicitWidth: 26
                implicitHeight: 26
                icon: ServiceMusic.isPlaying ? "pause" : "play_arrow"
                iconSize: 17
                iconColor: Colors.primary
                enabledButton: ServiceMusic.canTogglePlaying
                onClicked: ServiceMusic.togglePlaying()
            }

            M3IconButton {
                implicitWidth: 26
                implicitHeight: 26
                icon: "skip_next"
                iconSize: 15
                enabledButton: ServiceMusic.canGoNext
                onClicked: ServiceMusic.next()
            }
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottom: times.top
            anchors.bottomMargin: 8
            height: 3

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Colors.outlineVariant
                opacity: 0.5
            }

            Rectangle {
                width: parent.width * root.progress
                height: parent.height
                radius: height / 2
                color: Colors.primary

                Behavior on width { SpatialAnim { speed: "slow" } }
            }
        }

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            id: times
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            spacing: 0

            CustomText {
                content: ServiceMusic.formatTime(root.elapsed)
                size: 12
                customColor: Colors.outline
            }

            Item { Layout.fillWidth: true }

            CustomText {
                content: root.trackLength > 0 ? ServiceMusic.formatTime(root.trackLength) : "--:--"
                size: 12
                customColor: Colors.outline
            }
        }
    }
}
