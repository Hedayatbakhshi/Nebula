pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real micLevel: 0
    property real systemLevel: 0

    property bool wantMic: false
    property bool wantSystem: false

    property int _refCount: 0

    readonly property bool micActive: root._refCount > 0 && root.wantMic
    readonly property bool systemActive: root._refCount > 0 && root.wantSystem

    function retain() { root._refCount++ }

    function release() {
        if (root._refCount > 0) root._refCount--
        if (root._refCount === 0) {
            root.micLevel = 0
            root.systemLevel = 0
        }
    }

    function _config(sourceExpr) {
        return `SRC=` + sourceExpr + `
cava -p /dev/stdin <<CAVAEOF
[general]
bars = 6
framerate = 20
autosens = 1

[input]
method = pulse
source = $SRC

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59

[smoothing]
monstercat = 1.2
waves = 0
gravity = 120
noise_reduction = 0.25
CAVAEOF
`
    }

    function _peak(data) {
        const points = String(data).split(";")
            .map(p => parseFloat(p.trim()) / 100)
            .filter(p => !isNaN(p))
        if (points.length === 0) return -1
        return Math.min(1, Math.max.apply(null, points))
    }

    Process {
        id: micProc
        running: root.micActive
        command: ["sh", "-c", root._config("$(pactl get-default-source)")]
        stdout: SplitParser {
            onRead: data => {
                const v = root._peak(data)
                if (v >= 0) root.micLevel = v
            }
        }
        onRunningChanged: if (!running) root.micLevel = 0
    }

    Process {
        id: sysProc
        running: root.systemActive
        command: ["sh", "-c", root._config("$(pactl get-default-sink).monitor")]
        stdout: SplitParser {
            onRead: data => {
                const v = root._peak(data)
                if (v >= 0) root.systemLevel = v
            }
        }
        onRunningChanged: if (!running) root.systemLevel = 0
    }
}
