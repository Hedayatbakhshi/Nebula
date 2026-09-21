import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell
import QtQuick.Effects
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn
import "../../MatrialShapes/shape-library.js" as ShapeLibrary

WidgetHost {
    id: root
    configKey: "musicPlayer"
    tile: WidgetSizes.small
    resizable: true
    minSpan: Qt.size(2, 2)
    maxSpan: Qt.size(3, 3)
    defaultPos: Qt.point(200, 200)
    backdrop: false

    // Never start audio capture for a gallery thumbnail
    Component.onCompleted: if (!root.preview) ServiceCava.retain()
    Component.onDestruction: if (!root.preview) ServiceCava.release()

    readonly property string shapeLock: SettingsConfig.widgets.circularMusicShapeLock ?? ""
    readonly property var faceShape: root.shapeLock !== ""
        ? (ShapeLibrary.get(root.shapeLock) ?? MaterialShapeFn.getCookie12Sided())
        : MaterialShapeFn.getCookie12Sided()

    optionsComponent: Component {
        ShapePicker {
            selected: root.shapeLock
            autoHint: "Scalloped cookie, like a record label"
            onPicked: name => SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets, { circularMusicShapeLock: name })
        }
    }

    readonly property real side: Math.min(width, height)
    readonly property real ringWidth: Math.max(3, Math.round(root.side * 0.02))
    readonly property real faceSize: Math.round(root.side * 0.70)
    readonly property real ringSize: root.faceSize - 6
    readonly property real artSize: root.ringSize - 2 * (root.ringWidth + 3)

    readonly property bool hasTrack: ServiceMusic.activePlayer !== null
    readonly property string artUrl: ServiceMusic.activeTrack?.artUrl ?? ""
    readonly property string title: ServiceMusic.activeTrack?.title ?? ""
    readonly property string artist: ServiceMusic.activeTrack?.artist ?? ""

    readonly property real trackLength: ServiceMusic.trackLength
    readonly property real elapsed: ServiceMusic.activePlayer?.position ?? 0
    readonly property real progress: root.trackLength > 0
        ? Math.max(0, Math.min(1, root.elapsed / root.trackLength))
        : 0

    property bool revealed: hover.hovered

    HoverHandler { id: hover }

    BestArt {
        id: bestArt
        artUrl: root.artUrl
        trackKey: root.title + "|" + root.artist
    }

    component Visualizer: Canvas {
        id: viz
        property color fillColor: Colors.primary
        property real shapeRotation: 0

        anchors.centerIn: parent
        antialiasing: true

        NumberAnimation on shapeRotation {
            from: 0; to: 360
            duration: 20000
            loops: Animation.Infinite
            running: ServiceMusic.isPlaying && !root.preview
        }

        onShapeRotationChanged: requestPaint()
        onFillColorChanged: requestPaint()
        onWidthChanged: requestPaint()

        Connections {
            target: ServiceCava
            function onCavaData12Changed() { viz.requestPaint() }
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2
            const cy = height / 2

            const size       = Math.min(width, height)
            const baseOuterR = 0.43 * size
            const valleyR    = 0.37 * size
            const maxExt     = 0.07 * size

            const rotRad = shapeRotation * Math.PI / 180
            const data   = ServiceCava.cavaData12
            const verts  = []

            for (let i = 0; i < 12; i++) {
                const tipAngle = (Math.PI / 6  * (i + 1))     + rotRad
                const valAngle = (Math.PI / 12 * (2 * i + 3)) + rotRad
                const tipR     = baseOuterR + (data.length === 12 ? data[i] : 0) * maxExt

                verts.push({ x: cx + tipR    * Math.cos(tipAngle),
                             y: cy + tipR    * Math.sin(tipAngle) })
                verts.push({ x: cx + valleyR * Math.cos(valAngle),
                             y: cy + valleyR * Math.sin(valAngle) })
            }

            ctx.beginPath()
            const last  = verts[verts.length - 1]
            const first = verts[0]
            ctx.moveTo((last.x + first.x) / 2, (last.y + first.y) / 2)

            for (let i = 0; i < verts.length; i++) {
                const cur  = verts[i]
                const next = verts[(i + 1) % verts.length]
                ctx.quadraticCurveTo(cur.x, cur.y,
                                     (cur.x + next.x) / 2,
                                     (cur.y + next.y) / 2)
            }

            ctx.closePath()
            ctx.fillStyle = fillColor
            ctx.fill()
        }
    }

    Visualizer {
        width: root.side * 1.08
        height: width
        fillColor: Qt.alpha(Colors.primary, 0.4)
    }

    Visualizer {
        width: root.side
        height: width
        fillColor: Colors.primary
    }

    MaterialShapes.ShapeCanvas {
        anchors.centerIn: parent
        width: root.faceSize
        height: root.faceSize
        roundedPolygon: root.faceShape
        color: Colors.surface
    }

    Item {
        id: artMask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        MaterialShapes.ShapeCanvas {
            anchors.centerIn: parent
            width: root.artSize
            height: root.artSize
            roundedPolygon: root.faceShape
            color: "white"
        }
    }

    Item {
        id: artLayer
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Image {
            anchors.centerIn: parent
            width: root.artSize
            height: root.artSize
            source: bestArt.bestUrl !== "" ? bestArt.bestUrl : root.artUrl
            onStatusChanged: if (status === Image.Error && bestArt.bestUrl !== "") bestArt.reset()
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 400
            sourceSize.height: 400
            asynchronous: true
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: artLayer
        maskEnabled: true
        maskSource: artMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    MultiEffect {
        anchors.fill: parent
        source: artLayer
        visible: opacity > 0
        opacity: root.revealed ? 1 : 0
        Behavior on opacity { EffectsAnim {} }
        blurEnabled: true
        blur: 0.7
        blurMax: 48
        autoPaddingEnabled: false
        brightness: -0.35
        saturation: -0.2
        maskEnabled: true
        maskSource: artMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    MaterialIconSymbol {
        anchors.centerIn: parent
        visible: root.artUrl === ""
        content: "music_note"
        iconSize: Math.round(root.artSize * 0.3)
        customColor: Colors.outline
    }

    MaterialShapes.ShapeCanvas {
        anchors.centerIn: parent
        width: root.ringSize
        height: root.ringSize
        visible: root.hasTrack
        roundedPolygon: root.faceShape
        strokeProgress: root.progress
        strokeWidth: root.ringWidth
        strokeColor: Colors.primary
        strokeTrackColor: Qt.alpha(Colors.primary, 0.25)
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: root.artSize * 0.78
        spacing: 2
        visible: opacity > 0
        opacity: root.revealed && root.hasTrack ? 1 : 0
        Behavior on opacity { EffectsAnim {} }

        CustomText {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width
            visible: root.cols >= 3
            content: ServiceMusic.activeTrack?.identity ?? ""
            size: 11
            customColor: Qt.rgba(1, 1, 1, 0.7)
            elide: Text.ElideRight
        }

        CustomText {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width
            content: root.title
            size: Math.max(12, Math.round(root.side * 0.06))
            weight: 700
            customColor: Colors.primary
            elide: Text.ElideRight
        }

        CustomText {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width
            visible: root.artist !== ""
            content: root.artist
            size: Math.max(10, Math.round(root.side * 0.045))
            customColor: Qt.rgba(1, 1, 1, 0.75)
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            spacing: Math.round(root.side * 0.03)

            M3IconButton {
                implicitWidth: Math.round(root.side * 0.13)
                implicitHeight: implicitWidth
                color: "transparent"
                icon: "skip_previous"
                iconSize: Math.round(root.side * 0.085)
                iconColor: "white"
                iconHoverColor: Colors.primary
                enabledButton: ServiceMusic.canGoPrevious && !root.preview && !root.lifted
                onClicked: ServiceMusic.previous()
            }

            M3IconButton {
                implicitWidth: Math.round(root.side * 0.16)
                implicitHeight: implicitWidth
                color: "transparent"
                icon: ServiceMusic.isPlaying ? "pause" : "play_arrow"
                iconSize: Math.round(root.side * 0.11)
                iconColor: "white"
                iconHoverColor: Colors.primary
                enabledButton: ServiceMusic.canTogglePlaying && !root.preview && !root.lifted
                onClicked: ServiceMusic.togglePlaying()
            }

            M3IconButton {
                implicitWidth: Math.round(root.side * 0.13)
                implicitHeight: implicitWidth
                color: "transparent"
                icon: "skip_next"
                iconSize: Math.round(root.side * 0.085)
                iconColor: "white"
                iconHoverColor: Colors.primary
                enabledButton: ServiceMusic.canGoNext && !root.preview && !root.lifted
                onClicked: ServiceMusic.next()
            }
        }
    }
}
