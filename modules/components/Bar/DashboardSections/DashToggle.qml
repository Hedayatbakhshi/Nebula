import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.components.Bar

DashItem {
    id: root

    property Item coordSpace: null
    property string panelMode: ""
    signal openPanel(string mode, var parentPos, var pos, var srcSize, real srcRadius)

    card: true
    cardColor: "transparent"

    readonly property string which: String(root.opt("which") ?? "network")
    readonly property var entry: DashLayout.tileEntry(root.which)
    readonly property string face: {
        const f = String(root.opt("face") ?? "auto")
        if (f !== "auto")
            return f
        return root.outerW >= root.outerH * 1.8 && root.outerW >= 150 ? "tile" : "round"
    }
    readonly property bool opens: root.which === "network" || root.which === "bluetooth"
    readonly property string mode: root.which === "network" ? "wifi" : "bluetooth"

    readonly property bool on: {
        if (root.which === "network") return ServiceNetwork.wifiEnabled
        if (root.which === "bluetooth") return ServiceBluetooth.connectedDevices > 0 || ServiceBluetooth.state
        return DashLayout.isOn(root.which)
    }
    readonly property string icon: {
        if (root.which === "network") return ServiceNetwork.icon
        if (root.which === "bluetooth") return root.on ? "bluetooth" : "bluetooth_disabled"
        return root.entry ? (root.on ? root.entry.iconActive : root.entry.icon) : "toggle_on"
    }
    readonly property string title: root.which === "network"
        ? (ServiceNetwork.connectionType === "ethernet" ? "Ethernet" : "Wi-Fi")
        : root.entry ? root.entry.label : root.which
    readonly property string sub: {
        if (root.which === "network")
            return ServiceNetwork.connectionType === "ethernet" ? "Wired"
                : ServiceNetwork.currentSSID || (ServiceNetwork.wifiEnabled ? "Not connected" : "Off")
        if (root.which === "bluetooth")
            return ServiceBluetooth.connectedDevices === 0 ? (ServiceBluetooth.state ? "On" : "Off")
                : ServiceBluetooth.connectedDevices === 1 ? "1 device" : ServiceBluetooth.connectedDevices + " devices"
        return DashLayout.subtitleFor(root.which)
    }

    function toggle() {
        if (root.which === "network") ServiceNetwork.toggleWifi()
        else if (root.which === "bluetooth") { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled }
        else DashLayout.trigger(root.which)
    }

    function expand(from) {
        const space = root.coordSpace ?? root
        root.openPanel(root.mode, root.mapToItem(space, 0, 0), from.mapToItem(space, 0, 0),
                       Qt.size(from.width, from.height), from.radius)
    }

    DashTile {
        id: tile
        visible: root.face === "tile"
        anchors.fill: parent
        compact: root.height < 60
        title: root.title
        subtitle: root.sub
        icon: root.icon
        on: root.on
        radius: 20
        baseColor: Colors.surfaceContainerHigh
        chipColor: Colors.surfaceContainerHighest
        opacity: root.opens && root.panelMode === root.mode ? 0 : 1
        onActivated: root.opens ? root.expand(tile) : root.toggle()
    }

    Rectangle {
        id: round
        visible: root.face === "round"
        anchors.fill: parent
        readonly property real side: Math.min(root.width, root.height)
        radius: area.pressed ? round.side * 0.22 : root.on ? round.side * 0.32 : round.side / 2
        color: root.on ? Colors.primary : area.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
        Behavior on radius { SpatialAnim { speed: "fast" } }
        Behavior on color { EffectsColorAnim { speed: "fast" } }
        opacity: root.opens && root.panelMode === root.mode ? 0 : 1

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: root.icon
            iconSize: Math.max(16, Math.min(28, round.side * 0.42))
            customColor: root.on ? Colors.primaryText : Colors.surfaceText
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton && root.opens) root.expand(round)
                else root.toggle()
            }
        }

        CustomToolTip { content: root.title + " · " + root.sub; visible: area.containsMouse }
    }
}
