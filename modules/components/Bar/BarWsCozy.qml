import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Item {
    id: cozy

    property Item owner: null
    property string style: "lanterns"

    readonly property var ids: cozy.owner ? cozy.owner.wsIds : []
    readonly property int count: cozy.ids.length
    readonly property int activeId: cozy.owner ? cozy.owner.activeWsId : -1

    implicitWidth: face.item ? face.item.implicitWidth : 0
    implicitHeight: 32

    function go(id, ws) {
        if (cozy.owner)
            cozy.owner.focusWs(id, ws)
    }

    function isActive(id) {
        if (!cozy.owner)
            return false
        if (cozy.owner.perMonitorMode)
            return id === cozy.activeId
        const w = ServiceWorkspaces.getWorkspace(id)
        return !!w && w.active
    }

    component Slot: QtObject {
        required property int wsId
        property Item owner: null
        readonly property var ws: ServiceWorkspaces.getWorkspace(wsId)
        readonly property bool onOther: !!owner && owner.perMonitorMode && !!ws && !!ws.monitor
            && ws.monitor.name !== owner.screenName
        readonly property bool occupied: !!ws && !onOther
        readonly property bool active: !!owner && !onOther && (owner.perMonitorMode ? wsId === owner.activeWsId
                                                                                     : (!!ws && ws.active))
        readonly property int windows: occupied && ws.toplevels ? ws.toplevels.values.length : 0
    }

    Loader {
        id: face
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: {
            switch (cozy.style) {
            case "books":   return booksComp
            case "house":   return houseComp
            case "moons":   return moonsComp
            case "stars":   return starsComp
            case "map":     return mapComp
            case "dial":    return dialComp
            case "candles": return candlesComp
            }
            return lanternsComp
        }
    }

    Component {
        id: lanternsComp

        Item {
            id: lf
            readonly property real slot: 20
            implicitWidth: cozy.count * lf.slot + 12
            implicitHeight: 32

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Qt.alpha(Colors.outline, 0.6)
                    strokeWidth: 1
                    fillColor: "transparent"
                    startX: 3
                    startY: 5
                    PathQuad { x: lf.width - 3; y: 5; controlX: lf.width / 2; controlY: 15 }
                }
            }

            Repeater {
                model: cozy.ids
                delegate: Item {
                    id: lan
                    required property int modelData
                    required property int index
                    Slot { id: st; wsId: lan.modelData; owner: cozy.owner }

                    readonly property real cx: 6 + (lan.index + 0.5) * lf.slot
                    readonly property real t: (lan.cx - 3) / Math.max(1, lf.width - 6)
                    readonly property real sy: 5 + 20 * lan.t * (1 - lan.t)

                    x: lan.cx - 10
                    width: 20
                    height: 32

                    Rectangle {
                        x: -2
                        y: lan.sy + 1
                        width: 24
                        height: 24
                        radius: 12
                        color: Colors.primaryContainer
                        opacity: st.active ? 0.3 : 0
                        Behavior on opacity { EffectsAnim {} }
                    }

                    Item {
                        id: swing
                        y: lan.sy
                        width: 20
                        height: 20
                        transformOrigin: Item.Top

                        SequentialAnimation on rotation {
                            running: st.active
                            loops: Animation.Infinite
                            alwaysRunToEnd: true
                            NumberAnimation { to: 5; duration: 1300; easing.type: Easing.InOutSine }
                            NumberAnimation { to: -5; duration: 2600; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0; duration: 1300; easing.type: Easing.InOutSine }
                        }

                        Rectangle {
                            x: 9.5
                            width: 1
                            height: 4
                            color: Qt.alpha(Colors.outline, 0.6)
                        }

                        Rectangle {
                            width: st.active ? 12 : st.occupied ? 10 : 9
                            height: st.active ? 15 : st.occupied ? 13 : 12
                            x: 10 - width / 2
                            y: 4
                            radius: st.active ? 5 : 4.5
                            color: st.active ? Colors.primaryContainer
                                 : st.occupied ? Qt.darker(Colors.primaryContainer, 1.9) : "transparent"
                            border.width: st.active || st.occupied ? 0 : 1.2
                            border.color: Colors.outlineVariant
                            Behavior on width { SpatialAnim { speed: "fast" } }
                            Behavior on height { SpatialAnim { speed: "fast" } }
                            Behavior on color { EffectsColorAnim {} }

                            Rectangle {
                                anchors.centerIn: parent
                                visible: st.occupied && !st.active
                                width: 4
                                height: 7
                                radius: 2
                                color: Colors.primary
                                opacity: 0.55
                            }

                            CustomText {
                                anchors.centerIn: parent
                                visible: st.active
                                content: lan.modelData
                                size: 8
                                weight: 700
                                customColor: Colors.primaryContainerText
                            }
                        }

                        Rectangle {
                            x: 7
                            y: 2.5
                            width: 6
                            height: 2
                            radius: 1
                            color: Colors.outline
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cozy.go(lan.modelData, st.ws)
                    }
                }
            }
        }
    }

    Component {
        id: booksComp

        Item {
            implicitWidth: bookRow.implicitWidth + 4
            implicitHeight: 32

            Rectangle {
                y: 28
                width: parent.width
                height: 2.5
                radius: 1.2
                color: Colors.outline
                opacity: 0.7
            }

            Row {
                id: bookRow
                x: 2
                height: 28
                spacing: 2.5

                Repeater {
                    model: cozy.ids
                    delegate: Item {
                        id: bk
                        required property int modelData
                        Slot { id: st; wsId: bk.modelData; owner: cozy.owner }
                        readonly property var tones: [Colors.secondary, Colors.tertiaryContainer, Colors.primaryContainer,
                                                      Colors.surfaceVariantText, Colors.secondaryContainerText]

                        width: st.active ? 13 : st.occupied ? 8 : 4
                        height: 28
                        Behavior on width { SpatialAnim { speed: "fast" } }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: st.active ? 25 : st.occupied ? Math.min(24, 15 + st.windows * 2) : 12
                            radius: 1.8
                            transformOrigin: Item.BottomRight
                            rotation: !st.occupied && !st.active && bk.modelData % 3 === 0 ? -9 : 0
                            color: st.active ? Colors.primary
                                 : st.occupied ? bk.tones[bk.modelData % bk.tones.length] : Colors.surfaceContainerHighest
                            Behavior on height { SpatialAnim { speed: "fast" } }
                            Behavior on rotation { SpatialAnim { speed: "fast" } }
                            Behavior on color { EffectsColorAnim {} }

                            Rectangle {
                                visible: st.occupied && !st.active
                                y: 3
                                width: parent.width
                                height: 1.4
                                color: Colors.surface
                                opacity: 0.35
                            }

                            CustomText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 2
                                visible: st.active
                                content: bk.modelData
                                size: 8
                                weight: 700
                                customColor: Colors.primaryText
                            }

                            Rectangle {
                                visible: st.active
                                x: 2
                                y: 15
                                width: parent.width - 4
                                height: 1.6
                                color: Colors.primaryText
                                opacity: 0.5
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cozy.go(bk.modelData, st.ws)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: houseComp

        Item {
            id: hf
            readonly property real win: 12
            readonly property real gap: 5
            readonly property bool anyOpen: (Hyprland.toplevels?.values?.length ?? 0) > 0
            implicitWidth: 14 + cozy.count * hf.win + (cozy.count - 1) * hf.gap
            implicitHeight: 32

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Qt.alpha(Colors.surfaceVariantText, 0.55)
                    strokeWidth: 1.4
                    fillColor: "transparent"
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap
                    startX: 3
                    startY: 13
                    PathLine { x: hf.width / 2; y: 3 }
                    PathLine { x: hf.width - 3; y: 13 }
                }
                ShapePath {
                    strokeColor: Qt.alpha(Colors.outline, 0.6)
                    strokeWidth: 1.2
                    fillColor: "transparent"
                    startX: 2
                    startY: 29.5
                    PathLine { x: hf.width - 2; y: 29.5 }
                }
            }

            Rectangle {
                id: chimney
                x: hf.width - 27
                y: 4
                width: 6
                height: 6
                color: Colors.surfaceVariantText
                opacity: 0.45
            }

            Repeater {
                model: 3
                delegate: Rectangle {
                    id: puff
                    required property int index
                    x: chimney.x + 1
                    width: 4
                    height: 4
                    radius: 2
                    color: Colors.surfaceVariantText
                    opacity: 0
                    visible: hf.anyOpen

                    SequentialAnimation {
                        running: hf.anyOpen
                        loops: Animation.Infinite
                        PauseAnimation { duration: puff.index * 900 }
                        ParallelAnimation {
                            NumberAnimation { target: puff; property: "y"; from: 3; to: -4; duration: 2700; easing.type: Easing.OutSine }
                            NumberAnimation { target: puff; property: "x"; from: chimney.x + 1; to: chimney.x + 4; duration: 2700 }
                            NumberAnimation { target: puff; property: "scale"; from: 0.6; to: 1.4; duration: 2700 }
                            SequentialAnimation {
                                NumberAnimation { target: puff; property: "opacity"; from: 0; to: 0.35; duration: 700 }
                                NumberAnimation { target: puff; property: "opacity"; to: 0; duration: 2000 }
                            }
                        }
                        PauseAnimation { duration: (2 - puff.index) * 900 }
                    }
                }
            }

            Row {
                x: 7
                y: 15
                spacing: hf.gap

                Repeater {
                    model: cozy.ids
                    delegate: Item {
                        id: pane
                        required property int modelData
                        Slot { id: st; wsId: pane.modelData; owner: cozy.owner }
                        width: hf.win
                        height: hf.win

                        Rectangle {
                            anchors.centerIn: parent
                            width: hf.win + 6
                            height: hf.win + 6
                            radius: 4
                            color: Colors.primaryContainer
                            opacity: st.active ? 0.25 : 0
                            Behavior on opacity { EffectsAnim {} }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 2
                            color: st.active ? Colors.primary
                                 : st.occupied ? Qt.alpha(Colors.primaryContainer, 0.55) : Colors.surfaceContainerHighest
                            border.width: 1
                            border.color: Colors.outlineVariant
                            Behavior on color { EffectsColorAnim {} }
                        }

                        Rectangle {
                            x: hf.win / 2 - 0.5
                            width: 1
                            height: hf.win
                            color: Colors.surface
                            opacity: 0.55
                        }

                        Rectangle {
                            y: hf.win / 2 - 0.5
                            width: hf.win
                            height: 1
                            color: Colors.surface
                            opacity: 0.55
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -2
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cozy.go(pane.modelData, st.ws)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: moonsComp

        Item {
            implicitWidth: cozy.count * 19 + 6
            implicitHeight: 32

            Repeater {
                model: cozy.ids
                delegate: Item {
                    id: mn
                    required property int modelData
                    required property int index
                    Slot { id: st; wsId: mn.modelData; owner: cozy.owner }

                    readonly property real r: 6.2
                    readonly property real cx: 9.5
                    readonly property real cy: 12
                    readonly property real frac: Math.min(st.windows, 4) / 4

                    x: 3 + mn.index * 19
                    width: 19
                    height: 32

                    Rectangle {
                        x: mn.cx - width / 2
                        y: mn.cy - height / 2
                        width: (mn.r + 3.2) * 2
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 1.4
                        border.color: Colors.primary
                        opacity: st.active ? 1 : 0
                        scale: st.active ? 1 : 0.7
                        Behavior on opacity { EffectsAnim {} }
                        Behavior on scale { SpatialAnim { speed: "fast" } }
                    }

                    Rectangle {
                        x: mn.cx - width / 2
                        y: mn.cy - height / 2
                        width: st.occupied ? mn.r * 2 : (mn.r - 0.6) * 2
                        height: width
                        radius: width / 2
                        color: st.occupied ? Colors.surfaceContainerHighest : "transparent"
                        border.width: st.occupied ? 0 : 1.2
                        border.color: Colors.outlineVariant
                    }

                    Shape {
                        anchors.fill: parent
                        visible: st.occupied && mn.frac > 0
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeWidth: 0
                            strokeColor: "transparent"
                            fillColor: st.active ? Colors.primary : Colors.secondary
                            startX: mn.cx
                            startY: mn.cy - mn.r
                            PathArc {
                                x: mn.cx
                                y: mn.cy + mn.r
                                radiusX: mn.r
                                radiusY: mn.r
                                direction: PathArc.Clockwise
                            }
                            PathArc {
                                x: mn.cx
                                y: mn.cy - mn.r
                                radiusX: Math.max(0.01, mn.r * Math.abs(1 - 2 * mn.frac))
                                radiusY: mn.r
                                direction: mn.frac > 0.5 ? PathArc.Clockwise : PathArc.Counterclockwise
                            }
                        }
                    }

                    CustomText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 22
                        visible: st.active
                        content: mn.modelData
                        size: 8
                        weight: 700
                        customColor: Colors.primary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cozy.go(mn.modelData, st.ws)
                    }
                }
            }
        }
    }

    Component {
        id: starsComp

        Item {
            id: cf
            readonly property var ys: [18, 9, 20, 12, 22, 10, 17]
            implicitWidth: cozy.count * 19 + 6
            implicitHeight: 32

            function px(i) { return 3 + (i + 0.5) * 19 }
            function py(i) { return cf.ys[i % cf.ys.length] }

            readonly property var lit: {
                const out = []
                for (let i = 0; i < cozy.ids.length; i++) {
                    const w = ServiceWorkspaces.getWorkspace(cozy.ids[i])
                    if (w || cozy.isActive(cozy.ids[i]))
                        out.push(i)
                }
                return out
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Qt.alpha(Colors.surfaceVariantText, 0.35)
                    strokeWidth: 1
                    fillColor: "transparent"
                    PathPolyline { path: cf.lit.map(i => Qt.point(cf.px(i), cf.py(i))) }
                }
            }

            Repeater {
                model: cozy.ids
                delegate: Item {
                    id: star
                    required property int modelData
                    required property int index
                    Slot { id: st; wsId: star.modelData; owner: cozy.owner }

                    readonly property real rad: st.active ? 8 : st.occupied ? 3 + Math.min(st.windows, 4) : 0

                    x: cf.px(star.index) - 9
                    y: cf.py(star.index) - 9
                    width: 18
                    height: 18

                    Rectangle {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        radius: 9
                        color: Colors.primary
                        opacity: st.active ? 0.22 : 0
                        Behavior on opacity { EffectsAnim {} }
                    }

                    Shape {
                        id: sparkle
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        visible: star.rad > 0
                        preferredRendererType: Shape.CurveRenderer

                        SequentialAnimation on scale {
                            running: st.active
                            loops: Animation.Infinite
                            alwaysRunToEnd: true
                            NumberAnimation { to: 0.8; duration: 1100; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 1100; easing.type: Easing.InOutSine }
                        }

                        ShapePath {
                            strokeWidth: 0
                            strokeColor: "transparent"
                            fillColor: st.active ? Colors.primary : Colors.secondary
                            PathSvg {
                                path: {
                                    const r = star.rad
                                    const k = r * 0.28
                                    return `M9,${9 - r} Q${9 + k},${9 - k} ${9 + r},9 Q${9 + k},${9 + k} 9,${9 + r} `
                                         + `Q${9 - k},${9 + k} ${9 - r},9 Q${9 - k},${9 - k} 9,${9 - r} Z`
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        visible: star.rad === 0
                        width: 2.6
                        height: 2.6
                        radius: 1.3
                        color: Colors.outline
                        opacity: 0.6
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cozy.go(star.modelData, st.ws)
                    }
                }
            }
        }
    }

    Component {
        id: mapComp

        Item {
            implicitWidth: mapRow.implicitWidth + 4
            implicitHeight: 32

            Timer {
                id: refresh
                interval: 200
                onTriggered: Hyprland.refreshToplevels()
            }

            Component.onCompleted: refresh.restart()

            Connections {
                target: Hyprland
                function onRawEvent(event) {
                    if (["openwindow", "closewindow", "movewindowv2", "changefloatingmode", "fullscreen",
                         "activewindowv2", "workspacev2"].indexOf(event.name) >= 0)
                        refresh.restart()
                }
            }

            Row {
                id: mapRow
                x: 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: cozy.ids
                    delegate: Item {
                        id: fr
                        required property int modelData
                        Slot { id: st; wsId: fr.modelData; owner: cozy.owner }
                        readonly property bool shownFull: st.occupied || st.active

                        anchors.verticalCenter: parent.verticalCenter
                        width: st.active ? 30 : st.occupied ? 24 : 5
                        height: st.active ? 20 : st.occupied ? 16 : 12
                        Behavior on width { SpatialAnim { speed: "fast" } }
                        Behavior on height { SpatialAnim { speed: "fast" } }

                        Rectangle {
                            anchors.fill: parent
                            radius: fr.shownFull ? 4.5 : 2.5
                            color: st.active ? Qt.alpha(Colors.primary, 0.16)
                                 : st.occupied ? Colors.surfaceContainer : Colors.surfaceContainerHighest
                            border.width: fr.shownFull ? (st.active ? 1.4 : 1) : 0
                            border.color: st.active ? Colors.primary : Colors.outlineVariant
                        }

                        Item {
                            id: stage
                            anchors.fill: parent
                            anchors.margins: 2.5
                            visible: st.occupied
                            clip: true

                            readonly property var mon: st.ws ? st.ws.monitor : null
                            readonly property real mx: stage.mon ? stage.mon.x : 0
                            readonly property real my: stage.mon ? stage.mon.y : 0
                            readonly property real mw: cozy.owner ? cozy.owner.screenW : 1920
                            readonly property real mh: cozy.owner ? cozy.owner.screenH : 1080

                            Repeater {
                                model: st.ws ? st.ws.toplevels : null
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property var geo: modelData?.lastIpcObject ?? null
                                    readonly property bool placed: !!geo && !!geo.size && geo.size[0] > 0 && geo.size[1] > 0
                                    visible: placed
                                    x: placed ? (geo.at[0] - stage.mx) / stage.mw * stage.width : 0
                                    y: placed ? (geo.at[1] - stage.my) / stage.mh * stage.height : 0
                                    width: placed ? Math.max(2, geo.size[0] / stage.mw * stage.width - 1) : 0
                                    height: placed ? Math.max(2, geo.size[1] / stage.mh * stage.height - 1) : 0
                                    radius: 1.2
                                    color: st.active ? Colors.primary : Qt.alpha(Colors.surfaceVariantText, 0.5)
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cozy.go(fr.modelData, st.ws)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: dialComp

        Item {
            id: df
            readonly property real a0: 135
            readonly property real a1: 405
            readonly property int activeIndex: Math.max(0, cozy.ids.indexOf(cozy.activeId))
            implicitWidth: 44 + label.implicitWidth + 6
            implicitHeight: 32

            function ang(i) { return df.a0 + (df.a1 - df.a0) * i / Math.max(1, cozy.count - 1) }

            function step(d) {
                const n = cozy.count
                if (n === 0)
                    return
                const next = cozy.ids[(df.activeIndex + d + n) % n]
                cozy.go(next, ServiceWorkspaces.getWorkspace(next))
            }

            Rectangle {
                x: 3
                y: 3
                width: 26
                height: 26
                radius: 13
                color: Colors.surfaceContainerHigh
            }

            Repeater {
                model: cozy.ids
                delegate: Item {
                    id: tick
                    required property int modelData
                    required property int index
                    Slot { id: st; wsId: tick.modelData; owner: cozy.owner }
                    x: 16
                    y: 16
                    rotation: df.ang(tick.index)

                    Rectangle {
                        x: 15
                        y: -1
                        width: 3.5
                        height: 2
                        radius: 1
                        color: st.active ? Colors.primary : st.occupied ? Colors.secondary : Colors.outlineVariant
                        opacity: st.active || !st.occupied ? 1 : 0.8
                    }
                }
            }

            Item {
                x: 16
                y: 16
                rotation: df.ang(df.activeIndex)
                Behavior on rotation { SpatialAnim {} }

                Rectangle {
                    x: -1.5
                    y: -1.5
                    width: 12
                    height: 3
                    radius: 1.5
                    color: Colors.primary
                }
            }

            Rectangle {
                x: 12.8
                y: 12.8
                width: 6.4
                height: 6.4
                radius: 3.2
                color: Colors.primary
            }

            Row {
                id: label
                x: 38
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                CustomText {
                    anchors.verticalCenter: parent.verticalCenter
                    content: cozy.activeId > 0 ? cozy.activeId : "–"
                    size: 16
                    weight: 800
                    font.features: { "tnum": 1 }
                }
                CustomText {
                    anchors.verticalCenter: parent.verticalCenter
                    content: "/ " + cozy.count
                    size: 10
                    weight: 500
                    customColor: Colors.outline
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => df.step(mouse.button === Qt.RightButton ? -1 : 1)
                onWheel: wheel => {
                    const d = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                    if (d !== 0)
                        df.step(d > 0 ? -1 : 1)
                }
            }
        }
    }

    Component {
        id: candlesComp

        Item {
            implicitWidth: cozy.count * 16 + 8
            implicitHeight: 32

            Rectangle {
                y: 28
                width: parent.width
                height: 2.5
                radius: 1.2
                color: Colors.outline
                opacity: 0.6
            }

            Repeater {
                model: cozy.ids
                delegate: Item {
                    id: cd
                    required property int modelData
                    required property int index
                    Slot { id: st; wsId: cd.modelData; owner: cozy.owner }

                    readonly property var hs: [13, 16, 11, 15, 12, 14, 10]
                    readonly property real h: cd.hs[cd.index % cd.hs.length] + (st.active ? 3 : 0)
                    readonly property bool lit: st.occupied || st.active
                    readonly property real fh: st.active ? 9 : 5 + Math.min(st.windows, 3)
                    readonly property real fw: st.active ? 3.6 : 2.6

                    x: 4 + cd.index * 16
                    width: 16
                    height: 32

                    Rectangle {
                        x: 8 - 8
                        y: 28 - cd.h - 15
                        width: 16
                        height: 16
                        radius: 8
                        color: Colors.primaryContainer
                        opacity: st.active ? 0.25 : 0
                        Behavior on opacity { EffectsAnim {} }
                    }

                    Rectangle {
                        x: 4.8
                        y: 28 - cd.h
                        width: 6.4
                        height: cd.h
                        radius: 1.5
                        color: Colors.surfaceText
                        opacity: cd.lit ? 0.85 : 0.3
                        Behavior on y { SpatialAnim { speed: "fast" } }
                        Behavior on height { SpatialAnim { speed: "fast" } }
                    }

                    Rectangle {
                        x: 7.5
                        y: 28 - cd.h - 2.2
                        width: 1
                        height: 2.2
                        color: Colors.outline
                    }

                    Shape {
                        x: 8
                        y: 28 - cd.h - 2
                        visible: cd.lit
                        preferredRendererType: Shape.CurveRenderer
                        transform: Scale {
                            id: flick
                            yScale: 1
                        }

                        SequentialAnimation {
                            running: cd.lit
                            loops: Animation.Infinite
                            NumberAnimation { target: flick; property: "yScale"; to: 1.12; duration: 380 + cd.index * 47; easing.type: Easing.InOutSine }
                            NumberAnimation { target: flick; property: "yScale"; to: 0.9; duration: 460 + cd.index * 31; easing.type: Easing.InOutSine }
                        }

                        ShapePath {
                            strokeWidth: 0
                            strokeColor: "transparent"
                            fillColor: st.active ? Colors.primary : Colors.primaryContainer
                            PathSvg {
                                path: `M0,${-cd.fh} C${cd.fw},${-cd.fh * 0.45} ${cd.fw},0 0,0 C${-cd.fw},0 ${-cd.fw},${-cd.fh * 0.45} 0,${-cd.fh} Z`
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cozy.go(cd.modelData, st.ws)
                    }
                }
            }
        }
    }
}
