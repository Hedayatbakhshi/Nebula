import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

Item {
    id: root
    anchors.fill: parent

    property string shownKey: ""
    readonly property string wantedKey: GlobalStates.widgetSettingsKey

    readonly property var target: {
        const hosts = WidgetLayout.hosts
        for (let i = hosts.length - 1; i >= 0; i--)
            if (hosts[i].configKey === root.shownKey) return hosts[i]
        return null
    }

    readonly property var family: root.shownKey !== "" ? WidgetCatalog.familyFor(root.shownKey) : null
    readonly property bool hasStyles: root.family !== null && root.family.items.length > 1
                                      && root.family.items[0].styleKey !== undefined
    readonly property var activeItem: {
        if (!root.family) return null
        for (let i = 0; i < root.family.items.length; i++)
            if (root.family.items[i].key === root.shownKey && WidgetCatalog.isActive(root.family.items[i]))
                return root.family.items[i]
        return root.family.items[0]
    }
    readonly property string title: !root.activeItem ? ""
        : root.hasStyles ? root.family.section : root.activeItem.label
    readonly property string subtitle: !root.activeItem ? ""
        : root.hasStyles ? root.activeItem.label + " style" : root.family.section

    readonly property real cardWidth: 340
    readonly property real margin: 16
    readonly property real maxHeight: root.height * 0.72

    readonly property real topLimit: 80
    readonly property point placement: {
        const t = root.target
        if (!t) return Qt.point(root.margin, root.topLimit)
        const w = root.cardWidth
        const h = morph.contentHeight
        const gap = 20
        const clampX = x => Math.max(root.margin, Math.min(root.width - w - root.margin, x))
        const clampY = y => Math.max(root.topLimit, Math.min(root.height - h - root.margin, y))

        const right = t.homeX + t.width + gap
        if (right + w <= root.width - root.margin) return Qt.point(right, clampY(t.homeY))

        const underGear = clampX(t.homeX + t.width - w)
        const below = t.homeY + t.height + gap
        if (below + h <= root.height - root.margin) return Qt.point(underGear, below)
        const above = t.homeY - gap - h
        if (above >= root.topLimit) return Qt.point(underGear, above)

        const left = t.homeX - gap - w
        if (left >= root.margin) return Qt.point(left, clampY(t.homeY))
        return Qt.point(underGear, clampY(t.homeY))
    }
    readonly property real cardX: root.placement.x
    readonly property real cardY: root.placement.y

    onWantedKeyChanged: root.sync()

    function sync() {
        if (morph.opened) {
            if (root.wantedKey !== root.shownKey) morph.close()
            return
        }
        if (root.wantedKey !== "") {
            root.shownKey = root.wantedKey
            morph.open()
        }
    }

    onTargetChanged: if (root.target === null && root.shownKey !== "") goneTimer.restart()

    Timer {
        id: goneTimer
        interval: 250
        onTriggered: if (root.shownKey !== "" && root.target === null) GlobalStates.widgetSettingsKey = ""
    }

    Keys.onEscapePressed: GlobalStates.widgetSettingsKey = ""

    component ActionRow: Rectangle {
        id: row
        property bool first: false
        property bool last: false
        property string icon: ""
        property string label: ""
        property bool danger: false
        signal activated()

        Layout.fillWidth: true
        implicitHeight: 46
        topLeftRadius: row.first ? 20 : 5
        topRightRadius: row.first ? 20 : 5
        bottomLeftRadius: row.last ? 20 : 5
        bottomRightRadius: row.last ? 20 : 5
        color: rowMouse.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
        Behavior on color { EffectsColorAnim {} }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 12
            spacing: 12

            MaterialIconSymbol {
                content: row.icon
                iconSize: 18
                customColor: row.danger ? Colors.error : Colors.primary
            }
            CustomText {
                Layout.fillWidth: true
                content: row.label
                size: 13
                customColor: row.danger ? Colors.error : Colors.surfaceText
            }
            MaterialIconSymbol {
                visible: !row.danger
                content: "chevron_right"
                iconSize: 18
                customColor: Colors.outline
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.activated()
        }
    }

    MorphCard {
        id: morph
        x: root.cardX
        y: root.cardY
        width: root.cardWidth
        contentHeight: Math.min(body.implicitHeight + 32, root.maxHeight)
        cardColor: Colors.surfaceContainer
        cardRadius: 28
        fadeCard: true
        srcWidth: 26
        srcHeight: 26
        srcRadius: 13
        srcX: root.target ? root.target.homeX + root.target.width - 19 - morph.x : 0
        srcY: root.target ? root.target.homeY - 7 - morph.y : 0

        onCloseFinished: {
            root.shownKey = ""
            if (root.wantedKey !== "") {
                root.shownKey = root.wantedKey
                morph.open()
            }
        }

        MouseArea {
            width: morph.width
            height: morph.contentHeight
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
        }

        Flickable {
            id: scroller
            width: morph.width
            height: morph.contentHeight
            contentWidth: width
            contentHeight: body.implicitHeight + 32
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            ColumnLayout {
                id: body
                x: 16
                y: 16
                width: morph.width - 32
                spacing: 0

                // ── Header ────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        implicitWidth: 40
                        implicitHeight: 40
                        radius: 14
                        color: Colors.primaryContainer

                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: "widgets"
                            iconSize: 20
                            customColor: Colors.primaryContainerText
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        CustomText {
                            Layout.fillWidth: true
                            content: root.title
                            size: 16
                            weight: 700
                            customColor: Colors.surfaceText
                            elide: Text.ElideRight
                        }
                        CustomText {
                            Layout.fillWidth: true
                            content: root.subtitle
                            size: 12
                            customColor: Colors.outline
                            elide: Text.ElideRight
                        }
                    }

                    M3IconButton {
                        implicitWidth: 34
                        implicitHeight: 34
                        icon: "close"
                        iconSize: 18
                        onClicked: GlobalStates.widgetSettingsKey = ""
                    }
                }

                // ── Style ─────────────────────────────────────────────
                CustomText {
                    visible: root.hasStyles
                    Layout.topMargin: 18
                    content: "Style"
                    size: 13
                    customColor: Colors.primary
                }

                Flickable {
                    visible: root.hasStyles
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    Layout.preferredHeight: 104
                    contentWidth: styleRow.implicitWidth
                    contentHeight: height
                    clip: true
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: styleRow
                        spacing: 8

                        Repeater {
                            model: root.hasStyles ? root.family.items : []

                            delegate: Rectangle {
                                id: styleTile
                                required property var modelData
                                readonly property bool active: WidgetCatalog.isActive(styleTile.modelData)

                                width: 92
                                height: 104
                                radius: 18
                                color: styleTile.active ? Qt.alpha(Colors.primary, 0.13) : Colors.surfaceContainerHigh
                                border.width: styleTile.active ? 2 : 0
                                border.color: Colors.primary

                                Item {
                                    id: pbox
                                    x: 8
                                    y: 8
                                    width: 76
                                    height: 64
                                    clip: true

                                    Loader {
                                        sourceComponent: styleTile.modelData.comp
                                        transformOrigin: Item.TopLeft
                                        scale: (item && item.implicitWidth > 0 && item.implicitHeight > 0)
                                            ? Math.min(pbox.width / item.implicitWidth,
                                                       pbox.height / item.implicitHeight, 1)
                                            : 1
                                        x: (pbox.width - width * scale) / 2
                                        y: (pbox.height - height * scale) / 2
                                    }
                                }

                                CustomText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 9
                                    content: styleTile.modelData.label
                                    size: 11
                                    weight: styleTile.active ? 700 : 500
                                    customColor: styleTile.active ? Colors.primary : Colors.surfaceText
                                }

                                RippleEffect {
                                    anchors.fill: parent
                                    radius: 18
                                    onClicked: WidgetCatalog.selectStyle(styleTile.modelData)
                                }
                            }
                        }
                    }
                }

                // ── Widget options ────────────────────────────────────
                CustomText {
                    visible: optionsLoader.active
                    Layout.topMargin: 18
                    content: "Options"
                    size: 13
                    customColor: Colors.primary
                }

                Loader {
                    id: optionsLoader
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    active: root.target !== null && root.target.optionsComponent !== null
                    visible: active
                    sourceComponent: root.target ? root.target.optionsComponent : null
                }

                // ── Actions ───────────────────────────────────────────
                CustomText {
                    Layout.topMargin: 18
                    content: "Widget"
                    size: 13
                    customColor: Colors.primary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    spacing: 3

                    ActionRow {
                        first: true
                        icon: "restart_alt"
                        label: "Reset size & position"
                        onActivated: WidgetCatalog.resetLayout(root.shownKey)
                    }

                    ActionRow {
                        icon: "open_in_new"
                        label: "Open in Settings"
                        onActivated: {
                            GlobalStates.widgetSettingsKey = ""
                            GlobalStates.widgetEditMode = false
                            GlobalStates.settingsPage = 3
                            GlobalStates.settingsOpen = true
                        }
                    }

                    ActionRow {
                        last: true
                        danger: true
                        icon: "delete"
                        label: "Remove from desktop"
                        onActivated: {
                            const key = root.shownKey
                            GlobalStates.widgetSettingsKey = ""
                            WidgetCatalog.remove(key)
                        }
                    }
                }
            }
        }
    }
}
