import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root
    anchors.fill: parent

    readonly property bool hasTrack: ServiceMusic.activePlayer !== null
    readonly property real elapsed: ServiceMusic.activePlayer?.position ?? 0
    readonly property real total: ServiceMusic.trackLength
    readonly property real progress: root.total > 0 ? Math.max(0, Math.min(1, root.elapsed / root.total)) : 0
    readonly property bool canSeek: ServiceMusic.activePlayer?.canSeek ?? false
    readonly property string album: {
        const a = ServiceMusic.activeTrack?.album ?? ""
        return a === "Unknown Album" ? "" : a
    }

    MusicEmptyState {
        anchors.fill: parent
        visible: !root.hasTrack
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.topMargin: 18
        anchors.bottomMargin: 14
        spacing: 4
        visible: root.hasTrack

        RowLayout {
            spacing: 5
            MaterialIconSymbol {
                content: ServiceMusic.isPlaying ? "graphic_eq" : "pause_circle"
                iconSize: 14
                customColor: Colors.outline
            }
            CustomText {
                content: ServiceMusic.activeTrack?.identity ?? ""
                size: 11
                customColor: Colors.outline
            }
        }

        Item {
            id: titleBox
            Layout.fillWidth: true
            Layout.preferredHeight: base.implicitHeight

            CustomText {
                id: base
                width: parent.width
                content: ServiceMusic.activeTrack?.title ?? ""
                family: SettingsConfig.general.displayFont ?? "Titan One"
                renderType: Text.QtRendering
                size: 36
                weight: 400
                elide: Text.ElideRight
                maximumLineCount: 1
                customColor: Colors.surfaceContainerHighest
            }

            Item {
                width: Math.min(base.width, base.paintedWidth) * root.progress
                height: base.height
                clip: true
                Behavior on width { SmoothedAnimation { velocity: 240 } }

                CustomText {
                    width: base.width
                    content: base.content
                    family: base.family
                    renderType: Text.QtRendering
                    size: 36
                    weight: 400
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    customColor: Colors.primary
                }
            }

            MouseArea {
                width: Math.min(base.width, base.paintedWidth)
                height: base.height
                enabled: root.canSeek && root.total > 0
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: mouse => ServiceMusic.activePlayer.position = Math.max(0, Math.min(1, mouse.x / width)) * root.total
            }
        }

        CustomText {
            Layout.fillWidth: true
            content: ServiceMusic.activeTrack?.artist ?? ""
            size: 15
            customColor: Colors.surfaceText
            elide: Text.ElideRight
        }

        CustomText {
            Layout.fillWidth: true
            visible: root.album !== ""
            content: root.album
            size: 12
            customColor: Colors.outline
            elide: Text.ElideRight
        }

        CustomText {
            Layout.topMargin: 4
            textFormat: Text.StyledText
            content: "<font color=\"" + Colors.primary + "\"><b>" + ServiceMusic.formatTime(root.elapsed) + "</b></font> of "
                     + ServiceMusic.formatTime(root.total) + ", " + ServiceMusic.formatTime(Math.max(0, root.total - root.elapsed)) + " left"
            size: 12
            customColor: Colors.surfaceVariantText
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Colors.surfaceContainerHighest
        }

        RowLayout {
            Layout.topMargin: 6
            spacing: 6

            Word {
                icon: "skip_previous"
                label: "Previous"
                usable: ServiceMusic.canGoPrevious
                onTapped: ServiceMusic.previous()
            }
            Word {
                icon: ServiceMusic.isPlaying ? "pause" : "play_arrow"
                label: ServiceMusic.isPlaying ? "Pause" : "Play"
                strong: true
                usable: ServiceMusic.canTogglePlaying
                onTapped: ServiceMusic.togglePlaying()
            }
            Word {
                icon: "skip_next"
                label: "Next"
                usable: ServiceMusic.canGoNext
                onTapped: ServiceMusic.next()
            }
        }
    }

    component Word: Rectangle {
        id: w
        property string icon: ""
        property string label: ""
        property bool strong: false
        property bool usable: true
        signal tapped

        implicitWidth: wRow.implicitWidth + 22
        implicitHeight: 34
        radius: 17
        opacity: w.usable ? 1 : 0.4
        color: w.strong ? Colors.surfaceContainerHighest : wArea.containsMouse ? Colors.surfaceContainerHigh : "transparent"
        Behavior on color { EffectsColorAnim {} }

        RowLayout {
            id: wRow
            anchors.centerIn: parent
            spacing: 5
            MaterialIconSymbol {
                content: w.icon
                iconSize: 17
                fill: 1
                customColor: w.strong || wArea.containsMouse ? Colors.surfaceText : Colors.surfaceVariantText
            }
            CustomText {
                content: w.label
                size: 12
                weight: 500
                customColor: w.strong || wArea.containsMouse ? Colors.surfaceText : Colors.surfaceVariantText
            }
        }

        MouseArea {
            id: wArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: w.usable
            cursorShape: Qt.PointingHandCursor
            onClicked: w.tapped()
        }
    }
}
