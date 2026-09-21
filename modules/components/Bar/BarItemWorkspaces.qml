import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import Quickshell.Widgets
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/shape-library.js" as ShapeLibrary

Item {
    id: root

    property Item host: null
    property string itemId: ""
    readonly property bool shown: true

    readonly property int wsCount: SettingsConfig.general.workspaceCount ?? 5
    readonly property bool wsNumbers: SettingsConfig.general.showWorkspaceNumbers ?? false
    readonly property bool perMonitorMode: SettingsConfig.general.perMonitorWorkspaces ?? false

    readonly property int otherOccupied: {
        if (!perMonitorMode) return 0
        var count = 0
        var vals = Hyprland.workspaces.values
        for (var i = 0; i < vals.length; i++) {
            if (vals[i].monitor?.name !== layout.screen.name) count++
        }
        return count
    }

    readonly property var thisMonitor: {
        var mons = Hyprland.monitors?.values ?? []
        for (var i = 0; i < mons.length; i++) {
            if (mons[i].name === layout.screen.name) return mons[i]
        }
        return null
    }

    readonly property int activeWsId: thisMonitor?.activeWorkspace?.id ?? -1

    readonly property bool otherFocused: perMonitorMode
        && (Hyprland.focusedMonitor?.name ?? layout.screen.name) !== layout.screen.name

    readonly property int monitorCount: Hyprland.monitors?.values?.length ?? 1
    readonly property bool showOtherIndicator: perMonitorMode && monitorCount > 1

    readonly property string style: BarLayout.opt(root.itemId, "style") ?? "pill"
    readonly property var wsIds: Array.from({ length: root.wsCount }, (_, i) => i + 1)
    readonly property var shapeCycle: ["cookie4", "clover4", "sunny", "cookie6", "softBurst", "cookie9", "flower", "cookie7"]

    implicitWidth: face.item ? face.item.implicitWidth : 0
    implicitHeight: 30

    function focusWs(id, ws) {
        if (ws)
            ws.activate()
        else
            Hyprland.dispatch(`hl.dsp.focus({ workspace = '${id}' })`)
    }

    component WsState: QtObject {
        required property int wsId
        readonly property var ws: ServiceWorkspaces.getWorkspace(wsId)
        readonly property bool onOther: root.perMonitorMode && !!ws && !!ws.monitor
            && ws.monitor.name !== layout.screen.name
        readonly property bool occupied: !!ws && !onOther
        readonly property bool active: !onOther && (root.perMonitorMode ? wsId === root.activeWsId
                                                                        : (!!ws && ws.active))
    }

    Loader {
        id: face
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: {
            switch (root.style) {
            case "shapes":  return shapesComp
            case "worm":    return wormComp
            case "numbers": return numbersComp
            case "strip":   return stripComp
            case "kanji":   return kanjiComp
            }
            return pillComp
        }
    }

    Component {
        id: pillComp

        Rectangle {
            id: wsPill
            implicitWidth: row.implicitWidth + 6
            implicitHeight: 30
            radius: 15
            color: Colors.surfaceContainer

            RowLayout {
                id: row
                anchors.centerIn: parent
                spacing: 6

                Repeater {
                    model: ScriptModel {
                        values: Array.from({ length: root.wsCount }, (_, i) => i + 1)
                    }

                    delegate: Rectangle {
                        required property var modelData
                        property int workspaceId: modelData
                        property var currentWorkspace: ServiceWorkspaces.getWorkspace(workspaceId)
                        readonly property bool isOccupied: !!currentWorkspace
                        readonly property bool showNumbers: root.wsNumbers

                        readonly property bool onOtherMonitor: root.perMonitorMode
                            && !!currentWorkspace
                            && !!currentWorkspace.monitor
                            && currentWorkspace.monitor.name !== layout.screen.name

                        readonly property bool occupiedHere: isOccupied && !onOtherMonitor

                        readonly property bool isActive: !onOtherMonitor && (root.perMonitorMode
                            ? workspaceId === root.activeWsId
                            : (!!currentWorkspace && currentWorkspace.active))

                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: 25
                        Layout.preferredWidth: occupiedHere
                            ? Math.max(25, (topLevels.appList?.width ?? 0) + 12)
                            : 25
                        radius: 15
                        color: isActive     ? Colors.primary
                             : occupiedHere ? Colors.surfaceContainerHighest
                                            : "transparent"

                        border.width: (occupiedHere && !isActive) || onOtherMonitor ? 1 : 0
                        border.color: onOtherMonitor ? Qt.alpha(Colors.outline, 0.35)
                                                     : Qt.alpha(Colors.outline, 0.15)

                        Behavior on Layout.preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on color                 { ColorAnimation  { duration: 200 } }

                        Rectangle {
                            visible: !occupiedHere
                            implicitWidth: 5
                            implicitHeight: 5
                            color: onOtherMonitor ? Qt.alpha(Colors.outline, 0.45) : Colors.outline
                            radius: width / 2
                            anchors.centerIn: parent
                        }

                        Loader {
                            id: topLevels
                            anchors.fill: parent
                            active: occupiedHere && !showNumbers
                            visible: active
                            sourceComponent: TopLevels {}
                            property var appList: item ? item.appList : null
                        }

                        CustomText {
                            anchors.centerIn: parent
                            visible: showNumbers && occupiedHere
                            content: workspaceId.toString()
                            size: 10
                            weight: isActive ? 800 : 600
                            customColor: isActive ? Colors.primaryText : Colors.surfaceText
                            Behavior on customColor { ColorAnimation { duration: 200 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (currentWorkspace) currentWorkspace.activate()
                                else Hyprland.dispatch(`hl.dsp.focus({ workspace = '${workspaceId}' })`)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: 25
                    Layout.preferredWidth: root.showOtherIndicator ? 25 : 0
                    opacity: root.showOtherIndicator ? 1 : 0
                    visible: Layout.preferredWidth > 0
                    radius: 12
                    color: root.otherFocused ? Colors.primary : "transparent"
                    border.width: root.otherFocused ? 0 : 1
                    border.color: Qt.alpha(Colors.outline, 0.35)

                    Behavior on color                 { ColorAnimation  { duration: 200 } }
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on opacity               { NumberAnimation { duration: 180 } }

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: "tv_displays"
                        iconSize: 12
                        customColor: root.otherFocused ? Colors.primaryText : Colors.outline
                        Behavior on customColor { ColorAnimation { duration: 200 } }
                    }

                    CustomToolTip {
                        content: root.otherOccupied + " workspace" + (root.otherOccupied !== 1 ? "s" : "") + " on other monitor" + (root.otherFocused ? " — focused" : "")
                        visible: otherMonHov.containsMouse
                    }
                    MouseArea { id: otherMonHov; anchors.fill: parent; hoverEnabled: true }
                }
            }
        }
    }

    Component {
        id: shapesComp
        Row {
            spacing: 4
            Repeater {
                model: root.wsIds
                delegate: Item {
                    id: cell
                    required property int modelData
                    required property int index
                    WsState { id: st; wsId: cell.modelData }
                    readonly property real side: st.active ? 28 : st.occupied ? 17 : 12
                    width: 30
                    height: 30

                    MaterialShapes.ShapeCanvas {
                        id: shape
                        anchors.centerIn: parent
                        width: cell.side
                        height: cell.side
                        roundedPolygon: ShapeLibrary.get(st.active ? "cookie12"
                                                          : root.shapeCycle[cell.index % root.shapeCycle.length])
                        color: st.active ? Colors.primary
                             : st.occupied ? Qt.alpha(Colors.surfaceText, 0.78)
                             : st.onOther ? Qt.alpha(Colors.outlineVariant, 0.5)
                             : Colors.outlineVariant
                        Behavior on width { SpatialAnim { speed: "fast" } }
                        Behavior on height { SpatialAnim { speed: "fast" } }

                        RotationAnimator on rotation {
                            from: 0
                            to: 360
                            duration: 9000
                            loops: Animation.Infinite
                            running: st.active
                        }
                    }

                    Connections {
                        target: st
                        function onActiveChanged() {
                            if (!st.active)
                                shape.rotation = 0
                        }
                    }

                    CustomText {
                        anchors.centerIn: parent
                        visible: st.active
                        content: cell.modelData.toString()
                        size: 10
                        weight: 800
                        customColor: Colors.primaryText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.focusWs(cell.modelData, st.ws)
                    }
                }
            }
        }
    }

    Component {
        id: wormComp
        Rectangle {
            id: track
            readonly property real dot: 8
            readonly property real pill: 22
            readonly property real gap: 12
            readonly property int activeIndex: root.wsIds.indexOf(root.activeWsId)
            implicitWidth: (root.wsCount - 1) * (track.dot + track.gap) + track.pill + 16
            implicitHeight: 30
            radius: 15
            color: Colors.surfaceContainer

            Repeater {
                model: root.wsIds
                delegate: Rectangle {
                    id: dotItem
                    required property int modelData
                    required property int index
                    WsState { id: st; wsId: dotItem.modelData }
                    readonly property bool before: track.activeIndex >= 0 && dotItem.index > track.activeIndex
                    x: 8 + dotItem.index * (track.dot + track.gap) + (dotItem.before ? track.pill - track.dot : 0)
                    y: 11
                    width: st.active ? track.pill : track.dot
                    height: 8
                    radius: 4
                    color: st.active ? Colors.primary : st.occupied ? Colors.outline : "transparent"
                    border.width: st.active || st.occupied ? 0 : 1.5
                    border.color: Colors.outlineVariant
                    Behavior on x { SpatialAnim { speed: "fast" } }
                    Behavior on width { SpatialAnim { speed: "fast" } }
                    Behavior on color { EffectsColorAnim {} }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -5
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.focusWs(dotItem.modelData, st.ws)
                    }
                }
            }
        }
    }

    Component {
        id: numbersComp
        Item {
            id: nums
            readonly property real cell: 24
            readonly property int activeIndex: root.wsIds.indexOf(root.activeWsId)
            implicitWidth: root.wsCount * nums.cell
            implicitHeight: 30

            Row {
                Repeater {
                    model: root.wsIds
                    delegate: Item {
                        id: numItem
                        required property int modelData
                        WsState { id: st; wsId: numItem.modelData }
                        width: nums.cell
                        height: 30

                        CustomText {
                            anchors.centerIn: parent
                            content: numItem.modelData.toString()
                            size: 13
                            weight: st.active ? 800 : 600
                            customColor: st.active ? Colors.primary
                                       : st.occupied ? Colors.surfaceText : Colors.outlineVariant
                            Behavior on customColor { EffectsColorAnim {} }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.focusWs(numItem.modelData, st.ws)
                        }
                    }
                }
            }

            Rectangle {
                visible: nums.activeIndex >= 0
                x: Math.max(0, nums.activeIndex) * nums.cell + (nums.cell - width) / 2
                y: 25
                width: 12
                height: 3
                radius: 1.5
                color: Colors.primary
                Behavior on x { SpatialAnim { speed: "fast" } }
            }
        }
    }

    Component {
        id: stripComp
        Rectangle {
            implicitWidth: stripRow.implicitWidth + 6
            implicitHeight: 30
            radius: 15
            color: Colors.surfaceContainer

            Row {
                id: stripRow
                anchors.centerIn: parent
                spacing: 3

                Repeater {
                    model: root.wsIds
                    delegate: Rectangle {
                        id: seg
                        required property int modelData
                        WsState { id: st; wsId: seg.modelData }
                        width: st.occupied ? Math.max(24, icons.implicitWidth + 14) : st.active ? 25 : 10
                        height: 24
                        radius: 12
                        color: st.active ? Colors.primaryContainer
                             : st.occupied ? Colors.surfaceContainerHigh : "transparent"
                        Behavior on width { SpatialAnim { speed: "fast" } }
                        Behavior on color { EffectsColorAnim {} }
                        Component.onCompleted: ServiceWorkspaces.refreshToplevels()

                        Rectangle {
                            anchors.centerIn: parent
                            visible: !st.occupied
                            width: 2
                            height: st.active ? 10 : 12
                            radius: 1
                            color: st.active ? Colors.primaryContainerText : Colors.outlineVariant
                        }

                        Row {
                            id: icons
                            anchors.centerIn: parent
                            spacing: 5
                            visible: st.occupied
                            Repeater {
                                model: st.occupied && st.ws ? st.ws.toplevels : null
                                delegate: IconImage {
                                    required property var modelData
                                    implicitSize: 15
                                    source: Quickshell.iconPath(DesktopEntries.heuristicLookup(modelData.wayland?.appId)?.icon,
                                                                "image-missing")
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.focusWs(seg.modelData, st.ws)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: kanjiComp
        Row {
            spacing: 3
            Repeater {
                model: root.wsIds
                delegate: Rectangle {
                    id: kan
                    required property int modelData
                    WsState { id: st; wsId: kan.modelData }
                    width: 26
                    height: 26
                    radius: 13
                    color: st.active ? Colors.primary : "transparent"
                    Behavior on color { EffectsColorAnim {} }

                    CustomText {
                        anchors.centerIn: parent
                        content: ServiceJp.count(kan.modelData)
                        family: ServiceJp.serif
                        size: String(ServiceJp.count(kan.modelData)).length > 1 ? 10 : 14
                        weight: 700
                        customColor: st.active ? Colors.primaryText
                                   : st.occupied ? Colors.surfaceText : Colors.outlineVariant
                        Behavior on customColor { EffectsColorAnim {} }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.focusWs(kan.modelData, st.ws)
                    }
                }
            }
        }
    }
}
