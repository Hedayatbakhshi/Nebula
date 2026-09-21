import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root

    required property Item launcher
    readonly property var appView: rows

    readonly property bool roomy: root.height >= 480
    readonly property bool alphabetical: ServiceLauncher.sortMode !== "used"
    readonly property var suggested: root.launcher.searching || root.launcher.selectedCategory !== "All"
        ? [] : root.launcher.mostUsed(4)

    readonly property var model: {
        const out = []
        const apps = root.launcher.filteredApps
        if (root.launcher.searching) {
            out.push({ header: "RESULTS" })
            for (const a of apps) out.push({ app: a, hint: root.launcher.categoryOf(a) })
            return out
        }
        if (root.suggested.length > 0) {
            out.push({ header: "SUGGESTED", accent: false })
            for (const a of root.suggested) {
                const n = root.launcher.usageCount(a)
                out.push({ app: a, hint: n > 0 ? n + "×" : "Pinned" })
            }
        }
        if (!root.alphabetical) {
            out.push({ header: "ALL APPS" })
            for (const a of apps) out.push({ app: a, hint: root.launcher.categoryOf(a) })
            return out
        }
        let letter = ""
        for (const a of apps) {
            const l = (a.name ?? "?").charAt(0).toUpperCase()
            const key = /[A-Z]/.test(l) ? l : "#"
            if (key !== letter) {
                letter = key
                out.push({ header: key, accent: true })
            }
            out.push({ app: a, hint: root.launcher.categoryOf(a) })
        }
        return out
    }

    readonly property var letters: {
        const out = []
        for (const r of root.model) if (r.header && r.header.length === 1) out.push(r.header)
        return out
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        LauncherSearch {
            launcher: root.launcher
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: 16
            color: Colors.surfaceContainer
        }

        Row {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            spacing: 6
            clip: true
            visible: root.width >= 320 && ServiceLauncher.enabledModes.length > 0

            Repeater {
                model: ServiceLauncher.enabledModes
                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool on: ServiceLauncher.mode === chip.modelData.id
                    width: chipRow.implicitWidth + 20
                    height: 28
                    radius: 8
                    color: chip.on ? Colors.secondaryContainer
                         : chipArea.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6
                        MaterialIconSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            content: chip.modelData.icon
                            iconSize: 14
                            customColor: chip.on ? Colors.secondaryContainerText : Colors.primary
                        }
                        CustomText {
                            anchors.verticalCenter: parent.verticalCenter
                            content: chip.modelData.label
                            size: 11
                            weight: 600
                            customColor: chip.on ? Colors.secondaryContainerText : Colors.surfaceText
                        }
                        CustomText {
                            anchors.verticalCenter: parent.verticalCenter
                            content: chip.modelData.prefix
                            size: 11
                            customColor: Colors.outline
                        }
                    }

                    MouseArea {
                        id: chipArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launcher.setQuery(chip.on ? "" : chip.modelData.prefix + (chip.modelData.prefix === "w" ? " " : ""))
                    }
                }
            }
        }

        LauncherModeArea {
            launcher: root.launcher
            visible: !root.launcher.isApps
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        RowLayout {
            visible: root.launcher.isApps
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            LauncherRows {
                id: rows
                launcher: root.launcher
                Layout.fillWidth: true
                Layout.fillHeight: true
                rows: root.model
                rowHeight: Math.max(44, ServiceLauncher.iconSize + 16)
                iconSize: ServiceLauncher.iconSize
                showHints: root.width >= 380
                keyHints: root.width >= 340
            }

            Column {
                id: scrubber
                visible: root.roomy && !root.launcher.searching && root.letters.length > 3
                Layout.preferredWidth: 18
                Layout.fillHeight: true
                readonly property real step: height / Math.max(1, root.letters.length)

                Repeater {
                    model: scrubber.visible ? root.letters : []
                    delegate: Item {
                        id: letterCell
                        required property string modelData
                        width: 18
                        height: scrubber.step

                        CustomText {
                            anchors.centerIn: parent
                            content: letterCell.modelData
                            size: 10
                            weight: 600
                            customColor: letterArea.containsMouse ? Colors.primary : Colors.outline
                        }

                        MouseArea {
                            id: letterArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rows.positionViewAtIndex(rows.rowOf(letterCell.modelData), ListView.Beginning)
                        }
                    }
                }
            }
        }

        RowLayout {
            visible: root.height >= 440 && root.width >= 340
            Layout.fillWidth: true
            spacing: 12

            Rectangle { Layout.fillWidth: true; Layout.columnSpan: 3; height: 1; color: Colors.surfaceContainerHigh; visible: false }

            Row {
                spacing: 6
                LauncherKey { label: "↑↓" }
                CustomText { anchors.verticalCenter: parent.verticalCenter; content: "Move"; size: 11; customColor: Colors.outline }
            }
            Row {
                spacing: 6
                LauncherKey { label: "↵" }
                CustomText { anchors.verticalCenter: parent.verticalCenter; content: "Open"; size: 11; customColor: Colors.outline }
            }
            Row {
                spacing: 6
                visible: root.width >= 400
                LauncherKey { label: "Esc" }
                CustomText { anchors.verticalCenter: parent.verticalCenter; content: root.launcher.searching ? "Clear" : "Close"; size: 11; customColor: Colors.outline }
            }
            Item { Layout.fillWidth: true }
        }
    }
}
