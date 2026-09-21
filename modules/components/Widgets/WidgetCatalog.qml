pragma Singleton

import Quickshell
import QtQuick
import qs.modules.settings

Singleton {
    id: root

    readonly property Component cProfileCard:   Component { ProfileCard            { preview: true } }
    readonly property Component cProfileTile:   Component { ProfileTile            { preview: true } }
    readonly property Component cPhotoFrame:    Component { PhotoFrameWidget       { preview: true } }
    readonly property Component cClockVeil:      Component { ClockVeil      { preview: true } }
    readonly property Component cClockBloom:     Component { ClockBloom     { preview: true } }
    readonly property Component cClockOrbit:     Component { ClockOrbit     { preview: true } }
    readonly property Component cClockScript:    Component { ClockScript    { preview: true } }
    readonly property Component cClockStack:     Component { ClockStack     { preview: true } }
    readonly property Component cClockCondensed: Component { ClockCondensed { preview: true } }
    readonly property Component cMusicCircle:   Component { CircularMusicPlayer    { preview: true } }
    readonly property Component cMusicStrip:    Component { MusicStripWidget       { preview: true } }
    readonly property Component cCassette:      Component { CassetteWidget         { preview: true } }
    readonly property Component cVinyl:         Component { VinylWidget            { preview: true } }
    readonly property Component cAlbumShape:    Component { AlbumShapeWidget       { preview: true } }
    readonly property Component cAnalogClassic: Component { AnalogClockClassic     { preview: true } }
    readonly property Component cAnalogMinimal: Component { AnalogClockMinimal     { preview: true } }
    readonly property Component cAnalogShape:   Component { AnalogClockShape       { preview: true } }
    readonly property Component cDateDefault:   Component { DateWidget             { preview: true } }
    readonly property Component cDateCalendar:  Component { DateWidgetCalendar     { preview: true } }
    readonly property Component cDatePill:      Component { DateWidgetPill         { preview: true } }
    readonly property Component cDateSplit:     Component { DateWidgetSplit        { preview: true } }
    readonly property Component cDateBold:      Component { DateWidgetBold         { preview: true } }
    readonly property Component cDateGhost:     Component { DateWidgetGhost        { preview: true } }
    readonly property Component cDateAccent:    Component { DateWidgetAccent       { preview: true } }
    readonly property Component cDateInline:    Component { DateWidgetInline       { preview: true } }
    readonly property Component cDateShape:     Component { DateWidgetShape        { preview: true } }
    readonly property Component cWeatherSlant:  Component { WeatherWidgetSlanted   { preview: true } }
    readonly property Component cWeatherCast:   Component { WeatherWidgetForecast  { preview: true } }
    readonly property Component cWeatherDetail: Component { WeatherWidgetDetails   { preview: true } }
    readonly property Component cWeatherHourly: Component { WeatherHourlyWidget    { preview: true } }
    readonly property Component cWeatherWind:   Component { WeatherWindWidget      { preview: true } }
    readonly property Component cWeatherBaro:   Component { WeatherBarometerWidget { preview: true } }
    readonly property Component cSunArc:        Component { SunArcWidget           { preview: true } }
    readonly property Component cMoonPhase:     Component { MoonPhaseWidget        { preview: true } }
    readonly property Component cWeatherShape:  Component { WeatherShapeWidget     { preview: true } }
    readonly property Component cJpDay:         Component { JpDayWidget            { preview: true } }
    readonly property Component cJpClock:       Component { JpClockWidget          { preview: true } }
    readonly property Component cJpHaiku:       Component { JpHaikuWidget          { preview: true } }
    readonly property Component cJpWeather:     Component { JpWeatherWidget        { preview: true } }
    readonly property Component cJpKanji:       Component { JpKanjiWidget          { preview: true } }
    readonly property Component cJpSeal:        Component { JpSealWidget           { preview: true } }
    readonly property Component cClaudeCode:    Component { ClaudeCodeWidget       { preview: true } }
    readonly property Component cTaskList:      Component { TaskListWidget         { preview: true } }
    readonly property Component cStickyNote:    Component { StickyNoteWidget       { preview: true } }
    readonly property Component cPomodoro:      Component { PomodoroWidget         { preview: true } }
    readonly property Component cWorldClock:    Component { WorldClockWidget       { preview: true } }
    readonly property Component cHeadlines:     Component { HeadlinesWidget        { preview: true } }
    readonly property Component cSysDefault:    Component { SystemMonitorWidget    { preview: true } }
    readonly property Component cSysCompact:    Component { SystemMonitorCompact   { preview: true } }
    readonly property Component cSysPulse:      Component { SystemMonitorPulse     { preview: true } }
    readonly property Component cBattDefault:   Component { BatteryWidget          { preview: true } }
    readonly property Component cBattMinimal:   Component { BatteryWidgetMinimal   { preview: true } }
    readonly property Component cBattRing:      Component { BatteryWidgetRing      { preview: true } }
    readonly property Component cBattShape:     Component { BatteryWidgetShape     { preview: true } }
    readonly property Component cStatStack:    Component { StatStackWidget        { preview: true } }
    readonly property Component cNetGraph:      Component { NetworkGraphWidget     { preview: true } }
    readonly property Component cVpn:           Component { VpnWidget              { preview: true } }

    // show      — the SettingsConfig.widgets key that turns the family on
    // styleKey  — the key holding which variant is active (omitted if only one)
    // style     — this card's variant value
    // def       — the family's default variant, for the ?? fallback
    readonly property var catalog: [
        { section: "Personal", items: [
            { label: "Card", key: "profileCard", comp: root.cProfileCard, show: "showProfileCard", styleKey: "profileCardStyle", style: "card", def: "card" },
            { label: "Tile", key: "profileCard", comp: root.cProfileTile, show: "showProfileCard", styleKey: "profileCardStyle", style: "tile", def: "card" },
            { label: "Photo Frame", key: "photoFrame", comp: root.cPhotoFrame, show: "showPhotoFrame" }
        ]},
        { section: "Music", items: [
            { label: "Circular Player", key: "musicPlayer", comp: root.cMusicCircle, show: "showCircularMusicPlayer" },
            { label: "Now Playing",     key: "musicStrip",  comp: root.cMusicStrip,  show: "showMusicStrip" },
            { label: "Cassette",        key: "cassette",    comp: root.cCassette,    show: "showCassette" },
            { label: "Vinyl",           key: "vinyl",       comp: root.cVinyl,       show: "showVinyl" },
            { label: "Art Shape",       key: "albumShape",  comp: root.cAlbumShape,  show: "showAlbumShape" }
        ]},
        { section: "Digital Clock", items: [
            { label: "Veil",      key: "clock", comp: root.cClockVeil,      show: "showClock", styleKey: "digitalClockStyle", style: "veil",      def: "veil" },
            { label: "Bloom",     key: "clock", comp: root.cClockBloom,     show: "showClock", styleKey: "digitalClockStyle", style: "bloom",     def: "veil" },
            { label: "Orbit",     key: "clock", comp: root.cClockOrbit,     show: "showClock", styleKey: "digitalClockStyle", style: "orbit",     def: "veil" },
            { label: "Script",    key: "clock", comp: root.cClockScript,    show: "showClock", styleKey: "digitalClockStyle", style: "script",    def: "veil" },
            { label: "Stack",     key: "clock", comp: root.cClockStack,     show: "showClock", styleKey: "digitalClockStyle", style: "stack",     def: "veil" },
            { label: "Condensed", key: "clock", comp: root.cClockCondensed, show: "showClock", styleKey: "digitalClockStyle", style: "condensed", def: "veil" }
        ]},
        { section: "Analog Clock", items: [
            { label: "Classic", key: "analogClock", comp: root.cAnalogClassic, show: "showAnalogClock", styleKey: "analogClockStyle", style: "classic", def: "classic" },
            { label: "Minimal", key: "analogClock", comp: root.cAnalogMinimal, show: "showAnalogClock", styleKey: "analogClockStyle", style: "minimal", def: "classic" },
            { label: "Shape",   key: "analogClock", comp: root.cAnalogShape,   show: "showAnalogClock", styleKey: "analogClockStyle", style: "shape",   def: "classic" }
        ]},
        { section: "Date", items: [
            { label: "Default",  key: "dateWidget", comp: root.cDateDefault,  show: "showDateWidget", styleKey: "dateWidgetStyle", style: "default",  def: "default" },
            { label: "Calendar", key: "dateWidget", comp: root.cDateCalendar, show: "showDateWidget", styleKey: "dateWidgetStyle", style: "calendar", def: "default" },
            { label: "Pill",     key: "dateWidget", comp: root.cDatePill,     show: "showDateWidget", styleKey: "dateWidgetStyle", style: "pill",     def: "default" },
            { label: "Split",    key: "dateWidget", comp: root.cDateSplit,    show: "showDateWidget", styleKey: "dateWidgetStyle", style: "split",    def: "default" },
            { label: "Bold",     key: "dateWidget", comp: root.cDateBold,     show: "showDateWidget", styleKey: "dateWidgetStyle", style: "bold",     def: "default" },
            { label: "Ghost",    key: "dateWidget", comp: root.cDateGhost,    show: "showDateWidget", styleKey: "dateWidgetStyle", style: "ghost",    def: "default" },
            { label: "Accent",   key: "dateWidget", comp: root.cDateAccent,   show: "showDateWidget", styleKey: "dateWidgetStyle", style: "accent",   def: "default" },
            { label: "Inline",   key: "dateWidget", comp: root.cDateInline,   show: "showDateWidget", styleKey: "dateWidgetStyle", style: "inline",   def: "default" },
            { label: "Shape",    key: "dateWidget", comp: root.cDateShape,    show: "showDateWidget", styleKey: "dateWidgetStyle", style: "shape",    def: "default" }
        ]},
        { section: "Weather", items: [
            { label: "Slanted",  key: "weatherSlanted",   comp: root.cWeatherSlant,  show: "showWeatherSlanted" },
            { label: "Forecast", key: "weatherForecast",  comp: root.cWeatherCast,   show: "showWeatherForecast" },
            { label: "Details",  key: "weatherDetails",   comp: root.cWeatherDetail, show: "showWeatherDetails" },
            { label: "Hourly",   key: "weatherHourly",    comp: root.cWeatherHourly, show: "showWeatherHourly" },
            { label: "Wind",     key: "weatherWind",      comp: root.cWeatherWind,   show: "showWeatherWind" },
            { label: "Pressure", key: "weatherBarometer", comp: root.cWeatherBaro,   show: "showWeatherBarometer" },
            { label: "Sun Arc",  key: "sunArc",           comp: root.cSunArc,        show: "showSunArc" },
            { label: "Moon",     key: "moonPhase",        comp: root.cMoonPhase,     show: "showMoonPhase" },
            { label: "Shape",    key: "weatherShape",     comp: root.cWeatherShape,  show: "showWeatherShape" }
        ]},
        { section: "Japanese", items: [
            { label: "暦 Day",    key: "jpDay",     comp: root.cJpDay,     show: "showJpDay" },
            { label: "縦 Clock",  key: "jpClock",   comp: root.cJpClock,   show: "showJpClock" },
            { label: "俳句 Haiku", key: "jpHaiku",   comp: root.cJpHaiku,   show: "showJpHaiku" },
            { label: "天気 Tenki", key: "jpWeather", comp: root.cJpWeather, show: "showJpWeather" },
            { label: "漢字 Kanji", key: "jpKanji",   comp: root.cJpKanji,   show: "showJpKanji" },
            { label: "印 Seal",   key: "jpSeal",    comp: root.cJpSeal,    show: "showJpSeal" }
        ]},
        { section: "Productivity", items: [
            { label: "Claude Code", key: "claudeCode", comp: root.cClaudeCode, show: "showClaudeCode" },
            { label: "Tasks",       key: "taskList",   comp: root.cTaskList,   show: "showTaskList" },
            { label: "Note",        key: "stickyNote", comp: root.cStickyNote, show: "showStickyNote" },
            { label: "Pomodoro",    key: "pomodoro",   comp: root.cPomodoro,   show: "showPomodoro" },
            { label: "World Clock", key: "worldClock", comp: root.cWorldClock, show: "showWorldClock" }
        ]},
        { section: "News", items: [
            { label: "Headlines", key: "headlines", comp: root.cHeadlines, show: "showHeadlines" }
        ]},
        { section: "System", items: [
            { label: "Monitor",    key: "sysMonitor",   comp: root.cSysDefault,  show: "showSystemMonitor", styleKey: "systemMonitorStyle", style: "default", def: "default" },
            { label: "Compact",    key: "sysMonitor",   comp: root.cSysCompact,  show: "showSystemMonitor", styleKey: "systemMonitorStyle", style: "compact", def: "default" },
            { label: "Pulse",      key: "sysMonitor",   comp: root.cSysPulse,    show: "showSystemMonitor", styleKey: "systemMonitorStyle", style: "pulse",   def: "default" },
            { label: "Battery",    key: "battery",      comp: root.cBattDefault, show: "showBattery", styleKey: "batteryStyle", style: "default", def: "default" },
            { label: "Bar",        key: "battery",      comp: root.cBattMinimal, show: "showBattery", styleKey: "batteryStyle", style: "minimal", def: "default" },
            { label: "Ring",       key: "battery",      comp: root.cBattRing,    show: "showBattery", styleKey: "batteryStyle", style: "ring",    def: "default" },
            { label: "Shape",      key: "battery",      comp: root.cBattShape,   show: "showBattery", styleKey: "batteryStyle", style: "shape",   def: "default" },
            { label: "Stat Stack", key: "statStack",    comp: root.cStatStack,   show: "showStatStack" },
            { label: "Network",    key: "networkGraph", comp: root.cNetGraph,    show: "showNetworkGraph" },
            { label: "VPN",        key: "vpn",          comp: root.cVpn,         show: "showVpn" }
        ]}
    ]

    function familyFor(key) {
        for (let s = 0; s < root.catalog.length; s++) {
            const items = root.catalog[s].items.filter(i => i.key === key)
            if (items.length > 0) return { section: root.catalog[s].section, items: items }
        }
        return null
    }

    readonly property var _legacyStyles: ({
        "digitalClockStyle": { "shapes": "bloom", "stacked": "stack" }
    })

    function styleValue(item) {
        const raw = SettingsConfig.widgets[item.styleKey] ?? item.def
        const map = root._legacyStyles[item.styleKey]
        if (!map)
            return raw
        if (map[raw] !== undefined)
            return map[raw]
        const known = root.catalog.some(sec => sec.items.some(i => i.styleKey === item.styleKey && i.style === raw))
        return known ? raw : item.def
    }

    function isActive(item) {
        if (!(SettingsConfig.widgets[item.show] ?? false)) return false
        if (!item.styleKey) return true
        return root.styleValue(item) === item.style
    }

    function selectStyle(item) {
        const patch = {}
        patch[item.show] = true
        if (item.styleKey) patch[item.styleKey] = item.style
        SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets, patch)
    }

    function remove(key) {
        const family = root.familyFor(key)
        if (!family) return
        const patch = {}
        patch[family.items[0].show] = false
        SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets, patch)
    }

    function resetLayout(key) {
        const next = Object.assign({}, SettingsConfig.widgets)
        delete next[key + "X"]
        delete next[key + "Y"]
        delete next[key + "W"]
        delete next[key + "H"]
        SettingsConfig.widgets = next
    }
}
