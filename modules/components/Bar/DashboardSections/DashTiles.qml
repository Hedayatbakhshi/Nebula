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

    readonly property var ids: DashLayout.listFor(root.instanceId, "items", DashLayout.tileCatalog, DashLayout.tileDefault)
    readonly property int colSetting: Number(root.opt("columns") ?? 0)
    readonly property bool compact: root.height < root.ids.length / Math.max(1, grid.columns) * 70
    readonly property real tileH: root.compact ? 54 : 62

    function titleFor(id) {
        if (id === "network")
            return ServiceNetwork.connectionType === "ethernet" ? "Ethernet" : "Wi-Fi"
        const e = DashLayout.tileEntry(id)
        return e ? e.label : id
    }

    function subFor(id) {
        if (id === "network")
            return ServiceNetwork.connectionType === "ethernet" ? "Wired"
                : ServiceNetwork.currentSSID || (ServiceNetwork.wifiEnabled ? "Not connected" : "Off")
        if (id === "bluetooth")
            return ServiceBluetooth.connectedDevices === 0 ? "No devices"
                : ServiceBluetooth.connectedDevices === 1 ? "1 device"
                : ServiceBluetooth.connectedDevices + " devices"
        return DashLayout.subtitleFor(id)
    }

    function onFor(id) {
        if (id === "network") return ServiceNetwork.wifiEnabled
        if (id === "bluetooth") return ServiceBluetooth.connectedDevices > 0
        return DashLayout.isOn(id)
    }

    function iconFor(id) {
        if (id === "network") return ServiceNetwork.icon
        if (id === "bluetooth") return ServiceBluetooth.connectedDevices > 0 ? "bluetooth" : "bluetooth_disabled"
        const e = DashLayout.tileEntry(id)
        return e ? (DashLayout.isOn(id) ? e.iconActive : e.icon) : "toggle_on"
    }

    GridLayout {
        id: grid
        anchors.fill: parent
        columns: root.colSetting > 0 ? root.colSetting : Math.max(1, Math.min(3, Math.floor((root.width + 8) / 150)))
        columnSpacing: root.compact ? 6 : 8
        rowSpacing: root.compact ? 6 : 8

        Repeater {
            model: root.ids
            delegate: DashTile {
                id: tile
                required property string modelData
                readonly property bool opens: tile.modelData === "network" || tile.modelData === "bluetooth"
                compact: root.compact
                baseColor: root.rowColor
                chipColor: root.chipColor
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                title: root.titleFor(tile.modelData)
                subtitle: root.subFor(tile.modelData)
                icon: root.iconFor(tile.modelData)
                on: root.onFor(tile.modelData)
                opacity: tile.opens && root.panelMode === (tile.modelData === "network" ? "wifi" : "bluetooth") ? 0 : 1
                onActivated: {
                    if (tile.opens) {
                        const space = root.coordSpace ?? root
                        root.openPanel(tile.modelData === "network" ? "wifi" : "bluetooth",
                                       root.mapToItem(space, 0, 0), tile.mapToItem(space, 0, 0),
                                       Qt.size(tile.width, tile.height), tile.radius)
                    } else {
                        DashLayout.trigger(tile.modelData)
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.columnSpan: grid.columns
        }
    }
}
