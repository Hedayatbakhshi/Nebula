pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

Item {
    id: insp

    property QtObject editor: null
    property bool editing: false
    property real topLimit: 48

    readonly property string sel: insp.editor ? insp.editor.selectedItem : ""
    readonly property string itemId: insp.sel.indexOf("dash:") === 0 ? insp.sel.slice(5) : ""
    readonly property bool wanted: insp.editing && insp.itemId !== "" && insp.editor.drawerMode === "inspector"
        && DashLayout.activeDash !== null
    readonly property var entry: insp.itemId !== "" ? DashLayout.entry(insp.itemId) : null
    readonly property var spec: DashLayout.items.find(i => i.id === insp.itemId) ?? null
    readonly property bool legacy: insp.entry ? insp.entry.legacy === true : false

    readonly property var lookOpts: insp.itemId !== "" ? DashLayout.optionsIn(insp.itemId, "look") : []
    readonly property var contentOpts: insp.itemId !== "" ? DashLayout.optionsIn(insp.itemId, "content") : []
    readonly property var sizeOpts: insp.itemId !== "" ? DashLayout.optionsIn(insp.itemId, "size") : []
    readonly property var tabs: [{ id: "look", label: "Look", has: insp.lookOpts.length > 0 },
                                 { id: "content", label: "Content", has: insp.contentOpts.length > 0 },
                                 { id: "size", label: "Size", has: true }].filter(t => t.has)
    property string tab: "look"
    readonly property string shownTab: insp.tabs.some(t => t.id === insp.tab) ? insp.tab : (insp.tabs[0]?.id ?? "size")
    readonly property var shownOpts: insp.shownTab === "look" ? insp.lookOpts
        : insp.shownTab === "content" ? insp.contentOpts : insp.sizeOpts

    property rect dashRect: Qt.rect(0, 0, 0, 0)
    property rect cellRect: Qt.rect(0, 0, 0, 0)

    function locate() {
        const d = DashLayout.activeDash
        if (!d || !insp.parent)
            return
        insp.dashRect = d.mapToItem(insp.parent, 0, 0, d.width, d.height)
        const c = d.cellItem(insp.itemId)
        insp.cellRect = c ? c.mapToItem(insp.parent, 0, 0, c.width, c.height) : Qt.rect(0, 0, 0, 0)
    }

    Timer {
        interval: 80
        repeat: true
        running: insp.wanted
        triggeredOnStart: true
        onTriggered: insp.locate()
    }

    onItemIdChanged: insp.tab = "look"

    readonly property real gap: 28
    readonly property bool onLeft: insp.dashRect.x - insp.gap - insp.width >= 12
    readonly property real bottomEdge: insp.dashRect.y + insp.dashRect.height

    width: 380
    x: insp.onLeft ? insp.dashRect.x - insp.gap - insp.width : insp.dashRect.x + insp.dashRect.width + insp.gap
    y: insp.topLimit
    height: Math.max(420, Math.min(insp.parent ? insp.parent.height - insp.y - 12 : 800, insp.bottomEdge + 16 - insp.y))

    property real t: insp.wanted ? 1 : 0
    Behavior on t { SpatialAnim { speed: "default" } }
    visible: insp.t > 0.01
    opacity: insp.t
    transform: Translate { x: (1 - insp.t) * (insp.onLeft ? 24 : -24) }

    MouseArea {
        anchors.fill: parent
    }

    Rectangle {
        visible: insp.cellRect.width > 0
        x: insp.onLeft ? insp.width : insp.cellRect.x + insp.cellRect.width - insp.x
        y: insp.cellRect.y + insp.cellRect.height / 2 - insp.y - 1
        width: insp.onLeft ? insp.cellRect.x - insp.x - insp.width : insp.x - insp.cellRect.x - insp.cellRect.width
        height: 2
        color: Qt.alpha(Colors.primary, 0.6)
    }

    Rectangle {
        id: sheet
        anchors.fill: parent
        radius: 28
        color: Colors.surfaceContainer
        border.width: 1
        border.color: Qt.alpha(Colors.outline, 0.18)
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: head.implicitHeight + 32
                color: Colors.surfaceContainerLow
                topLeftRadius: 28
                topRightRadius: 28

                ColumnLayout {
                    id: head
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        M3IconButton {
                            icon: "arrow_back"
                            onClicked: if (insp.editor) {
                                insp.editor.selectedItem = "dashboard"
                                insp.editor.drawerMode = "options"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            CustomText {
                                Layout.fillWidth: true
                                content: insp.entry ? insp.entry.label : ""
                                size: 18
                                weight: 600
                            }
                            CustomText {
                                Layout.fillWidth: true
                                content: (insp.entry ? insp.entry.group : "") + (insp.spec ? " · " + insp.spec.w + " × " + insp.spec.h : "")
                                size: 12
                                weight: 400
                                customColor: Colors.surfaceVariantText
                            }
                        }

                        M3IconButton {
                            visible: !insp.legacy
                            icon: "content_copy"
                            onClicked: {
                                const nid = DashLayout.duplicateItem(insp.itemId)
                                if (nid !== "" && insp.editor)
                                    insp.editor.selectedItem = "dash:" + nid
                            }
                        }

                        Rectangle {
                            implicitWidth: 40
                            implicitHeight: 40
                            radius: delArea.pressed ? 12 : 20
                            color: delArea.containsMouse ? Colors.error : Colors.errorContainer
                            Behavior on radius { SpatialAnim { speed: "fast" } }

                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: "delete"
                                iconSize: 19
                                customColor: delArea.containsMouse ? Colors.errorText : Colors.errorContainerText
                            }

                            MouseArea {
                                id: delArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const id = insp.itemId
                                    const d = DashLayout.activeDash
                                    if (insp.editor) {
                                        insp.editor.selectedItem = "dashboard"
                                        insp.editor.drawerMode = "options"
                                    }
                                    Qt.callLater(() => { if (d) d.removeItem(id); else DashLayout.dropItem(id) })
                                }
                            }

                            CustomToolTip { content: "Remove"; visible: delArea.containsMouse }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(150, Math.max(70, (insp.cellRect.height > 0 ? insp.cellRect.height : 100)
                                                         * Math.min(1, (insp.width - 60) / Math.max(1, insp.cellRect.width)) + 24))
                        radius: 20
                        color: Colors.surface

                        DashThumb {
                            anchors.fill: parent
                            anchors.margins: 12
                            instanceId: insp.wanted ? insp.itemId : ""
                            srcW: insp.cellRect.width > 0 ? insp.cellRect.width : 300
                            srcH: insp.cellRect.height > 0 ? insp.cellRect.height : 120
                        }
                    }

                    M3ButtonGroup {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        visible: insp.tabs.length > 1
                        fillWidth: true
                        textSize: 13
                        activeColor: Colors.secondaryContainer
                        activeTextColor: Colors.secondaryContainerText
                        model: insp.tabs.map(t => ({ value: t.id, label: t.label }))
                        activeCheck: function(v) { return insp.shownTab === v }
                        onSegmentClicked: v => insp.tab = v
                    }
                }
            }

            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: body.implicitHeight + 28
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                ColumnLayout {
                    id: body
                    x: 18
                    y: 14
                    width: flick.width - 36
                    spacing: 14

                    ColumnLayout {
                        visible: insp.shownTab === "size" && insp.spec !== null
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            model: [{ key: "w", label: "Width", sub: "Columns", max: DashLayout.columns },
                                    { key: "h", label: "Height", sub: "Rows", max: 24 }]

                            delegate: RowLayout {
                                id: stepRow
                                required property var modelData
                                readonly property int cur: insp.spec ? insp.spec[stepRow.modelData.key] : 1
                                readonly property int lo: insp.entry ? (stepRow.modelData.key === "w" ? insp.entry.minW : insp.entry.minH) ?? 1 : 1
                                readonly property int hi: Math.min(stepRow.modelData.max,
                                    insp.entry ? (stepRow.modelData.key === "w" ? insp.entry.maxW : insp.entry.maxH) ?? 99 : 99)
                                Layout.fillWidth: true
                                spacing: 10

                                function step(d) {
                                    const v = Math.max(stepRow.lo, Math.min(stepRow.hi, stepRow.cur + d))
                                    if (v === stepRow.cur || !insp.spec)
                                        return
                                    if (stepRow.modelData.key === "w") DashLayout.resizeItem(insp.itemId, v, insp.spec.h)
                                    else DashLayout.resizeItem(insp.itemId, insp.spec.w, v)
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    CustomText { content: stepRow.modelData.label; size: 14; weight: 500 }
                                    CustomText { content: stepRow.modelData.sub; size: 11; weight: 400; customColor: Colors.outline }
                                }

                                M3IconButton {
                                    icon: "remove"
                                    enabledButton: stepRow.cur > stepRow.lo
                                    onClicked: stepRow.step(-1)
                                }
                                CustomText {
                                    Layout.preferredWidth: 28
                                    horizontalAlignment: Text.AlignHCenter
                                    content: stepRow.cur
                                    size: 16
                                    weight: 700
                                }
                                M3IconButton {
                                    icon: "add"
                                    enabledButton: stepRow.cur < stepRow.hi
                                    onClicked: stepRow.step(1)
                                }
                            }
                        }

                        CustomText {
                            Layout.fillWidth: true
                            content: insp.spec ? "Column " + (insp.spec.x + 1) + ", row " + (insp.spec.y + 1) + ". Drag the item to move it; others make room." : ""
                            wrapMode: Text.WordWrap
                            elide: Text.ElideNone
                            size: 12
                            weight: 400
                            customColor: Colors.outline
                        }

                        Rectangle {
                            visible: insp.sizeOpts.length > 0
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Colors.outlineVariant
                        }
                    }

                    Rectangle {
                        readonly property bool fits: insp.shownTab === "content" && insp.spec !== null
                            && (insp.spec.kind === "tiles" || insp.spec.kind === "bubbles")
                        visible: fits
                        Layout.fillWidth: true
                        implicitHeight: splitCol.implicitHeight + 24
                        radius: 18
                        color: splitArea.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh

                        RowLayout {
                            id: splitCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 14
                            spacing: 12
                            MaterialIconSymbol { content: "call_split"; iconSize: 20; customColor: Colors.primary }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                CustomText { Layout.fillWidth: true; content: "Place each toggle separately"; size: 14; weight: 600 }
                                CustomText {
                                    Layout.fillWidth: true
                                    content: "Turns this group into single Toggle items you can move one by one"
                                    size: 11
                                    weight: 400
                                    customColor: Colors.outline
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideNone
                                }
                            }
                        }

                        MouseArea {
                            id: splitArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const id = insp.itemId
                                if (insp.editor) {
                                    insp.editor.selectedItem = "dashboard"
                                    insp.editor.drawerMode = ""
                                }
                                Qt.callLater(() => DashLayout.splitToggles(id))
                            }
                        }
                    }

                    Repeater {
                        model: insp.shownOpts

                        delegate: ColumnLayout {
                            id: optBlock
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            spacing: 14

                            Rectangle {
                                visible: optBlock.index > 0
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: Colors.outlineVariant
                            }

                            EditOptionRow {
                                Layout.fillWidth: true
                                instanceId: insp.itemId
                                spec: optBlock.modelData
                            }
                        }
                    }

                    CustomText {
                        visible: insp.shownOpts.length === 0 && insp.shownTab !== "size"
                        Layout.fillWidth: true
                        content: "Nothing to change here."
                        size: 12
                        customColor: Colors.outline
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Colors.outlineVariant
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 12
                Layout.leftMargin: 18
                spacing: 8

                CustomText {
                    Layout.fillWidth: true
                    content: "Changes save as you go"
                    size: 12
                    weight: 400
                    customColor: Colors.outline
                }

                M3Button {
                    variant: "filled"
                    label: "Done"
                    icon: "check"
                    onClicked: if (insp.editor) insp.editor.drawerMode = ""
                }
            }
        }
    }
}
