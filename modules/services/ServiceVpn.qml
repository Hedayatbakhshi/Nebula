pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool installed: false
    property bool connected: false
    property bool busy: false
    property string error: ""

    property string country: ""
    property string city: ""
    property string serverId: ""
    property string ip: ""
    property string protocol: ""
    property int load: -1

    function connectFastest() {
        if (root.busy || !root.installed) return
        root.busy = true
        root.error = ""
        connectProcess.command = ["protonvpn", "connect"]
        connectProcess.running = true
    }

    function disconnectVpn() {
        if (root.busy || !root.installed) return
        root.busy = true
        root.error = ""
        disconnectProcess.running = true
    }

    // `protonvpn status` is the only source that survives a shell restart — the
    // connect command's output is long gone by then. Both shapes are accepted:
    // the labelled block status prints, and the one-line sentence connect prints.
    function _parseDetails(out) {
        function grab(re) {
            const m = out.match(re)
            return m ? m[1].trim() : ""
        }
        let server  = grab(/^\s*Server:\s*(.+)$/mi)
        let country = grab(/^\s*Country:\s*(.+)$/mi)
        let city    = grab(/^\s*City:\s*(.+)$/mi)

        const inline = server.match(/^(\S+)\s+in\s+([^,]+),\s*(.+)$/)
        if (inline) {
            server = inline[1].trim()
            if (!city)    city    = inline[2].trim()
            if (!country) country = inline[3].trim()
        }

        if (!server)  server  = grab(/Connected to (\S+)/i)
        if (!country) country = grab(/Connected to \S+ in [^,]+,\s*([^.\n]+)/i)
        if (!city)    city    = grab(/Connected to \S+ in ([^,]+),/i)

        const ip      = grab(/^\s*IP(?:\s*address)?:\s*([0-9a-fA-F:.]+)/mi)
                     || grab(/new IP address is ([0-9a-fA-F:.]*[0-9a-fA-F])/i)
        const load     = grab(/^\s*Load:\s*(\d+)\s*%/mi)
        const protocol = grab(/^\s*Protocol:\s*(\S+)/mi)

        // Only ever fill in — a status print that omits a field must not wipe what
        // the connect output already told us.
        if (server)  root.serverId = server
        if (country) root.country  = country
        if (city)    root.city     = city
        if (ip)      root.ip       = ip
        if (load)     root.load     = parseInt(load, 10)
        if (protocol) root.protocol = protocol.toLowerCase()
    }

    function _resetConnectionState() {
        root.connected = false
        root.country = ""
        root.city = ""
        root.serverId = ""
        root.ip = ""
        root.protocol = ""
        root.load = -1
    }

    Component.onCompleted: {
        installedCheck.running = true
        statusProcess.running = true
    }

    // ── Installed check ──────────────────────────────────────────────
    Process {
        id: installedCheck
        command: ["which", "protonvpn"]
        running: false
        onExited: function(code) { root.installed = (code === 0) }
    }

    // ── Status polling ───────────────────────────────────────────────
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!root.installed) return
            statusProcess.running = true
        }
    }

    Process {
        id: statusProcess
        command: ["protonvpn", "status"]
        running: false
        property string _buffer: ""
        stdout: SplitParser {
            onRead: function(line) { statusProcess._buffer += line + "\n" }
        }
        onRunningChanged: if (running) statusProcess._buffer = ""
        onExited: function(code) {
            const out = statusProcess._buffer
            if (/Status:\s*Connected/i.test(out)) {
                root.connected = true
                root._parseDetails(out)
            } else if (/Status:\s*Disconnected/i.test(out)) {
                if (root.connected) root._resetConnectionState()
                root.connected = false
            }
        }
    }

    // ── Connect ──────────────────────────────────────────────────────
    Process {
        id: connectProcess
        running: false
        property string _buffer: ""
        stdout: SplitParser {
            onRead: function(line) { connectProcess._buffer += line + "\n" }
        }
        stderr: SplitParser {
            onRead: function(line) { connectProcess._buffer += line + "\n" }
        }
        onRunningChanged: if (running) connectProcess._buffer = ""
        onExited: function(code) {
            root.busy = false
            const out = connectProcess._buffer

            if (code === 0) {
                root.connected = true
                root._parseDetails(out)
            } else {
                root._resetConnectionState()
                if (/sign.?in|log.?in|not authenticated/i.test(out)) {
                    root.error = "Not signed in — run \"protonvpn signin\" in a terminal"
                } else {
                    const lines = out.trim().split("\n").filter(l => l.trim().length > 0)
                    root.error = lines.length > 0 ? lines[lines.length - 1].replace(/^Error:\s*/, "") : "Connection failed"
                }
            }
        }
    }

    // ── Disconnect ───────────────────────────────────────────────────
    Process {
        id: disconnectProcess
        command: ["protonvpn", "disconnect"]
        running: false
        onExited: function(code) {
            root.busy = false
            root._resetConnectionState()
        }
    }
}
