pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import qs.modules.components.Widgets

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
    readonly property string _hand: "Just Another Hand"
    readonly property bool _music: root.cfg.showMusic !== false && !root.greeter && ServiceMusic.activePlayer !== null

    readonly property color _t: Colors.tertiary
    readonly property color accent: Qt.hsla(root._t.hslHue, Math.min(1, root._t.hslSaturation + 0.15), 0.76, 1)
    readonly property color onAccent: Qt.hsla(root._t.hslHue, 0.7, 0.16, 1)
    readonly property color ink: "#f1e7ea"
    readonly property color inkSoft: "#b8a8ae"
    readonly property color plate: "#241a1e"
    readonly property color paper: Qt.tint("#f6f0f1", Qt.alpha(Colors.primary, 0.05))
    readonly property color paperInk: "#3b2a31"

    property real develop: root._animated ? 0 : 1
    SequentialAnimation {
        running: root._animated
        PauseAnimation { duration: 700 }
        NumberAnimation { target: root; property: "develop"; to: 1; duration: 2200; easing.type: Easing.OutCubic }
    }

    LockStatusModel { id: status }

    component Print: Item {
        property real pad: 34 * root.u
        property real capH: 150 * root.u

        Rectangle {
            anchors.fill: parent
            color: root.paper
            antialiasing: true

            layer.enabled: !root.preview
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.6)
                shadowBlur: 1.0
                shadowVerticalOffset: 22 * root.u
                shadowScale: 1.02
                autoPaddingEnabled: true
            }
        }
    }

    MotionEnter {
        x: 130 * root.u
        y: 118 * root.u
        dy: -140 * root.u
        fromRotation: 9
        fromScale: 1.06
        delay: 120
        animated: root._animated
        exiting: root.exiting
        exitDy: 160 * root.u

        Print {
            id: mainPrint
            width: 900 * root.u
            height: 600 * root.u + pad + capH
            rotation: -3.2

            Item {
                id: photo
                x: mainPrint.pad
                y: mainPrint.pad
                width: parent.width - mainPrint.pad * 2
                height: 600 * root.u
                clip: true

                Image {
                    anchors.fill: parent
                    source: WallpaperTheme.wallpaperScreen
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: root.preview ? 480 : 1400
                    asynchronous: true
                    cache: true

                    layer.enabled: root.develop < 1
                    layer.effect: MultiEffect {
                        saturation: -1 + root.develop
                        brightness: 0.55 * (1 - root.develop)
                        contrast: -0.4 * (1 - root.develop)
                    }
                }
            }

            RowLayout {
                anchors.left: parent.left
                anchors.leftMargin: mainPrint.pad + 10 * root.u
                anchors.top: photo.bottom
                anchors.topMargin: 16 * root.u
                spacing: 28 * root.u

                Text {
                    text: LockSession.hour + ":" + LockSession.minute + " " + LockSession.ampm.toLowerCase()
                    color: root.paperInk
                    font.family: root._hand
                    font.pixelSize: Math.round(96 * root.u)
                    renderType: Text.QtRendering
                }

                Text {
                    visible: root.cfg.showDate !== false
                    Layout.alignment: Qt.AlignBaseline
                    text: (LockSession.weekday.slice(0, 3) + " " + LockSession.dayNum + " " + LockSession.month.slice(0, 3)).toLowerCase()
                    color: "#7a5f69"
                    font.family: root._hand
                    font.pixelSize: Math.round(58 * root.u)
                    renderType: Text.QtRendering
                }
            }
        }
    }

    MotionEnter {
        visible: root._music
        x: 880 * root.u
        y: 560 * root.u
        dx: 260 * root.u
        dy: 220 * root.u
        fromRotation: 24
        delay: 900
        animated: root._animated
        exiting: root.exiting

        Print {
            id: albumPrint
            pad: 18 * root.u
            width: 330 * root.u
            height: 300 * root.u + pad + 74 * root.u
            rotation: 7

            Image {
                x: albumPrint.pad
                y: albumPrint.pad
                width: parent.width - albumPrint.pad * 2
                height: 300 * root.u
                source: albumBest.bestUrl !== "" ? albumBest.bestUrl : (ServiceMusic.activeTrack?.artUrl ?? "")
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 600
                smooth: true
                mipmap: true

                BestArt {
                    id: albumBest
                    artUrl: ServiceMusic.activeTrack?.artUrl ?? ""
                    trackKey: (ServiceMusic.activeTrack?.title ?? "") + "|" + (ServiceMusic.activeTrack?.artist ?? "")
                }
                asynchronous: true

                Rectangle {
                    anchors.fill: parent
                    z: -1
                    color: Qt.alpha(root.paperInk, 0.12)
                }
            }

            Text {
                x: albumPrint.pad + 4 * root.u
                y: albumPrint.pad + 300 * root.u + 8 * root.u
                width: parent.width - albumPrint.pad * 2 - 8 * root.u
                elide: Text.ElideRight
                text: ((ServiceMusic.activeTrack?.title ?? "") + " — " + (ServiceMusic.activeTrack?.artist ?? "")).toLowerCase()
                color: root.paperInk
                font.family: root._hand
                font.pixelSize: Math.round(42 * root.u)
                renderType: Text.QtRendering
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: -20 * root.u
                width: 150 * root.u
                height: 44 * root.u
                rotation: -4
                color: Qt.alpha(Qt.tint(root.accent, "#80ffffff"), 0.55)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ServiceMusic.togglePlaying()
            }
        }
    }

    ColumnLayout {
        x: root.width - width - 120 * root.u
        y: 150 * root.u
        width: 520 * root.u
        spacing: 26 * root.u

        MotionEnter {
            delay: 300
            dx: 60 * root.u
            dy: 0
            animated: root._animated
            exiting: root.exiting

            Column {
                spacing: 0
                Text {
                    text: (root.greeter ? "sign in," : LockSession.greeting.toLowerCase() + ",")
                    color: root.accent
                    font.family: root._hand
                    font.pixelSize: Math.round(80 * root.u)
                    renderType: Text.QtRendering
                }
                Text {
                    text: LockSession.user
                    color: root.ink
                    font.family: root._family
                    font.pixelSize: Math.round(84 * root.u)
                    font.weight: 700
                    font.letterSpacing: -1.5 * root.u
                    renderType: Text.QtRendering
                }
            }
        }

        MotionEnter {
            visible: root.cfg.showStatus !== false && !root.greeter && status.entries.length > 0
            Layout.fillWidth: true
            delay: 460
            dx: 320 * root.u
            dy: 0
            animated: root._animated
            exiting: root.exiting

            Rectangle {
                width: 520 * root.u
                height: 170 * root.u
                radius: 4 * root.u
                color: "#0a0708"

                Repeater {
                    model: 2
                    delegate: Row {
                        id: holes
                        required property int index
                        x: 12 * root.u
                        y: holes.index === 0 ? 8 * root.u : parent.height - 20 * root.u
                        spacing: 18 * root.u
                        Repeater {
                            model: 15
                            Rectangle { width: 16 * root.u; height: 12 * root.u; radius: 2 * root.u; color: "#3a2c31" }
                        }
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 10 * root.u

                    Repeater {
                        model: status.entries.slice(0, 3)

                        delegate: Rectangle {
                            id: frame
                            required property var modelData
                            width: 156 * root.u
                            height: 118 * root.u
                            radius: 3 * root.u
                            color: root.plate

                            Column {
                                anchors.centerIn: parent
                                spacing: 4 * root.u
                                MaterialIconSymbol {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    content: frame.modelData.icon
                                    iconSize: Math.round(34 * root.u)
                                    customColor: root.accent
                                }
                                CustomText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: Math.min(implicitWidth, 140 * root.u)
                                    content: frame.modelData.value
                                    size: Math.round(21 * root.u)
                                    weight: 600
                                    customColor: root.ink
                                }
                                CustomText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    content: frame.modelData.name.toUpperCase()
                                    size: Math.round(13 * root.u)
                                    weight: 500
                                    font.letterSpacing: 1.6 * root.u
                                    customColor: root.inkSoft
                                }
                            }
                        }
                    }
                }
            }
        }

        MotionEnter {
            delay: 600
            dx: 60 * root.u
            dy: 0
            animated: root._animated
            exiting: root.exiting

            LockAuthField {
                id: auth
                context: root.context
                fieldWidth: 520 * root.u
                fieldHeight: 78 * root.u
                fieldColor: root.plate
                idleBorder: Qt.alpha(root.accent, 0.3)
                accent: root.accent
                onAccent: root.onAccent
                placeholder: "Password"
                placeholderColor: root.inkSoft
                placeholderSize: Math.round(23 * root.u)
                showLockIcon: false
                submitAlways: true
            }
        }

        MotionEnter {
            visible: root.cfg.showPower !== false
            delay: 700
            dx: 60 * root.u
            dy: 0
            animated: root._animated
            exiting: root.exiting

            LockPowerActions {
                variant: "icons"
                box: 58 * root.u
                iconPx: Math.round(26 * root.u)
                spacing: 12 * root.u
                tone: root.inkSoft
                plate: root.plate
                plateHover: Qt.lighter(root.plate, 1.4)
            }
        }
    }
}
