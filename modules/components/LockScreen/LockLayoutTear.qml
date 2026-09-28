pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import "../Widgets/calendarMath.js" as CalMath

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
    readonly property string _serif: "Noto Serif Display"
    readonly property string _cond: "Fira Sans Condensed"
    readonly property string _hand: "Just Another Hand"
    readonly property bool _music: root.cfg.showMusic !== false && !root.greeter && ServiceMusic.activePlayer !== null
    readonly property bool _status: root.cfg.showStatus !== false && !root.greeter

    readonly property color _p: Colors.primary
    readonly property color paper: Qt.tint("#f4ede3", Qt.alpha(root._p, 0.05))
    readonly property color paperShade: Qt.darker(root.paper, 1.06)
    readonly property color paperDeep: Qt.darker(root.paper, 1.13)
    readonly property color ink: "#2a221b"
    readonly property color inkSoft: "#6d5d4f"
    readonly property color accent: Qt.hsla(root._p.hslHue, Math.min(1, root._p.hslSaturation * 0.9), 0.34, 1)
    readonly property color pen: "#23428a"
    readonly property color band: Qt.hsla(root._p.hslHue, Math.min(1, root._p.hslSaturation * 0.8), 0.62, 1)

    readonly property real padW: 640 * root.u
    readonly property real padH: 880 * root.u

    readonly property real moonAge: {
        LockSession.dayNum
        return CalMath.moonAge(new Date())
    }

    readonly property var nextHoliday: {
        LockSession.dayNum
        const list = ServiceClock.holidayData ?? []
        const now = new Date()
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        let best = null
        for (const h of list) {
            if (!h || !h.date) continue
            const p = String(h.date).split("-")
            const d = new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]))
            const days = Math.round((d - today) / 86400000)
            if (days < 0 || days > 60) continue
            if (!best || days < best.days) best = { name: h.localName || h.name || "", days: days }
        }
        return best
    }

    readonly property string note: {
        if (root.greeter) return "sign in, " + LockSession.user
        const h = root.nextHoliday
        if (h && h.name !== "") {
            if (h.days === 0) return h.name + " today"
            if (h.days === 1) return h.name + " tomorrow"
            return h.name + " in " + h.days + " days"
        }
        return LockSession.greeting.toLowerCase() + ", " + LockSession.user
    }

    readonly property string timeText: LockSession.hour + ":" + LockSession.minute + " " + LockSession.ampm.toLowerCase()
    readonly property real rest: 1 - Math.max(0, Math.min(1, (root.tear - 0.4) / 0.5))

    property real tear: 0
    property real flip: root._animated ? 0 : 1

    SequentialAnimation {
        running: root._animated
        PauseAnimation { duration: 620 }
        NumberAnimation {
            target: root; property: "flip"; to: 1; duration: 620
            easing.type: Easing.BezierSpline; easing.bezierCurve: [0.3, 0.0, 0.2, 1.0, 1, 1]
        }
    }

    onExitingChanged: if (root.exiting && root._animated) tearAnim.restart()

    NumberAnimation {
        id: tearAnim
        target: root
        property: "tear"
        from: 0
        to: 1
        duration: 820
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.35, 0.0, 0.75, 0.3, 1, 1]
    }

    component PaperShadow: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.55)
        shadowBlur: 1.0
        shadowVerticalOffset: 18 * root.u
        autoPaddingEnabled: true
    }

    component PaperPlate: Rectangle {
        radius: 6 * root.u
        bottomLeftRadius: 14 * root.u
        bottomRightRadius: 14 * root.u
        color: root.paper
        layer.enabled: !root.preview
        layer.effect: PaperShadow {}
    }

    component InfoItem: Row {
        property string icon: ""
        property string label: ""
        spacing: 8 * root.u
        MaterialIconSymbol {
            anchors.verticalCenter: parent.verticalCenter
            content: parent.icon
            iconSize: Math.round(26 * root.u)
            customColor: root.accent
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.label
            color: root.inkSoft
            font.family: root._family
            font.pixelSize: Math.round(23 * root.u)
            renderType: Text.QtRendering
        }
    }

    component PageFace: Rectangle {
        id: face
        property int day: LockSession.dayNum
        property string weekday: LockSession.weekday
        property string monthLine: LockSession.month + " " + new Date().getFullYear()
        property bool full: true

        radius: 6 * root.u
        bottomLeftRadius: 14 * root.u
        bottomRightRadius: 14 * root.u
        color: root.paper

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 30 * root.u
            topLeftRadius: face.radius
            topRightRadius: face.radius
            color: root.band
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 76 * root.u
            spacing: 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: face.monthLine.toUpperCase()
                color: root.accent
                font.family: root._cond
                font.pixelSize: Math.round(30 * root.u)
                font.weight: Font.Bold
                font.letterSpacing: 9 * root.u
                renderType: Text.QtRendering
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: face.day
                color: root.ink
                font.family: root._serif
                font.pixelSize: Math.round(330 * root.u)
                font.weight: Font.Medium
                renderType: Text.QtRendering
                height: 350 * root.u
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: face.weekday.toUpperCase()
                color: "#5b4d40"
                font.family: root._cond
                font.pixelSize: Math.round(34 * root.u)
                font.weight: Font.Bold
                font.letterSpacing: 13 * root.u
                renderType: Text.QtRendering
            }
        }
    }

    MotionEnter {
        id: padEnter
        x: (root.width - root.padW) / 2
        y: (root.height - root.padH) / 2 + 10 * root.u
        dy: -150 * root.u
        fromRotation: -4
        fromScale: 1.04
        delay: 80
        animated: root._animated
        exiting: false

        Item {
            id: pad
            width: root.padW
            height: root.padH

            Item {
                anchors.fill: parent
                opacity: root.rest

                Rectangle {
                    x: 14 * root.u
                    width: parent.width - 28 * root.u
                    y: parent.height - 20 * root.u
                    height: 40 * root.u
                    radius: 14 * root.u
                    color: root.paperDeep
                }
                Rectangle {
                    x: 6 * root.u
                    width: parent.width - 12 * root.u
                    y: parent.height - 30 * root.u
                    height: 40 * root.u
                    radius: 14 * root.u
                    color: root.paperShade
                    layer.enabled: !root.preview
                    layer.effect: PaperShadow {}
                }
            }

            PageFace {
                id: nextPage
                opacity: root.rest
                width: parent.width
                height: parent.height
                visible: root.tear > 0
                day: new Date(Date.now() + 86400000).getDate()
                weekday: Qt.formatDate(new Date(Date.now() + 86400000), "dddd")
                monthLine: Qt.formatDate(new Date(Date.now() + 86400000), "MMMM yyyy")
            }

            Item {
                id: page
                width: parent.width
                height: parent.height
                opacity: 1 - Math.max(0, (root.tear - 0.75) / 0.25)

                transform: [
                    Rotation {
                        origin.x: page.width
                        origin.y: 0
                        axis { x: 0; y: 0; z: 1 }
                        angle: -38 * root.tear * root.tear
                    },
                    Rotation {
                        origin.x: page.width / 2
                        origin.y: page.height / 2
                        axis { x: 0; y: 1; z: 0 }
                        angle: 28 * Math.sin(root.tear * Math.PI * 1.5)
                    },
                    Translate {
                        x: -120 * root.u * root.tear
                        y: root.height * 0.95 * root.tear * root.tear
                    }
                ]

                PaperPlate {
                    anchors.fill: parent
                }

                PageFace {
                    id: pageFace
                    anchors.fill: parent
                }

                MotionEnter {
                    x: 0
                    width: parent.width
                    y: 600 * root.u
                    dy: 18 * root.u
                    delay: 900
                    animated: root._animated
                    exiting: false

                    Column {
                        width: page.width
                        spacing: 16 * root.u

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 34 * root.u

                            InfoItem { icon: "schedule"; label: root.timeText }
                            InfoItem { visible: root._status; icon: "dark_mode"; label: CalMath.moonPhaseName(root.moonAge) }
                            InfoItem {
                                visible: root._status && ServiceWeather.currentCondition !== null
                                icon: ServiceWeather.getWeatherIcon(ServiceWeather.weatherCode).icon
                                label: ServiceWeather.temperature
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: page.width - 80 * root.u
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.note + (root.greeter ? "" : " ✎")
                            color: root.pen
                            rotation: -2
                            font.family: root._hand
                            font.pixelSize: Math.round(52 * root.u)
                            renderType: Text.QtRendering
                        }
                    }
                }

                Shape {
                    x: 18 * root.u
                    width: parent.width - 36 * root.u
                    y: parent.height - 118 * root.u
                    height: 2
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: Qt.alpha(root.ink, 0.35)
                        strokeWidth: Math.max(1.5, 3 * root.u)
                        strokeStyle: ShapePath.DashLine
                        dashPattern: [3, 3]
                        fillColor: "transparent"
                        startX: 0; startY: 1
                        PathLine { x: page.width - 36 * root.u; y: 1 }
                    }
                }

                MotionEnter {
                    x: (page.width - 480 * root.u) / 2
                    y: page.height - 104 * root.u
                    dy: 14 * root.u
                    delay: 1050
                    animated: root._animated
                    exiting: false

                    LockAuthField {
                        id: auth
                        context: root.context
                        variant: "line"
                        fieldWidth: 480 * root.u
                        fieldHeight: 62 * root.u
                        accent: root.accent
                        onAccent: root.paper
                        placeholder: root.greeter ? "Tear here · password" : "Tear here — type your password"
                        placeholderColor: root.inkSoft
                        placeholderFamily: root._family
                        placeholderSize: Math.round(22 * root.u)
                        showLockIcon: false
                        showFailureLine: false
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height + 8 * root.u
                    visible: root.context?.showFailure ?? false
                    text: "wrong password — try again"
                    color: Colors.error
                    font.family: root._hand
                    font.pixelSize: Math.round(40 * root.u)
                    renderType: Text.QtRendering
                }
            }

            PageFace {
                id: yesterday
                width: parent.width
                height: parent.height
                visible: root._animated && root.flip < 1
                day: new Date(Date.now() - 86400000).getDate()
                weekday: Qt.formatDate(new Date(Date.now() - 86400000), "dddd")
                monthLine: Qt.formatDate(new Date(Date.now() - 86400000), "MMMM yyyy")
                opacity: 1 - Math.max(0, (root.flip - 0.55) / 0.45)
                transform: [
                    Rotation {
                        origin.x: yesterday.width / 2
                        origin.y: 0
                        axis { x: 1; y: 0; z: 0 }
                        angle: 100 * root.flip
                    },
                    Translate { y: -40 * root.u * root.flip }
                ]
            }

            Shape {
                id: stub
                visible: root.tear > 0
                opacity: root.rest
                width: parent.width
                height: 44 * root.u
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillColor: root.band
                    startX: 0; startY: 0
                    PathLine { x: stub.width; y: 0 }
                    PathLine { x: stub.width; y: 30 * root.u }
                    PathPolyline {
                        path: {
                            const pts = []
                            const n = 28
                            for (let i = 0; i <= n; i++) {
                                const x = stub.width * (1 - i / n)
                                const y = (i % 2 === 0 ? 30 : 40) * root.u + ((i * 7) % 5) * root.u
                                pts.push(Qt.point(x, y))
                            }
                            return pts
                        }
                    }
                    PathLine { x: 0; y: 0 }
                }
            }

            Row {
                x: 64 * root.u
                y: -20 * root.u
                opacity: root.rest
                spacing: (pad.width - 128 * root.u - 4 * 22 * root.u) / 3
                Repeater {
                    model: 4
                    Rectangle {
                        width: 22 * root.u
                        height: 58 * root.u
                        radius: 11 * root.u
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#8d8a86" }
                            GradientStop { position: 0.5; color: "#e6e2dc" }
                            GradientStop { position: 1.0; color: "#8d8a86" }
                        }
                    }
                }
            }
        }
    }

    MotionEnter {
        visible: root._music
        x: (root.width + root.padW) / 2 + 60 * root.u
        y: (root.height - root.padH) / 2 + 150 * root.u
        dx: 180 * root.u
        dy: 40 * root.u
        fromRotation: 14
        delay: 1150
        animated: root._animated
        exiting: root.exiting
        exitDx: 260 * root.u
        exitDy: 0

        Item {
            id: sticky
            width: 300 * root.u
            height: 250 * root.u
            rotation: 4

            Rectangle {
                anchors.fill: parent
                color: Colors.tertiaryContainer
                bottomRightRadius: 26 * root.u
                antialiasing: true
                layer.enabled: !root.preview
                layer.effect: PaperShadow {}
            }

            Column {
                x: 26 * root.u
                y: 22 * root.u
                width: parent.width - 52 * root.u
                spacing: 4 * root.u

                Text {
                    text: "now playing"
                    color: Colors.tertiaryContainerText
                    font.family: root._hand
                    font.pixelSize: Math.round(44 * root.u)
                    renderType: Text.QtRendering
                }
                Text {
                    width: parent.width
                    text: ServiceMusic.activeTrack?.title ?? ""
                    color: Colors.tertiaryContainerText
                    font.family: root._family
                    font.pixelSize: Math.round(26 * root.u)
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    renderType: Text.QtRendering
                }
                Text {
                    width: parent.width
                    text: ServiceMusic.activeTrack?.artist ?? ""
                    color: Qt.alpha(Colors.tertiaryContainerText, 0.75)
                    font.family: root._family
                    font.pixelSize: Math.round(20 * root.u)
                    elide: Text.ElideRight
                    renderType: Text.QtRendering
                }
            }

            MaterialIconSymbol {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 22 * root.u
                content: ServiceMusic.isPlaying ? "pause_circle" : "play_circle"
                iconSize: Math.round(46 * root.u)
                customColor: Colors.tertiaryContainerText
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ServiceMusic.togglePlaying()
            }
        }
    }

    MotionEnter {
        visible: root.cfg.showPower !== false
        x: root.width - width - 64 * root.u
        y: root.height - height - 56 * root.u
        dx: 60 * root.u
        dy: 0
        delay: 1250
        animated: root._animated
        exiting: root.exiting

        LockPowerActions {
            variant: "icons"
            box: 58 * root.u
            iconPx: Math.round(26 * root.u)
            spacing: 12 * root.u
            tone: Colors.surfaceVariantText
            plate: Qt.alpha(Colors.surfaceContainerHigh, 0.8)
            plateHover: Colors.surfaceContainerHighest
        }
    }
}
