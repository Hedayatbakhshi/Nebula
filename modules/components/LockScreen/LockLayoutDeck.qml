pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/shape-library.js" as ShapeLibrary

Item {
    id: root

    property var context: null
    property bool preview: false
    property bool exiting: false
    property bool greeter: false
    property var cfg: LockSession.cfg

    readonly property Item authField: auth
    readonly property bool _animated: !root.preview
    readonly property real u: Math.min(root.width / 1920, root.height / 1080)
    readonly property string _family: SettingsConfig.general.defaultFont ?? "Rubik"
    readonly property bool _music: root.cfg.showMusic !== false && !root.greeter && ServiceMusic.activePlayer !== null
    readonly property bool _playing: root._music && ServiceMusic.isPlaying
    readonly property real _length: root._music ? ServiceMusic.trackLength : 0
    readonly property real _position: root._music ? (ServiceMusic.activePlayer?.position ?? 0) : 0
    readonly property real progress: root._length > 0 ? Math.max(0, Math.min(1, root._position / root._length)) : 0

    property real ringIn: root._animated ? 0 : 1
    SequentialAnimation {
        running: root._animated
        PauseAnimation { duration: 500 }
        NumberAnimation { target: root; property: "ringIn"; to: 1; duration: 1200; easing.type: Easing.OutCubic }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root._playing && (ServiceMusic.activePlayer?.positionSupported ?? false)
        onTriggered: ServiceMusic.activePlayer.positionChanged()
    }

    function fmt(s) {
        s = Math.max(0, Math.floor(s))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    LockStatusModel { id: status }

    component Transport: MotionEnter {
        id: tb
        property string icon: ""
        property int order: 0
        signal activated
        anchors.verticalCenter: parent.verticalCenter
        dy: 0
        fromScale: 0.3
        delay: 600 + tb.order * 80
        animated: root._animated
        exiting: root.exiting

        M3IconButton {
            implicitWidth: 84 * root.u
            implicitHeight: 84 * root.u
            icon: tb.icon
            iconSize: Math.round(40 * root.u)
            color: Qt.alpha(Colors.surfaceText, 0.1)
            onClicked: tb.activated()
        }
    }


    MotionEnter {
        x: 120 * root.u
        y: 120 * root.u
        width: 640 * root.u
        height: width
        dy: 0
        fromScale: 0.55
        fromRotation: -70
        delay: 80
        animated: root._animated
        exiting: root.exiting

        Item {
            id: disc
            anchors.fill: parent

            RotationAnimation on rotation {
                running: root._animated && !root.exiting
                paused: !root._playing && root._music
                from: 0; to: 360
                duration: 48000
                loops: Animation.Infinite
            }

            LockShapeImage {
                anchors.fill: parent
                source: root._music ? (ServiceMusic.activeTrack?.artUrl ?? "") : WallpaperTheme.wallpaper
                trackKey: root._music ? (ServiceMusic.activeTrack?.title ?? "") + "|" + (ServiceMusic.activeTrack?.artist ?? "") : ""
                shapeName: "cookie12"
                sourceSize: 1024
                fallbackIcon: "music_note"
                fallbackColor: Colors.surfaceContainerHigh
                fallbackIconColor: Colors.outline
            }

            MaterialShapes.ShapeCanvas {
                anchors.centerIn: parent
                width: parent.width + 72 * root.u
                height: width
                roundedPolygon: ShapeLibrary.get("cookie12")
                color: "transparent"
                strokeProgress: root._music ? root.progress * root.ringIn : 0
                strokeWidth: 12 * root.u
                strokeColor: Colors.primary
                strokeTrackColor: Qt.alpha(Colors.surfaceText, 0.14 * root.ringIn)
            }
        }
    }

    ColumnLayout {
        x: 840 * root.u
        y: 170 * root.u
        width: 580 * root.u
        spacing: 0

        MotionEnter {
            delay: 300
            dy: 30 * root.u
            animated: root._animated
            exiting: root.exiting

            CustomText {
                content: root._music ? "NOW PLAYING" + ((ServiceMusic.activePlayer?.identity ?? "") !== "" ? " · " + ServiceMusic.activePlayer.identity.toUpperCase() : "")
                       : root.greeter ? "SIGN IN" : "NOTHING PLAYING"
                size: Math.round(22 * root.u)
                weight: 600
                font.letterSpacing: 4.4 * root.u
                customColor: Colors.primary
            }
        }

        MotionEnter {
            Layout.topMargin: 10 * root.u
            Layout.fillWidth: true
            delay: 380
            dy: 50 * root.u
            animated: root._animated
            exiting: root.exiting

            Text {
                width: 580 * root.u
                text: root._music ? (ServiceMusic.activeTrack?.title ?? "") : LockSession.greeting + ","
                color: Colors.surfaceText
                font.family: root._family
                font.pixelSize: Math.round(110 * root.u)
                font.weight: 800
                font.letterSpacing: -3.8 * root.u
                lineHeight: 0.95
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                renderType: Text.QtRendering
            }
        }

        MotionEnter {
            Layout.topMargin: 14 * root.u
            delay: 460
            dy: 30 * root.u
            animated: root._animated
            exiting: root.exiting

            CustomText {
                width: Math.min(implicitWidth, 580 * root.u)
                content: root._music ? (ServiceMusic.activeTrack?.artist ?? "") : LockSession.user
                size: Math.round(36 * root.u)
                weight: 400
                customColor: Colors.surfaceVariantText
            }
        }

        MotionEnter {
            visible: root._music && root._length > 0
            Layout.topMargin: 30 * root.u
            delay: 520
            dy: 20 * root.u
            animated: root._animated
            exiting: root.exiting

            CustomText {
                content: root.fmt(root._position) + " / " + root.fmt(root._length)
                size: Math.round(22 * root.u)
                weight: 500
                font.features: { "tnum": 1 }
                customColor: Colors.outline
            }
        }
    }

    Row {
        visible: root._music
        x: 840 * root.u
        y: 620 * root.u
        spacing: 22 * root.u

        Transport { icon: "skip_previous"; order: 0; onActivated: ServiceMusic.previous() }

        MotionEnter {
            anchors.verticalCenter: parent.verticalCenter
            dy: 0
            fromScale: 0.2
            fromRotation: -90
            delay: 680
            animated: root._animated
            exiting: root.exiting

            MaterialShapes.ShapeCanvas {
                width: 128 * root.u
                height: width
                roundedPolygon: ShapeLibrary.get(root._playing ? "cookie9" : "circle")
                color: playArea.pressed ? Qt.darker(Colors.primary, 1.1) : Colors.primary

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: root._playing ? "pause" : "play_arrow"
                    iconSize: Math.round(58 * root.u)
                    customColor: Colors.primaryText
                }

                MouseArea {
                    id: playArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ServiceMusic.togglePlaying()
                }
            }
        }

        Transport { icon: "skip_next"; order: 2; onActivated: ServiceMusic.next() }
    }

    MotionEnter {
        x: root.width - width - 110 * root.u
        y: 110 * root.u
        delay: 200
        dx: 40 * root.u
        dy: 0
        animated: root._animated
        exiting: root.exiting

        Column {
            spacing: 0

            Text {
                anchors.right: parent.right
                text: LockSession.hourPad
                color: Colors.surfaceText
                font.family: root._family
                font.pixelSize: Math.round(170 * root.u)
                font.weight: 700
                font.letterSpacing: -8 * root.u
                lineHeight: 0.84
                renderType: Text.QtRendering
            }
            Text {
                anchors.right: parent.right
                text: LockSession.minute
                color: Colors.primary
                font.family: root._family
                font.pixelSize: Math.round(170 * root.u)
                font.weight: 700
                font.letterSpacing: -8 * root.u
                lineHeight: 0.84
                renderType: Text.QtRendering
            }
            CustomText {
                visible: root.cfg.showDate !== false
                anchors.right: parent.right
                topPadding: 24 * root.u
                content: LockSession.weekday + ", " + LockSession.dayNum + " " + LockSession.month
                size: Math.round(28 * root.u)
                weight: 500
                customColor: Colors.surfaceVariantText
            }
        }
    }

    MotionEnter {
        visible: root.cfg.showStatus !== false && !root.greeter
        x: 120 * root.u
        y: root.height - height - 96 * root.u
        delay: 760
        dy: 30 * root.u
        animated: root._animated
        exiting: root.exiting

        Row {
            spacing: 28 * root.u
            Repeater {
                model: status.entries
                delegate: Row {
                    required property var modelData
                    spacing: 10 * root.u
                    MaterialIconSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        content: parent.modelData.icon
                        iconSize: Math.round(28 * root.u)
                        customColor: Colors.primary
                    }
                    CustomText {
                        anchors.verticalCenter: parent.verticalCenter
                        content: parent.modelData.value
                        size: Math.round(22 * root.u)
                        weight: 500
                        customColor: Colors.surfaceVariantText
                    }
                }
            }
        }
    }

    MotionEnter {
        x: root.width - width - 110 * root.u
        y: root.height - height - 84 * root.u
        delay: 700
        dy: 30 * root.u
        animated: root._animated
        exiting: root.exiting

        RowLayout {
            spacing: 16 * root.u

            LockPowerActions {
                visible: root.cfg.showPower !== false
                Layout.alignment: Qt.AlignTop
                variant: "icons"
                box: 64 * root.u
                iconPx: Math.round(26 * root.u)
                spacing: 10 * root.u
                plate: Qt.alpha(Colors.surfaceText, 0.1)
                plateHover: Qt.alpha(Colors.surfaceText, 0.2)
            }

            LockShapeImage {
                Layout.preferredWidth: 64 * root.u
                Layout.preferredHeight: 64 * root.u
                Layout.alignment: Qt.AlignTop
                source: SettingsConfig.general.profile ?? ""
            }

            LockAuthField {
                id: auth
                context: root.context
                fieldWidth: 400 * root.u
                fieldHeight: 70 * root.u
                fieldColor: Qt.alpha(Colors.surfaceText, 0.1)
                placeholder: "Password"
                placeholderColor: Qt.alpha(Colors.surfaceText, 0.55)
                placeholderSize: Math.round(22 * root.u)
                showLockIcon: false
                submitAlways: true
            }
        }
    }
}
