import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root

    required property Item launcher
    readonly property Item appView: nav

    readonly property bool searching: root.launcher.searching
    readonly property var apps: root.searching ? root.launcher.filteredApps : []
    readonly property bool hasTop: root.apps.length > 0
    readonly property var topApp: root.hasTop ? root.apps[0] : null
    readonly property bool compact: root.height < 460
    readonly property var actions: {
        if (!root.searching) return []
        const q = root.launcher.query
        const out = []
        if (ServiceLauncher.enabledModes.some(m => m.id === "run"))
            out.push({ icon: "terminal", label: "Run “" + q + "” in a terminal", key: "run" })
        out.push({ icon: "travel_explore", label: "Search the web for “" + q + "”", key: "web" })
        return out
    }
    readonly property var model: {
        const out = []
        if (root.searching) {
            if (root.apps.length > 1) out.push({ header: "APPLICATIONS" })
            for (let i = 1; i < root.apps.length; i++)
                out.push({ app: root.apps[i], hint: root.launcher.categoryOf(root.apps[i]) })
            return out
        }
        const sug = root.launcher.mostUsed(6)
        if (sug.length > 0) {
            out.push({ header: "SUGGESTED" })
            for (const a of sug) out.push({ app: a, hint: root.launcher.timeAgo(a) || "Pinned" })
        }
        out.push({ header: "ALL APPS" })
        for (const a of root.launcher.filteredApps) out.push({ app: a, hint: root.launcher.categoryOf(a) })
        return out
    }

    function runAction(a) {
        const q = root.launcher.query
        if (a.key === "run") {
            root.launcher.setQuery("> " + q)
        } else {
            Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(q)])
            root.launcher.closed()
        }
    }

    Item {
        id: nav
        property int activeIndex: 0
        readonly property int columns: 1
        readonly property int topCount: root.hasTop ? 1 : 0
        readonly property int navCount: nav.topCount + list.navCount + root.actions.length

        function activateIndex(i) {
            if (i < nav.topCount) {
                root.launcher.launch(root.topApp)
            } else if (i < nav.topCount + list.navCount) {
                list.activateIndex(i)
            } else {
                const a = root.actions[i - nav.topCount - list.navCount]
                if (a) root.runAction(a)
            }
        }

        function reveal(i) {
            if (i >= nav.topCount && i < nav.topCount + list.navCount)
                list.reveal(i)
        }
    }

    component Pill: Rectangle {
        id: pill
        property string label: ""
        property bool filled: false
        signal tapped
        implicitWidth: pillText.implicitWidth + 28
        implicitHeight: 34
        radius: 17
        color: pill.filled ? Colors.primary : "transparent"
        border.width: pill.filled ? 0 : 1
        border.color: Colors.outlineVariant
        CustomText {
            id: pillText
            anchors.centerIn: parent
            content: pill.label
            size: 12
            weight: 700
            customColor: pill.filled ? Colors.primaryText : Colors.surfaceText
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.tapped()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        LauncherSearch {
            launcher: root.launcher
            Layout.fillWidth: true
            Layout.preferredHeight: root.compact ? 50 : 60
            radius: height / 2
            fontSize: root.compact ? 15 : 17
        }

        LauncherModeArea {
            launcher: root.launcher
            visible: !root.launcher.isApps
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Rectangle {
            id: topCard
            visible: root.launcher.isApps && root.hasTop
            Layout.fillWidth: true
            Layout.preferredHeight: root.compact ? 76 : 96
            radius: 22
            color: nav.activeIndex === 0 ? Colors.secondaryContainer : Colors.surfaceContainer
            Behavior on color { ColorAnimation { duration: 100 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 14

                LauncherIcon {
                    app: root.topApp
                    size: root.compact ? 44 : 60
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    CustomText {
                        content: "TOP HIT"
                        size: 10
                        weight: 700
                        font.letterSpacing: 1
                        customColor: Colors.primary
                    }
                    CustomText {
                        Layout.fillWidth: true
                        content: root.topApp?.name ?? ""
                        size: root.compact ? 16 : 20
                        weight: 700
                        elide: Text.ElideRight
                        customColor: nav.activeIndex === 0 ? Colors.secondaryContainerText : Colors.surfaceText
                    }
                    CustomText {
                        Layout.fillWidth: true
                        visible: root.width >= 420
                        content: [root.topApp?.comment || root.topApp?.genericName || "", root.launcher.categoryOf(root.topApp)]
                            .filter(x => x !== "").join(" · ")
                        size: 12
                        elide: Text.ElideRight
                        customColor: Colors.outline
                    }
                }

                Pill {
                    label: "Open"
                    filled: true
                    onTapped: root.launcher.launch(root.topApp)
                }
                Pill {
                    visible: root.width >= 540
                    label: root.topApp && ServiceApps.isPinned(root.topApp) ? "Unpin" : "Pin"
                    onTapped: if (root.topApp) ServiceApps.togglePin(root.topApp)
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onEntered: nav.activeIndex = 0
                onClicked: event => {
                    if (event.button === Qt.RightButton) root.launcher.openMenu(topCard, event.x, event.y, root.topApp)
                    else root.launcher.launch(root.topApp)
                }
            }
        }

        LauncherRows {
            id: list
            visible: root.launcher.isApps
            launcher: root.launcher
            nav: nav
            indexOffset: nav.topCount
            Layout.fillWidth: true
            Layout.fillHeight: true
            rows: root.model
            rowHeight: root.compact ? 44 : 52
            iconSize: root.compact ? 26 : 32
            showHints: root.width >= 400
            keyHints: true
        }

        ColumnLayout {
            visible: root.launcher.isApps && root.actions.length > 0 && root.height >= 400
            Layout.fillWidth: true
            spacing: 2

            CustomText {
                Layout.leftMargin: 12
                content: "ACTIONS"
                size: 11
                weight: 700
                font.letterSpacing: 0.8
                customColor: Colors.outline
            }

            Repeater {
                model: root.actions
                delegate: Rectangle {
                    id: act
                    required property var modelData
                    required property int index
                    readonly property int navIndex: nav.topCount + list.navCount + act.index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 14
                    color: nav.activeIndex === act.navIndex ? Colors.secondaryContainer
                         : actArea.containsMouse ? Qt.alpha(Colors.primary, 0.08) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12
                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            radius: 10
                            color: Colors.surfaceContainerHigh
                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: act.modelData.icon
                                iconSize: 18
                                customColor: Colors.primary
                            }
                        }
                        CustomText {
                            Layout.fillWidth: true
                            content: act.modelData.label
                            size: 13
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: actArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: nav.activeIndex = act.navIndex
                        onClicked: root.runAction(act.modelData)
                    }
                }
            }
        }

        RowLayout {
            visible: root.width >= 460 && root.height >= 420
            Layout.fillWidth: true
            spacing: 14

            Repeater {
                model: [["↑↓", "Move"], ["↵", "Open"], ["=", "Calculate"], [":", "Emoji"], [">", "Run"]]
                    .slice(0, root.width >= 640 ? 5 : root.width >= 540 ? 4 : 2)
                delegate: Row {
                    required property var modelData
                    spacing: 6
                    LauncherKey { label: parent.modelData[0] }
                    CustomText { anchors.verticalCenter: parent.verticalCenter; content: parent.modelData[1]; size: 11; customColor: Colors.outline }
                }
            }
            Item { Layout.fillWidth: true }
            Row {
                spacing: 6
                LauncherKey { label: "Esc" }
                CustomText { anchors.verticalCenter: parent.verticalCenter; content: "Close"; size: 11; customColor: Colors.outline }
            }
        }
    }
}
