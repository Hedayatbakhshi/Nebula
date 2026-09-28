import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root
    anchors.fill: parent

    readonly property var players: Mpris.players.values
    readonly property bool hasPlayers: root.players.length > 0

    implicitHeight: root.hasPlayers ? list.implicitHeight + 20 : 200

    Timer {
        interval: 1000
        repeat: true
        running: root.visible && root.hasPlayers
        onTriggered: {
            for (const p of root.players)
                if (p.isPlaying)
                    p.positionChanged()
        }
    }

    MusicEmptyState {
        anchors.fill: parent
        visible: !root.hasPlayers
    }

    ColumnLayout {
        id: list
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 6
        visible: root.hasPlayers

        Repeater {
            model: root.players

            delegate: Rectangle {
                id: row
                required property MprisPlayer modelData
                readonly property bool followed: ServiceMusic.activePlayer === row.modelData
                readonly property real length: {
                    const raw = Number(row.modelData.metadata?.["mpris:length"])
                    if (isFinite(raw) && raw > 0)
                        return raw / 1000000
                    return row.modelData.lengthSupported ? row.modelData.length : 0
                }
                readonly property real progress: row.length > 0 ? Math.max(0, Math.min(1, row.modelData.position / row.length)) : 0
                readonly property string art: row.followed ? (ServiceMusic.activeTrack?.artUrl ?? "") : (row.modelData.trackArtUrl ?? "")

                Layout.fillWidth: true
                implicitHeight: 70
                radius: 18
                color: row.followed ? Colors.secondaryContainer : rowArea.containsMouse ? Colors.surfaceContainerHigh : "transparent"
                Behavior on color { EffectsColorAnim {} }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: row.followed ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: ServiceMusic.setActivePlayer(row.modelData)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 12
                    spacing: 12

                    Item {
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 52

                        ClippingWrapperRectangle {
                            anchors.fill: parent
                            radius: 14
                            color: Colors.surfaceContainerHighest

                            Item {
                                MaterialIconSymbol {
                                    anchors.centerIn: parent
                                    visible: row.art === ""
                                    content: "album"
                                    iconSize: 24
                                    customColor: Colors.outline
                                }
                                Image {
                                    anchors.fill: parent
                                    visible: row.art !== ""
                                    source: row.art
                                    sourceSize.width: 104
                                    sourceSize.height: 104
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectCrop
                                }
                            }
                        }

                        Rectangle {
                            x: parent.width - 18
                            y: parent.height - 18
                            width: 22
                            height: 22
                            radius: 11
                            color: Colors.surfaceContainerHighest
                            border.width: 3
                            border.color: row.color.a > 0 ? row.color : Colors.surfaceContainer

                            MusicPlayerIcon {
                                anchors.centerIn: parent
                                player: row.modelData
                                side: 13
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        CustomText {
                            Layout.fillWidth: true
                            content: (row.modelData.identity ?? "") + (row.followed ? ", shown in the bar" : "")
                            size: 10
                            customColor: row.followed ? Colors.secondaryContainerText : Colors.outline
                            elide: Text.ElideRight
                        }
                        CustomText {
                            Layout.fillWidth: true
                            content: row.modelData.trackTitle || "Unknown title"
                            size: 13
                            weight: 600
                            customColor: Colors.surfaceText
                            elide: Text.ElideRight
                        }
                        CustomText {
                            Layout.fillWidth: true
                            content: row.modelData.trackArtist || ""
                            size: 11
                            customColor: Colors.surfaceVariantText
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.topMargin: 5
                            Layout.preferredHeight: 3
                            radius: 1.5
                            color: Colors.surfaceContainerHighest
                            visible: row.length > 0

                            Rectangle {
                                width: parent.width * row.progress
                                height: parent.height
                                radius: 1.5
                                color: Colors.primary
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
                        opacity: row.modelData.canTogglePlaying ? 1 : 0.4
                        color: row.followed ? Colors.primary : ppArea.containsMouse ? Colors.surfaceBright : Colors.surfaceContainerHighest
                        Behavior on color { EffectsColorAnim {} }

                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: row.modelData.isPlaying ? "pause" : "play_arrow"
                            iconSize: 20
                            fill: 1
                            customColor: row.followed ? Colors.primaryText : Colors.surfaceText
                        }

                        MouseArea {
                            id: ppArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: row.modelData.canTogglePlaying
                            cursorShape: Qt.PointingHandCursor
                            onClicked: row.modelData.togglePlaying()
                        }
                    }
                }
            }
        }
    }
}
