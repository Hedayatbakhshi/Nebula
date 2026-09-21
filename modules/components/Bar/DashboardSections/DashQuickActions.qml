import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.settings
import qs.modules.components.Bar

Rectangle{
    id: root
    property bool compact: false

    readonly property var actions: {
        const out = []
        const ids = DashLayout.quickItems
        for (let i = 0; i < ids.length; i++) {
            const e = DashLayout.quickEntry(ids[i])
            if (e) out.push(e)
        }
        return out
    }

    readonly property bool _dnd: SettingsConfig.notifications?.doNotDisturb ?? false

    readonly property real buttonSize: {
        const v = DashLayout.opt("quickActions", "size")
        const s = (typeof v === "number" && v > 0) ? v : 46
        return root.compact ? Math.round(s * 0.83) : s
    }

    function isOn(id) {
        switch (id) {
        case "airplane":      return !ServiceNetwork.wifiEnabled
        case "notifications": return ServiceNotification.muted
        case "speaker":       return ServicePipewire.muted
        case "mic":           return ServicePipewire.micMuted
        case "awake":         return ServiceIdleInhibit.active
        case "dnd":           return root._dnd
        case "gameMode":      return ServiceGameMode.active
        case "recording":     return ServiceTools.isRecording
        case "tools":         return GlobalStates.toolsWidgetOpen
        case "clipboard":     return GlobalStates.clipboardOpen
        case "wallpaper":     return GlobalStates.wallpaperOpen
        case "overview":      return GlobalStates.overviewOpen
        case "settings":      return GlobalStates.settingsOpen
        }
        return false
    }

    function trigger(id) {
        switch (id) {
        case "airplane":      ServiceNetwork.toggleWifi(); return
        case "notifications": ServiceNotification.toggleMute(); return
        case "speaker":       ServicePipewire.toggleMute(); return
        case "mic":           ServicePipewire.toggleMicMute(); return
        case "awake":         ServiceIdleInhibit.toggle(); return
        case "dnd":
            SettingsConfig.notifications = Object.assign({}, SettingsConfig.notifications,
                                                         { doNotDisturb: !root._dnd })
            return
        case "gameMode":      ServiceGameMode.toggle(); return
        case "recording":
        case "tools":         GlobalStates.toolsWidgetOpen = !GlobalStates.toolsWidgetOpen; return
        case "clipboard":     GlobalStates.clipboardOpen = !GlobalStates.clipboardOpen; return
        case "wallpaper":     GlobalStates.wallpaperOpen = !GlobalStates.wallpaperOpen; return
        case "overview":      GlobalStates.overviewOpen = !GlobalStates.overviewOpen; return
        case "settings":      GlobalStates.settingsOpen = !GlobalStates.settingsOpen; return
        }
    }

    implicitHeight: root.actions.length === 0 ? 0 : iconRow.implicitHeight
    color: "transparent"

    ColumnLayout{
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        ExpressiveIconRow {
            id: iconRow
            Layout.fillWidth: true
            Layout.preferredHeight: iconRow.implicitHeight
            rowHeight: root.buttonSize
            minWidth: root.buttonSize
            model: root.actions
            iconFor: function(m, active) { return active ? m.iconActive : m.icon }
            activeCheck: function(i) {
                const a = root.actions[i]
                return a ? root.isOn(a.id) : false
            }
            onTriggered: i => {
                const a = root.actions[i]
                if (a) root.trigger(a.id)
            }
        }
    }
}
