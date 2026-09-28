import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Shapes
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Item {
    id: quiet

    property Item owner: null
    property string style: "ruler"

    readonly property var ids: quiet.owner ? quiet.owner.wsIds : []
    readonly property int count: quiet.ids.length
    readonly property int activeId: quiet.owner ? quiet.owner.activeWsId : -1
    readonly property int activeIndex: quiet.ids.indexOf(quiet.activeId)
    readonly property bool needsApps: quiet.style === "focus" || quiet.style === "ring"

    implicitWidth: face.item ? face.item.implicitWidth : 0
    implicitHeight: 30

    function go(id, ws) {
        if (quiet.owner)
            quiet.owner.focusWs(id, ws)
    }

    function step(delta) {
        if (quiet.count === 0)
            return
        const from = Math.max(0, quiet.activeIndex)
        const next = quiet.ids[(from + delta + quiet.count) % quiet.count]
        quiet.go(next, ServiceWorkspaces.getWorkspace(next))
    }

    function mainApp(ws) {
        const tops = ws && ws.toplevels ? ws.toplevels.values : []
        const tally = {}
        let best = ""
        for (let i = 0; i < tops.length; i++) {
            const id = tops[i]?.wayland?.appId ?? ""
            if (!id)
                continue
            tally[id] = (tally[id] ?? 0) + 1
            if (!best || tally[id] > tally[best])
                best = id
        }
        return best
    }

    function appName(appId) {
        if (!appId)
            return ""
        const entry = DesktopEntries.heuristicLookup(appId)
        return entry?.name ?? appId
    }

    function appIcon(appId) {
        return Quickshell.iconPath(DesktopEntries.heuristicLookup(appId)?.icon, "image-missing")
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

    Slot {
        id: current
        wsId: quiet.activeId
        owner: quiet.owner
    }

    readonly property string currentApp: quiet.needsApps ? quiet.mainApp(current.occupied ? current.ws : null) : ""

    Timer {
        id: refresh
        interval: 200
        onTriggered: Hyprland.refreshToplevels()
    }

    Component.onCompleted: if (quiet.needsApps) refresh.restart()

    Connections {
        target: Hyprland
        enabled: quiet.needsApps
        function onRawEvent(event) {
            if (["openwindow", "closewindow", "movewindowv2", "activewindowv2", "workspacev2"].indexOf(event.name) >= 0)
                refresh.restart()
        }
    }

    Loader {
        id: face
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: {
            switch (quiet.style) {
            case "ring":       return ringComp
            case "viewfinder": return viewfinderComp
            case "focus":      return focusComp
            case "cards":      return cardsComp
            }
            return rulerComp
        }
    }

    Component {
        id: rulerComp

        Item {
            id: ruler
            readonly property real pitch: 11
            implicitWidth: quiet.count * ruler.pitch + 12
            implicitHeight: 30

            Repeater {
                model: quiet.ids
                delegate: Item {
                    id: tickCell
                    required property int modelData
                    required property int index
                    Slot { id: st; wsId: tickCell.modelData; owner: quiet.owner }
                    x: tickCell.index * ruler.pitch
                    width: ruler.pitch
                    height: 30

                    Rectangle {
                        x: (ruler.pitch - width) / 2
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                        width: 2
                        radius: 1
                        height: st.active ? 18 : st.occupied ? 11 : 5
                        color: st.active ? Colors.primary
                             : st.occupied ? Colors.surfaceVariantText
                             : st.onOther ? Qt.alpha(Colors.outlineVariant, 0.5) : Colors.outlineVariant
                        Behavior on height { SpatialAnim { speed: "fast" } }
                        Behavior on color { EffectsColorAnim {} }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: quiet.go(tickCell.modelData, st.ws)
                    }
                }
            }

            CustomText {
                visible: quiet.activeIndex >= 0
                x: Math.max(0, quiet.activeIndex) * ruler.pitch + ruler.pitch / 2 + 3
                y: 2
                content: quiet.activeId.toString()
                size: 9
                weight: 800
                customColor: Colors.primary
                Behavior on x { SpatialAnim { speed: "fast" } }
            }
        }
    }

    Component {
        id: ringComp

        Item {
            id: ringFace
            readonly property real side: 28
            readonly property real gap: quiet.count > 6 ? 11 : 14
            implicitWidth: ringFace.side + 8 + caption.implicitWidth + 4
            implicitHeight: 30

            Item {
                id: dial
                width: ringFace.side
                height: ringFace.side
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: quiet.ids
                    delegate: Shape {
                        id: arc
                        required property int modelData
                        required property int index
                        Slot { id: st; wsId: arc.modelData; owner: quiet.owner }
                        readonly property real span: 360 / Math.max(1, quiet.count)
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            fillColor: "transparent"
                            capStyle: ShapePath.FlatCap
                            strokeWidth: st.active ? 4.5 : 3
                            strokeColor: st.active ? Colors.primary
                                       : st.occupied ? Colors.secondary
                                       : Colors.surfaceContainerHighest
                            Behavior on strokeWidth { SpatialAnim { speed: "fast" } }
                            Behavior on strokeColor { EffectsColorAnim {} }

                            PathAngleArc {
                                centerX: ringFace.side / 2
                                centerY: ringFace.side / 2
                                radiusX: ringFace.side / 2 - 3
                                radiusY: ringFace.side / 2 - 3
                                startAngle: -90 + arc.index * arc.span + ringFace.gap / 2
                                sweepAngle: arc.span - ringFace.gap
                            }
                        }
                    }
                }

                CustomText {
                    anchors.centerIn: parent
                    content: quiet.activeIndex >= 0 ? quiet.activeId.toString() : ""
                    size: 10
                    weight: 800
                    customColor: Colors.surfaceText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        const dx = mouse.x - width / 2
                        const dy = mouse.y - height / 2
                        const deg = (Math.atan2(dy, dx) * 180 / Math.PI + 90 + 360) % 360
                        const i = Math.min(quiet.count - 1, Math.floor(deg / (360 / Math.max(1, quiet.count))))
                        if (i >= 0)
                            quiet.go(quiet.ids[i], ServiceWorkspaces.getWorkspace(quiet.ids[i]))
                    }
                    onWheel: wheel => {
                        const d = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                        if (d !== 0)
                            quiet.step(d > 0 ? -1 : 1)
                    }
                }
            }

            CustomText {
                id: caption
                x: ringFace.side + 8
                anchors.verticalCenter: parent.verticalCenter
                content: quiet.currentApp ? quiet.appName(quiet.currentApp) : "Empty"
                size: 11
                weight: 500
                customColor: quiet.currentApp ? Colors.surfaceVariantText : Colors.outline
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 110)
            }
        }
    }

    Component {
        id: viewfinderComp

        Item {
            id: vf
            readonly property real cell: 20
            implicitWidth: quiet.count * vf.cell
            implicitHeight: 30

            Row {
                Repeater {
                    model: quiet.ids
                    delegate: Item {
                        id: vfCell
                        required property int modelData
                        Slot { id: st; wsId: vfCell.modelData; owner: quiet.owner }
                        width: vf.cell
                        height: 30

                        CustomText {
                            anchors.centerIn: parent
                            content: vfCell.modelData.toString()
                            size: 12
                            weight: st.active ? 700 : 500
                            customColor: st.active ? Colors.primary
                                       : st.occupied ? Colors.surfaceVariantText : Colors.outline
                            opacity: st.active || st.occupied ? 1 : 0.5
                            Behavior on customColor { EffectsColorAnim {} }
                            Behavior on opacity { EffectsAnim {} }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: quiet.go(vfCell.modelData, st.ws)
                        }
                    }
                }
            }

            Item {
                id: frame
                visible: quiet.activeIndex >= 0
                x: Math.max(0, quiet.activeIndex) * vf.cell
                y: 3
                width: vf.cell
                height: 24
                Behavior on x { SpatialAnim { speed: "fast" } }

                Repeater {
                    model: 4
                    delegate: Item {
                        id: corner
                        required property int index
                        readonly property bool atRight: corner.index % 2 === 1
                        readonly property bool atBottom: corner.index > 1
                        x: corner.atRight ? frame.width - width : 0
                        y: corner.atBottom ? frame.height - height : 0
                        width: 6
                        height: 6

                        Rectangle {
                            y: corner.atBottom ? parent.height - 2 : 0
                            width: parent.width
                            height: 2
                            radius: 1
                            color: Colors.primary
                        }

                        Rectangle {
                            x: corner.atRight ? parent.width - 2 : 0
                            width: 2
                            height: parent.height
                            radius: 1
                            color: Colors.primary
                        }
                    }
                }
            }
        }
    }

    Component {
        id: focusComp

        Row {
            spacing: 5

            Repeater {
                model: quiet.ids
                delegate: Item {
                    id: fp
                    required property int modelData
                    Slot { id: st; wsId: fp.modelData; owner: quiet.owner }
                    width: pill.width
                    height: 30

                    Rectangle {
                        id: pill
                        anchors.verticalCenter: parent.verticalCenter
                        width: st.active ? content.implicitWidth + 16 : st.occupied ? 8 : 6
                        height: st.active ? 24 : st.occupied ? 8 : 6
                        radius: height / 2
                        clip: true
                        color: st.active ? Colors.primary
                             : st.occupied ? Colors.surfaceVariantText
                             : st.onOther ? Qt.alpha(Colors.outlineVariant, 0.5) : Colors.outlineVariant
                        Behavior on width { SpatialAnim { speed: "fast" } }
                        Behavior on height { SpatialAnim { speed: "fast" } }
                        Behavior on color { EffectsColorAnim {} }

                        Row {
                            id: content
                            x: 6
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5
                            opacity: st.active ? 1 : 0
                            visible: opacity > 0
                            Behavior on opacity { EffectsAnim {} }

                            IconImage {
                                visible: !!quiet.currentApp
                                anchors.verticalCenter: parent.verticalCenter
                                implicitSize: 15
                                source: quiet.currentApp && st.active ? quiet.appIcon(quiet.currentApp) : ""
                            }

                            MaterialIconSymbol {
                                visible: !quiet.currentApp
                                anchors.verticalCenter: parent.verticalCenter
                                content: "add"
                                iconSize: 15
                                customColor: Colors.primaryText
                            }

                            CustomText {
                                anchors.verticalCenter: parent.verticalCenter
                                content: quiet.currentApp ? quiet.appName(quiet.currentApp) : "Empty"
                                size: 11
                                weight: 600
                                customColor: Colors.primaryText
                                elide: Text.ElideRight
                                width: Math.min(implicitWidth, 96)
                            }

                            CustomText {
                                visible: current.windows > 1
                                anchors.verticalCenter: parent.verticalCenter
                                content: current.windows.toString()
                                size: 10
                                weight: 500
                                customColor: Qt.alpha(Colors.primaryText, 0.7)
                            }

                            Item { width: 2; height: 1 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.leftMargin: -2
                        anchors.rightMargin: -2
                        cursorShape: Qt.PointingHandCursor
                        onClicked: quiet.go(fp.modelData, st.ws)
                    }
                }
            }
        }
    }

    Component {
        id: cardsComp

        Rectangle {
            id: deck
            readonly property real cardW: 20
            readonly property real overlap: 5
            implicitWidth: deckRow.implicitWidth + deck.overlap + 10
            implicitHeight: 30
            radius: 15
            color: Colors.surfaceContainer

            Row {
                id: deckRow
                x: 5
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: quiet.ids
                    delegate: Item {
                        id: slot
                        required property int modelData
                        required property int index
                        Slot { id: st; wsId: slot.modelData; owner: quiet.owner }
                        readonly property bool shownCard: st.occupied || st.active
                        width: slot.shownCard ? deck.cardW - deck.overlap + (st.active ? 3 : 0) : 0
                        height: 30
                        z: st.active ? 50 : 40 - Math.abs(slot.index - Math.max(0, quiet.activeIndex))
                        Behavior on width { SpatialAnim { speed: "fast" } }

                        Rectangle {
                            id: card
                            width: deck.cardW + (st.active ? 3 : 0)
                            height: 22
                            y: st.active ? 2 : 5
                            radius: 6
                            opacity: slot.shownCard ? 1 : 0
                            color: st.active ? Colors.primary : Colors.surfaceContainerHighest
                            border.width: 2
                            border.color: Colors.surfaceContainer
                            Behavior on y { SpatialAnim { speed: "fast" } }
                            Behavior on width { SpatialAnim { speed: "fast" } }
                            Behavior on opacity { EffectsAnim {} }
                            Behavior on color { EffectsColorAnim {} }

                            CustomText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 3
                                content: slot.modelData.toString()
                                size: 9
                                weight: 700
                                customColor: st.active ? Colors.primaryText : Colors.surfaceVariantText
                            }
                        }

                        MouseArea {
                            anchors.fill: card
                            enabled: slot.shownCard
                            cursorShape: Qt.PointingHandCursor
                            onClicked: quiet.go(slot.modelData, st.ws)
                        }
                    }
                }
            }
        }
    }
}
