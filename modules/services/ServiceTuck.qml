pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    readonly property string special: "special:tuck"
    property var tucked: []

    function addr(a) {
        const s = String(a ?? "")
        return s.startsWith("0x") ? s : "0x" + s
    }

    function sync() {
        const inSpecial = Hyprland.toplevels.values.filter(t => (t.lastIpcObject?.workspace?.name ?? t.workspace?.name) === root.special)
        const keep = root.tucked.filter(e => inSpecial.some(t => root.addr(t.address) === e.address))
        for (const t of inSpecial) {
            const a = root.addr(t.address)
            if (!keep.some(e => e.address === a))
                keep.push({ address: a, cls: t.lastIpcObject?.class ?? "", title: t.title ?? "", from: 1, at: Date.now() })
        }
        for (const e of keep) {
            const t = inSpecial.find(x => root.addr(x.address) === e.address)
            if (t)
                e.title = t.title ?? e.title
        }
        root.tucked = keep
    }

    function tuckFocused() {
        const t = Hyprland.activeToplevel
        if (!t)
            return
        const ipc = t.lastIpcObject ?? {}
        const ws = ipc.workspace?.name ?? t.workspace?.name ?? ""
        if (ws === root.special || ws.startsWith("special:"))
            return
        const a = root.addr(t.address)
        root.tucked = root.tucked.filter(e => e.address !== a).concat([{
            address: a,
            cls: ipc.class ?? "",
            title: t.title ?? "",
            from: ipc.workspace?.id ?? Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1,
            at: Date.now()
        }])
        Hyprland.dispatch(`hl.dsp.window.move({ window = "address:${a}", workspace = "${root.special}", follow = false })`)
        refresh.restart()
    }

    function restore(address) {
        const e = root.tucked.find(x => x.address === address)
        if (!e)
            return
        const here = Hyprland.focusedMonitor?.activeWorkspace?.id ?? e.from
        root.tucked = root.tucked.filter(x => x.address !== address)
        Hyprland.dispatch(`hl.dsp.window.move({ window = "address:${address}", workspace = ${here}, follow = true })`)
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${address}" })`)
        refresh.restart()
    }

    function close(address) {
        root.tucked = root.tucked.filter(x => x.address !== address)
        Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${address}" })`)
        refresh.restart()
    }

    function restoreLast() {
        if (root.tucked.length)
            root.restore(root.tucked[root.tucked.length - 1].address)
    }

    Timer {
        id: refresh
        interval: 250
        onTriggered: Hyprland.refreshToplevels()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["closewindow", "movewindowv2", "openwindow", "windowtitlev2"].indexOf(event.name) >= 0)
                settle.restart()
        }
    }

    Connections {
        target: Hyprland.toplevels
        function onValuesChanged() { settle.restart() }
    }

    Timer {
        id: settle
        interval: 300
        onTriggered: root.sync()
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels()
        settle.restart()
    }

    GlobalShortcut {
        name: "tuck"
        description: "Tuck the focused window onto the screen edge"
        onPressed: root.tuckFocused()
    }

    GlobalShortcut {
        name: "untuck"
        description: "Bring back the last tucked window"
        onPressed: root.restoreLast()
    }

    IpcHandler {
        target: "tuck"
        function tuck(): void { root.tuckFocused() }
        function restoreLast(): void { root.restoreLast() }
    }
}
