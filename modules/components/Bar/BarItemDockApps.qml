import Quickshell
import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root

    property Item host: null
    property string itemId: ""
    readonly property bool shown: root.model.length > 0

    readonly property string showMode: BarLayout.opt(root.itemId, "show") ?? "all"
    readonly property bool dimmed: BarLayout.opt(root.itemId, "dim") === true

    readonly property var model: {
        const all = ServiceApps.dockModel
        if (root.showMode === "pinned")   return all.filter(e => !!e.pinned)
        if (root.showMode === "unpinned") return all.filter(e => !e.pinned)
        if (root.showMode === "idle")     return all.filter(e => !!e.pinned && (e.toplevels?.length ?? 0) === 0)
        return all
    }
    readonly property int entriesVersion: ServiceApps.list.length
    readonly property real icon: root.host && root.host.iconSize ? root.host.iconSize : 32
    readonly property real cell: root.icon + 12
    readonly property real stride: root.cell + 2
    readonly property bool editing: !!root.host && !!root.host.editing
    property real gripW: root.editing ? 22 : 0

    readonly property var appRects: root.model.map((e, i) => ({
        appId: e.appId ?? "",
        pinned: !!e.pinned,
        x: root.gripW + i * root.stride,
        w: root.cell
    }))

    readonly property QtObject editor: root.host && root.host.editor ? root.host.editor : null
    readonly property bool appDrag: !!root.editor && root.editor.mode === "app"
    readonly property int dragFrom: {
        if (!root.appDrag)
            return -1
        const want = root.editor.appId.toLowerCase()
        return root.model.findIndex(e => (e.appId ?? "").toLowerCase() === want)
    }
    readonly property int dropAt: root.appDrag ? root.editor.appDropIndex : -1

    function shiftFor(i) {
        if (root.dropAt < 0 || root.dragFrom < 0 || i === root.dragFrom)
            return 0
        let s = 0
        let j = i
        if (i > root.dragFrom) {
            s -= root.stride
            j = i - 1
        }
        if (j >= root.dropAt)
            s += root.stride
        return s
    }

    implicitWidth: root.gripW + Math.max(0, root.model.length * root.stride - 2)
    implicitHeight: root.icon + 22
    opacity: root.dimmed && !root.editing ? 0.55 : 1
    Behavior on opacity { EffectsAnim { speed: "fast" } }

    Behavior on gripW {
        SpatialAnim { speed: "fast" }
    }

    Rectangle {
        visible: root.gripW > 1
        x: 2
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, root.gripW - 6)
        height: root.cell - 8
        radius: width / 2
        color: Qt.alpha(Colors.outline, 0.14)
        opacity: Math.min(1, root.gripW / 22)

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: "drag_indicator"
            iconSize: 16
            customColor: Colors.surfaceText
        }
    }

    Repeater {
        model: root.model

        delegate: Item {
            id: dockItem
            required property var modelData
            required property int index

            readonly property bool isRunning: dockItem.modelData.toplevels.length > 0
            readonly property bool isActive: dockItem.modelData.toplevels.some(t => t.activated)
            readonly property int winCount: Math.min(dockItem.modelData.toplevels.length, 3)
            readonly property bool pinned: !!dockItem.modelData.pinned
            readonly property bool offer: root.editing && !dockItem.pinned

            x: root.gripW + dockItem.index * root.stride
            width: root.cell
            height: root.height
            opacity: root.appDrag && dockItem.index === root.dragFrom ? 0 : 1

            transform: Translate {
                x: root.shiftFor(dockItem.index)
                Behavior on x {
                    SpatialAnim { speed: "fast" }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: root.icon + 8
                height: root.icon + 8
                radius: 12
                color: dockIconArea.containsMouse
                    ? Colors.primaryContainer
                    : dockItem.isActive
                        ? Qt.alpha(Colors.primaryContainer, 0.45)
                        : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                scale: dockIconArea.containsMouse ? 1.15 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
                }
            }

            Image {
                anchors.centerIn: parent
                width: root.icon
                height: root.icon
                source: root.entriesVersion >= 0
                    ? Quickshell.iconPath(DesktopEntries.heuristicLookup(dockItem.modelData.appId)?.icon, "image-missing")
                    : ""
                sourceSize.width: 48
                sourceSize.height: 48
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                opacity: dockItem.offer ? 0.5 : 1
                Behavior on opacity { EffectsAnim { speed: "fast" } }

                scale: dockIconArea.containsMouse ? 1.12 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
                }
            }

            Rectangle {
                visible: dockItem.offer
                x: parent.width / 2 + root.icon / 2 - width + 4
                y: parent.height / 2 - root.icon / 2 - 4
                width: 18
                height: 18
                radius: 9
                color: Colors.primary

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "push_pin"
                    iconSize: 12
                    customColor: Colors.primaryText
                }
            }

            Rectangle {
                visible: dockItem.isRunning
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 3
                width: dockItem.winCount === 1 ? 6 : dockItem.winCount === 2 ? 12 : 18
                height: 4
                radius: 2
                color: dockItem.isActive ? Colors.primary : Qt.alpha(Colors.primary, 0.45)

                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: dockIconArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onEntered: if (root.host && root.host.appEntered) root.host.appEntered(dockItem.modelData, dockItem)
                onExited: if (root.host && root.host.appExited) root.host.appExited()

                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        if (dockItem.modelData.toplevels.length > 0)
                            dockItem.modelData.toplevels[0].activate()
                        else
                            ServiceApps.launch(dockItem.modelData.appId)
                    } else if (root.host && root.host.appMenu) {
                        root.host.appMenu(dockItem.modelData, dockItem)
                    }
                }
            }
        }
    }
}
