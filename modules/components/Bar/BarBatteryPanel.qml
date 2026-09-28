pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.settings

Item {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property var cell: UPower.devices.values.find(d => d && d.isLaptopBattery) ?? UPower.displayDevice
    readonly property real rate: Math.abs(root.cell.changeRate)
    readonly property real level: Math.max(0, Math.min(1, root.dev.percentage))
    readonly property int state: root.dev.state
    readonly property bool charging: root.state === UPowerDeviceState.Charging
    readonly property bool full: root.state === UPowerDeviceState.FullyCharged
    readonly property bool plugged: !UPower.onBattery
    readonly property bool low: root.level < 0.2 && !root.plugged
    readonly property color tint: root.low ? Colors.error : Colors.primary
    readonly property color onTint: root.low ? Colors.errorText : Colors.primaryText

    readonly property string title: root.charging ? "Charging"
        : root.full ? "Fully charged"
        : root.plugged ? "Plugged in, not charging"
        : root.low ? "Battery low" : "On battery"

    function span(seconds) {
        if (!seconds || seconds <= 0)
            return root.plugged ? "Unplug to see" : "–"
        const h = Math.floor(seconds / 3600)
        const m = Math.round((seconds % 3600) / 60)
        return h > 0 ? h + " h " + m + " min" : m + " min"
    }

    readonly property var stats: [
        { icon: "schedule", tint: Colors.primary,
          label: root.charging ? "Full in" : root.plugged ? "On battery" : "Left",
          value: root.charging ? root.span(root.dev.timeToFull)
               : root.span(root.cell.timeToEmpty > 0 ? root.cell.timeToEmpty
                           : root.rate > 0 ? root.cell.energy / root.rate * 3600 : 0) },
        { icon: "bolt", tint: Colors.tertiary, label: root.charging ? "Charging at" : "Draw",
          value: root.rate > 0.05 ? root.rate.toFixed(1) + " W" : root.plugged ? "Idle on AC" : "–" },
        { icon: "favorite", tint: Colors.secondary, label: "Health",
          value: ServiceUPower.health > 0 ? Math.round(ServiceUPower.health * 100) + "%" : "–" },
        { icon: "battery_full_alt", tint: Colors.primary, label: "Capacity",
          value: root.cell.energyCapacity > 0 ? root.cell.energyCapacity.toFixed(1) + " Wh" : "–" }
    ]

    function iconFor(d) {
        if (d.isLaptopBattery) return "laptop"
        switch (d.type) {
        case UPowerDeviceType.Keyboard: return "keyboard"
        case UPowerDeviceType.Mouse: return "mouse"
        case UPowerDeviceType.Headset:
        case UPowerDeviceType.Headphones: return "headphones"
        case UPowerDeviceType.Phone: return "smartphone"
        case UPowerDeviceType.Tablet: return "tablet"
        case UPowerDeviceType.GamingInput: return "sports_esports"
        case UPowerDeviceType.Speakers: return "speaker"
        case UPowerDeviceType.Pen: return "stylus"
        case UPowerDeviceType.Touchpad: return "touchpad_mouse"
        }
        return "battery_full"
    }

    readonly property var devices: {
        const list = UPower.devices.values.filter(d => d && d.type !== UPowerDeviceType.LinePower
            && (d.isLaptopBattery || (d.isPresent !== false && d.percentage > 0)))
        return list.sort((a, b) => (b.isLaptopBattery ? 1 : 0) - (a.isLaptopBattery ? 1 : 0))
    }

    function nameOf(d) {
        return d.isLaptopBattery ? "This laptop" : (d.model || UPowerDeviceType.toString(d.type))
    }

    function subOf(d) {
        if (d.isLaptopBattery)
            return root.title
        return UPowerDeviceType.toString(d.type)
    }

    implicitWidth: 400
    implicitHeight: col.implicitHeight + 36

    ColumnLayout {
        id: col
        x: 18
        y: 18
        width: root.width - 36
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Item {
                id: cell
                Layout.preferredWidth: 124
                Layout.preferredHeight: 232

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 42
                    height: 14
                    topLeftRadius: 8
                    topRightRadius: 8
                    bottomLeftRadius: 3
                    bottomRightRadius: 3
                    color: Colors.surfaceContainerHighest
                }

                Rectangle {
                    id: body
                    y: 10
                    width: parent.width
                    height: parent.height - 10
                    radius: 32
                    color: Colors.surfaceContainerHighest
                    clip: true

                    Canvas {
                        id: liquid
                        anchors.fill: parent
                        property real phase: 0
                        readonly property real surfaceY: body.height * (1 - root.level)
                        onSurfaceYChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()

                        Connections {
                            target: root
                            function onTintChanged() { liquid.requestPaint() }
                        }

                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.reset()
                            ctx.beginPath()
                            ctx.roundedRect(0, 0, width, height, body.radius, body.radius)
                            ctx.clip()
                            const amp = root.level >= 0.995 ? 0 : 6
                            const wl = width / 1.5
                            ctx.beginPath()
                            ctx.moveTo(0, height)
                            for (let x = 0; x <= width; x += 2)
                                ctx.lineTo(x, liquid.surfaceY + amp * Math.sin((x / wl) * Math.PI * 2 + liquid.phase))
                            ctx.lineTo(width, height)
                            ctx.closePath()
                            ctx.fillStyle = root.tint
                            ctx.fill()
                        }

                        NumberAnimation on phase {
                            running: root.charging && root.visible
                            from: 0
                            to: Math.PI * 2
                            duration: 2400
                            loops: Animation.Infinite
                        }
                        onPhaseChanged: requestPaint()
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        CustomText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            content: Math.round(root.level * 100)
                            family: SettingsConfig.general?.displayFont || "Titan One"
                            renderType: Text.QtRendering
                            size: 40
                            weight: 400
                            customColor: root.level > 0.55 ? root.onTint : Colors.surfaceText
                        }
                        MaterialIconSymbol {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.plugged
                            content: "bolt"
                            iconSize: 22
                            customColor: root.level > 0.45 ? root.onTint : Colors.primary
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    CustomText { Layout.fillWidth: true; content: root.title; size: 17; weight: 600 }
                    CustomText {
                        Layout.fillWidth: true
                        content: root.plugged ? "Plugged in" : "Unplugged"
                        size: 12
                        weight: 400
                        customColor: Colors.surfaceVariantText
                    }
                }

                Repeater {
                    model: root.stats

                    delegate: Rectangle {
                        id: statRow
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: 16
                        color: Colors.surfaceContainerHigh

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10
                            MaterialIconSymbol { content: statRow.modelData.icon; iconSize: 18; customColor: statRow.modelData.tint }
                            CustomText {
                                Layout.fillWidth: true
                                content: statRow.modelData.label
                                size: 12
                                weight: 400
                                customColor: Colors.surfaceVariantText
                            }
                            CustomText { content: statRow.modelData.value; size: 13; weight: 700 }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: ServiceUPower.powerProfiles

                delegate: Rectangle {
                    id: mode
                    required property var modelData
                    required property int index
                    readonly property bool on: ServiceUPower.powerProfile === mode.index
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: modeArea.pressed ? 14 : mode.on ? 22 : 32
                    color: mode.on ? Colors.primary : modeArea.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
                    Behavior on radius { SpatialAnim { speed: "fast" } }
                    Behavior on color { EffectsColorAnim { speed: "fast" } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 3
                        MaterialIconSymbol {
                            anchors.horizontalCenter: parent.horizontalCenter
                            content: mode.modelData.icon
                            iconSize: 22
                            customColor: mode.on ? Colors.primaryText : Colors.surfaceText
                        }
                        CustomText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            content: mode.modelData.name
                            size: 11
                            weight: 600
                            customColor: mode.on ? Colors.primaryText : Colors.surfaceText
                        }
                    }

                    MouseArea {
                        id: modeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ServiceUPower.setPowerProfile(mode.index)
                    }
                }
            }
        }

        CustomText {
            visible: root.devices.length > 0
            content: "Your devices"
            size: 12
            weight: 600
            customColor: Colors.primary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Repeater {
                model: root.devices

                delegate: Rectangle {
                    id: devRow
                    required property var modelData
                    required property int index
                    readonly property real pct: Math.max(0, Math.min(1, devRow.modelData.percentage))
                    readonly property bool first: devRow.index === 0
                    readonly property bool last: devRow.index === root.devices.length - 1
                    Layout.fillWidth: true
                    implicitHeight: 56
                    topLeftRadius: devRow.first ? 18 : 5
                    topRightRadius: devRow.first ? 18 : 5
                    bottomLeftRadius: devRow.last ? 18 : 5
                    bottomRightRadius: devRow.last ? 18 : 5
                    color: Colors.surfaceContainerHigh

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 14
                        spacing: 12

                        Rectangle {
                            implicitWidth: 36
                            implicitHeight: 36
                            radius: 12
                            color: Colors.surfaceContainerHighest
                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: root.iconFor(devRow.modelData)
                                iconSize: 20
                                customColor: Colors.primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            CustomText { Layout.fillWidth: true; content: root.nameOf(devRow.modelData); size: 13; weight: 600 }
                            CustomText {
                                Layout.fillWidth: true
                                content: root.subOf(devRow.modelData)
                                size: 11
                                weight: 400
                                customColor: Colors.outline
                            }
                        }

                        Rectangle {
                            implicitWidth: 70
                            implicitHeight: 6
                            radius: 3
                            color: Colors.surfaceContainerHighest
                            Rectangle {
                                width: parent.width * devRow.pct
                                height: parent.height
                                radius: 3
                                color: devRow.pct < 0.2 ? Colors.error : devRow.pct < 0.35 ? Colors.tertiary : Colors.primary
                            }
                        }

                        CustomText {
                            Layout.preferredWidth: 38
                            horizontalAlignment: Text.AlignRight
                            content: Math.round(devRow.pct * 100) + "%"
                            size: 12
                            weight: 700
                        }
                    }
                }
            }
        }
    }
}
