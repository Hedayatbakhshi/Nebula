pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

Item {
    id: win

    property QtObject editor: null
    property bool editing: false
    property real topLimit: 96

    readonly property string sel: win.editor ? win.editor.selectedItem : ""
    readonly property bool wanted: win.editing && win.sel === "dashboard"
        && (win.editor.panelStage || win.editor.drawerMode === "options")

    property string tab: "add"
    property string group: "All"
    property string query: ""

    readonly property var groupChoices: ["All", "Time", "Media", "Controls", "System", "Panels"]
    readonly property var groupOf: ({ "Time": "Time", "Media": "Media and info", "Controls": "Controls",
                                      "System": "System", "Panels": "Panels" })
    readonly property var kinds: {
        const q = win.query.toLowerCase()
        const g = win.groupOf[win.group] ?? ""
        const out = []
        for (const name of DashLayout.groups) {
            const list = DashLayout.catalog.filter(e => !e.hidden && e.group === name
                && (g === "" || e.group === g)
                && (q === "" || e.label.toLowerCase().indexOf(q) >= 0 || DashLayout.describe(e.id).toLowerCase().indexOf(q) >= 0))
            if (list.length === 0)
                continue
            if (g === "")
                out.push({ header: name === "Media and info" ? "Media" : name })
            for (const e of list)
                out.push({ header: "", e: e })
        }
        return out
    }

    property rect dashRect: Qt.rect(0, 0, 0, 0)

    function locate() {
        const d = DashLayout.activeDash
        if (!d || !win.parent)
            return
        win.dashRect = d.mapToItem(win.parent, 0, 0, d.width, d.height)
    }

    Timer {
        interval: 80
        repeat: true
        running: win.wanted
        triggeredOnStart: true
        onTriggered: win.locate()
    }

    function sizeOf(e) {
        const d = DashLayout.activeDash
        const cw = d ? d.cellW : 140
        const rh = d ? d.rowH : 56
        const gap = DashLayout.gap
        return Qt.size(Math.min(3, e.defW) * (cw + gap) - gap, Math.max(56, Math.min(2, e.defH) * (rh + gap) - gap))
    }

    function close() {
        if (!win.editor)
            return
        win.editor.drawerMode = ""
        win.editor.panelStage = false
        win.editor.selectedItem = ""
    }

    function openPanel(item) {
        if (!win.editor)
            return
        win.editor.drawerMode = ""
        win.editor.selectedItem = item
        win.editor.panelStage = true
    }

    readonly property real gap: 28
    readonly property bool hasDash: win.dashRect.width > 0
    readonly property bool onLeft: !win.hasDash || win.dashRect.x - win.gap - win.width >= 12
    readonly property real bottomEdge: win.hasDash ? win.dashRect.y + win.dashRect.height : (win.parent ? win.parent.height - 80 : 800)

    width: 440
    x: !win.hasDash ? 24 : win.onLeft ? win.dashRect.x - win.gap - win.width : win.dashRect.x + win.dashRect.width + win.gap
    y: win.topLimit
    height: Math.max(460, Math.min(win.parent ? win.parent.height - win.y - 12 : 800, win.bottomEdge + 16 - win.y))

    property real t: win.wanted ? 1 : 0
    Behavior on t { SpatialAnim { speed: "default" } }
    visible: win.t > 0.01
    opacity: win.t
    transform: Translate { x: (1 - win.t) * (win.onLeft ? 24 : -24) }

    MouseArea {
        anchors.fill: parent
    }

    component Section: ColumnLayout {
        id: sec
        property string title: ""
        property bool first: false
        default property alias body: secBody.data
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            visible: !sec.first
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colors.outlineVariant
        }
        CustomText {
            content: sec.title
            size: 12
            weight: 600
            customColor: Colors.primary
        }
        ColumnLayout {
            id: secBody
            Layout.fillWidth: true
            spacing: 10
        }
    }

    component SwitchRow: RowLayout {
        id: sr
        property string label: ""
        property string sub: ""
        property bool on: false
        signal toggled(bool state)
        Layout.fillWidth: true
        Layout.minimumHeight: 40
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            CustomText { Layout.fillWidth: true; content: sr.label; size: 14; weight: 500 }
            CustomText {
                Layout.fillWidth: true
                visible: sr.sub !== ""
                content: sr.sub
                size: 11
                weight: 400
                customColor: Colors.outline
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
            }
        }
        CustomToogle {
            isToggleOn: sr.on
            onToggled: state => sr.toggled(state)
        }
    }

    Rectangle {
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
                Layout.preferredHeight: head.implicitHeight + 30
                color: Colors.surfaceContainerLow
                topLeftRadius: 28
                topRightRadius: 28

                ColumnLayout {
                    id: head
                    anchors.fill: parent
                    anchors.margins: 16
                    anchors.leftMargin: 18
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            CustomText { Layout.fillWidth: true; content: "Dashboard"; size: 18; weight: 600 }
                            CustomText {
                                Layout.fillWidth: true
                                content: DashLayout.items.length + " items · " + DashLayout.columns + " columns"
                                size: 12
                                weight: 400
                                customColor: Colors.surfaceVariantText
                            }
                        }

                        M3IconButton {
                            icon: "close"
                            onClicked: win.close()
                        }
                    }

                    M3ButtonGroup {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        fillWidth: true
                        iconSize: 16
                        textSize: 13
                        activeColor: Colors.secondaryContainer
                        activeTextColor: Colors.secondaryContainerText
                        model: [{ value: "add", label: "Add items" }, { value: "layout", label: "Layout" },
                                { value: "on", label: "On it · " + DashLayout.items.length }]
                        activeCheck: function(v) { return win.tab === v }
                        onSegmentClicked: v => win.tab = v
                    }
                }
            }

            ColumnLayout {
                visible: win.tab === "add"
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.margins: 18
                    Layout.bottomMargin: 10
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: 21
                        color: Colors.surfaceContainerHighest
                        border.width: search.activeFocus ? 2 : 0
                        border.color: Colors.primary

                        MaterialIconSymbol {
                            id: searchIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            content: "search"
                            iconSize: 20
                            customColor: Colors.surfaceVariantText
                        }

                        TextInput {
                            id: search
                            anchors.left: searchIcon.right
                            anchors.leftMargin: 10
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            clip: true
                            selectByMouse: true
                            color: Colors.surfaceText
                            selectionColor: Qt.alpha(Colors.primary, 0.35)
                            font.pixelSize: 14
                            font.family: SettingsConfig.general.defaultFont ?? "Rubik"
                            onTextChanged: win.query = search.text
                            Keys.onEscapePressed: event => {
                                if (search.text !== "") {
                                    search.text = ""
                                    event.accepted = true
                                } else {
                                    event.accepted = false
                                }
                            }
                        }

                        CustomText {
                            anchors.left: search.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: search.text === "" && !search.activeFocus
                            content: "Search " + DashLayout.catalog.filter(e => !e.hidden).length + " items"
                            size: 14
                            customColor: Colors.outline
                        }
                    }

                    EditChoice {
                        Layout.fillWidth: true
                        maxPerRow: 6
                        minCell: 60
                        rowHeight: 34
                        choices: win.groupChoices.map(g => ({ value: g, label: g }))
                        value: win.group
                        onPicked: v => win.group = v
                    }
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 18
                    Layout.rightMargin: 18
                    clip: true
                    spacing: 6
                    boundsBehavior: Flickable.StopAtBounds
                    model: win.kinds
                    delegate: Item {
                        id: cellWrap
                        required property var modelData
                        width: list.width
                        height: cellWrap.modelData.header !== "" ? 30 : 68

                        CustomText {
                            visible: cellWrap.modelData.header !== ""
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            content: cellWrap.modelData.header
                            size: 12
                            weight: 600
                            customColor: Colors.primary
                        }

                        Rectangle {
                            id: rowItem
                            visible: cellWrap.modelData.header === ""
                            anchors.fill: parent
                            readonly property var modelData: cellWrap.modelData.e ?? ({ id: "", label: "", icon: "", defW: 1, defH: 1 })
                            readonly property bool can: rowItem.modelData.id !== "" && DashLayout.canAdd(rowItem.modelData.id)
                            readonly property size real: win.sizeOf(rowItem.modelData)
                            radius: 16
                            opacity: rowItem.can ? 1 : 0.45
                            color: rowArea.pressed && rowArea.moved ? Colors.primaryContainer
                                : rowArea.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
                            Behavior on color { EffectsColorAnim { speed: "fast" } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                anchors.rightMargin: 10
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: 96
                                    Layout.preferredHeight: 56
                                    radius: 10
                                    color: Colors.surface
                                    clip: true

                                    DashThumb {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        kindOverride: rowItem.modelData.id
                                        srcW: rowItem.real.width
                                        srcH: rowItem.real.height
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    CustomText { Layout.fillWidth: true; content: rowItem.modelData.label; size: 14; weight: 600 }
                                    CustomText {
                                        Layout.fillWidth: true
                                        content: rowItem.can ? DashLayout.describe(rowItem.modelData.id) : "Already on the dashboard"
                                        size: 12
                                        weight: 400
                                        customColor: Colors.surfaceVariantText
                                    }
                                }

                                Rectangle {
                                    implicitWidth: sizeText.implicitWidth + 12
                                    implicitHeight: 22
                                    radius: 6
                                    color: Colors.surfaceContainerHighest
                                    CustomText {
                                        id: sizeText
                                        anchors.centerIn: parent
                                        content: rowItem.modelData.defW + "×" + rowItem.modelData.defH
                                        size: 11
                                        weight: 500
                                        customColor: Colors.surfaceVariantText
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 34
                                    implicitHeight: 34
                                    radius: 17
                                    color: rowItem.can ? Colors.primary : Colors.surfaceContainerHighest
                                    MaterialIconSymbol {
                                        anchors.centerIn: parent
                                        content: rowItem.can ? "add" : "check"
                                        iconSize: 18
                                        customColor: rowItem.can ? Colors.primaryText : Colors.surfaceVariantText
                                    }
                                }
                            }

                            MouseArea {
                                id: rowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: true
                                cursorShape: !rowItem.can ? Qt.ForbiddenCursor : rowArea.pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                property point press: Qt.point(0, 0)
                                property bool moved: false

                                onPressed: mouse => {
                                    rowArea.press = Qt.point(mouse.x, mouse.y)
                                    rowArea.moved = false
                                }
                                onPositionChanged: mouse => {
                                    if (!rowArea.pressed || !rowItem.can || !DashLayout.activeDash)
                                        return
                                    if (!rowArea.moved && Math.abs(mouse.x - rowArea.press.x) + Math.abs(mouse.y - rowArea.press.y) > 6) {
                                        rowArea.moved = true
                                        DashLayout.activeDash.beginExternal(rowItem.modelData.id)
                                    }
                                    if (!rowArea.moved)
                                        return
                                    const sp = rowArea.mapToItem(null, mouse.x, mouse.y)
                                    proxy.x = sp.x - proxy.width / 2
                                    proxy.y = sp.y - proxy.height / 2
                                    DashLayout.activeDash.trackExternal(rowArea, mouse.x, mouse.y)
                                }
                                onReleased: {
                                    if (rowArea.moved) {
                                        if (DashLayout.activeDash)
                                            DashLayout.activeDash.endExternal(true)
                                    } else if (rowItem.can) {
                                        const id = DashLayout.place(rowItem.modelData.id)
                                        if (id !== "" && win.editor)
                                            win.editor.selectedItem = "dash:" + id
                                    }
                                    rowArea.moved = false
                                }
                                onCanceled: {
                                    if (rowArea.moved && DashLayout.activeDash)
                                        DashLayout.activeDash.endExternal(false)
                                    rowArea.moved = false
                                }
                            }

                            Rectangle {
                                id: proxy
                                parent: rowItem.Window.contentItem
                                z: 1000
                                visible: rowArea.moved && rowArea.pressed
                                    && !(DashLayout.activeDash && DashLayout.activeDash.preview)
                                width: proxyRow.implicitWidth + 24
                                height: 40
                                radius: 20
                                color: Colors.primaryContainer
                                border.width: 2
                                border.color: Colors.primary

                                Row {
                                    id: proxyRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    MaterialIconSymbol {
                                        anchors.verticalCenter: parent.verticalCenter
                                        content: rowItem.modelData.icon
                                        iconSize: 18
                                        customColor: Colors.primaryContainerText
                                    }
                                    CustomText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        content: rowItem.modelData.label
                                        size: 13
                                        weight: 600
                                        customColor: Colors.primaryContainerText
                                    }
                                }
                            }
                        }
                    }

                    CustomText {
                        anchors.centerIn: parent
                        visible: list.count === 0
                        content: "Nothing matches “" + win.query + "”"
                        size: 13
                        customColor: Colors.outline
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
                    MaterialIconSymbol { content: "pan_tool_alt"; iconSize: 16; customColor: Colors.surfaceVariantText }
                    CustomText {
                        Layout.fillWidth: true
                        content: "Drag a row onto the panel, or click it to drop it in the first free spot"
                        size: 12
                        weight: 400
                        customColor: Colors.surfaceVariantText
                        wrapMode: Text.WordWrap
                        elide: Text.ElideNone
                    }
                }
            }

            Flickable {
                id: layoutFlick
                visible: win.tab === "layout"
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: layoutCol.implicitHeight + 32
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                ColumnLayout {
                    id: layoutCol
                    x: 18
                    y: 16
                    width: layoutFlick.width - 36
                    spacing: 16

                    Section {
                        title: "Panel size"
                        first: true

                        EditChoice {
                            Layout.fillWidth: true
                            choices: BarLayout.panelPresets("dashboard")
                            isActive: function(v) { return BarLayout.presetActive("dashboard", v) }
                            onPicked: v => BarLayout.applyPreset("dashboard", v)
                        }
                        PanelSizeSliders {
                            Layout.fillWidth: true
                            kind: "dashboard"
                        }
                        CustomText {
                            Layout.fillWidth: true
                            content: "Or drag the panel's edges"
                            size: 12
                            weight: 400
                            customColor: Colors.surfaceVariantText
                        }
                    }

                    Section {
                        title: "Grid"

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            CustomText { Layout.fillWidth: true; content: "Columns"; size: 14; weight: 500 }
                            M3IconButton {
                                icon: "remove"
                                enabledButton: DashLayout.columns > 1
                                onClicked: DashLayout.setColumns(DashLayout.columns - 1)
                            }
                            CustomText {
                                Layout.preferredWidth: 28
                                horizontalAlignment: Text.AlignHCenter
                                content: String(DashLayout.columns)
                                size: 16
                                weight: 700
                            }
                            M3IconButton {
                                icon: "add"
                                enabledButton: DashLayout.columns < 12
                                onClicked: DashLayout.setColumns(DashLayout.columns + 1)
                            }
                        }

                        SwitchRow {
                            label: "Fill the panel height"
                            sub: BarLayout.panelH("dashboard") < 0
                                ? "Give the panel a height (drag its edge) and rows stretch to fill it"
                                : DashLayout.fitRows ? "Rows stretch as you resize the panel" : "Rows keep the height below"
                            on: DashLayout.fitRows
                            onToggled: state => DashLayout.setFitRows(state)
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            opacity: DashLayout.fitRows && BarLayout.panelH("dashboard") >= 0 ? 0.45 : 1

                            RowLayout {
                                Layout.fillWidth: true
                                CustomText { Layout.fillWidth: true; content: "Row height"; size: 14; weight: 500 }
                                CustomText { content: DashLayout.rowHeight + " px"; size: 13; customColor: Colors.surfaceVariantText }
                            }
                            M3Slider {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                stepCount: 11
                                currentStep: Math.round((DashLayout.rowHeight - 40) / 8)
                                valueText: String(40 + currentStep * 8)
                                onStepChanged: step => DashLayout.setRowHeight(40 + step * 8)
                            }
                        }
                    }

                    Section {
                        title: "Classic sections"

                        SwitchRow {
                            label: "Frame them in a titled card"
                            sub: "Profile and the notification centre"
                            on: DashLayout.cards
                            onToggled: state => DashLayout.setCards(state)
                        }
                    }

                    Section {
                        title: "Other panels"

                        EditChoice {
                            Layout.fillWidth: true
                            maxPerRow: 3
                            choices: [{ value: "clock", label: "Calendar", icon: "calendar_month" },
                                      { value: "weather", label: "Weather", icon: "partly_cloudy_day" },
                                      { value: "launcher", label: "Apps", icon: "apps" },
                                      { value: "wallpaper", label: "Wallpaper", icon: "wallpaper" },
                                      { value: "clipboard", label: "Clipboard", icon: "content_paste" }]
                            isActive: function(v) { return false }
                            onPicked: v => win.openPanel(v)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        implicitHeight: 42
                        radius: 21
                        color: resetArea.containsMouse ? Colors.errorContainer : Colors.surfaceContainerHighest
                        Behavior on color { EffectsColorAnim { speed: "fast" } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialIconSymbol {
                                content: "restart_alt"
                                iconSize: 18
                                customColor: resetArea.containsMouse ? Colors.errorContainerText : Colors.error
                            }
                            CustomText {
                                content: "Reset the dashboard"
                                size: 13
                                weight: 600
                                customColor: resetArea.containsMouse ? Colors.errorContainerText : Colors.error
                            }
                        }

                        MouseArea {
                            id: resetArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: DashLayout.reset()
                        }
                    }
                }
            }

            ListView {
                id: onList
                visible: win.tab === "on"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 18
                clip: true
                spacing: 3
                boundsBehavior: Flickable.StopAtBounds
                model: DashLayout.items.slice().sort((a, b) => a.y - b.y || a.x - b.x)

                delegate: Rectangle {
                    id: onRow
                    required property var modelData
                    required property int index
                    readonly property var entry: DashLayout.kindEntry(onRow.modelData.kind)
                    width: onList.width
                    height: 52
                    topLeftRadius: onRow.index === 0 ? 18 : 5
                    topRightRadius: onRow.index === 0 ? 18 : 5
                    bottomLeftRadius: onRow.index === onList.count - 1 ? 18 : 5
                    bottomRightRadius: onRow.index === onList.count - 1 ? 18 : 5
                    color: onArea.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 6
                        spacing: 12

                        MaterialIconSymbol {
                            content: onRow.entry ? onRow.entry.icon : "widgets"
                            iconSize: 20
                            customColor: Colors.primary
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            CustomText { Layout.fillWidth: true; content: onRow.entry ? onRow.entry.label : onRow.modelData.id; size: 14; weight: 600 }
                            CustomText {
                                content: onRow.modelData.w + " × " + onRow.modelData.h + " · column " + (onRow.modelData.x + 1) + ", row " + (onRow.modelData.y + 1)
                                size: 11
                                weight: 400
                                customColor: Colors.surfaceVariantText
                            }
                        }
                        M3IconButton {
                            icon: "delete"
                            onClicked: {
                                const k = onRow.modelData.id
                                Qt.callLater(() => DashLayout.dropItem(k))
                            }
                        }
                    }

                    MouseArea {
                        id: onArea
                        anchors.fill: parent
                        anchors.rightMargin: 48
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (win.editor) {
                            win.editor.selectedItem = "dash:" + onRow.modelData.id
                            win.editor.drawerMode = "inspector"
                        }
                    }
                }

                CustomText {
                    anchors.centerIn: parent
                    visible: onList.count === 0
                    content: "The dashboard is empty. Add items from the first tab."
                    size: 13
                    customColor: Colors.outline
                }
            }
        }
    }
}
