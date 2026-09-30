import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.modules.utils
import qs.modules.settings

Scope {
    id: root

    required property var ripple

    readonly property string source: WallpaperTheme.wallpaperScreen !== "" ? "file://" + WallpaperTheme.wallpaperScreen : ""
    readonly property string transition: SettingsConfig.theme.transitionType ?? "fade"
    readonly property var shaped: ["left", "right", "top", "bottom", "wipe", "wave", "grow", "center", "any", "outer"]

    // How the image is fitted to the screen. "crop" fills the screen and cuts
    // the overflow, "fit" shows the whole image and letterboxes, "stretch"
    // distorts to fill, "tile" repeats. A portrait photo on a landscape screen
    // loses a lot to "crop", which is why this is user-selectable now.
    readonly property string fillModeName: SettingsConfig.theme.wallpaperFill ?? "crop"
    readonly property var fillModes: ({
        crop:    Image.PreserveAspectCrop,
        fit:     Image.PreserveAspectFit,
        stretch: Image.Stretch,
        tile:    Image.Tile
    })
    readonly property int fillMode: fillModes[fillModeName] ?? Image.PreserveAspectCrop

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData

            screen: modelData
            anchors { top: true; left: true; right: true; bottom: true }
            color: "black"
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell:wallpaper"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            property bool aFront: true
            readonly property Image frontImg: win.aFront ? imgA : imgB
            readonly property Image backImg: win.aFront ? imgB : imgA
            readonly property string wanted: root.source
            property real progress: 0
            property real swapMode: 0
            property vector2d swapOrigin: Qt.vector2d(width / 2, height / 2)
            property vector2d swapDir: Qt.vector2d(1, 0)

            onWantedChanged: win.load()
            Component.onCompleted: win.load()

            function load() {
                if (win.wanted === "")
                    return
                if (swap.running) {
                    swap.stop()
                    win.finish()
                }
                if (win.frontImg.source.toString() === win.wanted) {
                    win.backImg.source = ""
                    return
                }
                if (win.frontImg.status !== Image.Ready) {
                    win.frontImg.source = win.wanted
                    return
                }
                win.backImg.source = win.wanted
                if (win.backImg.status === Image.Ready)
                    win.begin()
            }

            function ready(img) {
                if (img === win.backImg && img.source.toString() === win.wanted && !swap.running)
                    win.begin()
            }

            function begin() {
                let t = root.transition
                if (t === "random")
                    t = root.shaped[Math.floor(Math.random() * root.shaped.length)]
                const w = win.width, h = win.height
                win.swapOrigin = Qt.vector2d(w / 2, h / 2)
                win.swapMode = 1
                if (t === "none") {
                    win.finish()
                    return
                } else if (t === "left") {
                    win.swapDir = Qt.vector2d(1, 0)
                } else if (t === "right") {
                    win.swapDir = Qt.vector2d(-1, 0)
                } else if (t === "top") {
                    win.swapDir = Qt.vector2d(0, 1)
                } else if (t === "bottom") {
                    win.swapDir = Qt.vector2d(0, -1)
                } else if (t === "wipe") {
                    win.swapDir = Qt.vector2d(0.7071, 0.7071)
                } else if (t === "wave") {
                    win.swapMode = 2
                    win.swapDir = Qt.vector2d(0.866, 0.5)
                } else if (t === "grow" || t === "center") {
                    win.swapMode = 3
                } else if (t === "any") {
                    win.swapMode = 3
                    win.swapOrigin = Qt.vector2d(w * (0.15 + Math.random() * 0.7), h * (0.15 + Math.random() * 0.7))
                } else if (t === "outer") {
                    win.swapMode = 4
                } else {
                    win.swapMode = 0
                }
                const fade = win.swapMode === 0
                swap.duration = t === "simple" ? 350 : fade ? 900 : 1200
                swap.easing.type = fade ? Easing.Linear : Easing.BezierSpline
                win.progress = 0
                swap.start()
            }

            function finish() {
                win.aFront = !win.aFront
                win.progress = 0
                win.backImg.source = ""
            }

            NumberAnimation {
                id: swap
                target: win
                property: "progress"
                from: 0
                to: 1
                easing.bezierCurve: M3Motion.emphasizedCurve
                onFinished: win.finish()
            }

            Image {
                id: imgA
                anchors.fill: parent
                visible: win.frontImg === imgA && !swap.running
                fillMode: root.fillMode
                asynchronous: true
                cache: false
                onStatusChanged: if (status === Image.Ready) win.ready(imgA)
            }

            Image {
                id: imgB
                anchors.fill: parent
                visible: win.frontImg === imgB && !swap.running
                fillMode: root.fillMode
                asynchronous: true
                cache: false
                onStatusChanged: if (status === Image.Ready) win.ready(imgB)
            }

            ShaderEffect {
                anchors.fill: parent
                visible: swap.running
                property vector2d itemSize: Qt.vector2d(width, height)
                property real progress: win.progress
                property real mode: win.swapMode
                property vector2d origin: win.swapOrigin
                property vector2d dir: win.swapDir
                property var fromTex: win.frontImg
                property var toTex: win.backImg
                fragmentShader: Qt.resolvedUrl("../../../shaders/qsb/wallswap.frag.qsb")
            }

            ShaderEffect {
                anchors.fill: parent
                visible: root.ripple.moving && root.ripple.monitorName === win.modelData.name
                    && win.frontImg.status === Image.Ready
                property vector2d itemSize: Qt.vector2d(width, height)
                property vector4d r0: root.ripple.uniformFor(0)
                property vector4d r1: root.ripple.uniformFor(1)
                property vector4d r2: root.ripple.uniformFor(2)
                property vector4d r3: root.ripple.uniformFor(3)
                property vector4d r4: root.ripple.uniformFor(4)
                property vector4d r5: root.ripple.uniformFor(5)
                property vector4d r6: root.ripple.uniformFor(6)
                property vector4d r7: root.ripple.uniformFor(7)
                property vector4d r8: root.ripple.uniformFor(8)
                property vector4d r9: root.ripple.uniformFor(9)
                property color tint: Colors.primary
                property real strength: root.ripple.strength
                property var source: win.frontImg
                fragmentShader: Qt.resolvedUrl("../../../shaders/qsb/ripple.frag.qsb")
            }
        }
    }
}
