pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property int count: 120
    property var captured: []
    property int _users: 0

    readonly property real total: ServiceMusic.trackLength
    readonly property string key: (ServiceMusic.activeTrack?.title ?? "") + "|" + (ServiceMusic.activeTrack?.artist ?? "")

    onKeyChanged: root.reset()
    Component.onCompleted: root.reset()

    function retain() {
        root._users++
        if (root._users === 1)
            ServiceCava.retain()
    }

    function release() {
        if (root._users === 0)
            return
        root._users--
        if (root._users === 0)
            ServiceCava.release()
    }

    function reset() {
        const a = []
        for (let i = 0; i < root.count; i++)
            a.push(-1)
        root.captured = a
    }

    readonly property var seed: {
        let h = 2166136261
        for (let i = 0; i < root.key.length; i++) {
            h ^= root.key.charCodeAt(i)
            h = Math.imul(h, 16777619) >>> 0
        }
        const a = (h % 97) / 9, b = (h % 31) / 5, c = (h % 13) / 3
        const out = []
        for (let i = 0; i < root.count; i++) {
            const v = 0.5 + 0.28 * Math.sin(i * 0.23 + a) + 0.16 * Math.sin(i * 0.071 + b) + 0.1 * Math.sin(i * 0.61 + c)
            out.push(Math.max(0.14, Math.min(1, v)))
        }
        return out
    }

    function sample() {
        const d = ServiceCava.cavaData
        if (!d || d.length === 0 || root.total <= 0)
            return
        let s = 0
        for (let i = 0; i < d.length; i++)
            s += d[i]
        const level = Math.max(0.08, Math.min(1, (s / d.length) * 1.8))
        const pos = ServiceMusic.activePlayer?.position ?? 0
        const idx = Math.floor(Math.max(0, Math.min(0.9999, pos / root.total)) * root.count)
        const prev = root.captured[idx] ?? -1
        if (prev >= level)
            return
        const next = root.captured.slice()
        next[idx] = level
        root.captured = next
    }

    function cell(i, bars) {
        const lo = Math.floor(i * root.count / bars)
        const hi = Math.max(lo + 1, Math.floor((i + 1) * root.count / bars))
        let best = -1, seedMax = 0
        for (let k = lo; k < hi && k < root.count; k++) {
            best = Math.max(best, root.captured[k] ?? -1)
            seedMax = Math.max(seedMax, root.seed[k] ?? 0)
        }
        return best >= 0 ? { v: best, real: true } : { v: seedMax * 0.55, real: false }
    }

    Timer {
        interval: 250
        repeat: true
        running: root._users > 0 && ServiceMusic.isPlaying && root.total > 0
        onTriggered: root.sample()
    }
}
