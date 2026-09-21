import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs.modules.utils
import qs.modules.components.Bar
import qs.modules.settings
import qs.modules.components.AppLauncher
import qs.modules.components.ToolsWidget
import qs.modules.components.Setting
import qs.modules.components.Clipboard
import qs.modules.components.Notification
import qs.modules.components.Osd
import qs.modules.components.Widgets
import qs.modules.services
import qs.modules.customComponents
import "../Bar/BarPath.js" as BarPath
import "../Bar/BarOps.js" as BarOps

Item {
    id: surface
    anchors.fill: parent

    property bool isPrimary: true
    property QtObject editor: null
    property string edge: "top"
    readonly property bool bottomEdge: surface.edge === "bottom"
    readonly property real barH: surface.bottomEdge ? BarLayout.dockHeight : Appearance.size.barHeight
    readonly property real edgeInset: surface.bottomEdge
        ? surface.height - sectionsRow.y - sectionsRow.height : sectionsRow.y
    property Scale flip: Scale { origin.y: surface.height / 2; yScale: -1 }
    readonly property Item rowItem: sectionsRow
    readonly property Item leftRepeater: leftRep
    readonly property Item centerRepeater: centerRep
    readonly property Item rightRepeater: rightRep
    readonly property Item leftGroupItem: leftGroup
    readonly property Item centerGroupItem: centerGroup
    readonly property Item rightGroupItem: rightGroup
    readonly property Item dashCard: pillDashPanel
    readonly property Item weatherCard: pillWeatherPanel

    property real disX: surface.bottomEdge ? BarLayout.dockRadius : BarLayout.cornerRadius
    property real disY: surface.bottomEdge ? BarLayout.dockRadius : BarLayout.cornerRadius
    property real radX: surface.bottomEdge ? BarLayout.dockRadius : BarLayout.cornerRadius
    property real radY: surface.bottomEdge ? BarLayout.dockRadius : BarLayout.cornerRadius
    property real lineDis: 4
    property string barMode: surface.bottomEdge ? BarLayout.dockStyle
        : (SettingsConfig.general.barMode ?? (SettingsConfig.general.flatBarMode === false ? "stepped" : "flat"))
    property real pillMargin: surface.bottomEdge ? BarLayout.dockPillGap : (SettingsConfig.general.pillMargin ?? 6)
    property real pillLeftMargin:  SettingsConfig.general.pillLeftMargin  ?? 6
    property real pillRightMargin: SettingsConfig.general.pillRightMargin ?? 6

    readonly property real blockGapSetting: surface.bottomEdge ? BarLayout.dockBlockGap : BarLayout.blockGap
    property real groupGap: surface.blockGapSetting >= 0 ? surface.blockGapSetting
        : (surface.barMode === "stepped" ? 2 * surface.disX + 28 : 14)
    Behavior on groupGap { enabled: BarLayout.settled; SpatialAnim { speed: "default" } }

    readonly property real bridgeTarget: surface.barMode === "stepped" ? surface.lineDis : surface.barH
    readonly property real endTarget: surface.barMode === "pill" ? surface.barH / 2 : -surface.disX
    readonly property real flareTarget: surface.barMode === "pill" ? 0 : 1
    property real bridgeAnim: surface.bridgeTarget
    property real endAnim: surface.endTarget
    property real flareAnim: surface.flareTarget
    Behavior on bridgeAnim { enabled: BarLayout.settled; SpatialAnim { speed: "default" } }
    Behavior on endAnim    { enabled: BarLayout.settled; SpatialAnim { speed: "default" } }
    Behavior on flareAnim  { enabled: BarLayout.settled; SpatialAnim { speed: "default" } }

    property var leftLeaving: ({})
    property var centerLeaving: ({})
    property var rightLeaving: ({})

    function groupLayout(rep) {
        surface.blockItems
        const xs = []
        let x = 0
        let before = 0
        for (let k = 0; k < rep.count; k++) {
            const o = rep.itemAt(k)
            const pc = o ? Math.min(1, o.pc) : 0
            x += surface.groupGap * Math.min(pc, before)
            xs.push(x)
            x += o ? o.width : 0
            before = Math.max(before, pc)
        }
        return { xs: xs, total: x }
    }

    function blockGone(model, side, leaving, id) {
        Qt.callLater(() => BarLayout.dropLeaving(model, BarLayout.idsFor(side, surface.edge), "blockId", leaving, id))
    }

    property var blockItems: []

    readonly property var visibleBlocks: surface.blockItems
        .filter(b => b && b.parent && b.visible)
        .sort((a, b) => (a.parent.x + a.x) - (b.parent.x + b.x))

    readonly property var pathBlocks: {
        const out = []
        const top = surface.edgeInset
        const bridge = top + surface.bridgeAnim
        for (let isl = 0; isl < surface.visibleBlocks.length; isl++) {
            const b = surface.visibleBlocks[isl]
            const bx = sectionsRow.x + b.parent.x + b.x
            const p = Math.min(1, b.pc) * (surface.bottomEdge && surface.barMode !== "pill" ? surface.reveal : 1)
            const bot = bridge + (top + surface.barH - bridge) * p
            if (!b.tabOpen) {
                out.push({ x: bx, w: b.width, bot: bot, isl: isl })
                continue
            }
            const tx = bx + b.tabX
            const tX = tx + b.tabW
            const ux = Math.min(bx, tx)
            const uX = Math.max(bx + b.width, tX)
            const tbot = bridge + (top + b.tabPathH - bridge) * p
            if (tx > ux + 0.01)
                out.push({ x: ux, w: tx - ux, bot: bot, isl: isl })
            out.push({ x: tx, w: b.tabW, bot: tbot, isl: isl })
            if (uX > tX + 0.01)
                out.push({ x: tX, w: uX - tX, bot: bot, isl: isl })
        }
        out.sort((p, q) => p.x - q.x)
        for (let i = 1; i < out.length; i++) {
            const a = out[i - 1]
            const b = out[i]
            const aR = a.x + a.w
            if (b.x >= aR - 0.01)
                continue
            if (b.bot >= a.bot) {
                a.w = Math.max(0, b.x - a.x)
                a.trimmed = true
            } else {
                const bR = b.x + b.w
                b.x = Math.min(aR, bR)
                b.w = Math.max(0, bR - b.x)
                b.trimmed = true
            }
        }
        return out.filter(sg => !sg.trimmed || sg.w > 0.01)
    }

    readonly property var openTabs: surface.visibleBlocks.filter(b => b.tabOpen)

    readonly property var tabRects: {
        const out = []
        for (const b of surface.openTabs) {
            if (b.tabW <= 0.5)
                continue
            out.push({ id: b.blockId, l: b.absX + b.tabX, r: b.absX + b.tabX + b.tabW })
        }
        return out
    }


    readonly property real leftLimit: centerGroup.width > 0 ? centerGroup.x - 12 : rightGroup.x - 12
    readonly property real centerLimit: Math.max(1, rightGroup.x - surface.groupGap)

    property string floatKind: ""
    property real floatCenter: 0
    property string floatBlock: ""
    property string floatItem: ""

    function openFloating(kind, centerX, blockId, itemId) {
        if (surface.floatKind === kind && surface.floatBlock === blockId) {
            surface.floatKind = ""
            return
        }
        surface.floatCenter = centerX
        surface.floatBlock = blockId
        surface.floatItem = itemId
        surface.floatKind = kind
    }

    function collectBlocks() {
        const out = []
        for (const rep of [leftRep, centerRep, rightRep]) {
            for (let i = 0; i < rep.count; i++) {
                const it = rep.itemAt(i)
                if (it) out.push(it)
            }
        }
        surface.blockItems = out
    }

    function syncGroups() {
        BarLayout.syncAnimated(leftModel,   BarLayout.idsFor("left", surface.edge),   "blockId", surface.leftLeaving)
        BarLayout.syncAnimated(centerModel, BarLayout.idsFor("center", surface.edge), "blockId", surface.centerLeaving)
        BarLayout.syncAnimated(rightModel,  BarLayout.idsFor("right", surface.edge),  "blockId", surface.rightLeaving)
    }

    Connections {
        target: BarLayout
        function onAllBlocksChanged() { surface.syncGroups() }
        function onNeedSysHostChanged() { surface.syncGroups() }
        function onDockOnChanged() { surface.syncGroups() }
    }

    readonly property bool autoHide: surface.bottomEdge && (SettingsConfig.general.dockAutoHide ?? true)
        && surface.barMode !== "flat"
    readonly property bool dockActive: !surface.autoHide || revealHover.hovered || GlobalStates.barEditMode
        || BarLayout.sysPanelOpen || surface.visibleBlocks.some(b => b.hovering || b.tabOpen)
    property bool dockHidden: false
    property real reveal: surface.dockHidden ? 0 : 1
    Behavior on reveal {
        SpatialAnim { speed: "default" }
    }
    readonly property real slide: (1 - surface.reveal) * (surface.barH + surface.edgeInset + 6)
    property Translate slideT: Translate { y: surface.barMode === "pill" ? surface.slide : 0 }
    property Translate rowSlide: Translate { y: surface.slide }

    onDockActiveChanged: {
        if (surface.dockActive) {
            hideTimer.stop()
            surface.dockHidden = false
        } else {
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: surface.dockHidden = !surface.dockActive
    }

    readonly property bool sdfWanted: surface.bottomEdge ? BarLayout.dockSdf : BarLayout.barSdf
    readonly property bool sdfOn: surface.sdfWanted
        && surface.sdfField.segs.length <= 12 && surface.sdfField.pills.length <= 4
        && surface.sdfField.flares.length <= 6

    readonly property var sdfOpts: ({
        left: sectionsRow.x,
        right: sectionsRow.x + sectionsRow.width,
        top: surface.edgeInset,
        bridge: surface.bridgeAnim,
        endR: surface.endAnim,
        rMax: surface.disX,
        needGap: 2 * surface.disX + 24,
        screenH: layout.height,
        screenW: layout.width,
        bottomFlare: surface.flareAnim
    })

    readonly property var pillGroups: {
        const groups = []
        for (const seg of surface.pathBlocks) {
            if (!groups[seg.isl])
                groups[seg.isl] = []
            groups[seg.isl].push(seg)
        }
        return groups.filter(g => g && g.length)
    }

    readonly property var sdfField: {
        if (!surface.sdfWanted)
            return BarPath.sdfEmpty()
        if (surface.barMode !== "pill")
            return BarPath.sdfData(surface.pathBlocks, surface.sdfOpts)
        const h = surface.barH
        return BarPath.sdfIslands(surface.pillGroups,
            Object.assign({}, surface.sdfOpts, { bridge: h, endR: h / 2, bottomFlare: 0 }))
    }

    readonly property real sdfTop: surface.edgeInset
    readonly property real sdfBot: surface.edgeInset
        + (surface.barMode === "pill" ? surface.barH : surface.bridgeAnim)
    readonly property real sdfRMax: surface.disX
    readonly property real sdfFlip: surface.height + (surface.barMode === "pill" ? surface.slide : 0)

    readonly property real sdfCut: {
        let b = surface.edgeInset + surface.bridgeAnim + Math.abs(surface.endAnim) + surface.barH
        for (const s of surface.pathBlocks)
            b = Math.max(b, s.bot)
        return b + surface.disX * 2 + 2
    }

    readonly property var span: {
        let l = Infinity
        let r = -Infinity
        for (const b of surface.visibleBlocks) {
            const bx = sectionsRow.x + b.parent.x + b.x
            l = Math.min(l, bx)
            r = Math.max(r, bx + b.width)
        }
        return l < r ? { x: l, w: r - l } : { x: 0, w: 0 }
    }

    Component.onCompleted: {
        surface.syncGroups()
        if (!surface.dockActive)
            hideTimer.restart()
    }

    Shape{
        visible: !surface.sdfOn
        preferredRendererType: Shape.CurveRenderer
        transform: surface.bottomEdge ? [surface.flip, surface.slideT] : []
        ShapePath{
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: Colors.surface
            fillRule: ShapePath.WindingFill
            PathSvg {
                path: {
                    if (surface.sdfOn)
                        return ""
                    const o = {
                        left: sectionsRow.x,
                        right: sectionsRow.x + sectionsRow.width,
                        top: surface.edgeInset,
                        bridge: surface.bridgeAnim,
                        endR: surface.endAnim,
                        rMax: surface.disX,
                        needGap: 2 * surface.disX + 24,
                        screenH: layout.height,
                        screenW: layout.width,
                        bottomFlare: surface.flareAnim
                    }
                    if (surface.barMode !== "pill")
                        return BarPath.shape(surface.pathBlocks, o)
                    const groups = []
                    for (const seg of surface.pathBlocks) {
                        if (!groups[seg.isl])
                            groups[seg.isl] = []
                        groups[seg.isl].push(seg)
                    }
                    const h = surface.barH
                    return BarPath.islands(groups, Object.assign(o, { bridge: h, endR: h / 2, bottomFlare: 0 }))
                }
            }
        }
    }

    Item {
        id: sectionsRow
        transform: surface.bottomEdge ? [surface.rowSlide] : []
        opacity: surface.bottomEdge ? surface.reveal : 1
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin:   !surface.bottomEdge && surface.barMode === "pill" ? surface.pillMargin : 0
        anchors.bottomMargin: surface.bottomEdge && surface.barMode === "pill" ? surface.pillMargin : 0
        anchors.leftMargin:  surface.barMode === "pill" ? surface.pillLeftMargin  : 0
        anchors.rightMargin: surface.barMode === "pill" ? surface.pillRightMargin : 0

        Behavior on anchors.topMargin   { enabled: BarLayout.settled; SpatialAnim { speed: "default" } }
        Behavior on anchors.bottomMargin { enabled: BarLayout.settled; SpatialAnim { speed: "default" } }
        Behavior on anchors.leftMargin  { enabled: BarLayout.settled; SpatialAnim { speed: "default" } }
        Behavior on anchors.rightMargin { enabled: BarLayout.settled; SpatialAnim { speed: "default" } }

        ListModel { id: leftModel }
        ListModel { id: centerModel }
        ListModel { id: rightModel }

        Item {
            id: leftGroup
            anchors.left: parent.left
            readonly property var lay: surface.groupLayout(leftRep)
            width: leftGroup.lay.total
            height: surface.barH
            y: surface.bottomEdge ? sectionsRow.height - height : 0

            Repeater {
                id: leftRep
                model: leftModel
                delegate: BarBlock {
                    id: leftBlock
                    edge: surface.edge
                    x: leftGroup.lay.xs[leftBlock.index] ?? 0
                    editor: surface.editor
                    absX: sectionsRow.x + leftGroup.x + leftBlock.x
                    coverTabs: surface.tabRects
                    spanL: sectionsRow.x
                    spanR: sectionsRow.x + sectionsRow.width
                    maxWidth: leftBlock.index === leftModel.count - 1 ? Math.max(1, surface.leftLimit - leftBlock.x) : -1
                    floatOpenerId: surface.floatKind !== "" && surface.floatBlock === leftBlock.blockId ? surface.floatItem : ""
                    onFloatRequested: (kind, cx, id) => surface.openFloating(kind, cx, leftBlock.blockId, id)
                    onFloatCloseRequested: surface.floatKind = ""
                    onGone: surface.blockGone(leftModel, "left", surface.leftLeaving, leftBlock.blockId)
                }
                onItemAdded: Qt.callLater(surface.collectBlocks)
                onItemRemoved: Qt.callLater(surface.collectBlocks)
            }
        }

        Item {
            id: centerGroup
            x: {
                const ideal = (sectionsRow.width - centerGroup.width) / 2
                const limit = rightGroup.x - centerGroup.width - surface.groupGap
                return Math.max(0, Math.min(ideal, limit))
            }
            readonly property var lay: surface.groupLayout(centerRep)
            width: centerGroup.lay.total
            height: surface.barH
            y: surface.bottomEdge ? sectionsRow.height - height : 0

            Repeater {
                id: centerRep
                model: centerModel
                delegate: BarBlock {
                    id: centerBlock
                    edge: surface.edge
                    x: centerGroup.lay.xs[centerBlock.index] ?? 0
                    editor: surface.editor
                    absX: sectionsRow.x + centerGroup.x + centerBlock.x
                    coverTabs: surface.tabRects
                    spanL: sectionsRow.x
                    spanR: sectionsRow.x + sectionsRow.width
                    maxWidth: centerBlock.index === centerModel.count - 1 ? Math.max(1, surface.centerLimit - centerBlock.x) : -1
                    floatOpenerId: surface.floatKind !== "" && surface.floatBlock === centerBlock.blockId ? surface.floatItem : ""
                    onFloatRequested: (kind, cx, id) => surface.openFloating(kind, cx, centerBlock.blockId, id)
                    onFloatCloseRequested: surface.floatKind = ""
                    onGone: surface.blockGone(centerModel, "center", surface.centerLeaving, centerBlock.blockId)
                }
                onItemAdded: Qt.callLater(surface.collectBlocks)
                onItemRemoved: Qt.callLater(surface.collectBlocks)
            }
        }

        Item {
            id: rightGroup
            anchors.right: parent.right
            readonly property var lay: surface.groupLayout(rightRep)
            width: rightGroup.lay.total
            height: surface.barH
            y: surface.bottomEdge ? sectionsRow.height - height : 0

            Repeater {
                id: rightRep
                model: rightModel
                delegate: BarBlock {
                    id: rightBlock
                    edge: surface.edge
                    x: rightGroup.lay.xs[rightBlock.index] ?? 0
                    editor: surface.editor
                    absX: sectionsRow.x + rightGroup.x + rightBlock.x
                    coverTabs: surface.tabRects
                    spanL: sectionsRow.x
                    spanR: sectionsRow.x + sectionsRow.width
                    floatOpenerId: surface.floatKind !== "" && surface.floatBlock === rightBlock.blockId ? surface.floatItem : ""
                    onFloatRequested: (kind, cx, id) => surface.openFloating(kind, cx, rightBlock.blockId, id)
                    onFloatCloseRequested: surface.floatKind = ""
                    onGone: surface.blockGone(rightModel, "right", surface.rightLeaving, rightBlock.blockId)
                }
                onItemAdded: Qt.callLater(surface.collectBlocks)
                onItemRemoved: Qt.callLater(surface.collectBlocks)
            }
        }
    }

    Item {
        id: revealZone
        visible: surface.bottomEdge
        x: surface.span.x
        y: surface.height - 8
        width: surface.span.w
        height: 8
        HoverHandler { id: revealHover }
    }

    Rectangle {
        id: pillDashPanel
        visible: surface.isPrimary && surface.barMode === "pill" && surface.floatKind === "dashboard"

        x:      Math.max(surface.pillLeftMargin, Math.min(parent.width - width - surface.pillRightMargin, surface.floatCenter - width / 2))
        y:      surface.bottomEdge ? ServiceGaps.topFinal + 8 : surface.pillMargin + surface.barH + 8
        width:  BarLayout.floatPanelW("dashboard")

        readonly property real fullHeight: surface.bottomEdge
            ? parent.height - y - surface.pillMargin - surface.barH - 8
            : parent.height - y - surface.pillMargin - 8

        height: BarLayout.panelHeightIn("dashboard",
            (pillDashLoader.item && pillDashLoader.item.anyFills === false)
                ? Math.min(pillDashPanel.fullHeight, pillDashLoader.item.implicitHeight)
                : pillDashPanel.fullHeight,
            pillDashPanel.fullHeight)
        radius: 20
        color:  Colors.surface
        clip:   true

        readonly property real slideFrom: surface.floatCenter < parent.width / 2 ? -340 : 340

        opacity: 0
        property real _slideX: slideFrom
        transform: Translate { x: pillDashPanel._slideX }

        NumberAnimation on opacity { from: 0; to: 1; duration: 300; easing.type: Easing.OutQuad; running: pillDashPanel.visible }
        NumberAnimation on _slideX { from: pillDashPanel.slideFrom; to: 0; duration: 300; easing.type: Easing.OutCubic; running: pillDashPanel.visible }

        Loader {
            id: pillDashLoader
            anchors.fill: parent
            active:  pillDashPanel.visible
            visible: false
            Timer {
                interval: 250
                running:  pillDashPanel.visible
                onTriggered: pillDashLoader.visible = true
            }
            sourceComponent: Dashboard {
                onToggleDashboard: surface.floatKind = ""
            }
        }
    }

    Rectangle {
        id: pillWeatherPanel
        visible: surface.isPrimary && surface.barMode === "pill" && surface.floatKind === "weather"

        x:      Math.max(surface.pillLeftMargin, Math.min(parent.width - width - surface.pillRightMargin, surface.floatCenter - width / 2))
        y:      surface.bottomEdge ? parent.height - surface.pillMargin - surface.barH - 8 - height
                                   : surface.pillMargin + surface.barH + 8
        width:  BarLayout.floatPanelW("weather")
        height: BarLayout.panelHeightIn("weather", pillWeatherLoader.item ? pillWeatherLoader.item.implicitHeight : 0,
                                        parent.height - surface.pillMargin * 2 - surface.barH - 16)
        radius: 20
        color:  Colors.surface
        clip:   true

        readonly property real slideFrom: surface.floatCenter < parent.width / 2
            ? -(pillWeatherPanel.width + 20) : pillWeatherPanel.width + 20

        opacity: 0
        property real _slideX: slideFrom
        transform: Translate { x: pillWeatherPanel._slideX }

        NumberAnimation on opacity { from: 0; to: 1; duration: 300; easing.type: Easing.OutQuad;   running: pillWeatherPanel.visible }
        NumberAnimation on _slideX { from: pillWeatherPanel.slideFrom; to: 0; duration: 300; easing.type: Easing.OutCubic; running: pillWeatherPanel.visible }

        Loader {
            id: pillWeatherLoader
            anchors.fill: parent
            active:  pillWeatherPanel.visible
            visible: false
            Timer {
                interval: 250
                running:  pillWeatherPanel.visible
                onTriggered: pillWeatherLoader.visible = true
            }
            sourceComponent: WeatherPanel {
                onClosed: surface.floatKind = ""
            }
        }
    }
}
