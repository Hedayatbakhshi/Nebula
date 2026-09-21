import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "vinyl"
    tile: WidgetSizes.large
    defaultPos: Qt.point(460, 620)

    readonly property string artUrl: ServiceMusic.activeTrack?.artUrl ?? ""
    readonly property bool hasArt: artUrl !== ""
    readonly property bool hasTrack: ServiceMusic.activePlayer !== null
    readonly property real trackLength: ServiceMusic.trackLength
    readonly property real elapsed: ServiceMusic.activePlayer?.position ?? 0

    readonly property real progress: trackLength > 0
        ? Math.max(0, Math.min(1, elapsed / trackLength))
        : 0

    readonly property real discR: 100
    readonly property real discCx: 160
    readonly property real discCy: 122

    readonly property real pivotX: 252
    readonly property real pivotY: 30
    readonly property real armLen: 120

    readonly property real outerRho: 93
    readonly property real innerRho: 43
    readonly property real parkRho: 106

    readonly property real armAngle: {
        const dx = discCx - pivotX
        const dy = discCy - pivotY
        const d = Math.hypot(dx, dy)
        const rho = ServiceMusic.isPlaying
            ? outerRho + (innerRho - outerRho) * progress
            : parkRho
        const c = Math.max(-1, Math.min(1, (armLen * armLen + d * d - rho * rho) / (2 * armLen * d)))
        return (Math.atan2(dy, dx) - Math.acos(c)) * 180 / Math.PI
    }

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: WidgetSizes.cardColor

        Rectangle {
            width: root.discR * 2 + 16
            height: width
            radius: width / 2
            x: root.discCx - width / 2
            y: root.discCy - width / 2
            color: Colors.surfaceContainerLow
        }

        Item {
            id: discSpin
            width: root.discR * 2
            height: width
            x: root.discCx - root.discR
            y: root.discCy - root.discR

            NumberAnimation on rotation {
                from: 0
                to: 360
                duration: 1800
                loops: Animation.Infinite
                running: ServiceMusic.isPlaying
            }

            Canvas {
                id: grooves
                anchors.fill: parent
                antialiasing: true

                property color discColor: Qt.darker(Colors.surfaceContainerHighest, 3.0)
                property color grooveColor: Qt.alpha(Colors.surfaceBright, 0.10)
                property color rimColor: Qt.alpha(Colors.surfaceBright, 0.22)

                onDiscColorChanged: requestPaint()
                onGrooveColorChanged: requestPaint()
                onRimColorChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onVisibleChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()

                    const cx = width / 2
                    const cy = height / 2
                    const R = Math.min(width, height) / 2
                    if (R <= 0) return

                    ctx.beginPath()
                    ctx.arc(cx, cy, R, 0, 2 * Math.PI)
                    ctx.fillStyle = discColor
                    ctx.fill()

                    ctx.strokeStyle = grooveColor
                    ctx.lineWidth = 1
                    for (let r = R * 0.44; r < R - 4; r += 4.5) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                        ctx.stroke()
                    }

                    ctx.strokeStyle = rimColor
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    ctx.arc(cx, cy, R - 1, 0, 2 * Math.PI)
                    ctx.stroke()
                }
            }

            Item {
                id: labelContent
                anchors.centerIn: parent
                width: 86
                height: 86
                visible: false
                layer.enabled: true

                Rectangle {
                    anchors.fill: parent
                    color: Colors.primaryContainer
                }

                Image {
                    anchors.fill: parent
                    source: root.artUrl
                    visible: root.hasArt
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 128
                    sourceSize.height: 128
                    asynchronous: true
                }

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "music_note"
                    iconSize: 30
                    customColor: Colors.primaryContainerText
                    visible: !root.hasArt
                }
            }

            Rectangle {
                id: labelMask
                anchors.centerIn: parent
                width: 86
                height: 86
                radius: width / 2
                visible: false
                layer.enabled: true
            }

            MultiEffect {
                anchors.fill: labelContent
                source: labelContent
                maskEnabled: true
                maskSource: labelMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }

            Rectangle {
                anchors.centerIn: parent
                width: 9
                height: 9
                radius: width / 2
                color: Colors.outlineVariant
            }
        }

        MouseArea {
            x: root.discCx - root.discR
            y: root.discCy - root.discR
            width: root.discR * 2
            height: width
            enabled: !root.lifted && ServiceMusic.canTogglePlaying
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: ServiceMusic.togglePlaying()
        }

        Item {
            x: root.pivotX
            y: root.pivotY
            width: 0
            height: 0
            transformOrigin: Item.TopLeft
            rotation: root.armAngle

            Behavior on rotation { SpatialAnim { speed: "slow" } }

            Rectangle {
                x: -24
                y: -8
                width: 20
                height: 16
                radius: 8
                color: Colors.outlineVariant
            }

            Rectangle {
                x: 6
                y: -2
                width: root.armLen - 20
                height: 4
                radius: 2
                color: Colors.outline
            }

            Rectangle {
                x: root.armLen - 18
                y: -9
                width: 18
                height: 18
                radius: 5
                color: Colors.outlineVariant
            }

            Rectangle {
                x: root.armLen - 4
                y: -2
                width: 5
                height: 5
                radius: 2.5
                color: Colors.primary
            }
        }

        Rectangle {
            x: root.pivotX - 11
            y: root.pivotY - 11
            width: 22
            height: 22
            radius: width / 2
            color: Colors.surfaceContainerHigh
            border.width: 1
            border.color: Colors.outlineVariant

            Rectangle {
                anchors.centerIn: parent
                width: 7
                height: 7
                radius: width / 2
                color: Colors.outline
            }
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.bottomMargin: 18
            spacing: 1

            CustomMarqueeText {
                Layout.fillWidth: true
                content: root.hasTrack
                    ? (ServiceMusic.activeTrack?.title ?? "Unknown Title")
                    : "Nothing playing"
                size: 15
                weight: 700
                scrolling: !root.preview
            }

            CustomText {
                Layout.fillWidth: true
                content: root.hasTrack
                    ? (ServiceMusic.activeTrack?.artist ?? "Unknown Artist")
                    : "put a record on"
                size: 12
                elide: Text.ElideRight
                customColor: Colors.outline
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 6

                M3IconButton {
                    implicitWidth: 30
                    implicitHeight: 30
                    icon: "skip_previous"
                    iconSize: 16
                    enabledButton: ServiceMusic.canGoPrevious
                    onClicked: ServiceMusic.previous()
                }

                M3IconButton {
                    implicitWidth: 30
                    implicitHeight: 30
                    icon: "skip_next"
                    iconSize: 16
                    enabledButton: ServiceMusic.canGoNext
                    onClicked: ServiceMusic.next()
                }

                Item { Layout.fillWidth: true }

                CustomText {
                    content: root.trackLength > 0
                        ? ServiceMusic.formatTime(root.elapsed) + " / " + ServiceMusic.formatTime(root.trackLength)
                        : ServiceMusic.formatTime(root.elapsed)
                    size: 11
                    customColor: Colors.outline
                }
            }
        }
    }
}
