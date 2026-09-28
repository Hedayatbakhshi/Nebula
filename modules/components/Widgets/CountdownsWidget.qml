import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "countdowns"
    tile: WidgetSizes.strip
    resizable: true
    minSpan: Qt.size(3, 1.5)
    maxSpan: Qt.size(5, 1.5)
    defaultPos: Qt.point(365, 605)

    property bool adding: false

    readonly property var holiday: {
        ServiceClock.date
        const list = ServiceClock.holidayData ?? []
        let best = null
        for (const h of list) {
            if (!h || !h.date) continue
            const n = ServicePersonal.daysUntil(h.date, false)
            if (n < 0) continue
            if (!best || n < best.days) best = { name: h.localName || h.name || "Holiday", days: n, auto: true }
        }
        return best
    }

    readonly property var items: {
        ServiceClock.date
        const out = []
        if (root.preview) return [{ name: "Gandhi Jayanti", days: 9, auto: true }, { name: "Jaipur trip", days: 24, idx: 0 }]
        if (root.holiday) out.push(root.holiday)
        const own = ServicePersonal.countdowns.map((c, i) => ({ name: c.name, days: ServicePersonal.daysUntil(c.date, c.yearly), idx: i }))
            .filter(c => c.days >= 0)
        own.sort((a, b) => a.days - b.days)
        return out.concat(own)
    }
    readonly property int slots: Math.max(1, root.cols - 1)

    component Field: Rectangle {
        id: field
        property alias input: ti
        property string hint: ""
        Layout.fillHeight: true
        Layout.maximumHeight: 36
        radius: 12
        color: ti.activeFocus ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
        CustomText {
            anchors.verticalCenter: parent.verticalCenter
            x: 10
            visible: ti.text === ""
            content: field.hint
            size: 12
            customColor: Colors.outline
        }
        TextInput {
            id: ti
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            color: Colors.surfaceText
            font.pixelSize: 12
            font.family: SettingsConfig.general.defaultFont ?? "Rubik"
            onActiveFocusChanged: if (activeFocus) GlobalStates.widgetTextFocus = true
            Keys.onEscapePressed: {
                root.adding = false
                GlobalStates.widgetTextFocus = false
            }
        }
    }

    function tryAdd() {
        if (ServicePersonal.addCountdown(nameIn.text, dateIn.text)) {
            nameIn.text = ""
            dateIn.text = ""
            root.adding = false
            GlobalStates.widgetTextFocus = false
        } else {
            dateIn.forceActiveFocus()
        }
    }

    WidgetCard {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: parent.pad
            spacing: 8

            WidgetTitle {
                Layout.fillWidth: true
                icon: "hourglass_top"
                title: "Countdowns"
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                visible: !root.adding

                Repeater {
                    model: root.items.slice(0, root.slots)
                    delegate: Rectangle {
                        id: tile
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 14
                        color: Colors.surfaceContainerHigh

                        HoverHandler { id: tileHover }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            anchors.leftMargin: 10
                            spacing: 0
                            CustomText {
                                content: tile.modelData.days === 0 ? "Today" : tile.modelData.days
                                size: tile.modelData.days === 0 ? 18 : 24
                                weight: 600
                                customColor: tile.modelData.auto ? Colors.tertiary : Colors.primary
                            }
                            CustomText {
                                Layout.fillWidth: true
                                content: (tile.modelData.days === 1 ? "day · " : tile.modelData.days === 0 ? "" : "days · ") + tile.modelData.name
                                size: 11
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                                customColor: Colors.surfaceVariantText
                            }
                        }

                        MaterialIconSymbol {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 6
                            visible: tileHover.hovered && tile.modelData.idx !== undefined && !root.preview
                            content: "close"
                            iconSize: 14
                            customColor: Colors.outline
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ServicePersonal.removeCountdown(tile.modelData.idx)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: root.items.length >= root.slots ? 44 : -1
                    Layout.fillWidth: root.items.length < root.slots
                    Layout.fillHeight: true
                    radius: 14
                    color: addArea.containsMouse ? Colors.surfaceContainerHigh : "transparent"
                    border.width: 1.5
                    border.color: Colors.outlineVariant

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        MaterialIconSymbol { anchors.horizontalCenter: parent.horizontalCenter; content: "add"; iconSize: 20; customColor: Colors.outline }
                        CustomText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.items.length < root.slots
                            content: "add a date"
                            size: 11
                            customColor: Colors.outline
                        }
                    }

                    MouseArea {
                        id: addArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !root.preview
                        cursorShape: Qt.PointingHandCursor
                        onEntered: GlobalStates.widgetTextFocus = true
                        onExited: if (!root.adding) GlobalStates.widgetTextFocus = false
                        onClicked: {
                            root.adding = true
                            nameIn.forceActiveFocus()
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6
                visible: root.adding

                Field {
                    id: nameField
                    Layout.fillWidth: true
                    hint: "What’s coming?"
                    input.onAccepted: dateIn.forceActiveFocus()
                }
                Field {
                    id: dateField
                    Layout.preferredWidth: 96
                    hint: "12 Oct"
                    input.onAccepted: root.tryAdd()
                }
                MaterialIconSymbol {
                    content: "check"
                    iconSize: 20
                    customColor: Colors.primary
                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.tryAdd() }
                }
            }
        }
    }

    readonly property Item nameIn: nameField.input
    readonly property Item dateIn: dateField.input
}
