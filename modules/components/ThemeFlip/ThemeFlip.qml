import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.modules.services
import qs.modules.settings

Scope {
    id: root

    property int held: 0
    readonly property bool active: ServiceWallpaper.flipPhase > 0

    Component.onCompleted: ServiceWallpaper.flipAvailable = true

    onActiveChanged: {
        if (!root.active)
            return
        root.held = 0
        captureFallback.restart()
    }

    function frameHeld() {
        root.held++
        if (root.held >= Quickshell.screens.length && ServiceWallpaper.flipPhase === 1) {
            captureFallback.stop()
            ServiceWallpaper.flipCaptured()
        }
    }

    Timer {
        id: captureFallback
        interval: 600
        onTriggered: if (ServiceWallpaper.flipPhase === 1) ServiceWallpaper.flipCaptured()
    }

    Timer {
        running: ServiceWallpaper.flipPhase === 3
        interval: 800
        onTriggered: ServiceWallpaper.flipDone()
    }

    Variants {
        model: root.active ? Quickshell.screens : []

        PanelWindow {
            id: win

            required property var modelData

            screen: modelData
            anchors { top: true; left: true; right: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:themeflip"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            readonly property point center: {
                const p = ServiceWallpaper.flipPoint
                return p ? Qt.point(p.x - win.modelData.x, p.y - win.modelData.y)
                         : Qt.point(win.width / 2, win.height / 2)
            }
            readonly property real far: Math.max(
                Math.hypot(win.center.x, win.center.y),
                Math.hypot(win.width - win.center.x, win.center.y),
                Math.hypot(win.center.x, win.height - win.center.y),
                Math.hypot(win.width - win.center.x, win.height - win.center.y))
            property real radius: -2

            ScreencopyView {
                anchors.fill: parent
                captureSource: win.modelData
                live: false
                paintCursor: false
                onHasContentChanged: if (hasContent) heldTimer.start()
                layer.enabled: true
                layer.effect: ShaderEffect {
                    property vector2d itemSize: Qt.vector2d(width, height)
                    property vector2d center: Qt.vector2d(win.center.x, win.center.y)
                    property real radius: win.radius
                    fragmentShader: Qt.resolvedUrl("../../../shaders/qsb/themeflip.frag.qsb")
                }
            }

            Timer {
                id: heldTimer
                interval: 34
                onTriggered: root.frameHeld()
            }

            NumberAnimation {
                target: win
                property: "radius"
                from: -2
                to: win.far + 4
                duration: 750
                easing.type: Easing.BezierSpline
                easing.bezierCurve: M3Motion.emphasizedCurve
                running: ServiceWallpaper.flipPhase === 3
            }
        }
    }
}
