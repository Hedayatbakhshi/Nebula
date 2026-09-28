import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root

    property var player: null
    property real side: 14
    property color glyphColor: Colors.primary

    readonly property var entry: {
        const p = root.player
        if (!p)
            return null
        return DesktopEntries.heuristicLookup(p.desktopEntry || "") ?? DesktopEntries.heuristicLookup(p.identity || "")
    }
    readonly property string src: root.entry && ServiceApps.list.length >= 0
        ? Quickshell.iconPath(root.entry.icon ?? "", true) : ""

    implicitWidth: root.side
    implicitHeight: root.side

    IconImage {
        anchors.fill: parent
        visible: root.src !== ""
        source: root.src
        implicitSize: root.side
    }

    MaterialIconSymbol {
        anchors.centerIn: parent
        visible: root.src === ""
        content: "music_note"
        iconSize: root.side
        fill: 1
        customColor: root.glyphColor
    }
}
