import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents

Item {
    id: root

    property Item host: null
    property string itemId: ""
    readonly property bool shown: true
    readonly property bool flexible: true
    readonly property real fixedPart: 40

    readonly property real setWidth: BarLayout.opt(root.itemId, "width") ?? 200
    readonly property bool fixed: root.setWidth > 0
    readonly property real target: root.fixed ? root.setWidth : 200
    readonly property real cap: root.host && root.host.maxWidth > 0
        ? Math.max(0, Math.min(root.target, root.host.maxWidth - root.host.fixedWidth - root.fixedPart))
        : root.target

    implicitWidth: root.fixedPart + (titleBox.visible ? titleBox.width : 0)
    implicitHeight: 32

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        height: 32
        radius: 10
        color: Colors.surfaceContainer

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: Hyprland.activeToplevel ? "ad" : "desktop_windows"
            iconSize: 18
            customColor: Colors.surfaceText
        }
    }

    Item {
        id: titleBox
        x: root.fixedPart
        anchors.verticalCenter: parent.verticalCenter
        visible: root.cap > 4
        width: root.fixed ? root.cap : titleCol.implicitWidth
        height: titleCol.implicitHeight

        ColumnLayout {
            id: titleCol
            width: implicitWidth
            spacing: 0

            CustomText {
                visible: BarLayout.opt(root.itemId, "lines") !== "one"
                Layout.maximumWidth: root.cap
                content: ToplevelManager.activeToplevel
                         ? (ToplevelManager.activeToplevel.appId ?? "")
                         : "Desktop"
                size: 10
                weight: 700
                customColor: Colors.outline
                elide: Text.ElideRight
            }
            CustomText {
                Layout.maximumWidth: root.cap
                content: ToplevelManager.activeToplevel
                         ? (ToplevelManager.activeToplevel.title ?? "")
                         : "Workspace " + (Hyprland.focusedMonitor?.activeWorkspace?.id ?? "")
                size: 13
                weight: 800
                elide: Text.ElideRight
            }
        }
    }
}
