pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.settings
import qs.modules.services
import "DashOps.js" as DashOps

Singleton {
    id: root

    readonly property var quickCatalog: [
        { id: "airplane",      label: "Airplane",   icon: "travel",              iconActive: "airplanemode_inactive" },
        { id: "notifications", label: "Notifications", icon: "notifications",    iconActive: "notifications_off" },
        { id: "speaker",       label: "Speaker",    icon: "volume_up",           iconActive: "volume_off" },
        { id: "mic",           label: "Mic",        icon: "mic",                 iconActive: "mic_off" },
        { id: "awake",         label: "Awake",      icon: "bedtime",             iconActive: "coffee" },
        { id: "dnd",           label: "Do not disturb", icon: "do_not_disturb_off", iconActive: "do_not_disturb_on" },
        { id: "gameMode",      label: "Game mode",  icon: "sports_esports",      iconActive: "sports_esports" },
        { id: "recording",     label: "Recording",  icon: "screen_record",       iconActive: "stop_circle" },
        { id: "tools",         label: "Tools",      icon: "screenshot_monitor",  iconActive: "screenshot_monitor" },
        { id: "clipboard",     label: "Clipboard",  icon: "content_paste",       iconActive: "content_paste" },
        { id: "wallpaper",     label: "Wallpaper",  icon: "wallpaper",           iconActive: "wallpaper" },
        { id: "overview",      label: "Overview",   icon: "grid_view",           iconActive: "grid_view" },
        { id: "settings",      label: "Settings",   icon: "settings",            iconActive: "settings" }
    ]

    readonly property var quickDefault: ["airplane", "notifications", "speaker", "mic", "awake"]

    function quickEntry(id) {
        return root.quickCatalog.find(e => e.id === id) ?? null
    }

    readonly property var catalog: [
        { id: "profile", label: "Profile", icon: "account_circle",
          options: [{ key: "showAvatar", label: "Avatar", type: "toggle", default: true },
                    { key: "showUptime", label: "Uptime", type: "toggle", default: true },
                    { key: "hActions", label: "Buttons", type: "heading" },
                    { key: "showSettings", label: "Settings", type: "toggle", default: true },
                    { key: "showReload", label: "Reload", type: "toggle", default: true },
                    { key: "showPower", label: "Power", type: "toggle", default: true },
                    { key: "showClose", label: "Close", type: "toggle", default: true }] },
        { id: "controls", label: "Controls", icon: "tune",
          options: [{ key: "hSliders", label: "Sliders", type: "heading" },
                    { key: "brightness", label: "Brightness", type: "toggle", default: true },
                    { key: "volume", label: "Volume", type: "toggle", default: true },
                    { key: "hTiles", label: "Tiles", type: "heading" },
                    { key: "network", label: "Network", type: "toggle", default: true },
                    { key: "bluetooth", label: "Bluetooth", type: "toggle", default: true },
                    { key: "tileColumns", label: "Side by side", type: "choice", default: 0,
                      choices: [{ value: 0, label: "Auto" }, { value: 1, label: "Stacked" },
                                { value: 2, label: "Two" }] },
                    { key: "hButtons", label: "Buttons", type: "heading" },
                    { key: "gameMode", label: "Game mode", type: "toggle", default: true },
                    { key: "power", label: "Power profile", type: "toggle", default: true },
                    { key: "recording", label: "Recording", type: "toggle", default: true }] },
        { id: "quickActions", label: "Quick actions", icon: "bolt",
          options: [{ key: "items", label: "Buttons", type: "buttons", catalog: root.quickCatalog,
                      default: root.quickDefault },
                    { key: "size", label: "Button size", type: "slider",
                      min: 32, max: 64, step: 2, default: 46 }] },
        { id: "notifications", label: "Notifications", icon: "notifications",
          options: [{ key: "fill", label: "Fill space", type: "toggle", default: true },
                    { key: "height", label: "List height", type: "slider", min: 160, max: 600, step: 20, default: 420,
                      onlyIf: { key: "fill", values: [false] } },
                    { key: "showActions", label: "Buttons", type: "toggle", default: true }] },
        { id: "media", label: "Media", icon: "music_note",
          options: [{ key: "hideIdle", label: "Hide when nothing plays", type: "toggle", default: true },
                    { key: "height", label: "Height", type: "slider",
                      min: 110, max: 240, step: 10, default: 150 }] },
        { id: "stats", label: "System stats", icon: "monitoring",
          options: [{ key: "cpu", label: "CPU", type: "toggle", default: true },
                    { key: "memory", label: "Memory", type: "toggle", default: true },
                    { key: "temp", label: "Temperature", type: "toggle", default: true },
                    { key: "gpu", label: "GPU", type: "toggle", default: false },
                    { key: "disk", label: "Disk", type: "toggle", default: true },
                    { key: "net", label: "Network", type: "toggle", default: true },
                    { key: "columns", label: "Meters per row", type: "choice", default: 0,
                      choices: [{ value: 0, label: "Auto" }, { value: 1, label: "One" },
                                { value: 2, label: "Two" }, { value: 4, label: "Four" }] }] },
        { id: "calendar", label: "Calendar", icon: "calendar_month",
          options: [{ key: "startDay", label: "Week starts", type: "choice", default: 0,
                      choices: [{ value: 0, label: "Sunday" }, { value: 1, label: "Monday" }] },
                    { key: "showHolidays", label: "Holidays", type: "toggle", default: true }] }
    ]

    readonly property var ids: root.catalog.map(e => e.id)

    readonly property var cfg: SettingsConfig.dashboard ?? ({})

    function entry(id) {
        return root.catalog.find(e => e.id === id) ?? null
    }

    function _list(v) {
        return (v !== undefined && v !== null && typeof v.length === "number")
            ? Array.prototype.slice.call(v) : undefined
    }

    readonly property var order: DashOps.sanitizeOrder(root._list(root.cfg.order), root.ids)

    readonly property var defaultOff: ["media", "stats"]

    function shows(id) {
        const v = root.cfg[id]
        if (v === undefined)
            return root.defaultOff.indexOf(id) < 0
        return v !== false
    }

    readonly property var visibleIds: root.order.filter(id => root.shows(id))
    readonly property var hiddenIds: root.order.filter(id => !root.shows(id))

    function _patch(o) {
        SettingsConfig.dashboard = Object.assign({}, SettingsConfig.dashboard ?? {}, o)
    }

    function moveBefore(id, before) {
        if (root.ids.indexOf(id) < 0)
            return
        root._patch({ order: DashOps.reorder(root.order, id, before) })
    }

    function hideSection(id) {
        if (root.visibleIds.length <= 1)
            return
        const o = {}
        o[id] = false
        root._patch(o)
    }

    function showSection(id) {
        const o = {}
        o[id] = true
        root._patch(o)
    }


    readonly property bool dnd: SettingsConfig.notifications?.doNotDisturb ?? false

    function isOn(id) {
        switch (id) {
        case "airplane":      return !ServiceNetwork.wifiEnabled
        case "notifications": return ServiceNotification.muted
        case "speaker":       return ServicePipewire.muted
        case "mic":           return ServicePipewire.micMuted
        case "awake":         return ServiceIdleInhibit.active
        case "dnd":           return root.dnd
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
                                                         { doNotDisturb: !root.dnd })
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

    function subtitleFor(id) {
        switch (id) {
        case "airplane":      return ServiceNetwork.wifiEnabled ? "Wi-Fi on" : "Radios off"
        case "notifications": return ServiceNotification.muted ? "Muted" : "Allowed"
        case "speaker":       return ServicePipewire.muted ? "Muted" : Math.round((ServicePipewire.volume ?? 0) * 100) + "%"
        case "mic":           return ServicePipewire.micMuted ? "Muted" : "Live"
        case "awake":         return ServiceIdleInhibit.active ? "Staying awake" : "Sleep allowed"
        case "dnd":           return root.dnd ? "On" : "Off"
        case "gameMode":      return ServiceGameMode.active ? "On" : "Off"
        case "recording":     return ServiceTools.isRecording ? "Recording" : "Idle"
        }
        return ""
    }

    readonly property bool cards: root.cfg.cards === true

    function setCards(on) {
        root._patch({ cards: on === true })
    }

    readonly property int columnsSetting: Number(root.cfg.columns ?? 0) || 0

    function setColumns(n) {
        root._patch({ columns: Number(n) || 0 })
    }

    readonly property string density: String(root.cfg.density ?? "auto")

    function setDensity(v) {
        root._patch({ density: String(v) })
    }

    function moveStep(id, delta) {
        const vis = root.visibleIds
        const i = vis.indexOf(id)
        const j = i + delta
        if (i < 0 || j < 0 || j >= vis.length)
            return
        root.moveBefore(id, delta < 0 ? vis[j] : (j + 1 < vis.length ? vis[j + 1] : ""))
    }

    readonly property var sectionOptions: root.cfg.options ?? ({})

    readonly property var quickItems: {
        const own = root.sectionOptions["quickActions"]
        const saved = root._list(own ? own.items : undefined)
        if (saved)
            return saved.filter(id => !!root.quickEntry(id))
        return root.quickDefault.filter(id => !own || own[id] !== false)
    }

    function specFor(id, key) {
        const e = root.entry(id)
        if (!e || !e.options)
            return null
        return e.options.find(o => o.key === key) ?? null
    }

    function opt(id, key) {
        const own = root.sectionOptions[id]
        const v = own ? own[key] : undefined
        if (v !== undefined)
            return v
        const s = root.specFor(id, key)
        return s ? s.default : undefined
    }

    function itemList(id, key) {
        const raw = root.opt(id, key)
        const list = root._list(raw)
        if (list)
            return list.filter(x => typeof x === "string")
        return []
    }

    function addItem(id, key, value) {
        const list = root.itemList(id, key)
        if (list.indexOf(value) >= 0)
            return
        list.push(value)
        root.setOption(id, key, list)
    }

    function removeItem(id, key, value) {
        root.setOption(id, key, root.itemList(id, key).filter(x => x !== value))
    }

    function setOption(id, key, value) {
        const next = Object.assign({}, root.sectionOptions)
        const own = Object.assign({}, next[id] ?? {})
        own[key] = value
        next[id] = own
        root._patch({ options: next })
    }

    function reset() {
        const o = { order: [], options: ({}), cards: false, columns: 0, density: "auto" }
        root.ids.forEach(id => { o[id] = true })
        root._patch(o)
    }

    IpcHandler {
        target: "dash"
        function state(): string {
            return JSON.stringify({ order: root.order, hidden: root.hiddenIds,
                                    options: root.sectionOptions, cfg: SettingsConfig.dashboard })
        }
        function reset(): void { root.reset() }
    }
}
