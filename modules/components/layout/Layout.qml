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

PanelWindow{
    id: layout
    color: "transparent"
    anchors{
        top: true
        left: true
        right: true
        bottom: true
    }

    property bool isPrimary: true

    readonly property bool barEditing: GlobalStates.barEditMode && isPrimary
    readonly property bool launcherPreview: layout.barEditing && barEditor.selectedItem === "launcher"
    readonly property string panelPreview: {
        const k = layout.barEditing ? BarLayout.panelFor(barEditor.selectedItem) : ""
        return k === "launcher" ? "" : k
    }
    readonly property bool dashPreview: layout.panelPreview !== ""
    readonly property bool anyPreview: layout.launcherPreview || layout.dashPreview
    readonly property string dashAnchor: {
        const opener = layout.panelPreview === "dashboard" ? "dashboard"
            : barEditor.selectedItem.indexOf("dash:") === 0 ? "dashboard" : barEditor.selectedItem
        const b = BarLayout.allBlocks.find(x => x.items.indexOf(opener) >= 0)
        return b ? b.anchor : "right"
    }
    readonly property bool previewRight: layout.dashPreview
        ? layout.dashAnchor !== "left"
        : ServiceLauncher.position === "item"
          && BarLayout.allBlocks.some(b => b.anchor === "right" && b.items.indexOf("launcher") >= 0)
    readonly property real popupY: topSurface.rowItem.y + Appearance.size.barHeight + (topSurface.barMode === "pill" ? 8 : 4)

    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.keyboardFocus: layout.barEditing ? WlrKeyboardFocus.Exclusive
                               : isPrimary && (GlobalStates.clipboardOpen || GlobalStates.wallpaperOpen
                                               || GlobalStates.fileDropOpen
                                               || GlobalStates.powerPanelOpen
                                               || GlobalStates.dockSearchActive
                                               || (GlobalStates.appLauncherOpen && GlobalStates.launcherHosted)) ? WlrKeyboardFocus.OnDemand
                                                             : WlrKeyboardFocus.None

    onBarEditingChanged: {
        topSurface.floatKind = ""
        barEditor.cancel()
        barEditor.selectedItem = ""
        if (layout.barEditing) drawerHost.open()
        else drawerHost.close()
    }

    Binding {
        target: GlobalStates
        property: "launcherPreview"
        value: true
        when: layout.isPrimary && layout.launcherPreview
    }

    Binding {
        target: GlobalStates
        property: "previewInsetRight"
        value: drawerHost.width + 48
        when: layout.isPrimary && layout.launcherPreview && !layout.previewRight
    }

    Binding {
        target: GlobalStates
        property: "previewInsetLeft"
        value: drawerHost.width + 48
        when: layout.isPrimary && layout.launcherPreview && layout.previewRight
    }

    Binding {
        target: GlobalStates
        property: "panelPreview"
        value: layout.panelPreview
        when: layout.isPrimary && layout.dashPreview
    }

    HyprlandFocusGrab {
        windows: [layout]
        active: layout.isPrimary && GlobalStates.appLauncherOpen && GlobalStates.launcherHosted
        onCleared: if (!active) GlobalStates.appLauncherOpen = false
    }

    mask: Region{
        item: maskRect;
        intersection: Intersection.Xor;

        Region {
            readonly property Item blk: topSurface.visibleBlocks[0] ?? null
            x: blk ? topSurface.rowItem.x + blk.parent.x + blk.x : 0
            y: blk ? topSurface.rowItem.y + blk.y : 0
            width:  blk && isPrimary ? blk.width  : 0
            height: blk && isPrimary ? blk.height : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item blk: topSurface.visibleBlocks[1] ?? null
            x: blk ? topSurface.rowItem.x + blk.parent.x + blk.x : 0
            y: blk ? topSurface.rowItem.y + blk.y : 0
            width:  blk && isPrimary ? blk.width  : 0
            height: blk && isPrimary ? blk.height : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item blk: topSurface.visibleBlocks[2] ?? null
            x: blk ? topSurface.rowItem.x + blk.parent.x + blk.x : 0
            y: blk ? topSurface.rowItem.y + blk.y : 0
            width:  blk && isPrimary ? blk.width  : 0
            height: blk && isPrimary ? blk.height : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item blk: topSurface.visibleBlocks[3] ?? null
            x: blk ? topSurface.rowItem.x + blk.parent.x + blk.x : 0
            y: blk ? topSurface.rowItem.y + blk.y : 0
            width:  blk && isPrimary ? blk.width  : 0
            height: blk && isPrimary ? blk.height : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item blk: topSurface.visibleBlocks[4] ?? null
            x: blk ? topSurface.rowItem.x + blk.parent.x + blk.x : 0
            y: blk ? topSurface.rowItem.y + blk.y : 0
            width:  blk && isPrimary ? blk.width  : 0
            height: blk && isPrimary ? blk.height : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item blk: topSurface.visibleBlocks[5] ?? null
            x: blk ? topSurface.rowItem.x + blk.parent.x + blk.x : 0
            y: blk ? topSurface.rowItem.y + blk.y : 0
            width:  blk && isPrimary ? blk.width  : 0
            height: blk && isPrimary ? blk.height : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item blk: topSurface.visibleBlocks[6] ?? null
            x: blk ? topSurface.rowItem.x + blk.parent.x + blk.x : 0
            y: blk ? topSurface.rowItem.y + blk.y : 0
            width:  blk && isPrimary ? blk.width  : 0
            height: blk && isPrimary ? blk.height : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item blk: topSurface.visibleBlocks[7] ?? null
            x: blk ? topSurface.rowItem.x + blk.parent.x + blk.x : 0
            y: blk ? topSurface.rowItem.y + blk.y : 0
            width:  blk && isPrimary ? blk.width  : 0
            height: blk && isPrimary ? blk.height : 0
            intersection: Intersection.Subtract
        }

        Region {
            readonly property Item tb: topSurface.openTabs[0] ?? null
            x: tb ? topSurface.rowItem.x + tb.parent.x + tb.x + tb.tabX : 0
            y: tb ? topSurface.rowItem.y : 0
            width:  tb && isPrimary ? tb.tabW : 0
            height: tb && isPrimary ? tb.tabH : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item tb: topSurface.openTabs[1] ?? null
            x: tb ? topSurface.rowItem.x + tb.parent.x + tb.x + tb.tabX : 0
            y: tb ? topSurface.rowItem.y : 0
            width:  tb && isPrimary ? tb.tabW : 0
            height: tb && isPrimary ? tb.tabH : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item tb: topSurface.openTabs[2] ?? null
            x: tb ? topSurface.rowItem.x + tb.parent.x + tb.x + tb.tabX : 0
            y: tb ? topSurface.rowItem.y : 0
            width:  tb && isPrimary ? tb.tabW : 0
            height: tb && isPrimary ? tb.tabH : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item tb: topSurface.openTabs[3] ?? null
            x: tb ? topSurface.rowItem.x + tb.parent.x + tb.x + tb.tabX : 0
            y: tb ? topSurface.rowItem.y : 0
            width:  tb && isPrimary ? tb.tabW : 0
            height: tb && isPrimary ? tb.tabH : 0
            intersection: Intersection.Subtract
        }

        Region {
            readonly property Item blk: bottomSurface.visible ? (bottomSurface.visibleBlocks[0] ?? null) : null
            x: blk ? bottomSurface.rowItem.x + blk.parent.x + blk.x : 0
            y: blk ? (bottomSurface.dockHidden ? layout.height - 8 : bottomSurface.rowItem.y + blk.parent.y + blk.y) : 0
            width:  blk ? blk.width  : 0
            height: blk ? (bottomSurface.dockHidden ? 8 : blk.height) : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item blk: bottomSurface.visible ? (bottomSurface.visibleBlocks[1] ?? null) : null
            x: blk ? bottomSurface.rowItem.x + blk.parent.x + blk.x : 0
            y: blk ? (bottomSurface.dockHidden ? layout.height - 8 : bottomSurface.rowItem.y + blk.parent.y + blk.y) : 0
            width:  blk ? blk.width  : 0
            height: blk ? (bottomSurface.dockHidden ? 8 : blk.height) : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item blk: bottomSurface.visible ? (bottomSurface.visibleBlocks[2] ?? null) : null
            x: blk ? bottomSurface.rowItem.x + blk.parent.x + blk.x : 0
            y: blk ? (bottomSurface.dockHidden ? layout.height - 8 : bottomSurface.rowItem.y + blk.parent.y + blk.y) : 0
            width:  blk ? blk.width  : 0
            height: blk ? (bottomSurface.dockHidden ? 8 : blk.height) : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item blk: bottomSurface.visible ? (bottomSurface.visibleBlocks[3] ?? null) : null
            x: blk ? bottomSurface.rowItem.x + blk.parent.x + blk.x : 0
            y: blk ? (bottomSurface.dockHidden ? layout.height - 8 : bottomSurface.rowItem.y + blk.parent.y + blk.y) : 0
            width:  blk ? blk.width  : 0
            height: blk ? (bottomSurface.dockHidden ? 8 : blk.height) : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item blk: bottomSurface.visible ? (bottomSurface.visibleBlocks[4] ?? null) : null
            x: blk ? bottomSurface.rowItem.x + blk.parent.x + blk.x : 0
            y: blk ? (bottomSurface.dockHidden ? layout.height - 8 : bottomSurface.rowItem.y + blk.parent.y + blk.y) : 0
            width:  blk ? blk.width  : 0
            height: blk ? (bottomSurface.dockHidden ? 8 : blk.height) : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item blk: bottomSurface.visible ? (bottomSurface.visibleBlocks[5] ?? null) : null
            x: blk ? bottomSurface.rowItem.x + blk.parent.x + blk.x : 0
            y: blk ? (bottomSurface.dockHidden ? layout.height - 8 : bottomSurface.rowItem.y + blk.parent.y + blk.y) : 0
            width:  blk ? blk.width  : 0
            height: blk ? (bottomSurface.dockHidden ? 8 : blk.height) : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item tb: bottomSurface.visible ? (bottomSurface.openTabs[0] ?? null) : null
            x: tb ? bottomSurface.rowItem.x + tb.parent.x + tb.x + tb.tabX : 0
            y: tb ? bottomSurface.rowItem.y + tb.parent.y + tb.y + tb.barH - tb.tabH : 0
            width:  tb ? tb.tabW : 0
            height: tb ? tb.tabH : 0
            intersection: Intersection.Subtract
        }
        Region {
            readonly property Item tb: bottomSurface.visible ? (bottomSurface.openTabs[1] ?? null) : null
            x: tb ? bottomSurface.rowItem.x + tb.parent.x + tb.x + tb.tabX : 0
            y: tb ? bottomSurface.rowItem.y + tb.parent.y + tb.y + tb.barH - tb.tabH : 0
            width:  tb ? tb.tabW : 0
            height: tb ? tb.tabH : 0
            intersection: Intersection.Subtract
        }

        Region {
            x: 0; y: 0
            width:  layout.barEditing ? layout.width  : 0
            height: layout.barEditing ? layout.height : 0
            intersection: Intersection.Subtract
        }

        Region{
            x: 0; y: 0
            width:  isPrimary ? 0 : layout.width
            height: isPrimary ? 0 : Appearance.size.barHeight
            intersection: Intersection.Subtract
        }

        Region {
            x:      topSurface.dashCard.x
            y:      topSurface.dashCard.y
            width:  topSurface.dashCard.visible ? topSurface.dashCard.width  : 0
            height: topSurface.dashCard.visible ? topSurface.dashCard.height : 0
            intersection: Intersection.Subtract
        }
        Region {
            x:      topSurface.weatherCard.x
            y:      topSurface.weatherCard.y
            width:  topSurface.weatherCard.visible ? topSurface.weatherCard.width  : 0
            height: topSurface.weatherCard.visible ? topSurface.weatherCard.height : 0
            intersection: Intersection.Subtract
        }
        Region {
            x:      bottomSurface.dashCard.x
            y:      bottomSurface.dashCard.y
            width:  bottomSurface.dashCard.visible ? bottomSurface.dashCard.width  : 0
            height: bottomSurface.dashCard.visible ? bottomSurface.dashCard.height : 0
            intersection: Intersection.Subtract
        }
        Region {
            x:      bottomSurface.weatherCard.x
            y:      bottomSurface.weatherCard.y
            width:  bottomSurface.weatherCard.visible ? bottomSurface.weatherCard.width  : 0
            height: bottomSurface.weatherCard.visible ? bottomSurface.weatherCard.height : 0
            intersection: Intersection.Subtract
        }

        Region {
            x:      notifPopups.x
            y:      notifPopups.y
            width:  (isPrimary && notifPopups.height > 0) ? notifPopups.width : 0
            height: isPrimary ? notifPopups.height : 0
            intersection: Intersection.Subtract
        }
    }
    Rectangle{
        id: maskRect
        implicitHeight: parent.height
        implicitWidth: parent.width
        anchors.bottom: parent.bottom
        color: "transparent"
    }

    SecondaryBar {
        visible: !isPrimary
    }

    Item{
        id: root
        anchors.fill: parent
        visible: isPrimary

        function inDrawerAt(x, y) {
            return drawerHost.visible
                && x >= drawerHost.x && x <= drawerHost.x + drawerHost.width
                && y >= drawerHost.y && y <= drawerHost.y + drawerHost.height
        }

        function surfaceAt(y) {
            if (bottomSurface.visible && BarLayout.dockOn) {
                const bandTop = bottomSurface.rowItem.y + bottomSurface.rowItem.height - bottomSurface.barH - 40
                if (y >= bandTop)
                    return bottomSurface
            }
            if (y <= topSurface.rowItem.y + topSurface.barH + 36)
                return topSurface
            return null
        }

        function trackApp(x, y) {
            barEditor.overDrawer = root.inDrawerAt(x, y)
            const host = bottomSurface.visibleBlocks.find(b => b.hasItem("dockApps"))
            const g = host ? host.appGeom() : null
            if (barEditor.overDrawer || !g || root.surfaceAt(y) !== bottomSurface
                    || x < g.x - 30 || x > g.x + g.w + 30) {
                barEditor.appDropIndex = -1
                return
            }
            barEditor.appDropIndex = BarOps.appDropIndex(g.apps, barEditor.appId, x)
        }

        function trackItem(x, y) {
            const inDrawer = root.inDrawerAt(x, y)
            barEditor.overDrawer = inDrawer
            barEditor.refusedTarget = ""
            const surf = inDrawer ? null : root.surfaceAt(y)
            if (!surf) {
                barEditor.dropBlock = ""
                return
            }
            let best = null
            let bestD = 1e9
            for (const b of surf.visibleBlocks) {
                if (b.leaving || b.blockId === "__sys")
                    continue
                const bx = surf.rowItem.x + b.parent.x + b.x
                const d = x < bx ? bx - x : (x > bx + b.width ? x - bx - b.width : 0)
                if (d < bestD) {
                    bestD = d
                    best = b
                }
            }
            if (!best || bestD > 80) {
                barEditor.dropBlock = ""
                return
            }
            if (!BarLayout.allows(barEditor.itemId, surf.edge)) {
                barEditor.dropBlock = ""
                barEditor.refusedTarget = best.blockId
                return
            }
            barEditor.dropBlock = best.blockId
            barEditor.dropIndex = best.dropIndexAt(x - (surf.rowItem.x + best.parent.x + best.x))
        }

        function trackBlock(x, y) {
            const surf = (bottomSurface.visible && BarLayout.dockOn && y > layout.height / 2) ? bottomSurface : topSurface
            const W = surf.rowItem.width
            const rel = x - surf.rowItem.x
            const side = rel < W / 3 ? "left" : (rel > 2 * W / 3 ? "right" : "center")
            const rep = side === "left" ? surf.leftRepeater : (side === "center" ? surf.centerRepeater : surf.rightRepeater)
            const group = side === "left" ? surf.leftGroupItem : (side === "center" ? surf.centerGroupItem : surf.rightGroupItem)
            const others = []
            for (let i = 0; i < rep.count; i++) {
                const b = rep.itemAt(i)
                if (b && b.blockId !== barEditor.fromBlock && b.visible && !b.leaving)
                    others.push(b)
            }
            let idx = 0
            for (const b of others) {
                if (surf.rowItem.x + group.x + b.x + b.width / 2 < x)
                    idx++
            }
            let caret
            if (others.length === 0)
                caret = side === "left" ? 8 : (side === "right" ? W - 8 : W / 2)
            else if (idx < others.length)
                caret = group.x + others[idx].x - surf.groupGap / 2
            else {
                const l = others[others.length - 1]
                caret = group.x + l.x + l.width + surf.groupGap / 2
            }
            barEditor.dropAnchor = side
            barEditor.dropEdge = surf.edge
            barEditor.dropBlockIndex = idx
            barEditor.caretX = surf.rowItem.x + Math.max(4, Math.min(W - 4, caret))
            barEditor.caretY = surf.rowItem.y + group.y + 4
            barEditor.caretH = surf.barH - 8
        }

        QtObject {
            id: barEditor

            property string mode: ""
            property string itemId: ""
            property string fromBlock: ""
            property int fromIndex: -1
            property real dragW: 0
            property string label: ""
            property string icon: ""
            property real px: 0
            property real py: 0
            property string dropBlock: ""
            property int dropIndex: 0
            property bool overDrawer: false
            property string dropAnchor: ""
            property int dropBlockIndex: 0
            property real caretX: -1
            property string selectedItem: ""
            property string dropEdge: "top"
            property real caretY: 0
            property real caretH: 0
            property string refusedTarget: ""
            property string appId: ""
            property bool appPinned: false
            property int appDropIndex: -1

            function beginItem(id, blockId, idx, w) {
                const e = BarLayout.entry(id)
                barEditor.itemId = id
                barEditor.fromBlock = blockId
                barEditor.fromIndex = idx
                barEditor.dragW = w
                barEditor.label = e ? e.label : id
                barEditor.icon = e ? e.icon : ""
                barEditor.dropBlock = blockId
                barEditor.dropIndex = Math.max(0, idx)
                barEditor.overDrawer = false
                barEditor.mode = "item"
            }

            function beginBlock(blockId) {
                barEditor.fromBlock = blockId
                barEditor.label = "Block"
                barEditor.icon = "drag_indicator"
                barEditor.dropAnchor = ""
                barEditor.caretX = -1
                barEditor.mode = "block"
            }

            function beginApp(appId, pinned, w) {
                const e = DesktopEntries.heuristicLookup(appId)
                barEditor.appId = appId
                barEditor.appPinned = pinned
                barEditor.appDropIndex = -1
                barEditor.fromBlock = ""
                barEditor.dragW = w
                barEditor.label = e && e.name ? e.name : appId
                barEditor.icon = pinned ? "drag_indicator" : "push_pin"
                barEditor.overDrawer = false
                barEditor.mode = "app"
            }

            function update(x, y) {
                barEditor.px = x
                barEditor.py = y
                if (barEditor.mode === "item") root.trackItem(x, y)
                else if (barEditor.mode === "block") root.trackBlock(x, y)
                else if (barEditor.mode === "app") root.trackApp(x, y)
            }

            function finish() {
                const mode = barEditor.mode
                const id = barEditor.itemId
                const from = barEditor.fromBlock
                const toBlock = barEditor.dropBlock
                const toIndex = barEditor.dropIndex
                const hide = barEditor.overDrawer
                const side = barEditor.dropAnchor
                const sideIndex = barEditor.dropBlockIndex
                const edge = barEditor.dropEdge
                const appId = barEditor.appId
                const appPinned = barEditor.appPinned
                const appIndex = barEditor.appDropIndex
                barEditor.cancel()
                if (mode === "app") {
                    if (hide) {
                        if (appPinned) Qt.callLater(() => ServiceApps.unpinById(appId))
                    } else if (appIndex >= 0) {
                        Qt.callLater(() => ServiceApps.movePin(appId, appIndex))
                    }
                    return
                }
                if (mode === "item") {
                    if (hide) {
                        if (id === barEditor.selectedItem) barEditor.selectedItem = ""
                        if (from !== "") Qt.callLater(() => BarLayout.hideItem(id))
                    } else if (toBlock !== "") {
                        Qt.callLater(() => BarLayout.moveItem(id, toBlock, toIndex))
                    }
                } else if (mode === "block" && side !== "") {
                    Qt.callLater(() => BarLayout.moveBlock(from, side, sideIndex, edge))
                }
            }

            function cancel() {
                barEditor.mode = ""
                barEditor.itemId = ""
                barEditor.fromBlock = ""
                barEditor.fromIndex = -1
                barEditor.dropBlock = ""
                barEditor.overDrawer = false
                barEditor.dropAnchor = ""
                barEditor.caretX = -1
                barEditor.refusedTarget = ""
                barEditor.appId = ""
                barEditor.appPinned = false
                barEditor.appDropIndex = -1
            }
        }

        Binding {
            target: BarLayout
            property: "editor"
            value: barEditor
            when: layout.isPrimary
        }
        Rectangle {
            anchors.fill: parent
            z: -1
            visible: layout.barEditing
            color: Qt.alpha(Colors.surface, 0.45)

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => {
                    if (barEditor.mode !== "")
                        return
                    if (barEditor.selectedItem !== "")
                        barEditor.selectedItem = ""
                    else if (mouse.y > topSurface.rowItem.y + Appearance.size.barHeight + 40)
                        GlobalStates.barEditMode = false
                }
            }
        }

        BarSdf {
            anchors.fill: parent
            bar: topSurface
            dock: bottomSurface
        }

        BarSurface {
            id: topSurface
            isPrimary: layout.isPrimary
            editor: barEditor
        }

        BarSurface {
            id: bottomSurface
            edge: "bottom"
            isPrimary: layout.isPrimary
            editor: barEditor
            visible: layout.isPrimary && !ServiceGameMode.hideWidgets && BarLayout.dockOn
        }

        Rectangle {
            z: 250
            visible: barEditor.mode === "block" && barEditor.caretX >= 0
            x: barEditor.caretX - 1.5
            y: barEditor.caretY
            width: 3
            height: barEditor.caretH
            radius: 1.5
            color: Colors.primary
        }

        BarEditDrawer {
            id: drawerHost
            z: 220
            editor: barEditor
            maxHeight: layout.height * 0.7
            width: Math.min(640, parent.width - 32)
            x: !layout.anyPreview ? (parent.width - width) / 2
                : layout.previewRight ? 24 : parent.width - width - 24
            y: topSurface.rowItem.y + Appearance.size.barHeight + 48
            Behavior on x {
                SpatialAnim { speed: "default" }
            }
        }

        Rectangle {
            id: dragGhost
            z: 300
            visible: barEditor.mode !== ""
            x: barEditor.px - width / 2
            y: barEditor.py - height / 2
            width: ghostRow.implicitWidth + 20
            height: 32
            radius: 16
            color: Colors.primaryContainer

            Row {
                id: ghostRow
                anchors.centerIn: parent
                spacing: 6

                MaterialIconSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    content: barEditor.icon
                    iconSize: 16
                    customColor: Colors.primaryContainerText
                }
                CustomText {
                    anchors.verticalCenter: parent.verticalCenter
                    content: barEditor.label
                    size: 12
                    weight: 700
                    customColor: Colors.primaryContainerText
                }
            }
        }

        Item {
            anchors.fill: parent
            focus: layout.barEditing
            Keys.onEscapePressed: {
                if (barEditor.mode !== "") barEditor.cancel()
                else if (barEditor.selectedItem !== "") barEditor.selectedItem = ""
                else GlobalStates.barEditMode = false
            }
        }

    }

    property bool isToolsWidgetClicked: false
    property bool isSettingClicked: false
    property bool showOsd: false

    GlobalShortcut{
        name: "toolsWidget"
        onPressed:{
            if(Hyprland.focusedMonitor.name === layout.screen.name){
                layout.isToolsWidgetClicked = !layout.isToolsWidgetClicked
            }
        }
    }

    NotificationPanel{
        id: notifPopups
        visible: isPrimary
    }

    readonly property int _topGap: ServiceGaps.topFinal
}
