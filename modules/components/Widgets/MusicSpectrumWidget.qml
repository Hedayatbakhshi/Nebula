import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "musicSpectrum"
    tile: Qt.size(WidgetSizes.span(3), WidgetSizes.span(2))
    resizable: true
    readonly property real sw: designStage.stageWidth
    readonly property real sh: designStage.stageHeight
    minSpan: Qt.size(3, 2)
    maxSpan: Qt.size(5, 2.5)
    backdropRadius: WidgetSizes.radius * designStage.k
    defaultPos: Qt.point(145, 825)

    readonly property string display: SettingsConfig.general?.displayFont || "Titan One"
    readonly property int count: 32
    readonly property var levels: {
        if (root.preview)
            return [0.4, 0.5, 0.68, 0.83, 0.82, 0.92, 0.78, 0.9, 0.8, 0.77, 0.63, 0.46, 0.42, 0.43, 0.36, 0.44, 0.44, 0.48, 0.5, 0.63, 0.52, 0.5, 0.48, 0.48, 0.32, 0.3, 0.25, 0.22, 0.18, 0.16, 0.12, 0.11]
        const d = ServiceCava.cavaData
        const out = []
        if (!d || d.length === 0) {
            for (let i = 0; i < root.count; i++)
                out.push(0)
            return out
        }
        for (let i = 0; i < root.count; i++) {
            const lo = Math.floor(i * d.length / root.count)
            const hi = Math.max(lo + 1, Math.floor((i + 1) * d.length / root.count))
            let s = 0
            for (let k = lo; k < hi; k++)
                s += d[k]
            out.push(Math.min(1, s / (hi - lo)))
        }
        return out
    }
    readonly property real peak: Math.max(...root.levels)

    MusicNow { id: m; preview: root.preview }

    Component.onCompleted: if (!root.preview) ServiceCava.retain()
    Component.onDestruction: if (!root.preview) ServiceCava.release()

    WidgetDesignStage {
        id: designStage
        anchors.fill: parent
        design: Qt.size(310, 200)

        WidgetCard {
            anchors.fill: parent
            clip: true

            Row {
                id: spectrum
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                height: parent.height * 0.72
                spacing: 4

                Repeater {
                    model: root.levels
                    delegate: Rectangle {
                        required property real modelData
                        anchors.bottom: parent.bottom
                        width: (spectrum.width - (root.count - 1) * 4) / root.count
                        height: Math.max(3, spectrum.height * modelData)
                        topLeftRadius: Math.min(6, width / 2)
                        topRightRadius: Math.min(6, width / 2)
                        color: modelData >= root.peak - 0.001 && modelData > 0.05 ? Colors.tertiaryContainer
                             : modelData > 0.8 ? Colors.primaryContainer : Colors.secondaryContainer
                        opacity: 0.92
                    }
                }
            }

            Rectangle {
                width: parent.width * m.progress
                height: 4
                color: Colors.primary
            }

            Column {
                x: 22; y: 20
                width: parent.width - 44
                spacing: 4
                CustomText {
                    content: (m.playing ? "NOW PLAYING" : "PAUSED") + (m.length > 0 ? " · " + m.elapsedText + " / " + m.lengthText : "")
                    size: 10
                    weight: 700
                    font.letterSpacing: 1.6
                    customColor: Colors.surfaceVariantText
                }
                CustomText {
                    width: parent.width
                    content: m.title
                    family: root.display
                    renderType: Text.QtRendering
                    size: root.sw < 400 ? 23 : 28
                    weight: 400
                }
                CustomText { width: parent.width; content: m.artist; size: 14; weight: 500 }
            }

            Rectangle {
                x: 20
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                width: pill.implicitWidth + 8
                height: 52
                radius: 26
                color: Qt.alpha(WidgetSizes.cardColor.a > 0.5 ? WidgetSizes.cardColor : Colors.surface, 0.92)
                Row {
                    id: pill
                    anchors.centerIn: parent
                    spacing: 4
                    MusicButton { width: 44; height: 44; icon: "skip_previous"; iconSize: 22; onClicked: m.previous() }
                    MusicButton { width: 44; height: 44; icon: m.playing ? "pause" : "play_arrow"; iconSize: 22; fg: Colors.primaryText; bg: Colors.primary; onClicked: m.toggle() }
                    MusicButton { width: 44; height: 44; icon: "skip_next"; iconSize: 22; onClicked: m.next() }
                }
            }
        }
    }
}
