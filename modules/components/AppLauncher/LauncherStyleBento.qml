import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root

    required property Item launcher
    readonly property Item appView: root.launcher.searching ? results : allGrid

    readonly property bool wide: root.width >= 640
    readonly property bool showBento: root.height >= 520 && !root.launcher.searching
    readonly property bool showRecent: root.width >= 760
    readonly property int cols: bentoBox.width >= 520 ? 4 : 2
    readonly property var spans: root.cols === 4
        ? [[2, 2], [2, 1], [1, 1], [1, 1], [2, 1], [1, 1], [1, 1]]
        : [[2, 2], [2, 1], [1, 1], [1, 1]]
    readonly property var tiles: root.launcher.mostUsed(root.spans.length)
    readonly property int rowH: root.height >= 700 ? 84 : 72

    property var now: new Date()
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
    readonly property string greeting: {
        const h = root.now.getHours()
        return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : "Good evening"
    }

    function subFor(app, short) {
        const n = root.launcher.usageCount(app)
        if (n > 0) return short ? n + "×" : "Opened " + n + (n === 1 ? " time" : " times")
        return "Pinned"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 16

        GridLayout {
            Layout.fillWidth: true
            columns: root.wide ? 2 : 1
            columnSpacing: 20
            rowSpacing: 10

            ColumnLayout {
                spacing: 2
                CustomText {
                    content: Qt.formatDateTime(root.now, "dddd, d MMMM · h:mm AP")
                    size: 13
                    customColor: Colors.outline
                }
                CustomText {
                    content: root.greeting
                    size: root.wide ? 28 : 24
                    weight: 700
                }
            }

            LauncherSearch {
                launcher: root.launcher
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 26
                placeholder: "Type to search " + ServiceApps.list.length + " apps"
            }
        }

        LauncherModeArea {
            launcher: root.launcher
            visible: !root.launcher.isApps
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        LauncherRows {
            id: results
            visible: root.launcher.isApps && root.launcher.searching
            launcher: root.launcher
            Layout.fillWidth: true
            Layout.fillHeight: true
            rows: root.launcher.filteredApps.map(a => ({ app: a, hint: root.launcher.categoryOf(a) }))
            rowHeight: 54
            iconSize: 32
            showComments: root.width >= 520
            keyHints: true
        }

        RowLayout {
            visible: root.launcher.isApps && root.showBento && root.tiles.length > 0
            Layout.fillWidth: true
            spacing: 16

            Item {
                id: bentoBox
                Layout.fillWidth: true
                Layout.preferredHeight: bento.implicitHeight

                GridLayout {
                    id: bento
                    width: parent.width
                    columns: root.cols
                    columnSpacing: 10
                    rowSpacing: 10

                    Repeater {
                        model: root.tiles
                        delegate: Rectangle {
                            id: tile
                            required property var modelData
                            required property int index
                            readonly property var span: root.spans[tile.index]
                            readonly property bool big: tile.span[1] === 2
                            readonly property bool accent: tile.index === 0
                            readonly property bool small: tile.span[0] === 1

                            Layout.columnSpan: tile.span[0]
                            Layout.rowSpan: tile.span[1]
                            Layout.fillWidth: true
                            Layout.preferredWidth: tile.span[0]
                            Layout.preferredHeight: tile.big ? root.rowH * 2 + 10 : root.rowH
                            radius: 24
                            color: tile.accent ? Colors.primaryContainer
                                 : tileArea.containsMouse ? Colors.surfaceContainerHigh : Colors.surfaceContainer
                            Behavior on color { ColorAnimation { duration: 100 } }

                            LauncherIcon {
                                visible: tile.big
                                x: 16
                                y: 16
                                app: tile.modelData
                                size: Math.min(72, tile.height - 80)
                            }

                            ColumnLayout {
                                visible: tile.big
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 16
                                spacing: 2
                                CustomText {
                                    Layout.fillWidth: true
                                    content: tile.modelData.name
                                    size: 20
                                    weight: 700
                                    elide: Text.ElideRight
                                    customColor: tile.accent ? Colors.primaryContainerText : Colors.surfaceText
                                }
                                CustomText {
                                    content: root.subFor(tile.modelData, false)
                                    size: 12
                                    customColor: tile.accent ? Colors.primaryContainerText : Colors.outline
                                }
                            }

                            RowLayout {
                                visible: !tile.big
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 12
                                spacing: 10
                                LauncherIcon {
                                    app: tile.modelData
                                    size: tile.small ? 32 : 40
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    CustomText {
                                        Layout.fillWidth: true
                                        content: tile.modelData.name
                                        size: tile.small ? 12 : 14
                                        weight: 700
                                        elide: Text.ElideRight
                                    }
                                    CustomText {
                                        Layout.fillWidth: true
                                        content: root.subFor(tile.modelData, tile.small)
                                        size: 11
                                        elide: Text.ElideRight
                                        customColor: Colors.outline
                                    }
                                }
                            }

                            MouseArea {
                                id: tileArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: event => {
                                    if (event.button === Qt.RightButton)
                                        root.launcher.openMenu(tileArea, event.x, event.y, tile.modelData)
                                    else
                                        root.launcher.launch(tile.modelData)
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: root.showRecent
                Layout.preferredWidth: 260
                Layout.preferredHeight: bento.implicitHeight
                radius: 24
                color: Colors.surfaceContainer

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    anchors.topMargin: 14
                    spacing: 0

                    CustomText {
                        Layout.bottomMargin: 6
                        content: "RECENT"
                        size: 11
                        weight: 700
                        font.letterSpacing: 0.8
                        customColor: Colors.primary
                    }

                    Repeater {
                        model: ServiceApps.recent(Math.max(1, Math.floor((bento.implicitHeight - 40) / 46)))
                        delegate: Item {
                            id: rec
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46

                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: -8
                                anchors.rightMargin: -8
                                radius: 12
                                color: recArea.containsMouse ? Qt.alpha(Colors.primary, 0.08) : "transparent"
                            }
                            RowLayout {
                                anchors.fill: parent
                                spacing: 10
                                LauncherIcon { app: rec.modelData; size: 28 }
                                CustomText {
                                    Layout.fillWidth: true
                                    content: rec.modelData.name
                                    size: 13
                                    weight: 600
                                    elide: Text.ElideRight
                                }
                                CustomText {
                                    content: root.launcher.timeAgo(rec.modelData)
                                    size: 11
                                    customColor: Colors.outline
                                }
                            }
                            MouseArea {
                                id: recArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.launcher.launch(rec.modelData)
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }

        ColumnLayout {
            visible: root.launcher.isApps && !root.launcher.searching
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                CustomText {
                    Layout.fillWidth: true
                    content: "ALL APPS"
                    size: 11
                    weight: 700
                    font.letterSpacing: 0.8
                    customColor: Colors.outline
                }
                CustomText {
                    content: ServiceApps.list.length + " apps"
                    size: 12
                    weight: 600
                    customColor: Colors.primary
                }
            }

            LauncherGrid {
                id: allGrid
                launcher: root.launcher
                Layout.fillWidth: true
                Layout.fillHeight: true
                apps: root.launcher.filteredApps
                iconSize: ServiceLauncher.iconSize + 6
                minCell: 88
                plate: "none"
            }
        }
    }
}
