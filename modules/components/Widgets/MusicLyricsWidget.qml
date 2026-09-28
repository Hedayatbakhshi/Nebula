import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "musicLyrics"
    tile: Qt.size(WidgetSizes.span(3), WidgetSizes.span(2.5))
    resizable: true
    readonly property real sw: designStage.stageWidth
    readonly property real sh: designStage.stageHeight
    minSpan: Qt.size(3, 2.5)
    maxSpan: Qt.size(5, 3.5)
    backdropRadius: WidgetSizes.radius * designStage.k
    defaultPos: Qt.point(1025, 385)

    readonly property string display: SettingsConfig.general?.displayFont || "Titan One"
    readonly property var lines: root.preview
        ? [{ t: 0, text: "the harbor lights go quiet" }, { t: 5, text: "and the radio hums your name" },
           { t: 10, text: "we were static on the water," }, { t: 15, text: "waiting for the tide to change" }]
        : ServiceLyrics.lines
    readonly property int current: root.preview ? 2 : ServiceLyrics.indexAt(m.elapsed + 0.3)
    function lineAt(i) { return i >= 0 && i < root.lines.length ? root.lines[i].text : "" }
    readonly property string note: root.preview ? ""
        : !m.hasTrack ? "Nothing playing"
        : ServiceLyrics.status === "loading" ? "Looking for lyrics…"
        : ServiceLyrics.status === "none" ? "No synced lyrics for this one"
        : ""

    MusicNow { id: m; preview: root.preview }

    Component.onCompleted: if (!root.preview) ServiceLyrics.retain()
    Component.onDestruction: if (!root.preview) ServiceLyrics.release()

    WidgetDesignStage {
        id: designStage
        anchors.fill: parent
        design: Qt.size(310, 255)

        WidgetCard {
            anchors.fill: parent

            Row {
                id: head
                x: parent.pad; y: parent.pad
                width: parent.width - parent.pad * 2
                spacing: 12
                MusicArt { width: 40; height: 40; radius: 12; source: m.artUrl }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: head.width - 40 - chip.width - 24
                    CustomText { width: parent.width; content: m.title; size: 14; weight: 700 }
                    CustomText { width: parent.width; content: m.artist; size: 12; customColor: Colors.surfaceVariantText }
                }
                Rectangle {
                    id: chip
                    anchors.verticalCenter: parent.verticalCenter
                    width: 66
                    height: 22
                    radius: 11
                    color: Colors.secondaryContainer
                    CustomText { anchors.centerIn: parent; content: "LYRICS"; size: 10; weight: 700; font.letterSpacing: 1.2; customColor: Colors.secondaryContainerText }
                }
            }

            Column {
                x: parent.pad
                anchors.top: head.bottom
                anchors.topMargin: 16
                width: parent.width - parent.pad * 2
                spacing: 7
                visible: root.note === ""

                CustomText { width: parent.width; content: root.lineAt(root.current - 2); size: 13; customColor: Colors.outlineVariant }
                CustomText { width: parent.width; content: root.lineAt(root.current - 1); size: 15; customColor: Colors.outline }
                CustomText {
                    width: parent.width
                    content: root.current < 0 ? "♪" : (root.lineAt(root.current) || "♪")
                    family: root.display
                    renderType: Text.QtRendering
                    size: root.sw < 400 ? 19 : 23
                    weight: 400
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    customColor: Colors.primary
                }
                CustomText { width: parent.width; content: root.lineAt(root.current + 1); size: 15; opacity: 0.7; customColor: Colors.surfaceVariantText }
            }

            CustomText {
                visible: root.note !== ""
                anchors.centerIn: parent
                content: root.note
                size: 14
                customColor: Colors.outline
            }

            Row {
                x: parent.pad
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.pad - 4
                width: parent.width - parent.pad * 2
                spacing: 10
                CustomText { anchors.verticalCenter: parent.verticalCenter; content: m.elapsedText; size: 11; customColor: Colors.outline }
                MeterSplitTrack {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 40 - 40 - 40 - 30
                    height: 6
                    stopDot: false
                    value: m.progress
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        enabled: m.canSeek
                        onClicked: mouse => m.seek((mouse.x - 8) / (width - 16))
                    }
                }
                CustomText { anchors.verticalCenter: parent.verticalCenter; content: m.lengthText; size: 11; customColor: Colors.outline }
                MusicButton { width: 40; height: 40; radius: 14; icon: m.playing ? "pause" : "play_arrow"; iconSize: 20; fg: Colors.primaryText; bg: Colors.primary; onClicked: m.toggle() }
            }
        }
    }
}
