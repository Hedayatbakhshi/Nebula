import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "cassette"
    tile: WidgetSizes.wide
    defaultPos: Qt.point(100, 620)

    readonly property bool hasTrack: ServiceMusic.activePlayer !== null
    readonly property real trackLength: ServiceMusic.trackLength
    readonly property real elapsed: ServiceMusic.activePlayer?.position ?? 0

    readonly property real progress: trackLength > 0
        ? Math.max(0, Math.min(1, elapsed / trackLength))
        : 0

    readonly property real hubR: 8
    readonly property real minR: 13
    readonly property real maxR: 28

    function reelRadius(fill) {
        const f = Math.max(0, Math.min(1, fill))
        return Math.sqrt(minR * minR + (maxR * maxR - minR * minR) * f)
    }

    readonly property real supplyR: reelRadius(1 - progress)
    readonly property real takeR: reelRadius(progress)

    Rectangle {
        id: shell
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: WidgetSizes.cardColor

        Repeater {
            model: 4

            Rectangle {
                required property int index

                width: 5
                height: 5
                radius: 2.5
                color: Colors.outlineVariant
                x: index % 2 === 0 ? 9 : shell.width - 14
                y: index < 2 ? 9 : shell.height - 14
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                radius: 10
                color: Colors.primaryContainer

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 8
                    height: 1
                    color: Qt.alpha(Colors.primaryContainerText, 0.18)
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 7
                    spacing: 0

                    CustomMarqueeText {
                        Layout.fillWidth: true
                        content: root.hasTrack
                            ? (ServiceMusic.activeTrack?.title ?? "Unknown Title")
                            : "Nothing playing"
                        size: 13
                        weight: 700
                        customColor: Colors.primaryContainerText
                        scrolling: !root.preview
                    }

                    CustomText {
                        Layout.fillWidth: true
                        content: root.hasTrack
                            ? (ServiceMusic.activeTrack?.artist ?? "Unknown Artist")
                            : "insert a tape"
                        size: 11
                        elide: Text.ElideRight
                        customColor: Qt.alpha(Colors.primaryContainerText, 0.7)
                    }
                }
            }

            Rectangle {
                id: tapeWindow
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Colors.surfaceContainerLowest
                border.width: 1
                border.color: Colors.outlineVariant

                readonly property real leftCx: 62
                readonly property real rightCx: width - 62

                Rectangle {
                    x: tapeWindow.leftCx + root.supplyR
                    width: Math.max(0, (tapeWindow.rightCx - root.takeR) - x)
                    height: 3
                    radius: 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    color: Colors.surfaceContainerHighest
                }

                Repeater {
                    model: 2

                    Item {
                        id: reel
                        required property int index

                        readonly property real discR: reel.index === 0 ? root.supplyR : root.takeR

                        width: root.maxR * 2
                        height: root.maxR * 2
                        x: (reel.index === 0 ? tapeWindow.leftCx : tapeWindow.rightCx) - width / 2
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.centerIn: parent
                            width: reel.discR * 2
                            height: width
                            radius: width / 2
                            color: Colors.surfaceContainerHighest

                            Behavior on width { SpatialAnim { speed: "slow" } }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: reel.discR * 2 - 6
                            height: width
                            radius: width / 2
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.alpha(Colors.outline, 0.35)

                            Behavior on width { SpatialAnim { speed: "slow" } }
                        }

                        Item {
                            anchors.centerIn: parent
                            width: root.hubR * 2
                            height: root.hubR * 2

                            NumberAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 2400
                                loops: Animation.Infinite
                                running: ServiceMusic.isPlaying
                            }

                            Repeater {
                                model: 3

                                Rectangle {
                                    required property int index

                                    anchors.centerIn: parent
                                    width: 3
                                    height: root.hubR * 2 + 7
                                    radius: 1.5
                                    color: Colors.primary
                                    rotation: index * 60
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: root.hubR
                                height: root.hubR
                                radius: width / 2
                                color: Colors.surfaceContainerLowest
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                spacing: 8

                CustomText {
                    content: ServiceMusic.formatTime(root.elapsed)
                    size: 11
                    customColor: Colors.outline
                }

                CustomText {
                    Layout.fillWidth: true
                    content: root.trackLength > 0 ? "/ " + ServiceMusic.formatTime(root.trackLength) : ""
                    size: 11
                    customColor: Qt.alpha(Colors.outline, 0.6)
                }

                M3IconButton {
                    implicitWidth: 30
                    implicitHeight: 30
                    icon: "skip_previous"
                    iconSize: 16
                    enabledButton: ServiceMusic.canGoPrevious
                    onClicked: ServiceMusic.previous()
                }

                M3IconButton {
                    implicitWidth: 30
                    implicitHeight: 30
                    icon: ServiceMusic.isPlaying ? "pause" : "play_arrow"
                    iconSize: 18
                    iconColor: Colors.primary
                    enabledButton: ServiceMusic.canTogglePlaying
                    onClicked: ServiceMusic.togglePlaying()
                }

                M3IconButton {
                    implicitWidth: 30
                    implicitHeight: 30
                    icon: "skip_next"
                    iconSize: 16
                    enabledButton: ServiceMusic.canGoNext
                    onClicked: ServiceMusic.next()
                }
            }
        }
    }
}
