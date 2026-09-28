import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "habits"
    tile: WidgetSizes.wide
    resizable: true
    minSpan: Qt.size(3, 2)
    maxSpan: Qt.size(4, 4)
    defaultPos: Qt.point(585, 385)

    readonly property var list: root.preview
        ? [{ name: "Read 20 min", done: {} }, { name: "8 glasses of water", done: {} }, { name: "Evening walk", done: {} }]
        : ServicePersonal.habits
    readonly property var sample: [[1, 1, 0, 1, 1, 1, 0], [1, 0, 1, 1, 0, 1, 1], [0, 1, 1, 0, 1, 0, 1]]
    readonly property var dayKeys: {
        ServiceClock.date
        return [6, 5, 4, 3, 2, 1, 0].map(o => ServicePersonal.todayKey(-o))
    }
    readonly property int room: Math.max(1, Math.floor((root.height - 96) / 30))
    property bool adding: false

    function isDone(i, k) {
        if (root.preview) return root.sample[i % 3][root.dayKeys.indexOf(k)] === 1
        return !!(root.list[i]?.done ?? {})[k]
    }

    WidgetCard {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: parent.pad
            spacing: 6

            WidgetTitle {
                Layout.fillWidth: true
                icon: "check_circle"
                title: "Habits"
                detail: {
                    if (root.list.length === 0) return ""
                    let n = 0
                    for (let i = 0; i < root.list.length; i++) if (root.isDone(i, root.dayKeys[6])) n++
                    return n + " of " + root.list.length + " today"
                }
            }

            Repeater {
                model: root.list.slice(0, root.room)
                delegate: RowLayout {
                    id: hab
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    spacing: 6

                    HoverHandler { id: habHover }

                    CustomText {
                        Layout.fillWidth: true
                        content: hab.modelData.name
                        size: 13
                        elide: Text.ElideRight
                    }

                    MaterialIconSymbol {
                        visible: habHover.hovered && !root.preview
                        content: "close"
                        iconSize: 14
                        customColor: Colors.outline
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ServicePersonal.removeHabit(hab.index)
                        }
                    }

                    Repeater {
                        model: root.dayKeys
                        delegate: Rectangle {
                            id: dot
                            required property var modelData
                            required property int index
                            readonly property bool on: root.isDone(hab.index, dot.modelData)
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            radius: 9
                            color: dot.on ? Colors.tertiary : (dotArea.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh)
                            border.width: dot.index === 6 ? 2 : 0
                            border.color: Colors.primary
                            Behavior on color { EffectsColorAnim { speed: "fast" } }
                            MouseArea {
                                id: dotArea
                                anchors.fill: parent
                                anchors.margins: -2
                                hoverEnabled: true
                                enabled: !root.preview
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ServicePersonal.toggleHabit(hab.index, dot.modelData)
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.list.length === 0 && !root.adding
                CustomText {
                    Layout.alignment: Qt.AlignCenter
                    content: "Add a habit to start tracking"
                    size: 12
                    customColor: Colors.outline
                }
            }

            Item { Layout.fillHeight: true; visible: root.list.length > 0 || root.adding }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    radius: 14
                    color: habitInput.activeFocus ? Colors.surfaceContainerHighest : "transparent"

                    HoverHandler {
                        enabled: !root.preview
                        onHoveredChanged: if (!habitInput.activeFocus) GlobalStates.widgetTextFocus = hovered
                    }
                    border.width: habitInput.activeFocus ? 0 : 1
                    border.color: Colors.outlineVariant

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6
                        MaterialIconSymbol { content: "add"; iconSize: 15; customColor: Colors.primary }
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            CustomText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: habitInput.text === ""
                                content: "New habit"
                                size: 12
                                customColor: Colors.outline
                            }
                            TextInput {
                                id: habitInput
                                anchors.fill: parent
                                verticalAlignment: TextInput.AlignVCenter
                                enabled: !root.preview
                                clip: true
                                color: Colors.surfaceText
                                font.pixelSize: 12
                                font.family: SettingsConfig.general.defaultFont ?? "Rubik"
                                onActiveFocusChanged: {
                                    root.adding = activeFocus
                                    if (!root.preview) GlobalStates.widgetTextFocus = activeFocus
                                }
                                Keys.onEscapePressed: { text = ""; focus = false }
                                onAccepted: {
                                    ServicePersonal.addHabit(text)
                                    text = ""
                                }
                            }
                        }
                    }
                }

                Row {
                    spacing: 6
                    Layout.rightMargin: 0
                    Repeater {
                        model: ["M", "T", "W", "T", "F", "S", "S"]
                        delegate: CustomText {
                            required property int index
                            width: 18
                            horizontalAlignment: Text.AlignHCenter
                            content: {
                                const k = root.dayKeys[index]
                                const p = k.split("-")
                                return ["S", "M", "T", "W", "T", "F", "S"][new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2])).getDay()]
                            }
                            size: 10
                            customColor: index === 6 ? Colors.primary : Colors.outline
                        }
                    }
                }
            }
        }
    }
}
