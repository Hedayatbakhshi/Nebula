import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root

    property int bars: 26
    property bool stretch: false
    property real barWidth: 3
    property real gap: 2
    property bool interactive: false
    property color playedColor: Colors.primary
    property color restColor: Colors.outlineVariant

    readonly property int barCount: root.stretch
        ? Math.max(12, Math.floor((root.width + root.gap) / (root.barWidth + root.gap))) : root.bars

    readonly property real elapsed: ServiceMusic.activePlayer?.position ?? 0
    readonly property real total: ServiceMusic.trackLength
    readonly property real progress: root.total > 0 ? Math.max(0, Math.min(1, root.elapsed / root.total)) : 0
    readonly property bool canSeek: root.interactive && (ServiceMusic.activePlayer?.canSeek ?? false)

    property bool dragging: false
    property real dragVal: 0
    readonly property real shown: root.dragging ? root.dragVal : root.progress
    readonly property real hoverFrac: seekArea.containsMouse ? Math.max(0, Math.min(1, (seekArea.mouseX - 4) / Math.max(1, root.width))) : -1

    implicitWidth: root.barCount * (root.barWidth + root.gap) - root.gap
    implicitHeight: 20

    Component.onCompleted: ServiceMusicWave.retain()
    Component.onDestruction: ServiceMusicWave.release()

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.gap

        Repeater {
            model: root.barCount

            Rectangle {
                required property int index
                readonly property var cell: {
                    ServiceMusicWave.captured
                    ServiceMusicWave.seed
                    return ServiceMusicWave.cell(index, root.barCount)
                }
                readonly property bool played: (index + 0.5) / root.barCount <= root.shown
                anchors.verticalCenter: parent.verticalCenter
                width: root.barWidth
                height: Math.max(root.barWidth, cell.v * root.height)
                radius: root.barWidth / 2
                color: played ? root.playedColor : root.restColor
                opacity: cell.real || played ? 1 : 0.7
                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on color { EffectsColorAnim { speed: "fast" } }
            }
        }
    }

    Rectangle {
        visible: root.canSeek && (root.hoverFrac >= 0 || root.dragging)
        x: (root.dragging ? root.dragVal : root.hoverFrac) * root.width - 1
        y: -6
        width: 2
        height: root.height + 12
        radius: 1
        color: Colors.tertiary
    }

    Rectangle {
        visible: root.canSeek && (root.hoverFrac >= 0 || root.dragging)
        readonly property real frac: root.dragging ? root.dragVal : root.hoverFrac
        x: Math.max(0, Math.min(root.width - width, frac * root.width - width / 2))
        y: -height - 10
        width: tipText.implicitWidth + 14
        height: 22
        radius: 8
        color: Colors.tertiary

        CustomText {
            id: tipText
            anchors.centerIn: parent
            content: ServiceMusic.formatTime(parent.frac * root.total)
            size: 11
            weight: 700
            customColor: Colors.tertiaryText
        }
    }

    MouseArea {
        id: seekArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: root.interactive
        enabled: root.canSeek
        cursorShape: root.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
        preventStealing: true

        function frac(mx) {
            return Math.max(0, Math.min(1, (mx - 4) / Math.max(1, root.width)))
        }

        onPressed: e => { root.dragging = true; root.dragVal = frac(e.x) }
        onPositionChanged: e => { if (pressed) root.dragVal = frac(e.x) }
        onReleased: e => {
            root.dragging = false
            if (root.total > 0)
                ServiceMusic.activePlayer.position = frac(e.x) * root.total
        }
    }
}
