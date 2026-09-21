import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents
import qs.modules.components.Bar

Rectangle {
    id: root

    property bool compact: false

    readonly property bool hasTrack: ServiceMusic.activePlayer !== null
    readonly property bool hideIdle: DashLayout.opt("media", "hideIdle") !== false

    readonly property real tallness: Number(DashLayout.opt("media", "height") ?? 150) || 150
    implicitHeight: root.hasTrack ? (root.compact ? root.tallness * 0.85 : root.tallness)
                                  : (root.hideIdle ? 0 : 74)
    visible: implicitHeight > 0
    Behavior on implicitHeight { SpatialAnim { speed: "default" } }

    radius: 20
    color: Colors.surfaceContainerHigh
    clip: true

    BarMusicPanel {
        anchors.fill: parent
        anchors.margins: root.compact ? 8 : 10
        visible: root.hasTrack
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
        spacing: 10
        visible: !root.hasTrack

        MaterialIconSymbol {
            content: "music_off"
            iconSize: 20
            customColor: Colors.outline
        }

        CustomText {
            Layout.fillWidth: true
            content: "Nothing playing"
            size: 12
            weight: 600
            customColor: Colors.outline
        }
    }
}
