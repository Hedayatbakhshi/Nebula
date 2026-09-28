import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.modules.utils
import qs.modules.settings
import qs.modules.services

Scope {
    id: root

    readonly property bool on: SettingsConfig.general.desktopRipple ?? false
    readonly property int lifeMs: 2600
    readonly property int slots: 10
    property double lastDrag: 0
    readonly property real strength: {
        const v = SettingsConfig.general.desktopRippleStrength ?? "normal"
        return v === "subtle" ? 0.6 : v === "splash" ? 1.5 : 1.0
    }
    property var ripples: []
    property string monitorName: ""
    property bool alive: false
    property double now: 0

    function spawn(screenName, x, y, amp) {
        if (!root.on || ServiceGameMode.active)
            return
        const t = Date.now()
        const same = screenName === root.monitorName
        const list = same ? root.ripples.filter(r => t - r.t0 < root.lifeMs) : []
        list.push({ x: x, y: y, t0: t, amp: amp ?? 1 })
        while (list.length > root.slots)
            list.shift()
        root.monitorName = screenName
        root.now = t
        root.ripples = list
        root.alive = true
        idle.restart()
    }

    function uniformFor(i) {
        const r = root.ripples[i]
        if (!r)
            return Qt.vector4d(0, 0, -1, 0)
        return Qt.vector4d(r.x, r.y, (root.now - r.t0) / 1000, r.amp)
    }

    onOnChanged: if (!root.on) {
        root.ripples = []
        root.alive = false
    }

    Timer {
        id: idle
        interval: 8000
        onTriggered: root.alive = false
    }

    Connections {
        target: GlobalStates
        function onDesktopClicked(screenName, x, y) { root.spawn(screenName, x, y, 1) }
        function onDesktopDragged(screenName, x, y) {
            const t = Date.now()
            if (t - root.lastDrag < 110)
                return
            root.lastDrag = t
            root.spawn(screenName, x, y, 0.6)
        }
    }

    IpcHandler {
        target: "ripple"
        function at(x: real, y: real): void {
            root.spawn(Quickshell.screens[0]?.name ?? "", x, y, 1)
        }
    }

    Loader {
        active: root.alive
        visible: active

        sourceComponent: PanelWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === root.monitorName) ?? Quickshell.screens[0]
            anchors { top: true; left: true; right: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell:ripple"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            readonly property bool moving: root.ripples.some(r => root.now - r.t0 < root.lifeMs)

            FrameAnimation {
                running: win.moving
                onTriggered: root.now = Date.now()
            }

            Image {
                id: wall
                anchors.fill: parent
                visible: false
                source: WallpaperTheme.wallpaperScreen !== "" ? "file://" + WallpaperTheme.wallpaperScreen : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            ShaderEffect {
                anchors.fill: parent
                visible: win.moving && wall.status === Image.Ready
                property vector2d itemSize: Qt.vector2d(width, height)
                property vector4d r0: root.uniformFor(0)
                property vector4d r1: root.uniformFor(1)
                property vector4d r2: root.uniformFor(2)
                property vector4d r3: root.uniformFor(3)
                property vector4d r4: root.uniformFor(4)
                property vector4d r5: root.uniformFor(5)
                property vector4d r6: root.uniformFor(6)
                property vector4d r7: root.uniformFor(7)
                property vector4d r8: root.uniformFor(8)
                property vector4d r9: root.uniformFor(9)
                property color tint: Colors.primary
                property real strength: root.strength
                property var source: wall
                fragmentShader: Qt.resolvedUrl("../../../shaders/qsb/ripple.frag.qsb")
            }
        }
    }
}
