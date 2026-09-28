import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "notebook"
    tile: WidgetSizes.wide
    resizable: true
    minSpan: Qt.size(3, 2)
    maxSpan: Qt.size(4, 3)
    defaultPos: Qt.point(585, 165)

    readonly property var vaults: root.preview
        ? [{ name: "Notes", count: 120, words: 96233, recent: [{ title: "Weekend plans", path: "", mtime: 0 }, { title: "Reading list", path: "", mtime: 0 }] },
           { name: "Journal", count: 34, words: 37529, recent: [] }]
        : ServicePersonal.vaults
    readonly property var active: root.preview ? root.vaults[0] : ServicePersonal.activeVault
    readonly property int notes: root.vaults.reduce((a, v) => a + (v.count ?? 0), 0)
    readonly property int words: root.vaults.reduce((a, v) => a + (v.words ?? 0), 0)
    readonly property var recent: (root.active?.recent ?? []).slice(0, root.rows >= 3 ? 4 : 2)
    property string flash: ""

    function ago(t) {
        if (!t) return ""
        const d = Math.floor((Date.now() / 1000 - t) / 86400)
        return d < 1 ? "today" : d === 1 ? "yesterday" : d < 30 ? d + " d ago" : Qt.formatDate(new Date(t * 1000), "d MMM")
    }

    Timer { id: flashTimer; interval: 2200; onTriggered: root.flash = "" }

    WidgetCard {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: parent.pad
            spacing: 5

            WidgetTitle {
                Layout.fillWidth: true
                icon: "menu_book"
                title: "Notebook"
                detail: root.notes + " notes"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Repeater {
                    model: root.vaults.slice(0, 2).map(v => [v.count, v.name]).concat([[Math.round(root.words / 1000) + "k", "words"]])
                    delegate: ColumnLayout {
                        required property var modelData
                        spacing: 0
                        CustomText { content: String(parent.modelData[0]); size: 18; weight: 600 }
                        CustomText {
                            content: parent.modelData[1]
                            size: 11
                            customColor: Colors.outline
                            Layout.maximumWidth: 90
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Repeater {
                model: root.recent
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    radius: 8
                    color: rowArea.containsMouse ? Colors.surfaceContainerHigh : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 8
                        MaterialIconSymbol { content: "edit_note"; iconSize: 15; customColor: Colors.secondary }
                        CustomText {
                            Layout.fillWidth: true
                            content: row.modelData.title.replace(/\.excalidraw$/, "")
                            size: 12
                            elide: Text.ElideRight
                        }
                        CustomText { content: root.ago(row.modelData.mtime); size: 11; customColor: Colors.outline }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !root.preview && row.modelData.path !== ""
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ServicePersonal.openNote(row.modelData.path)
                    }
                }
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 16
                color: jot.activeFocus ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh

                HoverHandler {
                    enabled: !root.preview
                    onHoveredChanged: if (!jot.activeFocus) GlobalStates.widgetTextFocus = hovered
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6
                    MaterialIconSymbol {
                        content: root.flash !== "" ? "check" : "add"
                        iconSize: 16
                        customColor: Colors.primary
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        CustomText {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            visible: jot.text === ""
                            elide: Text.ElideRight
                            content: root.flash !== "" ? root.flash
                                : root.active ? "Jot a thought into today’s note…" : "No Obsidian vault found"
                            size: 12
                            customColor: root.flash !== "" ? Colors.primary : Colors.outline
                        }
                        TextInput {
                            id: jot
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            enabled: !root.preview && root.active !== null
                            clip: true
                            color: Colors.surfaceText
                            font.pixelSize: 12
                            font.family: SettingsConfig.general.defaultFont ?? "Rubik"
                            selectByMouse: true
                            onActiveFocusChanged: if (!root.preview) GlobalStates.widgetTextFocus = activeFocus
                            Keys.onEscapePressed: { text = ""; focus = false }
                            onAccepted: {
                                if (ServicePersonal.jot(text)) {
                                    root.flash = "Added to " + ServicePersonal.todayKey(0) + ".md"
                                    flashTimer.restart()
                                    text = ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
