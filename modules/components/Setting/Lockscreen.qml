pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Widgets
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents
import qs.modules.components.LockScreen as L

Item {
    id: root

    readonly property var cfg: SettingsConfig.lockscreen ?? ({})
    readonly property var greeterCfg: SettingsConfig.greeter ?? ({})

    readonly property string activeLayout: L.LockCatalog.normalize(root.cfg.layout)
    readonly property string activeGreeter: L.LockCatalog.normalize(root.greeterCfg.layout)

    property bool greeterInstalled: false
    property string target: "lock"

    readonly property bool targetGreeter: root.greeterInstalled && root.target === "greeter"
    readonly property string activeValue: root.targetGreeter ? root.activeGreeter : root.activeLayout

    readonly property var targets: [
        { value: "lock",    label: "Lock screen",  icon: "lock" },
        { value: "greeter", label: "Login screen", icon: "login" }
    ]

    readonly property var toggles: [
        { key: "showDate",   label: "Date",         blurb: "Day and full date under the clock" },
        { key: "showStatus", label: "Status",       blurb: "Weather, battery, network, notifications" },
        { key: "showMusic",  label: "Music",        blurb: "Now playing and transport controls" },
        { key: "showPower",  label: "Power",        blurb: "Sleep, restart and shut down" }
    ]

    function patch(o) {
        const base = Object.assign({}, SettingsConfig.lockscreen)
        delete base.clockStyle
        base.layout = L.LockCatalog.normalize(base.layout)
        SettingsConfig.lockscreen = Object.assign(base, o)
    }

    function patchGreeter(o) {
        const base = Object.assign({}, SettingsConfig.greeter)
        base.layout = L.LockCatalog.normalize(base.layout)
        SettingsConfig.greeter = Object.assign(base, o)
    }

    Process {
        running: true
        command: ["bash", "-c",
            "systemctl is-enabled greetd >/dev/null 2>&1 "
            + "&& grep -rqs -e greeter.qml /etc/greetd/ "
            + "&& echo yes || echo no"]

        stdout: StdioCollector {
            onStreamFinished: root.greeterInstalled = text.trim() === "yes"
        }
    }

    component SectionLabel: CustomText {
        Layout.topMargin: 20
        size: 13
        customColor: Colors.primary
    }

    Flickable {
        ScrollBar.vertical: CustomScrollBar {}
        anchors.fill: parent
        contentHeight: column.implicitHeight
        contentWidth: width
        clip: true

        ColumnLayout {
            id: column
            width: parent.width
            anchors { top: parent.top; left: parent.left; right: parent.right }
            anchors { leftMargin: 5; rightMargin: 5; topMargin: 5 }
            spacing: 0

            CustomText {
                Layout.topMargin: 6
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                content: "Each style brings its own backdrop, clock and animations. Choose style opens a full-screen picker with a live preview."
                size: 12
                customColor: Colors.outline
            }

            SectionLabel { content: "Layout" }

            M3ButtonGroup {
                Layout.topMargin: 8
                Layout.preferredHeight: 34
                visible: root.greeterInstalled
                model: root.targets
                textSize: 12
                iconSize: 15
                activeCheck: value => value === root.target
                onSegmentClicked: value => root.target = value
            }

            CustomText {
                Layout.topMargin: 8
                content: root.targetGreeter
                    ? "Shown by greetd before you sign in. It is a login screen only \u2014 no music, weather, battery or network."
                    : "Shown when the session is locked."
                size: 12
                customColor: Colors.outline
            }

            Rectangle {
                id: current
                readonly property var entry: L.LockCatalog.entry(root.activeValue)
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.preferredHeight: currentCol.implicitHeight + 16
                radius: 20
                color: Colors.surfaceContainer

                ColumnLayout {
                    id: currentCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 10

                    ClippingRectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: width * 0.5625
                        radius: 14
                        color: "black"

                        L.LockPreview {
                            anchors.fill: parent
                            layoutStyle: root.activeValue
                            greeter: root.targetGreeter
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            radius: 14
                            border.width: 1
                            border.color: Qt.alpha(Colors.outlineVariant, 0.4)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        Layout.rightMargin: 2
                        Layout.bottomMargin: 2
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            CustomText { content: current.entry.label; size: 16; weight: 700; customColor: Colors.primary }
                            CustomText { Layout.fillWidth: true; content: current.entry.blurb; size: 12; customColor: Colors.outline }
                        }

                        Rectangle {
                            implicitWidth: chooseRow.implicitWidth + 32
                            implicitHeight: 40
                            radius: 20
                            color: Colors.primary

                            RowLayout {
                                id: chooseRow
                                anchors.centerIn: parent
                                spacing: 8
                                MaterialIconSymbol { content: "style"; iconSize: 18; customColor: Colors.primaryText }
                                CustomText { content: "Choose style"; size: 13; weight: 700; customColor: Colors.primaryText }
                            }

                            RippleEffect {
                                anchors.fill: parent
                                radius: 20
                                onClicked: GlobalStates.lockSelectorOpen = true
                            }
                        }
                    }
                }
            }

            SectionLabel { content: "Elements" }

            ColumnLayout {
                Layout.topMargin: 6
                Layout.fillWidth: true
                spacing: 3

                Repeater {
                    model: root.toggles

                    delegate: CustomCard {
                        id: toggleCard
                        required property int index
                        required property var modelData

                        autoRadius: false
                        topRadius: toggleCard.index === 0 ? 20 : 5
                        bottomRadius: toggleCard.index === root.toggles.length - 1 ? 20 : 5

                        RowLayout {
                            Layout.fillWidth: true

                            ColumnLayout {
                                spacing: 2
                                CustomText { content: toggleCard.modelData.label; size: 14 }
                                CustomText {
                                    content: toggleCard.modelData.blurb
                                    size: 12
                                    customColor: Colors.outline
                                }
                            }

                            Item { Layout.fillWidth: true }

                            CustomToogle {
                                isToggleOn: root.cfg[toggleCard.modelData.key] ?? true
                                onToggled: function(state) {
                                    var o = {}
                                    o[toggleCard.modelData.key] = state
                                    root.patch(o)
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
