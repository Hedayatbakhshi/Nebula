pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.settings

Singleton {
    id: root

    readonly property string cli: Quickshell.shellDir + "/bin/nebula"

    readonly property var urls: {
        const opts = SettingsConfig.dashboard?.options ?? {}
        const seen = []
        for (const k in opts) {
            const raw = opts[k] ? opts[k].calendars : undefined
            if (typeof raw !== "string")
                continue
            for (const u of raw.split(/[\s,]+/))
                if (/^(https?|webcal):\/\//.test(u) && seen.indexOf(u) < 0)
                    seen.push(u)
        }
        return seen
    }

    property var events: []
    property bool loading: false
    property int _users: 0
    property var now: new Date()

    function retain() {
        if (root._users++ === 0)
            root.refresh()
    }

    function release() {
        if (root._users > 0)
            root._users--
    }

    function refresh() {
        if (root.urls.length === 0) {
            root.events = []
            return
        }
        if (proc.running)
            return
        root.loading = true
        proc.command = [root.cli, "events"].concat(root.urls)
        proc.running = true
    }

    onUrlsChanged: if (root._users > 0) root.refresh()

    function startMs(e) {
        return e.allDay ? new Date(e.start + "T00:00:00").getTime() : e.start
    }

    function endMs(e) {
        return e.allDay ? new Date(e.end + "T00:00:00").getTime() : e.end
    }

    function holidayEvents(fromMs, toMs) {
        const out = []
        const list = ServiceClock.holidayData ?? []
        for (const h of list) {
            const t = new Date(h.date + "T00:00:00").getTime()
            if (t + 86400000 > fromMs && t < toMs)
                out.push({ title: h.name, allDay: true, holiday: true, calendar: -1,
                           start: h.date, end: Qt.formatDate(new Date(t + 86400000), "yyyy-MM-dd"), location: "" })
        }
        return out
    }

    function between(fromMs, toMs, holidays) {
        const own = root.events.filter(e => root.endMs(e) > fromMs && root.startMs(e) < toMs)
        const all = holidays ? own.concat(root.holidayEvents(fromMs, toMs)) : own
        return all.sort((a, b) => root.startMs(a) - root.startMs(b))
    }

    function upcoming(count, holidays) {
        const t = root.now.getTime()
        return root.between(t, t + 60 * 86400000, holidays).slice(0, count)
    }

    function today() {
        const d = new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate())
        return root.between(d.getTime(), d.getTime() + 86400000, false)
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false
                try {
                    const parsed = JSON.parse(text)
                    if (Array.isArray(parsed))
                        root.events = parsed
                } catch (e) {}
            }
        }
        onExited: root.loading = false
    }

    Timer {
        interval: 15 * 60000
        repeat: true
        running: root._users > 0
        onTriggered: root.refresh()
    }

    Timer {
        interval: 30000
        repeat: true
        running: root._users > 0
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
}
