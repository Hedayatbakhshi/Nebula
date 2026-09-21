import Quickshell
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn
import "../../MatrialShapes/shape-library.js" as ShapeLibrary

ShapeWidget {
    id: root
    configKey: "albumShape"
    tile: WidgetSizes.small
    resizable: true
    minSpan: Qt.size(2, 2)
    maxSpan: Qt.size(3, 3)
    defaultPos: Qt.point(660, 440)

    readonly property bool hasTrack: ServiceMusic.activePlayer !== null
    readonly property string artUrl: ServiceMusic.activeTrack?.artUrl ?? ""
    readonly property bool hasArt: root.artUrl !== ""
    readonly property string title: root.hasTrack ? (ServiceMusic.activeTrack?.title ?? "") : ""
    readonly property string artist: root.hasTrack ? (ServiceMusic.activeTrack?.artist ?? "") : ""

    readonly property real trackLength: ServiceMusic.trackLength
    readonly property real elapsed: ServiceMusic.activePlayer?.position ?? 0
    readonly property real progress: root.trackLength > 0
        ? Math.max(0, Math.min(1, root.elapsed / root.trackLength))
        : 0

    readonly property bool canSeek: (ServiceMusic.activePlayer?.canSeek ?? false)
        && root.trackLength > 0
    property bool scrubbing: false
    property real scrubProgress: 0
    property real shownProgress: 0
    property real _seekTarget: -1

    readonly property real ringProgress: root.scrubbing ? root.scrubProgress : root.shownProgress

    onProgressChanged: {
        if (root.scrubbing)
            return
        if (root._seekTarget >= 0) {
            if (Math.abs(root.progress - root._seekTarget) < 0.01)
                root._seekTarget = -1
            else
                return
        }
        root.shownProgress = root.progress
    }

    Timer {
        interval: 100
        repeat: true
        running: root.hasTrack && !root.scrubbing
            && (ServiceMusic.activePlayer?.isPlaying ?? false) && root.trackLength > 0
        onTriggered: root.shownProgress = Math.min(1, root.shownProgress + 0.1 / root.trackLength)
    }

    Timer {
        id: seekGuard
        interval: 2000
        running: root._seekTarget >= 0
        onTriggered: root._seekTarget = -1
    }

    readonly property string shapeLock: SettingsConfig.widgets.albumShapeLock ?? ""

    optionsComponent: Component {
        ShapePicker {
            selected: root.shapeLock
            autoHint: "Changes with each track, softens when paused"
            onPicked: name => SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets, { albumShapeLock: name })
        }
    }

    readonly property real ringWidth: 5
    readonly property real artSize: root.faceSize - 2 * (root.ringWidth + 4)

    readonly property int trackShape: {
        let h = 0
        const t = root.title
        for (let i = 0; i < t.length; i++) h = (h * 31 + t.charCodeAt(i)) | 0
        return Math.abs(h) % 8
    }

    shape: {
        if (root.shapeLock !== "") return ShapeLibrary.get(root.shapeLock) ?? MaterialShapeFn.getCircle()
        if (!root.hasTrack) return MaterialShapeFn.getCircle()
        if (!ServiceMusic.isPlaying) return MaterialShapeFn.getCookie12Sided()
        switch (root.trackShape) {
        case 1:  return MaterialShapeFn.getClover8Leaf()
        case 2:  return MaterialShapeFn.getFlower()
        case 3:  return MaterialShapeFn.getSunny()
        case 4:  return MaterialShapeFn.getPuffy()
        case 5:  return MaterialShapeFn.getGem()
        case 6:  return MaterialShapeFn.getCookie7Sided()
        case 7:  return MaterialShapeFn.getSoftBurst()
        default: return MaterialShapeFn.getCookie9Sided()
        }
    }

    HoverHandler { id: hover }

    BestArt {
        id: bestArt
        artUrl: root.artUrl
        trackKey: root.title + "|" + root.artist
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
            roundedPolygon: root.shape
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
        visible: root.hasArt
        source: artLayer
        maskEnabled: true
        maskSource: artMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    MultiEffect {
        anchors.fill: parent
        source: artLayer
        visible: root.hasArt && opacity > 0
        opacity: root.hasTrack && hover.hovered ? 1 : 0
        Behavior on opacity { EffectsAnim { speed: "fast" } }
        blurEnabled: true
        blur: 0.5
        blurMax: 32
        autoPaddingEnabled: false
        brightness: -0.3
        maskEnabled: true
        maskSource: artMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    MaterialIconSymbol {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -12
        visible: !root.hasArt
        content: "music_note"
        iconSize: Math.round(root.faceSize * 0.24)
        customColor: Colors.outline
    }

    MaterialShapes.ShapeCanvas {
        id: ringCanvas
        anchors.centerIn: parent
        width: root.faceSize
        height: root.faceSize
        visible: root.hasTrack
        roundedPolygon: root.shape
        strokeProgress: root.ringProgress
        strokeWidth: root.ringWidth
        strokeColor: Colors.primary
        strokeTrackColor: Qt.alpha(Colors.primary, 0.22)

        MouseArea {
            id: scrub
            anchors.fill: parent
            z: 50
            enabled: root.canSeek && !root.lifted
            visible: scrub.enabled
            hoverEnabled: true
            preventStealing: root.scrubbing
            acceptedButtons: Qt.LeftButton
            cursorShape: (scrub.containsMouse && scrub.onRing) || root.scrubbing
                         ? Qt.PointingHandCursor : Qt.ArrowCursor

            property bool onRing: false

            function seekTo(x, y) {
                const p = ringCanvas.progressAt(x, y)
                if (p >= 0)
                    root.scrubProgress = p
            }

            onPositionChanged: mouse => {
                scrub.onRing = ringCanvas.nearRing(mouse.x, mouse.y, root.ringWidth * 2.5)
                if (root.scrubbing)
                    scrub.seekTo(mouse.x, mouse.y)
            }
            onContainsMouseChanged: if (!scrub.containsMouse) scrub.onRing = false

            onPressed: mouse => {
                if (!ringCanvas.nearRing(mouse.x, mouse.y, root.ringWidth * 2.5)) {
                    mouse.accepted = false
                    return
                }
                root.scrubbing = true
                scrub.seekTo(mouse.x, mouse.y)
            }

            onReleased: {
                if (!root.scrubbing)
                    return
                const target = root.scrubProgress
                root.shownProgress = target
                root.scrubbing = false
                const player = ServiceMusic.activePlayer
                if (player && root.trackLength > 0) {
                    root._seekTarget = target
                    player.position = target * root.trackLength
                }
            }

            onCanceled: root.scrubbing = false
        }

        Rectangle {
            readonly property var knob: ringCanvas.pointAtProgress(root.ringProgress)
            visible: root.scrubbing && knob !== null
            x: (knob ? knob.x : 0) - width / 2
            y: (knob ? knob.y : 0) - height / 2
            width: root.ringWidth * 2.6
            height: width
            radius: width / 2
            color: Colors.primary
            border.width: 2
            border.color: Colors.primaryText
        }
    }

    Rectangle {
        id: titlePill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: controls.bottom
        anchors.topMargin: 2
        visible: opacity > 0
        opacity: root.hasTrack && hover.hovered ? 1 : 0
        Behavior on opacity { EffectsAnim { speed: "fast" } }
        width: Math.min(root.faceSize - 36, titleColumn.implicitWidth + 24)
        height: titleColumn.implicitHeight + 10
        radius: 12
        color: "transparent"

        ColumnLayout {
            id: titleColumn
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.8)
                shadowBlur: 0.5
                shadowVerticalOffset: 1
                shadowHorizontalOffset: 0
            }
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 5
            anchors.bottomMargin: 5
            spacing: 0

            CustomText {
                Layout.fillWidth: true
                content: root.title
                size: 11
                weight: 700
                customColor: "white"
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
            CustomText {
                Layout.fillWidth: true
                visible: root.artist !== ""
                content: root.artist
                size: 10
                customColor: Qt.rgba(1, 1, 1, 0.8)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    Rectangle {
        id: controls
        anchors.centerIn: parent
        visible: opacity > 0
        opacity: root.hasTrack && hover.hovered ? 1 : 0
        Behavior on opacity { EffectsAnim { speed: "fast" } }
        width: controlRow.implicitWidth + 10
        height: 32
        radius: 16
        color: "transparent"

        RowLayout {
            id: controlRow
            anchors.centerIn: parent
            spacing: 6
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.8)
                shadowBlur: 0.5
                shadowVerticalOffset: 1
                shadowHorizontalOffset: 0
            }

            M3IconButton {
                implicitWidth: 26
                implicitHeight: 26
                color: "transparent"
                iconHoverColor: Colors.primary
                icon: "skip_previous"
                iconSize: 15
                iconColor: "white"
                enabledButton: ServiceMusic.canGoPrevious && !root.preview
                onClicked: ServiceMusic.previous()
            }

            M3IconButton {
                implicitWidth: 26
                implicitHeight: 26
                color: "transparent"
                iconHoverColor: Colors.primary
                icon: ServiceMusic.isPlaying ? "pause" : "play_arrow"
                iconSize: 17
                iconColor: "white"
                enabledButton: ServiceMusic.canTogglePlaying && !root.preview
                onClicked: ServiceMusic.togglePlaying()
            }

            M3IconButton {
                implicitWidth: 26
                implicitHeight: 26
                color: "transparent"
                iconHoverColor: Colors.primary
                icon: "skip_next"
                iconSize: 15
                iconColor: "white"
                enabledButton: ServiceMusic.canGoNext && !root.preview
                onClicked: ServiceMusic.next()
            }
        }
    }
}
