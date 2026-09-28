pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.settings
import qs.modules.services
import qs.modules.utils
import "DashGrid.js" as DashGrid

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


    readonly property var tileCatalog: [
        { id: "network",   label: "Network",   icon: "wifi",      iconActive: "wifi" },
        { id: "bluetooth", label: "Bluetooth", icon: "bluetooth", iconActive: "bluetooth" }
    ].concat(root.quickCatalog)
    readonly property var tileDefault: ["network", "bluetooth", "dnd", "gameMode", "awake", "recording"]
    readonly property var bubbleDefault: ["network", "bluetooth", "dnd", "awake"]

    function tileEntry(id) {
        return root.tileCatalog.find(e => e.id === id) ?? null
    }

    readonly property var metricCatalog: [
        { id: "cpu",  label: "CPU",  icon: "memory" },
        { id: "gpu",  label: "GPU",  icon: "developer_board" },
        { id: "ram",  label: "RAM",  icon: "memory_alt" },
        { id: "temp", label: "Temp", icon: "thermostat" },
        { id: "disk", label: "Disk", icon: "hard_drive" }
    ]
    readonly property var metricDefault: ["cpu", "gpu", "ram", "temp"]

    function metricLabel(id) {
        const e = root.metricCatalog.find(m => m.id === id)
        return e ? e.label : id
    }

    function metricFraction(id) {
        switch (id) {
        case "cpu":  return ServiceSystemInfo.cpuUsage
        case "gpu":  return ServiceSystemInfo.gpuUsage
        case "ram":  return ServiceSystemInfo.memUsage
        case "temp": return Math.max(0, Math.min(1, ServiceSystemInfo.cpuTemp / 100))
        case "disk": return ServiceSystemInfo.diskUsage
        }
        return 0
    }

    function metricText(id) {
        if (id === "temp")
            return Math.round(ServiceSystemInfo.cpuTemp) + "°"
        return String(Math.round(root.metricFraction(id) * 100))
    }

    function metricDetail(id) {
        switch (id) {
        case "cpu":  return Math.round(ServiceSystemInfo.cpuTemp) + "°C"
        case "gpu":  return Math.round(ServiceSystemInfo.gpuTemp) + "°C"
        case "ram":  return ServiceSystemInfo.memUsedGb.toFixed(1) + " / " + Math.round(ServiceSystemInfo.memTotalGb) + " GB"
        case "temp": return "CPU"
        case "disk": return Math.round(ServiceSystemInfo.diskUsedGb) + " / " + Math.round(ServiceSystemInfo.diskTotalGb) + " GB"
        }
        return ""
    }

    function metricHistory(id) {
        switch (id) {
        case "cpu":  return ServiceDashData.cpuHist
        case "gpu":  return ServiceDashData.gpuHist
        case "ram":  return ServiceDashData.memHist
        case "temp": return ServiceDashData.tempHist.map(t => t / 100)
        }
        return []
    }

    function metricColor(id) {
        return id === "gpu" ? Colors.tertiary : id === "temp" ? Colors.secondary : Colors.primary
    }

    readonly property var groups: ["Time", "Media and info", "Controls", "System", "Panels"]

    readonly property var renamed: ({
        "w.musicStrip": "player", "w.claudeCode": "claude", "w.networkGraph": "network",
        "w.sysMonitor.compact": "gauges", "w.sysMonitor.pulse": "stat", "w.phone": "devices",
        "controls": "tiles", "quickActions": "bubbles", "media": "player", "calendar": "month", "stats": "gauges"
    })

    function migrate(kind) {
        if (root.renamed[kind])
            return root.renamed[kind]
        if (kind.indexOf("w.clock") === 0) return "clock"
        if (kind.indexOf("w.weather") === 0) return "weather"
        if (kind.indexOf("w.battery") === 0) return "battery"
        if (kind.indexOf("w.music") === 0) return "player"
        return kind
    }

    readonly property var baseCatalog: [
        { id: "profile", label: "Profile", icon: "account_circle", group: "Panels", legacy: true,
          minW: 1, minH: 1, defW: 4, defH: 1,
          options: [{ key: "showAvatar", label: "Avatar", type: "toggle", default: true },
                    { key: "showUptime", label: "Uptime", type: "toggle", default: true },
                    { key: "hActions", label: "Buttons", type: "heading" },
                    { key: "showSettings", label: "Settings", type: "toggle", default: true },
                    { key: "showReload", label: "Reload", type: "toggle", default: true },
                    { key: "showPower", label: "Power", type: "toggle", default: true },
                    { key: "showClose", label: "Close", type: "toggle", default: true }] },
        { id: "tiles", label: "Toggles", icon: "toggle_on", group: "Controls",
          minW: 1, minH: 1, defW: 2, defH: 3,
          options: [root.styleOption("tiles"),{ key: "items", label: "Tiles", type: "buttons", catalog: root.tileCatalog,
                      default: root.tileDefault },
                    { key: "columns", label: "Columns", type: "choice", default: 0,
                      choices: [{ value: 0, label: "Auto" }, { value: 1, label: "One" },
                                { value: 2, label: "Two" }, { value: 3, label: "Three" }] }] },
        { id: "bubbles", label: "Toggles", icon: "radio_button_checked", group: "Controls", hidden: true,
          minW: 1, minH: 1, defW: 1, defH: 2,
          options: [root.styleOption("bubbles"),{ key: "items", label: "Toggles", type: "buttons", catalog: root.tileCatalog,
                      default: root.bubbleDefault }] },
        { id: "slider", label: "Slider", icon: "linear_scale", group: "Controls",
          minW: 1, minH: 1, defW: 2, defH: 1,
          options: [{ key: "target", label: "Controls", type: "choice", default: "volume",
                      choices: [{ value: "volume", label: "Volume", icon: "volume_up" },
                                { value: "brightness", label: "Brightness", icon: "brightness_7" },
                                { value: "mic", label: "Mic", icon: "mic" }] },
                    { key: "showValue", label: "Value while dragging", type: "toggle", default: true },
                    { key: "color", label: "Colour", type: "choice", default: "auto",
                      choices: [{ value: "auto", label: "Auto" }, { value: "primary", label: "Primary" },
                                { value: "secondary", label: "Secondary" }, { value: "tertiary", label: "Tertiary" },
                                { value: "error", label: "Red" }] },
                    { key: "showLabel", label: "Name above when wide", type: "toggle", default: true,
                      sub: "Only at 3 columns or more" }] },
        { id: "power", label: "Power profile", icon: "bolt", group: "Controls",
          minW: 1, minH: 1, defW: 2, defH: 1,
          options: [{ key: "style", label: "Style", type: "choice", default: "buttons",
                      choices: [{ value: "buttons", label: "Three buttons", icon: "view_week" },
                                { value: "button", label: "One button + panel", icon: "open_in_full" }] }] },
        { id: "toggle", label: "Toggle", icon: "toggle_on", group: "Controls", noBackground: true,
          minW: 1, minH: 1, defW: 1, defH: 1,
          options: [{ key: "which", label: "Controls", type: "choice", default: "network",
                      choices: root.tileCatalog.filter(e => ["tools", "clipboard", "wallpaper", "overview", "settings"].indexOf(e.id) < 0)
                                   .map(e => ({ value: e.id, label: e.label, icon: e.icon })) },
                    { key: "face", label: "Style", type: "choice", default: "auto",
                      choices: [{ value: "auto", label: "By size" }, { value: "round", label: "Round" },
                                { value: "tile", label: "Tile" }] }] },
        { id: "timeline", label: "Day timeline", icon: "view_timeline", group: "Time",
          minW: 2, minH: 3, defW: 2, defH: 6,
          options: [{ key: "from", label: "Starts at", type: "slider", min: 0, max: 12, step: 1, default: 8 },
                    { key: "to", label: "Ends at", type: "slider", min: 13, max: 24, step: 1, default: 23 },
                    { key: "calendars", label: "Calendars", type: "text", default: "",
                      placeholder: "Paste iCal links, one or more" }] },
        { id: "nextUp", label: "Next up", icon: "event_upcoming", group: "Time",
          minW: 1, minH: 1, defW: 2, defH: 3,
          options: [{ key: "count", label: "Events", type: "slider", min: 1, max: 8, step: 1, default: 3 },
                    { key: "holidays", label: "Holidays", type: "toggle", default: true },
                    { key: "calendars", label: "Calendars", type: "text", default: "",
                      placeholder: "Paste iCal links, one or more" }] },
        { id: "notifications", label: "Notifications", icon: "notifications", group: "Panels", legacy: true,
          minW: 2, minH: 2, defW: 4, defH: 6,
          options: [{ key: "showActions", label: "Buttons", type: "toggle", default: true }] },
        { id: "processes", label: "Top processes", icon: "list_alt", group: "System",
          minW: 1, minH: 2, defW: 2, defH: 3,
          options: [{ key: "count", label: "Rows", type: "slider", min: 3, max: 12, step: 1, default: 5 },
                    { key: "sort", label: "Sort by", type: "choice", default: "cpu",
                      choices: [{ value: "cpu", label: "CPU" }, { value: "mem", label: "Memory" }] }] },
        { id: "storage", label: "Storage", icon: "hard_drive", group: "System",
          minW: 1, minH: 2, defW: 2, defH: 3, options: [] },
        { id: "clock", label: "Clock", icon: "schedule", group: "Time",
          minW: 1, minH: 1, defW: 2, defH: 2,
          options: [{ key: "face", label: "Face", type: "choice", default: "auto",
                      choices: [{ value: "auto", label: "By size" }, { value: "plain", label: "Plain" },
                                { value: "shapes", label: "Shapes" }, { value: "card", label: "Card" }] }] },
        { id: "month", label: "Month", icon: "calendar_month", group: "Time",
          minW: 2, minH: 3, defW: 2, defH: 4,
          options: [{ key: "startDay", label: "Week starts", type: "choice", default: 1,
                      choices: [{ value: 1, label: "Monday" }, { value: 0, label: "Sunday" }] },
                    { key: "holidays", label: "Holidays", type: "toggle", default: true },
                    { key: "calendars", label: "Calendars", type: "text", default: "",
                      placeholder: "Paste iCal links, one or more" }] },
        { id: "player", label: "Player", icon: "music_note", group: "Media and info",
          minW: 2, minH: 1, defW: 2, defH: 3, options: [] },
        { id: "weather", label: "Weather", icon: "partly_cloudy_day", group: "Media and info",
          minW: 1, minH: 2, defW: 2, defH: 3, options: [] },
        { id: "inbox", label: "Notification list", icon: "notifications", group: "Media and info",
          minW: 1, minH: 2, defW: 2, defH: 4, options: [] },
        { id: "levels", label: "Volume and brightness", icon: "tune", group: "Controls",
          minW: 1, minH: 2, defW: 1, defH: 3, options: [] },
        { id: "gauges", label: "Gauges", icon: "speed", group: "System",
          minW: 1, minH: 2, defW: 1, defH: 2,
          options: [{ key: "face", label: "Style", type: "grid", default: "dial",
                      choices: [{ value: "dial", label: "Tick dial", icon: "speed" },
                                { value: "rings", label: "Rings", icon: "radio_button_checked" },
                                { value: "cookie", label: "Cookie", icon: "cookie" },
                                { value: "liquid", label: "Liquid", icon: "water_drop" },
                                { value: "speedo", label: "Speedo", icon: "avg_pace" },
                                { value: "orbit", label: "Orbit", icon: "orbit" },
                                { value: "radial", label: "Radial history", icon: "sunny" },
                                { value: "segring", label: "Segments", icon: "donut_large" }] },
                    { key: "metrics", label: "Meters", type: "buttons", catalog: root.metricCatalog,
                      default: root.metricDefault }] },
        { id: "stat", label: "Stat", icon: "monitoring", group: "System",
          minW: 1, minH: 2, defW: 1, defH: 2,
          options: [{ key: "face", label: "Style", type: "grid", default: "heat",
                      choices: [{ value: "heat", label: "Heat strip", icon: "view_column" },
                                { value: "splittrack", label: "Split track", icon: "linear_scale" },
                                { value: "capsules", label: "Capsules", icon: "view_week" },
                                { value: "stacked", label: "Stacked", icon: "stacked_bar_chart" },
                                { value: "columns", label: "Columns", icon: "bar_chart" },
                                { value: "ruler", label: "Ruler", icon: "straighten" },
                                { value: "dots", label: "Dot matrix", icon: "grid_on" },
                                { value: "thumb", label: "Thumb", icon: "toggle_on" },
                                { value: "mirror", label: "Mirror (network)", icon: "compare_arrows" },
                                { value: "labelbar", label: "Label pill", icon: "battery_horiz_050" }] },
                    { key: "metric", label: "Shows", type: "choice", default: "cpu",
                      choices: [{ value: "cpu", label: "CPU" }, { value: "gpu", label: "GPU" },
                                { value: "ram", label: "RAM" }, { value: "temp", label: "Temp" },
                                { value: "disk", label: "Disk" }, { value: "net", label: "Net" }] }] },
        { id: "network", label: "Network", icon: "network_check", group: "System",
          minW: 2, minH: 2, defW: 3, defH: 2, options: [] },
        { id: "battery", label: "Battery", icon: "battery_full", group: "System",
          minW: 1, minH: 2, defW: 1, defH: 2,
          options: [{ key: "face", label: "Style", type: "grid", default: "liquid",
                      choices: [{ value: "liquid", label: "Liquid", icon: "water_drop" },
                                { value: "cookie", label: "Cookie", icon: "cookie" },
                                { value: "orbit", label: "Orbit", icon: "orbit" },
                                { value: "dial", label: "Tick dial", icon: "speed" },
                                { value: "segring", label: "Segments", icon: "donut_large" }] }] },
        { id: "devices", label: "Device batteries", icon: "devices", group: "System",
          minW: 1, minH: 2, defW: 2, defH: 2, options: [] },
        { id: "claude", label: "Claude Code", icon: "terminal", group: "System",
          minW: 2, minH: 2, defW: 2, defH: 3, options: [] }
    ]

    readonly property var backgroundOption: ({ key: "background", label: "Background", type: "toggle", default: true,
                                               sub: "Card behind the item" })

    readonly property var descs: ({
        clock: "Time in three faces", month: "Calendar with event dots", nextUp: "Your upcoming events",
        timeline: "Today, hour by hour", player: "What's playing, with controls", weather: "Now, next hours, 3 days",
        inbox: "Recent notifications", tiles: "Wi-Fi, Bluetooth, focus and more", slider: "Volume, brightness or mic",
        levels: "Two vertical sliders", power: "Saver, balanced, performance", toggle: "One switch, placed anywhere", gauges: "CPU, GPU, RAM, temperature",
        stat: "One number with its history", network: "Speed over time", processes: "What's using the CPU",
        storage: "Drives and free space", battery: "Charge and time left", devices: "Laptop, earbuds, phone",
        claude: "Tokens today and this week", profile: "Avatar, uptime, power", notifications: "The full notification centre"
    })

    function describe(kind) {
        return root.descs[kind] ?? ""
    }

    readonly property var lookKeys: ["face", "style", "color", "background", "showLabel", "showValue"]
    readonly property var sizeKeys: ["columns"]

    function tabOf(key) {
        return root.lookKeys.indexOf(key) >= 0 ? "look" : root.sizeKeys.indexOf(key) >= 0 ? "size" : "content"
    }

    function optionsIn(id, tab) {
        const e = root.entry(id)
        const all = e && e.options ? e.options : []
        return all.filter(o => o.type !== "heading" && root.tabOf(o.key) === tab)
    }

    function lookPicks(id) {
        return root.optionsIn(id, "look").filter(o => o.type === "choice" && o.choices)
    }

    function splitToggles(id) {
        const it = root.items.find(i => i.id === id)
        if (!it || (it.kind !== "tiles" && it.kind !== "bubbles"))
            return
        const which = root.listFor(id, "items", root.tileCatalog, it.kind === "bubbles" ? root.bubbleDefault : root.tileDefault)
        let list = root.items.filter(i => i.id !== id)
        const opts = Object.assign({}, root.sectionOptions)
        const cols = Math.max(1, Math.min(it.w, root.columns))
        which.forEach((w, n) => {
            const nid = DashGrid.newId("toggle", list)
            const x = it.x + (n % cols)
            const y = it.y + Math.floor(n / cols)
            const spot = DashGrid.push(list, { id: nid, kind: "toggle", x: x, y: y, w: 1, h: 1 }, root.columns)
            list = spot
            opts[nid] = { which: w }
        })
        root._patch({ options: opts })
        root._commit(list, root.labelOf(id) + " split")
    }

    function duplicateItem(id) {
        const it = root.items.find(i => i.id === id)
        const e = root.entry(id)
        if (!it || !e || e.legacy)
            return ""
        const nid = DashGrid.newId(it.kind, root.items)
        const spot = DashGrid.firstFree(root.items, it.w, it.h, root.columns)
        const own = root.sectionOptions[id]
        if (own) {
            const next = Object.assign({}, root.sectionOptions)
            next[nid] = JSON.parse(JSON.stringify(own))
            root._patch({ options: next })
        }
        root._commit(root.items.concat([{ id: nid, kind: it.kind, x: spot.x, y: spot.y, w: spot.w, h: it.h }]), e.label + " duplicated")
        return nid
    }

    readonly property var catalog: root.baseCatalog.map(e => e.legacy || e.noBackground ? e
        : Object.assign({}, e, { options: e.options.concat([root.backgroundOption]) }))

    function styleOption(kind) {
        return { key: "style", label: "Style", type: "choice", default: kind === "bubbles" ? "buttons" : "tiles",
                 choices: [{ value: "tiles", label: "Tiles", icon: "toggle_on" },
                           { value: "buttons", label: "Round buttons", icon: "radio_button_checked" }] }
    }

    function setKind(id, kind) {
        const list = root.items.map(i => i.id === id ? Object.assign({}, i, { kind: kind }) : i)
        root._commit(list, root.labelOf(id) + " changed")
    }

    readonly property var ids: root.catalog.map(e => e.id)

    readonly property var cfg: SettingsConfig.dashboard ?? ({})

    function kindEntry(kind) {
        return root.catalog.find(e => e.id === kind) ?? null
    }

    function entry(id) {
        const it = root.items.find(i => i.id === id)
        return root.kindEntry(it ? it.kind : id)
    }

    function kindOf(id) {
        const it = root.items.find(i => i.id === id)
        return it ? it.kind : id
    }

    function spanSpec(kind) {
        const e = root.kindEntry(kind)
        return e ? { minW: e.minW, minH: e.minH, maxW: e.maxW, maxH: e.maxH } : null
    }

    function _list(v) {
        return (v !== undefined && v !== null && typeof v.length === "number")
            ? Array.prototype.slice.call(v) : undefined
    }

    readonly property var defaultItems: [
        { id: "profile", kind: "profile", x: 0, y: 0, w: 4, h: 1 },
        { id: "clock",   kind: "clock",   x: 0, y: 1, w: 2, h: 2 },
        { id: "weather", kind: "weather", x: 2, y: 1, w: 2, h: 2 },
        { id: "tiles",   kind: "tiles",   x: 0, y: 3, w: 2, h: 3 },
        { id: "player",  kind: "player",  x: 2, y: 3, w: 2, h: 3 },
        { id: "slider",  kind: "slider",  x: 0, y: 6, w: 4, h: 1 },
        { id: "month",   kind: "month",   x: 0, y: 7, w: 2, h: 4 },
        { id: "nextUp",  kind: "nextUp",  x: 2, y: 7, w: 2, h: 4 }
    ]

    readonly property int gap: 10
    readonly property bool fitRows: root.cfg.fitRows !== false

    function setFitRows(on) {
        root._patch({ fitRows: on === true })
    }

    readonly property int rowHeight: Math.max(32, Math.min(160, Number(root.cfg.rowHeight ?? 56) || 56))
    readonly property int columns: Math.max(1, Math.min(12, Number(root.cfg.gridColumns ?? 0) || root.autoColumns))
    readonly property int autoColumns: Math.max(1, Math.min(8, Math.round(BarLayout.panelW("dashboard") / 150)))

    function _seed() {
        return root.defaultItems.map(i => Object.assign({}, i))
    }

    readonly property var items: {
        const saved = root._list(root.cfg.items)
        const raw = saved ? saved.map(i => i && i.kind ? Object.assign({}, i, { kind: root.migrate(i.kind) }) : i)
                                 .filter(i => i && root.kindEntry(i.kind)).map(i => Object.assign({}, i))
                          : root._seed()
        return DashGrid.normalize(raw, root.columns, k => root.spanSpec(k))
    }
    readonly property var itemIds: root.items.map(i => i.id)
    readonly property int rowsUsed: DashGrid.rowsUsed(root.items)

    function _patch(o) {
        SettingsConfig.dashboard = Object.assign({}, SettingsConfig.dashboard ?? {}, o)
    }

    function _saveItems(list) {
        root._patch({ items: list.map(i => ({ id: i.id, kind: i.kind, x: i.x, y: i.y, w: i.w, h: i.h })),
                      gridColumns: root.columns })
    }

    function canAdd(kind) {
        const e = root.kindEntry(kind)
        return !!e && (!e.legacy || root.itemIds.indexOf(kind) < 0)
    }

    function place(kind) {
        const e = root.kindEntry(kind)
        if (!root.canAdd(kind))
            return ""
        const w = Math.min(root.columns, e.defW ?? 2)
        const h = e.defH ?? 2
        const spot = DashGrid.firstFree(root.items, w, h, root.columns)
        const id = e.legacy ? kind : DashGrid.newId(kind, root.items)
        root._commit(root.items.concat([{ id: id, kind: kind, x: spot.x, y: spot.y, w: spot.w, h: h }]), e.label + " added")
        return id
    }

    function dropItem(id) {
        root._commit(root.items.filter(i => i.id !== id), root.labelOf(id) + " removed")
    }

    property Item activeDash: null
    property var undoItems: null
    property string undoLabel: ""

    function _commit(list, label) {
        root.undoItems = root.items.map(i => Object.assign({}, i))
        root.undoLabel = label
        root._saveItems(DashGrid.settle(list))
    }

    function undo() {
        if (!root.undoItems)
            return
        const back = root.undoItems
        root.undoItems = null
        root.undoLabel = ""
        root._saveItems(back)
    }

    function labelOf(id) {
        const e = root.entry(id)
        return e ? e.label : id
    }

    function previewPush(id, x, y, w, h, kind) {
        const it = root.items.find(i => i.id === id)
        const k = it ? it.kind : kind
        const sp = root.spanSpec(k) ?? {}
        const ww = Math.max(Math.min(root.columns, sp.minW ?? 1), Math.min(w, sp.maxW ?? root.columns, root.columns))
        const hh = Math.max(sp.minH ?? 1, Math.min(h, sp.maxH ?? 99))
        return DashGrid.push(root.items, { id: id, kind: k, x: x, y: y, w: ww, h: hh }, root.columns)
    }

    function commitPreview(list, id, verb) {
        root._commit(list, root.labelOf(id) + " " + verb)
    }

    function dropNew(kind, x, y) {
        const e = root.kindEntry(kind)
        if (!root.canAdd(kind))
            return ""
        const id = e.legacy ? kind : DashGrid.newId(kind, root.items)
        const list = DashGrid.push(root.items, { id: id, kind: kind, x: x, y: y,
                                                 w: Math.min(root.columns, e.defW ?? 2), h: e.defH ?? 2 }, root.columns)
        root._commit(list, e.label + " added")
        return id
    }

    function moveItem(id, x, y) {
        const it = root.items.find(i => i.id === id)
        if (it)
            root._commit(root.previewPush(id, x, y, it.w, it.h), root.labelOf(id) + " moved")
    }

    function resizeItem(id, w, h) {
        const it = root.items.find(i => i.id === id)
        if (it)
            root._commit(root.previewPush(id, it.x, it.y, w, h), root.labelOf(id) + " resized")
    }

    function setColumns(n) {
        const cols = Math.max(1, Math.min(12, Number(n) || 1))
        const list = DashGrid.normalize(root.items, cols, k => root.spanSpec(k))
        root._patch({ gridColumns: cols,
                      items: list.map(i => ({ id: i.id, kind: i.kind, x: i.x, y: i.y, w: i.w, h: i.h })) })
    }

    function setRowHeight(px) {
        root._patch({ rowHeight: Math.round(Number(px) || 56) })
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

    readonly property var sectionOptions: root.cfg.options ?? ({})

    function listFor(id, key, catalog, def) {
        const own = root.sectionOptions[id]
        const saved = root._list(own ? own[key] : undefined)
        return (saved ?? def).filter(x => catalog.some(e => e.id === x))
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
        const k = root.kindOf(id)
        if (key === "style" && (k === "tiles" || k === "bubbles")) {
            root.setKind(id, value === "buttons" ? "bubbles" : "tiles")
            return
        }
        const next = Object.assign({}, root.sectionOptions)
        const own = Object.assign({}, next[id] ?? {})
        own[key] = value
        next[id] = own
        root._patch({ options: next })
    }

    function reset() {
        root._patch({ options: ({}), cards: false, items: undefined, gridColumns: undefined, rowHeight: undefined })
    }

    IpcHandler {
        target: "dash"
        function state(): string {
            return JSON.stringify({ columns: root.columns, rowHeight: root.rowHeight, items: root.items,
                                    options: root.sectionOptions })
        }
        function reset(): void { root.reset() }
        function add(kind: string): string { return root.place(kind) }
        function remove(id: string): void { root.dropItem(id) }
        function undo(): void { root.undo() }
        function move(id: string, x: int, y: int): void { root.moveItem(id, x, y) }
        function resize(id: string, w: int, h: int): void { root.resizeItem(id, w, h) }
        function columns(n: int): void { root.setColumns(n) }
        function rows(px: int): void { root.setRowHeight(px) }
        function set(id: string, key: string, value: string): void {
            let v = value
            try { v = JSON.parse(value) } catch (e) {}
            root.setOption(id, key, v)
        }
    }
}
