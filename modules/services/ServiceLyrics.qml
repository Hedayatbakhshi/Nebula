pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int _users: 0
    property var lines: []
    property string status: "idle"
    property var _cache: ({})

    readonly property string title: ServiceMusic.activePlayer ? (ServiceMusic.activeTrack?.title ?? "") : ""
    readonly property string artist: ServiceMusic.activePlayer ? (ServiceMusic.activeTrack?.artist ?? "") : ""
    readonly property string key: root.title + "|" + root.artist

    onKeyChanged: if (root._users > 0) debounce.restart()

    function retain() {
        root._users++
        if (root._users === 1)
            debounce.restart()
    }

    function release() {
        if (root._users > 0)
            root._users--
    }

    function indexAt(seconds) {
        const l = root.lines
        let lo = 0, hi = l.length - 1, best = -1
        while (lo <= hi) {
            const mid = (lo + hi) >> 1
            if (l[mid].t <= seconds) {
                best = mid
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }
        return best
    }

    function parse(text) {
        const out = []
        for (const raw of String(text).split("\n")) {
            const m = raw.match(/^\s*\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$/)
            if (!m)
                continue
            out.push({ t: parseInt(m[1]) * 60 + parseFloat(m[2]), text: m[3].trim() })
        }
        return out.filter((l, i) => l.text !== "" || i === 0)
    }

    function fetch() {
        const k = root.key
        if (root.title === "" || root.title === "Unknown Title") {
            root.lines = []
            root.status = "none"
            return
        }
        if (root._cache[k] !== undefined) {
            root.lines = root._cache[k]
            root.status = root.lines.length > 0 ? "ok" : "none"
            return
        }
        root.status = "loading"
        root.lines = []
        proc.forKey = k
        const cmd = ["curl", "-sf", "-m", "8", "-G", "https://lrclib.net/api/search",
                     "--data-urlencode", "track_name=" + root.title]
        if (root.artist !== "" && root.artist !== "Unknown Artist")
            cmd.push("--data-urlencode", "artist_name=" + root.artist)
        proc.command = cmd
        proc.running = true
    }

    Timer {
        id: debounce
        interval: 700
        onTriggered: root.fetch()
    }

    Process {
        id: proc
        property string forKey: ""
        stdout: StdioCollector { id: out }
        onExited: {
            let parsed = []
            try {
                const list = JSON.parse(out.text)
                const hit = (Array.isArray(list) ? list : []).find(e => e.syncedLyrics)
                if (hit)
                    parsed = root.parse(hit.syncedLyrics)
            } catch (e) {
                parsed = []
            }
            const cache = Object.assign({}, root._cache)
            cache[proc.forKey] = parsed
            root._cache = cache
            if (proc.forKey === root.key) {
                root.lines = parsed
                root.status = parsed.length > 0 ? "ok" : "none"
            }
        }
    }
}
