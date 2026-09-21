import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.settings
import qs.modules.components.Bar.DashboardSections
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MatrialShapeFn
import "DashOps.js" as DashOps

Item{
    id: root
    anchors.fill: parent

    implicitHeight: cols.implicitHeight + root.pad * 2
    readonly property real pad: root.compact ? 7 : 10
    readonly property int autoColumns: root.width >= 900 ? 3 : root.width >= 520 ? 2 : 1
    readonly property int fitColumns: Math.max(1, Math.floor(root.width / 260))
    readonly property int columnCount: DashLayout.columnsSetting > 0
        ? Math.min(DashLayout.columnsSetting, root.fitColumns) : root.autoColumns
    readonly property bool hasNotifications: DashLayout.visibleIds.indexOf("notifications") >= 0
    readonly property bool split: root.columnCount > 1 && root.hasNotifications
    readonly property bool short: root.height > 0 && root.height < 380
    readonly property bool dense: DashLayout.density === "compact" ? true
        : DashLayout.density === "comfortable" ? root.compact
        : (root.compact || root.short)
    readonly property int stackColumns: Math.min(2, root.split ? root.columnCount - 1 : root.columnCount)

    onSplitChanged: root.syncSections()
    onStackColumnsChanged: root.syncSections()
    property string panelMode: ""   // "" | "wifi" | "bluetooth" | "modes"
    property bool   compact:   false

    property var parentPos
    property var wifiPos
    property var bluetoothPos
    property var pos
    property var srcSize: null
    property real srcRadius: 20


    readonly property bool isPill: SettingsConfig.general.barMode === "pill"

    readonly property int morphOpen: M3Motion.spatial.slowDuration
    readonly property int morphClose: M3Motion.spatial.defaultDuration

    property string activeMode: ""
    property bool panelVisible: false

    onPanelModeChanged: {
        closeTimer.stop()
        contentTimer.stop()
        if (root.panelMode !== "") {
            root.activeMode = root.panelMode
            root.panelVisible = true
            contentTimer.restart()
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: root.morphClose
        onTriggered: {
            panelLoader.active = false
            root.panelVisible = false
            root.activeMode = ""
        }
    }

    opacity: 0
    scale: root.isPill ? 1 : 0.8

    NumberAnimation on opacity {
        from: 0; to: 1; duration: 400; running: true
    }

    NumberAnimation on scale {
        from: root.isPill ? 1 : 0.8
        to: 1
        duration: 400
        running: true
    }


    Connections {
        target: ServiceNetwork
        function onWifiEnabledChanged() {
            SettingsConfig.toggles = Object.assign({}, SettingsConfig.toggles, { airplaneMode: !ServiceNetwork.wifiEnabled })
        }
    }

    Connections {
        target: ServicePipewire
        function onMutedChanged() {
            SettingsConfig.toggles = Object.assign({}, SettingsConfig.toggles, { speakerMuted: ServicePipewire.muted })
        }
        function onMicMutedChanged() {
            SettingsConfig.toggles = Object.assign({}, SettingsConfig.toggles, { micMuted: ServicePipewire.micMuted })
        }
    }




    // Overlay backdrop — fades in/out independently
    Rectangle {
        id: overlayBackdrop
        anchors.fill: parent
        z: 1
        radius: 20
        color: Qt.alpha(Colors.surface, 0.7)
        opacity: root.panelMode !== "" ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation {
                duration: root.panelMode !== "" ? root.morphOpen : root.morphClose
                easing.type: Easing.BezierSpline
                easing.bezierCurve: M3Motion.effects.curve
            }
        }
    }

    // Panel container — persistent so states/transitions actually animate
    Rectangle {
        id: container
        z: 2
        enabled: root.panelMode !== ""

        x: root.pos ? root.pos.x : 0
        y: root.pos ? root.pos.y : 0
        width:  root.srcSize ? root.srcSize.width  : (root.controlsItem?.width ?? 300)
        height: root.srcSize ? root.srcSize.height : 60
        radius: root.srcRadius
        opacity: {
            if (!root.panelVisible) return 0
            if (root.panelMode !== "") return 1
            const srcH = root.srcSize ? root.srcSize.height : 60
            const band = Math.max(40, srcH)
            return Math.max(0, Math.min(1, (container.height - srcH) / band))
        }
        visible: opacity > 0.01

        color: Colors.surfaceContainerHigh
        clip: true

        states: [
            State {
                name: "wifi"
                when: root.panelMode === "wifi"
                PropertyChanges {
                    target: container
                    x: root.parentPos ? root.parentPos.x : 0
                    y: root.parentPos ? root.parentPos.y : 0
                    width: (root.controlsItem?.width ?? 300)
                    height: (root.controlsItem?.height ?? 60) + 400
                    radius: 20
                }
            },
            State {
                name: "modes"
                when: root.panelMode === "modes"
                PropertyChanges {
                    target: container
                    x: root.parentPos ? root.parentPos.x : 0
                    y: root.parentPos ? root.parentPos.y : 0
                    width: (root.controlsItem?.width ?? 300)
                    height: 310
                    radius: 20
                }
            },
            State {
                name: "bluetooth"
                when: root.panelMode === "bluetooth"
                PropertyChanges {
                    target: container
                    x: root.parentPos ? root.parentPos.x : 0
                    y: root.parentPos ? root.parentPos.y : 0
                    width: (root.controlsItem?.width ?? 300)
                    height: (root.controlsItem?.height ?? 60) + 400
                    radius: 20
                }
            }
        ]

        transitions: [
            Transition {
                to: ""
                SpatialAnim {
                    properties: "x,y,width,height,radius"
                    speed: "default"
                }
            },
            Transition {
                SpatialAnim {
                    properties: "x,y,width,height,radius"
                    speed: "slow"
                }
            }
        ]

        Timer {
            id: contentTimer
            interval: root.morphOpen * 0.6
            onTriggered: if (root.panelMode !== "") panelLoader.active = true
        }

        Loader {
            id: panelLoader
            active: false
            anchors.fill: parent
            opacity: (root.panelMode !== "" && active) ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { EffectsAnim { speed: "default" } }
            sourceComponent: root.activeMode === "wifi" ? wifiComponent
                : root.activeMode === "bluetooth" ? bluetoothComponent
                : root.activeMode === "modes" ? modesComponent
                : null
        }

        Component {
            id: wifiComponent
            Wifi { onBackClicked: root.panelMode = "" }
        }

        Component {
            id: modesComponent
            ModesPanel { onBackClicked: root.panelMode = "" }
        }

        Component {
            id: bluetoothComponent
            Bluetooth { onBackClicked: root.panelMode = "" }
        }
    }

    NumberAnimation on opacity{
        from: 0
        to: 1
        duration: 200
        running: true
    }


    signal toggleDashboard
    property bool active: false//hoverHandler.hovered

    onActiveChanged:{
        if(!active) root.toggleDashboard()
    }


    // HoverHandler{
    //     id: hoverHandler
    // }

    property bool editing: false

    readonly property string selectedKey: {
        const sel = BarLayout.editor ? BarLayout.editor.selectedItem : ""
        return sel.indexOf("dash:") === 0 ? sel.slice(5) : ""
    }

    property string dragKey: ""
    property int dragFrom: -1
    property int dragTo: -1
    property real dragH: 0
    readonly property bool dragActive: root.dragKey !== ""

    function labelFor(key) {
        const e = DashLayout.entry(key)
        return e ? e.label : key
    }

    function fillsFor(key) {
        return DashLayout.opt(key, "fill") === true
    }

    readonly property bool anyFills: DashLayout.visibleIds.some(k => root.fillsFor(k))

    function selectSection(key) {
        if (BarLayout.editor)
            BarLayout.editor.selectedItem = "dash:" + key
    }

    function hideSection(key) {
        if (BarLayout.editor && BarLayout.editor.selectedItem === "dash:" + key)
            BarLayout.editor.selectedItem = "dashboard"
        DashLayout.hideSection(key)
    }

    function beginDrag(key, index, h) {
        root.dragKey = key
        root.dragFrom = index
        root.dragTo = index
        root.dragH = h
        root.applyShifts()
    }

    function updateDrag(dy) {
        const self = rep.itemAt(root.dragFrom)
        if (!self)
            return
        self.dragY = dy
        const rects = []
        for (let i = 0; i < rep.count; i++) {
            const s = rep.itemAt(i)
            rects.push(s ? { y: s.y, h: s.height } : null)
        }
        const k = DashOps.dropIndex(rects, root.dragFrom, self.y + self.height / 2 + dy)
        if (k !== root.dragTo) {
            root.dragTo = k
            root.applyShifts()
        }
    }

    function applyShifts() {
        const step = root.dragH + col.spacing
        for (let i = 0; i < rep.count; i++) {
            const s = rep.itemAt(i)
            if (!s || i === root.dragFrom)
                continue
            s.shift = DashOps.shiftFor(i, root.dragFrom, root.dragTo, step)
        }
    }

    function clearDrag() {
        for (let i = 0; i < rep.count; i++) {
            const s = rep.itemAt(i)
            if (s) {
                s.shift = 0
                s.dragY = 0
            }
        }
        root.dragKey = ""
        root.dragFrom = -1
        root.dragTo = -1
    }

    function endDrag() {
        const key = root.dragKey
        const to = root.dragTo
        const ids = []
        let landedY = 0
        for (let i = 0; i < rep.count; i++) {
            const s = rep.itemAt(i)
            if (!s)
                continue
            ids.push(s.sectionKey)
            if (s.sectionKey === key)
                landedY = s.y + s.dragY
        }
        const before = DashOps.beforeId(ids, key, to)

        root.dragKey = ""
        root.dragFrom = -1
        root.dragTo = -1

        Qt.callLater(() => {
            DashLayout.moveBefore(key, before)
            for (let i = 0; i < rep.count; i++) {
                const s = rep.itemAt(i)
                if (!s)
                    continue
                s.shift = 0
                if (s.sectionKey !== key)
                    s.dragY = 0
            }
            Qt.callLater(() => {
                for (let i = 0; i < rep.count; i++) {
                    const s = rep.itemAt(i)
                    if (s && s.sectionKey === key)
                        s.settleFrom(landedY)
                }
            })
        })
    }

    function cancelDrag() {
        root.clearDrag()
    }

    // The wifi/bluetooth overlay sizes itself from the controls section, so the
    // driver has to hand back a reference the Loader would otherwise hide.
    property Item controlsItem: null

    Component { id: cProfile
        DashProfile { compact: root.dense; onToggleDashboard: root.toggleDashboard() } }

    Component { id: cControls
        DashControls {
            compact: root.dense
            coordSpace: root
            panelMode: root.panelMode
            onToggleDashboard: root.toggleDashboard()
            Component.onCompleted: root.controlsItem = this
            Component.onDestruction: if (root.controlsItem === this) root.controlsItem = null
            onOpenPanel: function(mode, pPos, p, sz, r) {
                root.parentPos = pPos
                root.pos = p
                root.srcSize = sz
                root.srcRadius = r
                root.panelMode = mode
            }
        } }

    Component { id: cQuickActions;  DashQuickActions  { compact: root.dense } }
    Component { id: cMedia;         DashMedia         { compact: root.dense } }
    Component { id: cStats;         DashStats         { compact: root.dense } }
    Component { id: cNotifications; DashNotifications { compact: root.dense } }
    Component { id: cCalendar;      DashCalendar      { compact: root.dense } }

    function componentFor(key) {
        switch (key) {
            case "profile":       return cProfile
            case "controls":      return cControls
            case "quickActions":  return cQuickActions
            case "media":         return cMedia
            case "stats":         return cStats
            case "notifications": return cNotifications
            case "calendar":      return cCalendar
        }
        return null
    }

    ListModel { id: sectionModel }
    ListModel { id: sectionModelB }

    readonly property var stackedIds: root.split
        ? DashLayout.visibleIds.filter(k => k !== "notifications")
        : DashLayout.visibleIds

    function syncSections() {
        const ids = root.stackedIds
        const cut = root.stackColumns >= 2 ? Math.ceil(ids.length / 2) : ids.length
        BarLayout.syncModel(sectionModel,  ids.slice(0, cut), "key", null)
        BarLayout.syncModel(sectionModelB, ids.slice(cut),    "key", null)
    }

    Component.onCompleted: root.syncSections()

    Connections {
        target: DashLayout
        function onVisibleIdsChanged() { root.syncSections() }
    }

    Flickable {
        id: dashScroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(dashScroll.height, cols.implicitHeight + root.pad * 2)
        interactive: dashScroll.contentHeight > dashScroll.height + 1 && !root.dragActive
        boundsBehavior: Flickable.StopAtBounds
        clip: interactive

        RowLayout {
            id: cols
            x: root.pad
            y: root.pad
            width: dashScroll.width - root.pad * 2
            height: dashScroll.contentHeight - root.pad * 2
            spacing: root.pad

            ColumnLayout{
                id: col
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                spacing:         root.compact ? 7 : 10

                Repeater {
                    id: rep
                    model: sectionModel

                    delegate: DashSlot {
                        required property string key
                        required property int index

                        sectionKey: key
                        listIndex: index
                        dash: root
                        content: root.componentFor(key)
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.split || !root.anyFills
                }
            }

            ColumnLayout {
                id: colB
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                visible: root.stackColumns >= 2 && sectionModelB.count > 0
                spacing: col.spacing

                Repeater {
                    model: sectionModelB

                    delegate: DashSlot {
                        required property string key

                        sectionKey: key
                        listIndex: -1
                        movable: false
                        dash: root
                        content: root.componentFor(key)
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                visible: root.split
                spacing: col.spacing

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: root.split
                    sourceComponent: DashSlot {
                        sectionKey: "notifications"
                        listIndex: -1
                        movable: false
                        dash: root
                        content: cNotifications
                    }
                }
            }
        }
    }
}
