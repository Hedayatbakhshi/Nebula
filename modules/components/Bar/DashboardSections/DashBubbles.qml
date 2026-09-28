import QtQuick
import Quickshell.Bluetooth
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.components.Bar

DashItem {
    id: root

    readonly property var entries: DashLayout.listFor(root.instanceId, "items", DashLayout.tileCatalog, DashLayout.bubbleDefault)
        .map(id => DashLayout.tileEntry(id)).filter(e => !!e)

    function isOn(id) {
        if (id === "network") return ServiceNetwork.wifiEnabled
        if (id === "bluetooth") return ServiceBluetooth.state
        return DashLayout.isOn(id)
    }

    ExpressiveIconRow {
        id: row
        anchors.centerIn: parent
        width: root.width
        height: implicitHeight
        readonly property int fitPerRow: Math.max(1, Math.floor((root.width + 7) / 53))
        readonly property int lines: Math.max(1, Math.ceil(root.entries.length / row.fitPerRow))
        minWidth: 46
        idleColor: root.rowColor
        hoverColor: root.chipColor
        rowHeight: Math.max(36, Math.min(64, (root.height - (row.lines - 1) * 7) / row.lines))
        model: root.entries
        iconFor: function(m, active) {
            if (m.id === "network") return ServiceNetwork.icon
            if (m.id === "bluetooth") return active ? "bluetooth" : "bluetooth_disabled"
            return active ? m.iconActive : m.icon
        }
        activeCheck: function(i) {
            const e = root.entries[i]
            return e ? root.isOn(e.id) : false
        }
        onTriggered: i => {
            const e = root.entries[i]
            if (!e) return
            if (e.id === "network") ServiceNetwork.toggleWifi()
            else if (e.id === "bluetooth") { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled }
            else DashLayout.trigger(e.id)
        }
    }
}
