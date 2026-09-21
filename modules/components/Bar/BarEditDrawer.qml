import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Item {
    id: drawer

    property QtObject editor: null
    property bool alive: false
    property real maxHeight: 600
    property string tab: "add"

    readonly property string barMode: SettingsConfig.general.barMode
        ?? (SettingsConfig.general.flatBarMode === false ? "stepped" : "flat")
    readonly property bool dragOut: !!drawer.editor && drawer.editor.mode !== ""
        && (drawer.editor.fromBlock !== "" || (drawer.editor.mode === "app" && drawer.editor.appPinned))
    readonly property bool hiding: drawer.dragOut && drawer.editor.overDrawer
    readonly property string selected: drawer.editor ? drawer.editor.selectedItem : ""
    readonly property bool itemPage: drawer.selected !== ""
    readonly property bool dashPage: drawer.selected.indexOf("dash:") === 0
    readonly property string dashKey: drawer.dashPage ? drawer.selected.substring(5) : ""
    readonly property string itemTint: drawer.dashPage ? "none"
        : BarLayout.itemStyle(drawer.selected, "tint", "none")
    readonly property string itemShape: drawer.dashPage ? "none"
        : BarLayout.chipShape(drawer.selected)
    property real previewW: 0
    property real previewH: 0
    property bool previewSizable: false
    readonly property bool iconSizable: !drawer.dashPage && drawer.previewSizable
    readonly property real itemIconSize: drawer.dashPage ? 0
        : BarLayout.itemStyle(drawer.selected, "iconSize", 0)
    readonly property bool iconItem: !drawer.dashPage
        && BarLayout.iconOnly(drawer.previewW, drawer.previewH)
    readonly property bool shapedChip: drawer.iconItem && drawer.itemShape !== "none"
    readonly property bool groupPage: !drawer.dashPage && drawer.selected !== ""
        && BarLayout.isGroup(drawer.selected)
    readonly property var groupMembers: drawer.groupPage ? BarLayout.groupMembers(drawer.selected) : []
    readonly property var groupCandidates: {
        if (!drawer.groupPage)
            return []
        const out = []
        for (const e of BarLayout.catalog) {
            if (e.id === "group" || !BarLayout.allows(e.id, "bar"))
                continue
            if (drawer.groupMembers.indexOf(e.id) >= 0)
                continue
            if (!e.multi && BarLayout.hiddenItems.indexOf(e.id) < 0)
                continue
            out.push(e.id)
        }
        return out
    }

    component Chip: Rectangle {
        id: bchip
        property var entry: null
        property bool adding: false
        signal activated

        width: bchipRow.implicitWidth + 20
        height: 30
        radius: 15
        color: bchipArea.containsMouse ? Colors.surfaceContainerHighest
                                       : Colors.surfaceContainerHigh
        border.width: 1
        border.color: Qt.alpha(Colors.outline, 0.3)

        Row {
            id: bchipRow
            anchors.centerIn: parent
            spacing: 5

            MaterialIconSymbol {
                anchors.verticalCenter: parent.verticalCenter
                content: bchip.adding ? "add" : (bchip.entry ? bchip.entry.icon : "")
                iconSize: 15
                customColor: bchip.adding ? Colors.primary : Colors.surfaceText
            }
            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                content: bchip.entry ? bchip.entry.label : ""
                size: 12
                weight: 600
            }
            MaterialIconSymbol {
                anchors.verticalCenter: parent.verticalCenter
                visible: !bchip.adding
                content: "close"
                iconSize: 14
                customColor: bchipArea.containsMouse ? Colors.error : Colors.outline
            }
        }

        MouseArea {
            id: bchipArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: bchip.activated()
        }
    }

    component ChipArrow: Rectangle {
        id: arrow
        property string glyph: ""
        property bool enabled: true
        signal tapped

        width: 22
        height: 24
        radius: 8
        color: arrowArea.containsMouse && arrow.enabled ? Colors.primaryContainer : "transparent"
        opacity: arrow.enabled ? 1 : 0.3
        Behavior on color { EffectsColorAnim {} }

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: arrow.glyph
            iconSize: 16
            customColor: arrowArea.containsMouse && arrow.enabled ? Colors.primaryContainerText
                                                                  : Colors.surfaceText
        }

        MouseArea {
            id: arrowArea
            anchors.fill: parent
            enabled: arrow.enabled
            visible: arrow.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: arrow.tapped()
        }
    }

    component MemberChip: Rectangle {
        id: mchip
        property var entry: null
        property bool canLeft: false
        property bool canRight: false
        signal moveLeft
        signal moveRight
        signal removed

        width: mchipRow.implicitWidth + 12
        height: 32
        radius: 16
        color: Colors.surfaceContainerHigh
        border.width: 1
        border.color: Qt.alpha(Colors.outline, 0.3)

        Row {
            id: mchipRow
            anchors.centerIn: parent
            spacing: 2

            ChipArrow {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "chevron_left"
                enabled: mchip.canLeft
                onTapped: mchip.moveLeft()
            }

            MaterialIconSymbol {
                anchors.verticalCenter: parent.verticalCenter
                content: mchip.entry ? mchip.entry.icon : ""
                iconSize: 15
                customColor: Colors.surfaceText
            }

            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 5
                rightPadding: 3
                content: mchip.entry ? mchip.entry.label : ""
                size: 12
                weight: 600
            }

            ChipArrow {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "chevron_right"
                enabled: mchip.canRight
                onTapped: mchip.moveRight()
            }

            ChipArrow {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "close"
                onTapped: mchip.removed()
            }
        }
    }

    component GridChip: Rectangle {
        id: gchip
        property var choice: null
        property bool active: false
        signal activated

        implicitWidth: gchipRow.implicitWidth + 20
        implicitHeight: 32
        radius: 10
        color: gchip.active ? Colors.primaryContainer
             : gchipArea.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
        border.width: gchip.active ? 2 : 0
        border.color: Colors.primary
        Behavior on color { EffectsColorAnim {} }

        Row {
            id: gchipRow
            anchors.centerIn: parent
            spacing: 5

            MaterialIconSymbol {
                anchors.verticalCenter: parent.verticalCenter
                visible: !!gchip.choice && !!gchip.choice.icon
                content: gchip.choice && gchip.choice.icon ? gchip.choice.icon : ""
                iconSize: 15
                customColor: gchip.active ? Colors.primaryContainerText : Colors.surfaceText
            }
            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                content: gchip.choice ? gchip.choice.label : ""
                size: 12
                weight: 600
                customColor: gchip.active ? Colors.primaryContainerText : Colors.surfaceText
            }
        }

        MouseArea {
            id: gchipArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: gchip.activated()
        }
    }

    readonly property var tintChoices: [
        { value: "none",        label: "None" },
        { value: "primary",     label: "Primary" },
        { value: "secondary",   label: "Secondary" },
        { value: "tertiary",    label: "Tertiary" },
        { value: "surfaceText", label: "Neutral" }
    ]

    component BlockTintRow: ColumnLayout {
        id: btr
        property string blockId: ""
        readonly property string tint: BarLayout.blockStyle(btr.blockId, "tint", "none")
        readonly property real radius: BarLayout.blockStyle(btr.blockId, "radius", -1)
        readonly property real pad: BarLayout.blockStyle(btr.blockId, "pad", 4)

        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CustomText {
                Layout.preferredWidth: 96
                content: BarLayout.blockLabel(btr.blockId)
                size: 12
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: drawer.tintChoices

                    delegate: GridChip {
                        required property var modelData
                        choice: modelData
                        active: btr.tint === modelData.value
                        onActivated: BarLayout.setBlockStyle(btr.blockId, "tint", modelData.value)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 106
            visible: btr.tint !== "none"
            spacing: 12

            CustomText { Layout.preferredWidth: 60; content: "Radius"; size: 12 }
            M3Slider {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                stepCount: 14
                currentStep: btr.radius < 0 ? 0 : Math.round(btr.radius / 2) + 1
                valueText: currentStep === 0 ? "Pill" : String((currentStep - 1) * 2)
                onStepChanged: st => {
                    const v = st === 0 ? -1 : (st - 1) * 2
                    if (v !== btr.radius)
                        BarLayout.setBlockStyle(btr.blockId, "radius", v)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 106
            visible: btr.tint !== "none"
            spacing: 12

            CustomText { Layout.preferredWidth: 60; content: "Inset"; size: 12 }
            M3Slider {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                stepCount: 7
                currentStep: Math.round(btr.pad / 2)
                valueText: String(currentStep * 2) + "px"
                onStepChanged: st => {
                    if (st * 2 !== btr.pad)
                        BarLayout.setBlockStyle(btr.blockId, "pad", st * 2)
                }
            }
        }
    }

    function optValue(key) {
        return drawer.dashPage ? DashLayout.opt(drawer.dashKey, key)
                               : BarLayout.opt(drawer.selected, key)
    }

    function setOptValue(key, value) {
        if (drawer.dashPage)
            DashLayout.setOption(drawer.dashKey, key, value)
        else
            BarLayout.setOption(drawer.selected, key, value)
    }

    visible: drawer.alive
    height: Math.min(contentLoader.item ? contentLoader.item.contentHeight : 0, drawer.maxHeight)

    function open() {
        drawer.alive = true
        Qt.callLater(morph.open)
    }

    function close() {
        morph.close()
    }

    MouseArea {
        anchors.fill: parent
    }

    MorphCard {
        id: morph
        anchors.fill: parent
        srcWidth: 140
        srcHeight: 32
        srcRadius: 16
        contentHeight: drawer.height
        cardRadius: 24
        cardColor: Colors.surfaceContainer
        cardBorderWidth: drawer.hiding ? 2 : 0
        cardBorderColor: Colors.primary
        onCloseFinished: drawer.alive = false

        Loader {
            id: contentLoader
            active: drawer.alive
            sourceComponent: Component {
        Item {
            id: body
            width: drawer.width
            height: drawer.height

            readonly property real contentHeight: flick.contentHeight

            Flickable {
                id: flick
                anchors.fill: parent
                contentWidth: flick.width
                contentHeight: drawerCol.implicitHeight + 36
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: flick.contentHeight > flick.height

                ColumnLayout {
                    id: drawerCol
                    x: 18
                    y: 18
                    width: flick.width - 36
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        MaterialIconSymbol { content: "edit"; iconSize: 20; customColor: Colors.primary }
                        CustomText { content: "Edit layout"; size: 16; weight: 700 }
                        Item { Layout.fillWidth: true }
                        M3Button {
                            variant: "tonal"
                            icon: "restart_alt"
                            label: "Reset"
                            onClicked: BarLayout.reset()
                        }
                        M3Button {
                            icon: "check"
                            label: "Done"
                            onClicked: GlobalStates.barEditMode = false
                        }
                    }

                    M3ButtonGroup {
                        visible: !drawer.itemPage
                        Layout.preferredWidth: drawerCol.width
                        Layout.preferredHeight: 36
                        fillWidth: true
                        iconSize: 16
                        textSize: 12
                        model: [
                            { value: "add",  label: "Add items", icon: "add_circle" },
                            { value: "bar",  label: "Bar",       icon: "toolbar" },
                            { value: "dock", label: "Dock",      icon: "dock_to_bottom" }
                        ]
                        activeCheck: function(v) { return drawer.tab === v }
                        onSegmentClicked: function(v) { drawer.tab = v }
                    }

                    ColumnLayout {
                        id: selectedSection
                        Layout.fillWidth: true
                        spacing: 8
                        visible: drawer.itemPage

                        readonly property var entry: drawer.dashPage ? DashLayout.entry(drawer.dashKey)
                                                                     : BarLayout.entry(drawer.selected)
                        readonly property var margin: drawer.dashPage ? [0, 0]
                                                                      : BarLayout.marginsFor(drawer.selected)
                        readonly property var options: selectedSection.entry && selectedSection.entry.options
                            ? selectedSection.entry.options : []

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            M3IconButton {
                                icon: "arrow_back"
                                onClicked: if (drawer.editor) drawer.editor.selectedItem = drawer.dashPage ? "dashboard" : ""
                            }
                            MaterialIconSymbol {
                                content: selectedSection.entry ? selectedSection.entry.icon : ""
                                iconSize: 18
                                customColor: Colors.primary
                            }
                            CustomText {
                                Layout.fillWidth: true
                                content: selectedSection.entry ? selectedSection.entry.label : drawer.selected
                                elide: Text.ElideRight
                                size: 15
                                weight: 700
                            }
                            M3Button {
                                variant: "text"
                                visible: !drawer.dashPage
                                icon: "restart_alt"
                                label: "Reset margins"
                                enabledButton: selectedSection.margin[0] > 0 || selectedSection.margin[1] > 0
                                onClicked: BarLayout.clearMargins(drawer.selected)
                            }
                            M3Button {
                                variant: "text"
                                visible: drawer.dashPage
                                icon: "visibility_off"
                                label: "Hide"
                                onClicked: {
                                    const k = drawer.dashKey
                                    if (drawer.editor)
                                        drawer.editor.selectedItem = "dashboard"
                                    Qt.callLater(() => DashLayout.hideSection(k))
                                }
                            }
                        }

                        CustomText {
                            Layout.fillWidth: true
                            visible: drawer.selected === "launcher"
                            wrapMode: Text.WordWrap
                            content: "The launcher is open as a live preview. Changes show up as you make them."
                            size: 12
                            customColor: Colors.outline
                        }

                        CustomText {
                            Layout.fillWidth: true
                            visible: drawer.selected === "dashboard" || drawer.dashPage
                            wrapMode: Text.WordWrap
                            content: drawer.dashPage
                                ? "This section is live in the dashboard beside you. Drag it there to move it."
                                : "The dashboard is open as a live preview. Drag its sections to reorder them, and click one to open its own options."
                            size: 12
                            customColor: Colors.outline
                        }

                        ColumnLayout {
                            id: dashSections
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            spacing: 8
                            visible: drawer.selected === "dashboard"

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                CustomText { content: "Sections"; size: 13; customColor: Colors.primary }
                                Item { Layout.fillWidth: true }
                                M3Button {
                                    variant: "text"
                                    icon: "restart_alt"
                                    label: "Reset"
                                    onClicked: DashLayout.reset()
                                }
                            }

                            Repeater {
                                model: DashLayout.visibleIds

                                delegate: Rectangle {
                                    id: secRow
                                    required property string modelData
                                    required property int index
                                    readonly property var entry: DashLayout.entry(secRow.modelData)
                                    readonly property bool last: secRow.index === DashLayout.visibleIds.length - 1

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    radius: 12
                                    color: secArea.containsMouse ? Colors.surfaceContainerHighest
                                                                 : Colors.surfaceContainerHigh

                                    MouseArea {
                                        id: secArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (drawer.editor)
                                            drawer.editor.selectedItem = "dash:" + secRow.modelData
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 4
                                        spacing: 8

                                        MaterialIconSymbol {
                                            content: secRow.entry ? secRow.entry.icon : "widgets"
                                            iconSize: 17
                                            customColor: Colors.primary
                                        }

                                        CustomText {
                                            Layout.fillWidth: true
                                            content: secRow.entry ? secRow.entry.label : secRow.modelData
                                            size: 13
                                            weight: 600
                                            elide: Text.ElideRight
                                        }

                                        M3IconButton {
                                            implicitWidth: 30
                                            implicitHeight: 30
                                            icon: "keyboard_arrow_up"
                                            iconSize: 17
                                            enabledButton: secRow.index > 0
                                            onClicked: if (secRow.index > 0)
                                                DashLayout.moveStep(secRow.modelData, -1)
                                        }

                                        M3IconButton {
                                            implicitWidth: 30
                                            implicitHeight: 30
                                            icon: "keyboard_arrow_down"
                                            iconSize: 17
                                            enabledButton: !secRow.last
                                            onClicked: if (!secRow.last)
                                                DashLayout.moveStep(secRow.modelData, 1)
                                        }

                                        M3IconButton {
                                            implicitWidth: 30
                                            implicitHeight: 30
                                            icon: "visibility_off"
                                            iconSize: 17
                                            enabledButton: DashLayout.visibleIds.length > 1
                                            onClicked: {
                                                const k = secRow.modelData
                                                Qt.callLater(() => DashLayout.hideSection(k))
                                            }
                                        }
                                    }
                                }
                            }

                            CustomText {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                visible: DashLayout.hiddenIds.length > 0
                                content: "Add"
                                size: 11
                                weight: 700
                                customColor: Colors.outline
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: DashLayout.hiddenIds

                                    delegate: Rectangle {
                                        id: dashChip
                                        required property string modelData
                                        readonly property var entry: DashLayout.entry(dashChip.modelData)

                                        width: dashChipRow.implicitWidth + 22
                                        height: 32
                                        radius: 16
                                        color: dashChipArea.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
                                        border.width: 1
                                        border.color: Qt.alpha(Colors.outline, 0.3)

                                        Row {
                                            id: dashChipRow
                                            anchors.centerIn: parent
                                            spacing: 6

                                            MaterialIconSymbol {
                                                anchors.verticalCenter: parent.verticalCenter
                                                content: "add"
                                                iconSize: 16
                                            }
                                            CustomText {
                                                anchors.verticalCenter: parent.verticalCenter
                                                content: dashChip.entry ? dashChip.entry.label : dashChip.modelData
                                                size: 12
                                                weight: 600
                                            }
                                        }

                                        MouseArea {
                                            id: dashChipArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: DashLayout.showSection(dashChip.modelData)
                                        }

                                        CustomToolTip {
                                            content: "Put this section back"
                                            visible: dashChipArea.containsMouse
                                        }
                                    }
                                }
                            }

                            CustomText {
                                Layout.fillWidth: true
                                visible: DashLayout.hiddenIds.length === 0
                                wrapMode: Text.WordWrap
                                content: "Every section is in the dashboard."
                                size: 12
                                customColor: Colors.outline
                            }

                            CustomText { Layout.topMargin: 6; content: "Layout"; size: 13; customColor: Colors.primary }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                CustomText { Layout.preferredWidth: 96; content: "Columns"; size: 12 }
                                Item { Layout.fillWidth: true }
                                M3ButtonGroup {
                                    model: [{ value: 0, label: "Auto" }, { value: 1, label: "One" },
                                            { value: 2, label: "Two" }, { value: 3, label: "Three" }]
                                    activeCheck: function(v) { return DashLayout.columnsSetting === v }
                                    onSegmentClicked: function(v) { DashLayout.setColumns(v) }
                                }
                            }

                            CustomText {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                content: DashLayout.columnsSetting === 0
                                    ? "Auto follows the panel width: two columns past 520px, three past 900px."
                                    : "Fixed columns still drop back when the panel is too narrow to hold them."
                                size: 11
                                customColor: Colors.outline
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                CustomText { Layout.preferredWidth: 96; content: "Density"; size: 12 }
                                Item { Layout.fillWidth: true }
                                M3ButtonGroup {
                                    model: [{ value: "auto", label: "Auto" },
                                            { value: "comfortable", label: "Roomy" },
                                            { value: "compact", label: "Compact" }]
                                    activeCheck: function(v) { return DashLayout.density === v }
                                    onSegmentClicked: function(v) { DashLayout.setDensity(v) }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    CustomText { content: "Cards"; size: 13 }
                                    CustomText {
                                        content: DashLayout.cards ? "Each section sits in a titled card"
                                                                  : "Sections run flush, without frames"
                                        size: 11
                                        customColor: Colors.outline
                                    }
                                }

                                CustomToogle {
                                    isToggleOn: DashLayout.cards
                                    onToggled: state => DashLayout.setCards(state)
                                }
                            }
                        }

                        ColumnLayout {
                            id: panelSizeSection
                            readonly property string kind: drawer.dashPage ? "" : BarLayout.panelFor(drawer.selected)
                            readonly property var spec: BarLayout.panelSpecs[panelSizeSection.kind] ?? null
                            readonly property bool custom: panelSizeSection.kind !== ""
                                && BarLayout.panelCustom(panelSizeSection.kind)
                            readonly property real roomH: Math.max(0, drawer.Window.height - Appearance.size.barHeight - 16)

                            Layout.fillWidth: true
                            visible: panelSizeSection.spec !== null
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 4

                                CustomText {
                                    Layout.fillWidth: true
                                    content: "Panel size"
                                    size: 13
                                    customColor: Colors.primary
                                }
                                M3Button {
                                    variant: "text"
                                    icon: "restart_alt"
                                    label: "Default size"
                                    enabledButton: panelSizeSection.custom
                                    onClicked: BarLayout.clearPanelSize(panelSizeSection.kind)
                                }
                            }

                            CustomText {
                                Layout.fillWidth: true
                                visible: drawer.selected !== "dashboard"
                                wrapMode: Text.WordWrap
                                content: "The " + (panelSizeSection.spec ? panelSizeSection.spec.label.toLowerCase() : "")
                                    + " panel is open as a live preview. Drag its edges or use the sliders to resize it."
                                size: 12
                                customColor: Colors.outline
                            }

                            Repeater {
                                model: panelSizeSection.spec ? [
                                    { key: "w", label: "Width",  min: panelSizeSection.spec.minW, auto: false,
                                      max: panelSizeSection.spec.maxW },
                                    { key: "h", label: "Height", min: panelSizeSection.spec.minH, auto: panelSizeSection.spec.defH < 0,
                                      max: Math.max(panelSizeSection.spec.minH,
                                                    Math.min(panelSizeSection.spec.maxH, panelSizeSection.roomH)) }
                                ] : []

                                delegate: RowLayout {
                                    id: panelRow
                                    required property var modelData
                                    readonly property string kind: panelSizeSection.kind
                                    readonly property real value: panelRow.modelData.key === "w" ? BarLayout.panelW(panelRow.kind)
                                                                                                 : BarLayout.panelH(panelRow.kind)
                                    readonly property int offset: panelRow.modelData.auto ? 1 : 0
                                    readonly property bool isAuto: panelRow.modelData.auto && panelRow.value < 0
                                    readonly property int step: 10

                                    Layout.fillWidth: true
                                    spacing: 12

                                    CustomText {
                                        Layout.preferredWidth: 96
                                        content: panelRow.modelData.label
                                        size: 12
                                    }
                                    M3Slider {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30
                                        stepCount: Math.floor((panelRow.modelData.max - panelRow.modelData.min) / panelRow.step) + 1 + panelRow.offset
                                        currentStep: panelRow.isAuto ? 0
                                            : Math.max(panelRow.offset, Math.min(stepCount - 1,
                                                Math.round((panelRow.value - panelRow.modelData.min) / panelRow.step) + panelRow.offset))
                                        valueText: panelRow.modelData.auto && currentStep === 0 ? "Auto"
                                            : String(panelRow.modelData.min + (currentStep - panelRow.offset) * panelRow.step)
                                        onStepChanged: s => {
                                            const v = panelRow.modelData.auto && s === 0 ? -1
                                                : panelRow.modelData.min + (s - panelRow.offset) * panelRow.step
                                            if (Math.abs(v - panelRow.value) < panelRow.step / 2 && (v < 0) === (panelRow.value < 0))
                                                return
                                            const k = panelRow.kind
                                            if (panelRow.modelData.key === "w")
                                                BarLayout.setPanelSize(k, v, BarLayout.panelH(k))
                                            else
                                                BarLayout.setPanelSize(k, BarLayout.panelW(k), v)
                                        }
                                    }
                                    CustomText {
                                        Layout.preferredWidth: 48
                                        horizontalAlignment: Text.AlignRight
                                        content: panelRow.isAuto ? "Auto" : Math.round(panelRow.value) + "px"
                                        size: 12
                                        customColor: Colors.outline
                                    }
                                }
                            }
                        }

                        Repeater {
                            model: [
                                { side: "left",  label: "Left",  at: 0 },
                                { side: "right", label: "Right", at: 1 }
                            ]

                            delegate: RowLayout {
                                id: marginRow
                                required property var modelData
                                readonly property int px: selectedSection.margin[marginRow.modelData.at]

                                Layout.fillWidth: true
                                visible: !drawer.dashPage
                                spacing: 12

                                CustomText {
                                    Layout.preferredWidth: 96
                                    content: marginRow.modelData.label + " margin"
                                    size: 12
                                }
                                M3Slider {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 30
                                    stepCount: 21
                                    currentStep: Math.round(marginRow.px / 2)
                                    valueText: (currentStep * 2) + "px"
                                    onStepChanged: step => {
                                        if (step * 2 !== marginRow.px)
                                            BarLayout.setMargin(drawer.selected, marginRow.modelData.side, step * 2)
                                    }
                                }
                                CustomText {
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                    content: marginRow.px + "px"
                                    size: 12
                                    customColor: Colors.outline
                                }
                            }
                        }

                        Rectangle {
                            id: previewStrip
                            Layout.fillWidth: true
                            Layout.preferredHeight: Appearance.size.barHeight + 16
                            visible: !drawer.dashPage && previewLoader.status === Loader.Ready
                            radius: 12
                            color: Colors.surface

                            Item {
                                id: stubHost
                                width: 0
                                height: 0
                                visible: false
                                readonly property bool editing: false
                                readonly property real maxWidth: -1
                                readonly property real fixedWidth: 0
                                function hoverOpen(kind, item) {}
                                function openPanel(kind, item) {}
                                function closePanel() {}
                            }

                            BarItemChip {
                                anchors.centerIn: parent
                                width: Math.max(chipWidth, previewLoader.width)
                                height: Appearance.size.barHeight
                                itemId: drawer.selected
                                contentWidth: previewLoader.width
                                contentHeight: previewLoader.height
                                barH: Appearance.size.barHeight
                            }

                            Loader {
                                id: previewLoader
                                anchors.centerIn: parent
                                enabled: false
                                width: item ? item.implicitWidth : 0
                                height: item ? item.implicitHeight : 0
                                source: drawer.selected !== "" && !drawer.dashPage
                                        ? BarLayout.urlFor(drawer.selected) : ""
                                onWidthChanged: drawer.previewW = previewLoader.width
                                onHeightChanged: drawer.previewH = previewLoader.height
                                onStatusChanged: if (previewLoader.status !== Loader.Ready)
                                    drawer.previewSizable = false
                                onLoaded: {
                                    item.host = stubHost
                                    if ("itemId" in item)
                                        item.itemId = drawer.selected
                                    drawer.previewSizable = item.iconSizable === true
                                }
                            }
                        }

                        CustomText {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            visible: drawer.groupPage
                            content: "Items in this group"
                            size: 13
                            customColor: Colors.primary
                        }

                        Flow {
                            Layout.fillWidth: true
                            visible: drawer.groupPage
                            spacing: 6

                            Repeater {
                                model: drawer.groupMembers

                                delegate: MemberChip {
                                    required property string modelData
                                    required property int index
                                    entry: BarLayout.entry(modelData)
                                    canLeft: index > 0
                                    canRight: index < drawer.groupMembers.length - 1
                                    onMoveLeft: BarLayout.moveInGroup(drawer.selected, modelData, -1)
                                    onMoveRight: BarLayout.moveInGroup(drawer.selected, modelData, 1)
                                    onRemoved: BarLayout.removeFromGroup(drawer.selected, modelData)
                                }
                            }
                        }

                        CustomText {
                            Layout.fillWidth: true
                            visible: drawer.groupPage && drawer.groupMembers.length === 0
                            wrapMode: Text.WordWrap
                            content: "Empty. Add items below, then give the group a tint."
                            size: 12
                            customColor: Colors.outline
                        }

                        CustomText {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            visible: drawer.groupPage
                            content: "Add"
                            size: 13
                            customColor: Colors.primary
                        }

                        Flow {
                            Layout.fillWidth: true
                            visible: drawer.groupPage
                            spacing: 6

                            Repeater {
                                model: drawer.groupCandidates

                                delegate: Chip {
                                    required property string modelData
                                    entry: BarLayout.entry(modelData)
                                    adding: true
                                    onActivated: BarLayout.addToGroup(drawer.selected, modelData)
                                }
                            }
                        }

                        CustomText {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            visible: drawer.iconSizable
                            content: "Icon"
                            size: 13
                            customColor: Colors.primary
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: drawer.iconSizable
                            spacing: 12

                            CustomText {
                                Layout.preferredWidth: 96
                                content: "Size"
                                size: 12
                            }
                            M3Slider {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                stepCount: 16
                                currentStep: drawer.itemIconSize > 0
                                    ? Math.round(drawer.itemIconSize) - 9 : 0
                                valueText: currentStep === 0 ? "Auto" : String(currentStep + 9) + "px"
                                onStepChanged: st => {
                                    const v = st === 0 ? 0 : st + 9
                                    if (v !== drawer.itemIconSize)
                                        BarLayout.setItemStyle(drawer.selected, "iconSize", v)
                                }
                            }
                            CustomText {
                                Layout.preferredWidth: 40
                                horizontalAlignment: Text.AlignRight
                                content: drawer.itemIconSize > 0 ? drawer.itemIconSize + "px" : "Auto"
                                size: 12
                                customColor: Colors.outline
                            }
                        }

                        CustomText {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            visible: !drawer.dashPage
                            content: "Background"
                            size: 13
                            customColor: Colors.primary
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: !drawer.dashPage
                            spacing: 10

                            CustomText { Layout.preferredWidth: 96; content: "Tint"; size: 12 }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: drawer.tintChoices

                                    delegate: GridChip {
                                        required property var modelData
                                        choice: modelData
                                        active: drawer.itemTint === modelData.value
                                        onActivated: BarLayout.setItemStyle(drawer.selected, "tint", modelData.value)
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: !drawer.dashPage && drawer.itemTint !== "none"
                            spacing: 8

                            CustomText {
                                Layout.fillWidth: true
                                content: "Shape"
                                size: 12
                            }

                            CustomText {
                                Layout.fillWidth: true
                                visible: !drawer.iconItem
                                wrapMode: Text.WordWrap
                                content: "Single-icon items only."
                                size: 12
                                customColor: Colors.outline
                            }

                            ShapePicker {
                                Layout.fillWidth: true
                                visible: drawer.iconItem
                                autoLabel: "None"
                                autoIcon: "crop_square"
                                autoHint: "Rounded rectangle"
                                pickedHint: ""
                                selected: drawer.itemShape === "none" ? "" : drawer.itemShape
                                onPicked: name => BarLayout.setItemStyle(drawer.selected, "shape",
                                                                        name === "" ? "none" : name)
                            }
                        }

                        Repeater {
                            model: [
                                { key: "radius", label: "Radius",    min: 0, max: 24,  step: 2, def: -1, auto: "Pill", shapeLabel: "",        tintOnly: true,  groupOnly: false },
                                { key: "pad",    label: "Padding",   min: 0, max: 24,  step: 2, def: 10, auto: "",     shapeLabel: "Padding", tintOnly: true,  groupOnly: false },
                                { key: "gap",    label: "Spacing",   min: 0, max: 20,  step: 2, def: -1, auto: "Auto", shapeLabel: "Spacing", tintOnly: false, groupOnly: true },
                                { key: "minW",   label: "Min width", min: 0, max: 160, step: 8, def: 0,  auto: "",     shapeLabel: "",        tintOnly: true,  groupOnly: false },
                                { key: "minH",   label: "Height",    min: 0, max: 56,  step: 2, def: 0,  auto: "",     shapeLabel: "Size",    tintOnly: false, groupOnly: false }
                            ]

                            delegate: RowLayout {
                                id: chipRow
                                required property var modelData
                                readonly property bool hasAuto: chipRow.modelData.auto !== ""
                                readonly property real value: BarLayout.itemStyle(drawer.selected,
                                                                                  chipRow.modelData.key,
                                                                                  chipRow.modelData.def)
                                readonly property int off: chipRow.hasAuto ? 1 : 0
                                readonly property bool isAuto: chipRow.hasAuto && chipRow.value < 0

                                Layout.fillWidth: true
                                visible: !drawer.dashPage
                                    && (drawer.itemTint !== "none"
                                        || (!chipRow.modelData.tintOnly && drawer.groupPage))
                                    && (!chipRow.modelData.groupOnly || drawer.groupPage)
                                    && (!drawer.shapedChip || chipRow.modelData.shapeLabel !== "")
                                spacing: 12

                                CustomText {
                                    Layout.preferredWidth: 96
                                    content: drawer.shapedChip && chipRow.modelData.shapeLabel !== ""
                                             ? chipRow.modelData.shapeLabel : chipRow.modelData.label
                                    size: 12
                                }
                                M3Slider {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 30
                                    stepCount: Math.round((chipRow.modelData.max - chipRow.modelData.min)
                                                          / chipRow.modelData.step) + 1 + chipRow.off
                                    currentStep: chipRow.isAuto ? 0
                                        : Math.round((chipRow.value - chipRow.modelData.min) / chipRow.modelData.step) + chipRow.off
                                    valueText: chipRow.hasAuto && currentStep === 0 ? chipRow.modelData.auto
                                        : String(chipRow.modelData.min + (currentStep - chipRow.off) * chipRow.modelData.step)
                                    onStepChanged: st => {
                                        const v = chipRow.hasAuto && st === 0 ? -1
                                            : chipRow.modelData.min + (st - chipRow.off) * chipRow.modelData.step
                                        if (v !== chipRow.value)
                                            BarLayout.setItemStyle(drawer.selected, chipRow.modelData.key, v)
                                    }
                                }
                                CustomText {
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                    content: chipRow.isAuto ? chipRow.modelData.auto
                                           : (chipRow.value === 0 && !chipRow.hasAuto ? "Hug" : chipRow.value + "px")
                                    size: 12
                                    customColor: Colors.outline
                                }
                            }
                        }

                        Repeater {
                            model: selectedSection.options

                            delegate: RowLayout {
                                id: optRow
                                required property var modelData
                                readonly property var value: drawer.optValue(optRow.modelData.key)
                                readonly property string kind: optRow.modelData.type
                                readonly property int off: optRow.modelData.auto ? 1 : 0
                                readonly property var cond: optRow.modelData.onlyIf ?? null

                                Layout.fillWidth: true
                                Layout.topMargin: optRow.kind === "heading" ? 8 : 0
                                spacing: 12
                                visible: !optRow.cond
                                    || optRow.cond.values.indexOf(drawer.optValue(optRow.cond.key)) >= 0

                                CustomText {
                                    visible: optRow.kind === "heading"
                                    content: optRow.modelData.label
                                    size: 13
                                    customColor: Colors.primary
                                }

                                CustomText {
                                    visible: optRow.kind !== "heading" && optRow.kind !== "buttons"
                                        && optRow.kind !== "shape"
                                    Layout.preferredWidth: 96
                                    content: optRow.modelData.label
                                    size: 12
                                }

                                ColumnLayout {
                                    id: buttonList
                                    visible: optRow.kind === "buttons"
                                    Layout.fillWidth: true
                                    spacing: 6

                                    readonly property var chosen: optRow.kind === "buttons"
                                        ? DashLayout.itemList(drawer.dashKey, optRow.modelData.key) : []
                                    readonly property var pool: optRow.kind === "buttons"
                                        ? optRow.modelData.catalog.filter(e => buttonList.chosen.indexOf(e.id) < 0) : []

                                    CustomText {
                                        Layout.fillWidth: true
                                        content: "In the row"
                                        size: 11
                                        weight: 700
                                        customColor: Colors.outline
                                    }

                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Repeater {
                                            model: buttonList.chosen

                                            delegate: Chip {
                                                required property string modelData
                                                entry: optRow.modelData.catalog.find(e => e.id === modelData) ?? null
                                                onActivated: DashLayout.removeItem(drawer.dashKey,
                                                                                   optRow.modelData.key, modelData)
                                            }
                                        }
                                    }

                                    CustomText {
                                        Layout.fillWidth: true
                                        visible: buttonList.chosen.length === 0
                                        wrapMode: Text.WordWrap
                                        content: "No buttons in this row."
                                        size: 11
                                        customColor: Colors.outline
                                    }

                                    CustomText {
                                        Layout.fillWidth: true
                                        Layout.topMargin: 4
                                        visible: buttonList.pool.length > 0
                                        content: "Add"
                                        size: 11
                                        weight: 700
                                        customColor: Colors.outline
                                    }

                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Repeater {
                                            model: buttonList.pool

                                            delegate: Chip {
                                                required property var modelData
                                                entry: modelData
                                                adding: true
                                                onActivated: DashLayout.addItem(drawer.dashKey,
                                                                                optRow.modelData.key, modelData.id)
                                            }
                                        }
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    visible: optRow.kind === "toggle" || optRow.kind === "choice"
                                }

                                CustomToogle {
                                    visible: optRow.kind === "toggle"
                                    isToggleOn: optRow.value === true
                                    onToggled: state => drawer.setOptValue(optRow.modelData.key, state)
                                }

                                M3ButtonGroup {
                                    visible: optRow.kind === "choice"
                                    model: optRow.kind === "choice" ? optRow.modelData.choices : []
                                    activeCheck: function(v) { return optRow.value === v }
                                    onSegmentClicked: function(v) {
                                        drawer.setOptValue(optRow.modelData.key, v)
                                    }
                                }

                                M3Slider {
                                    id: optSlider
                                    visible: optRow.kind === "slider"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 30
                                    readonly property real lo: optRow.modelData.min ?? 0
                                    readonly property real st: optRow.modelData.step ?? 1
                                    stepCount: optRow.kind === "slider"
                                        ? Math.round(((optRow.modelData.max ?? 1) - optSlider.lo) / optSlider.st) + 1 + optRow.off : 0
                                    currentStep: optRow.kind !== "slider" ? -1
                                        : optRow.off && (optRow.value ?? 0) < 0 ? 0
                                        : Math.round(((optRow.value ?? optSlider.lo) - optSlider.lo) / optSlider.st) + optRow.off
                                    valueText: optRow.off && currentStep === 0 ? optRow.modelData.auto
                                        : String(optSlider.lo + (currentStep - optRow.off) * optSlider.st)
                                    onStepChanged: step => {
                                        const v = optRow.off && step === 0 ? -1 : optSlider.lo + (step - optRow.off) * optSlider.st
                                        if (v !== optRow.value)
                                            drawer.setOptValue(optRow.modelData.key, v)
                                    }
                                }

                                CustomText {
                                    visible: optRow.kind === "slider"
                                    Layout.preferredWidth: optRow.off ? 64 : 40
                                    horizontalAlignment: Text.AlignRight
                                    content: optRow.off && (optRow.value ?? 0) < 0 ? optRow.modelData.auto : String(optRow.value ?? "")
                                    size: 12
                                    customColor: Colors.outline
                                }

                                Rectangle {
                                    visible: optRow.kind === "text"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: 10
                                    color: Colors.surfaceContainerHigh
                                    border.width: fieldInput.activeFocus ? 2 : 0
                                    border.color: Colors.primary

                                    TextInput {
                                        id: fieldInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        verticalAlignment: TextInput.AlignVCenter
                                        clip: true
                                        selectByMouse: true
                                        color: Colors.surfaceText
                                        selectionColor: Qt.alpha(Colors.primary, 0.35)
                                        font.pixelSize: 13
                                        font.family: SettingsConfig.general.defaultFont ?? "Rubik"
                                        text: optRow.kind === "text" ? String(optRow.value ?? "") : ""
                                        onEditingFinished: {
                                            if (fieldInput.text !== String(optRow.value ?? ""))
                                                drawer.setOptValue(optRow.modelData.key, fieldInput.text)
                                        }
                                    }
                                }

                                Flow {
                                    visible: optRow.kind === "grid"
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Repeater {
                                        model: optRow.kind === "grid" ? optRow.modelData.choices : []

                                        delegate: GridChip {
                                            required property var modelData
                                            choice: modelData
                                            active: optRow.value === modelData.value
                                            onActivated: drawer.setOptValue(optRow.modelData.key, modelData.value)
                                        }
                                    }
                                }

                                ColumnLayout {
                                    visible: optRow.kind === "shape"
                                    Layout.fillWidth: true
                                    spacing: 8

                                    CustomText {
                                        content: optRow.modelData.label
                                        size: 12
                                    }

                                    ShapePicker {
                                        Layout.fillWidth: true
                                        showAuto: false
                                        selected: optRow.kind === "shape" ? String(optRow.value ?? "") : ""
                                        onPicked: name => drawer.setOptValue(optRow.modelData.key, name)
                                    }
                                }
                            }
                        }

                        CustomText {
                            Layout.fillWidth: true
                            visible: selectedSection.options.length === 0 && drawer.selected !== "dashboard"
                            wrapMode: Text.WordWrap
                            content: drawer.dashPage ? "This section has no options yet."
                                                     : "This item has no options besides its margins."
                            size: 12
                            customColor: Colors.outline
                        }
                    }

                    ColumnLayout {
                        id: addPage
                        Layout.fillWidth: true
                        spacing: 10
                        visible: !drawer.itemPage && drawer.tab === "add"

                        Repeater {
                            model: BarLayout.groups

                            delegate: RowLayout {
                                id: groupRow
                                required property string modelData
                                readonly property var chips: BarLayout.hiddenItems.filter(id => {
                                    const e = BarLayout.entry(id)
                                    return e && e.group === groupRow.modelData
                                })

                                Layout.fillWidth: true
                                spacing: 12
                                visible: groupRow.chips.length > 0

                                CustomText {
                                    Layout.preferredWidth: 72
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: 8
                                    content: groupRow.modelData
                                    size: 12
                                    weight: 600
                                    customColor: Colors.outline
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Repeater {
                                        model: groupRow.chips

                                        delegate: Rectangle {
                                            id: chip
                                            required property string modelData
                                            readonly property var entry: BarLayout.entry(chip.modelData)
                                            readonly property bool multi: !!chip.entry && !!chip.entry.multi

                                            width: chipRow.implicitWidth + 22
                                            height: 32
                                            radius: 16
                                            color: chipArea.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
                                            border.width: 1
                                            border.color: Qt.alpha(Colors.outline, chip.multi ? 0.5 : 0.3)
                                            opacity: drawer.editor && drawer.editor.mode === "item" && drawer.editor.itemId === chip.modelData ? 0.3 : 1

                                            Row {
                                                id: chipRow
                                                anchors.centerIn: parent
                                                spacing: 6

                                                MaterialIconSymbol {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    content: chip.multi ? "add" : (chip.entry ? chip.entry.icon : "")
                                                    iconSize: 16
                                                }
                                                CustomText {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    content: chip.entry ? chip.entry.label : chip.modelData
                                                    size: 12
                                                    weight: 600
                                                }
                                            }

                                            MouseArea {
                                                id: chipArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                preventStealing: true
                                                cursorShape: drawer.editor && drawer.editor.mode === "item" ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                                property real sx: 0
                                                property real sy: 0

                                                onPressed: mouse => {
                                                    chipArea.sx = mouse.x
                                                    chipArea.sy = mouse.y
                                                }
                                                onPositionChanged: mouse => {
                                                    if (!chipArea.pressed)
                                                        return
                                                    const e = drawer.editor
                                                    if (e.mode === "" && Math.hypot(mouse.x - chipArea.sx, mouse.y - chipArea.sy) > 4)
                                                        e.beginItem(chip.modelData, "", -1, 32)
                                                    if (e.mode !== "") {
                                                        const p = chipArea.mapToItem(null, mouse.x, mouse.y)
                                                        e.update(p.x, p.y)
                                                    }
                                                }
                                                onReleased: if (drawer.editor.mode !== "") drawer.editor.finish()
                                                onCanceled: drawer.editor.cancel()
                                            }

                                            CustomToolTip {
                                                content: chip.entry && chip.entry.surfaces
                                                    ? (chip.entry.surfaces[0] === "dock" ? "Dock only, drag onto the dock" : "Bar only, drag onto the bar")
                                                    : chip.multi ? "Drag onto the bar or dock to add another" : "Drag onto the bar or dock"
                                                visible: chipArea.containsMouse && !chipArea.pressed
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        CustomText {
                            Layout.fillWidth: true
                            visible: BarLayout.hiddenItems.length === 0
                            content: "Every item is already on the bar or dock."
                            size: 13
                            customColor: Colors.outline
                        }

                        CustomText {
                            Layout.fillWidth: true
                            Layout.topMargin: 2
                            wrapMode: Text.WordWrap
                            content: "Drag an item onto the bar or dock. Click one that is already there to change its options."
                            size: 12
                            customColor: Colors.outline
                        }
                    }

                    ColumnLayout {
                        id: barPage
                        Layout.fillWidth: true
                        spacing: 12
                        visible: !drawer.itemPage && drawer.tab === "bar"

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            enabled: drawer.barMode !== "pill"
                            opacity: enabled ? 1 : 0.5

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                CustomText { content: "SDF renderer"; size: 13 }
                                CustomText {
                                    content: "Experimental — draws the bar as a distance field"
                                    size: 11
                                    customColor: Colors.outline
                                }
                            }

                            CustomToogle {
                                isToggleOn: BarLayout.barSdf
                                onToggled: state => SettingsConfig.general =
                                    Object.assign({}, SettingsConfig.general, { barSdf: state })
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            CustomText { Layout.preferredWidth: 96; content: "Style"; size: 12 }
                            Item { Layout.fillWidth: true }
                            M3ButtonGroup {
                                model: [
                                    { value: "stepped", label: "Stepped", icon: "view_agenda" },
                                    { value: "flat",    label: "Flat",    icon: "remove" },
                                    { value: "pill",    label: "Pill",    icon: "circle" }
                                ]
                                activeCheck: function(value) { return drawer.barMode === value }
                                onSegmentClicked: function(value) {
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general, { barMode: value })
                                }
                            }
                        }

                        Repeater {
                            model: [
                                { key: "height",   label: "Height",        min: 32, max: 56,  step: 2, def: 40, auto: false },
                                { key: "itemGap",  label: "Item gap",      min: 0,  max: 16,  step: 1, def: 6,  auto: false },
                                { key: "blockGap", label: "Block gap",     min: 16, max: 120, step: 8, def: -1, auto: true },
                                { key: "radius",   label: "Corner radius", min: 8,  max: 24,  step: 1, def: 18, auto: false }
                            ]

                            delegate: RowLayout {
                                id: sizeRow
                                required property var modelData
                                readonly property real value: BarLayout.sizeValue(sizeRow.modelData.key, sizeRow.modelData.def)
                                readonly property int offset: sizeRow.modelData.auto ? 1 : 0
                                readonly property bool isAuto: sizeRow.modelData.auto && sizeRow.value < 0

                                Layout.fillWidth: true
                                spacing: 12

                                CustomText {
                                    Layout.preferredWidth: 96
                                    content: sizeRow.modelData.label
                                    size: 12
                                }
                                M3Slider {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 30
                                    stepCount: Math.round((sizeRow.modelData.max - sizeRow.modelData.min) / sizeRow.modelData.step) + 1 + sizeRow.offset
                                    currentStep: sizeRow.isAuto ? 0
                                        : Math.round((sizeRow.value - sizeRow.modelData.min) / sizeRow.modelData.step) + sizeRow.offset
                                    valueText: sizeRow.modelData.auto && currentStep === 0 ? "Auto"
                                        : String(sizeRow.modelData.min + (currentStep - sizeRow.offset) * sizeRow.modelData.step)
                                    onStepChanged: s => {
                                        const v = sizeRow.modelData.auto && s === 0 ? -1
                                            : sizeRow.modelData.min + (s - sizeRow.offset) * sizeRow.modelData.step
                                        if (v !== sizeRow.value)
                                            BarLayout.setSize(sizeRow.modelData.key, v)
                                    }
                                }
                                CustomText {
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                    content: sizeRow.isAuto ? "Auto" : sizeRow.value + "px"
                                    size: 12
                                    customColor: Colors.outline
                                }
                            }
                        }

                        CustomText {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            content: "Block tint"
                            size: 13
                            customColor: Colors.primary
                        }

                        Repeater {
                            model: BarLayout.blocks

                            delegate: BlockTintRow {
                                required property var modelData
                                Layout.fillWidth: true
                                blockId: modelData.id
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            CustomText { Layout.preferredWidth: 96; content: "Add block"; size: 12 }
                            Item { Layout.fillWidth: true }
                            Repeater {
                                model: [
                                    { side: "left",   label: "Left" },
                                    { side: "center", label: "Centre" },
                                    { side: "right",  label: "Right" }
                                ]
                                delegate: M3Button {
                                    required property var modelData
                                    variant: "tonal"
                                    icon: "add"
                                    label: modelData.label
                                    onClicked: BarLayout.addBlock(modelData.side)
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        id: dockPage
                        Layout.fillWidth: true
                        spacing: 12
                        visible: !drawer.itemPage && drawer.tab === "dock"

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                CustomText { content: "Show dock"; size: 13 }
                                CustomText {
                                    content: BarLayout.dockOn ? "Turn off to hide the dock entirely"
                                                              : "The dock is hidden."
                                    size: 11
                                    customColor: Colors.outline
                                }
                            }

                            CustomToogle {
                                isToggleOn: BarLayout.dockOn
                                onToggled: state => SettingsConfig.general =
                                    Object.assign({}, SettingsConfig.general, { dock: state })
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            visible: BarLayout.dockOn
                            enabled: BarLayout.dockStyle !== "flat"
                            opacity: enabled ? 1 : 0.5

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                CustomText { content: "Auto-hide"; size: 13 }
                                CustomText {
                                    content: BarLayout.dockStyle === "flat"
                                        ? "Not available while the dock is full width"
                                        : "Slide away until the pointer reaches the edge"
                                    size: 11
                                    customColor: Colors.outline
                                }
                            }

                            CustomToogle {
                                isToggleOn: (SettingsConfig.general.dockAutoHide ?? true)
                                            && BarLayout.dockStyle !== "flat"
                                onToggled: state => SettingsConfig.general =
                                    Object.assign({}, SettingsConfig.general, { dockAutoHide: state })
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            visible: BarLayout.dockOn
                            enabled: BarLayout.dockStyle !== "pill"
                            opacity: enabled ? 1 : 0.5

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                CustomText { content: "SDF renderer"; size: 13 }
                                CustomText {
                                    content: "Experimental — draws the dock as a distance field"
                                    size: 11
                                    customColor: Colors.outline
                                }
                            }

                            CustomToogle {
                                isToggleOn: BarLayout.dockSdf
                                onToggled: state => SettingsConfig.general =
                                    Object.assign({}, SettingsConfig.general, { dockSdf: state })
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            visible: BarLayout.dockOn

                            CustomText { Layout.preferredWidth: 96; content: "Style"; size: 12 }
                            Item { Layout.fillWidth: true }
                            M3ButtonGroup {
                                model: [
                                    { value: "match",   label: "Match bar" },
                                    { value: "stepped", label: "Stepped" },
                                    { value: "flat",    label: "Full" },
                                    { value: "pill",    label: "Pill" }
                                ]
                                activeCheck: function(value) { return BarLayout.dockStyleSetting === value }
                                onSegmentClicked: function(value) { BarLayout.setDockSize("style", value) }
                            }
                        }

                        Repeater {
                            model: BarLayout.dockOn ? [
                                { key: "height",   label: "Height",        min: 48, max: 80, step: 2, def: 60 },
                                { key: "iconSize", label: "Icon size",     min: 24, max: 48, step: 2, def: 32 },
                                { key: "itemGap",  label: "Item gap",      min: 0,  max: 16, step: 1, def: 2 },
                                { key: "blockGap", label: "Block gap",     min: 16, max: 120, step: 8, def: -1, auto: true },
                                { key: "radius",   label: "Corner radius", min: 8,  max: 28, step: 1, def: 18 }
                            ].concat(BarLayout.dockStyle === "pill"
                                ? [{ key: "pillGap", label: "Bottom gap", min: 0, max: 40, step: 1, def: BarLayout.dockPillGap }]
                                : []) : []

                            delegate: RowLayout {
                                id: dockRow
                                required property var modelData
                                readonly property real value: BarLayout.dockSize(dockRow.modelData.key, dockRow.modelData.def)
                                readonly property int offset: dockRow.modelData.auto ? 1 : 0
                                readonly property bool isAuto: !!dockRow.modelData.auto && dockRow.value < 0

                                Layout.fillWidth: true
                                spacing: 12

                                CustomText {
                                    Layout.preferredWidth: 96
                                    content: dockRow.modelData.label
                                    size: 12
                                }
                                M3Slider {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 30
                                    stepCount: Math.round((dockRow.modelData.max - dockRow.modelData.min) / dockRow.modelData.step) + 1 + dockRow.offset
                                    currentStep: dockRow.isAuto ? 0
                                        : Math.round((dockRow.value - dockRow.modelData.min) / dockRow.modelData.step) + dockRow.offset
                                    valueText: dockRow.modelData.auto && currentStep === 0 ? "Auto"
                                        : String(dockRow.modelData.min + (currentStep - dockRow.offset) * dockRow.modelData.step)
                                    onStepChanged: s => {
                                        const v = dockRow.modelData.auto && s === 0 ? -1
                                            : dockRow.modelData.min + (s - dockRow.offset) * dockRow.modelData.step
                                        if (v !== dockRow.value)
                                            BarLayout.setDockSize(dockRow.modelData.key, v)
                                    }
                                }
                                CustomText {
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                    content: dockRow.isAuto ? "Auto" : dockRow.value + "px"
                                    size: 12
                                    customColor: Colors.outline
                                }
                            }
                        }

                        CustomText {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            content: "Block tint"
                            size: 13
                            customColor: Colors.primary
                        }

                        Repeater {
                            model: BarLayout.bottomBlocks

                            delegate: BlockTintRow {
                                required property var modelData
                                Layout.fillWidth: true
                                blockId: modelData.id
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: BarLayout.dockOn

                            CustomText { Layout.preferredWidth: 96; content: "Add block"; size: 12 }
                            Item { Layout.fillWidth: true }
                            Repeater {
                                model: [
                                    { side: "left",   label: "Left" },
                                    { side: "center", label: "Centre" },
                                    { side: "right",  label: "Right" }
                                ]
                                delegate: M3Button {
                                    required property var modelData
                                    variant: "tonal"
                                    icon: "add"
                                    label: modelData.label
                                    onClicked: BarLayout.addBlock(modelData.side, "bottom")
                                }
                            }
                        }

                        ColumnLayout {
                            id: pinSection
                            Layout.fillWidth: true
                            Layout.topMargin: 6
                            spacing: 8
                            visible: BarLayout.dockOn

                            property string query: ""
                            readonly property var results: pinSection.query.trim().length === 0 ? []
                                : ServiceApps.fuzzyQuery(pinSection.query.trim()).slice(0, 8)

                            CustomText { content: "Pinned apps"; size: 13; customColor: Colors.primary }

                            CustomText {
                                content: "Drag icons in the dock to reorder them, or onto this card to unpin."
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                size: 12
                                customColor: Colors.outline
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: 18
                                color: Colors.surfaceContainerHigh
                                border.width: pinInput.activeFocus ? 2 : 0
                                border.color: Colors.primary

                                MaterialIconSymbol {
                                    id: pinSearchIcon
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    content: "search"
                                    iconSize: 16
                                    customColor: Colors.outline
                                }

                                TextInput {
                                    id: pinInput
                                    anchors.left: pinSearchIcon.right
                                    anchors.leftMargin: 8
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    verticalAlignment: TextInput.AlignVCenter
                                    clip: true
                                    selectByMouse: true
                                    color: Colors.surfaceText
                                    selectionColor: Qt.alpha(Colors.primary, 0.35)
                                    font.pixelSize: 13
                                    font.family: SettingsConfig.general.defaultFont ?? "Rubik"
                                    onTextChanged: pinSection.query = pinInput.text
                                    Keys.onEscapePressed: event => {
                                        if (pinInput.text !== "") {
                                            pinInput.text = ""
                                            event.accepted = true
                                        } else {
                                            event.accepted = false
                                        }
                                    }

                                    CustomText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: pinInput.text === ""
                                        content: "Search apps to pin"
                                        size: 13
                                        customColor: Colors.outline
                                    }
                                }
                            }

                            Repeater {
                                model: pinSection.results

                                delegate: RowLayout {
                                    id: pinRow
                                    required property var modelData
                                    readonly property bool pinned: ServiceApps.isPinnedById(pinRow.modelData.id)

                                    Layout.fillWidth: true
                                    spacing: 10

                                    Image {
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        source: Quickshell.iconPath(pinRow.modelData.icon, "image-missing")
                                        sourceSize.width: 44
                                        sourceSize.height: 44
                                        asynchronous: true
                                        fillMode: Image.PreserveAspectFit
                                    }
                                    CustomText {
                                        Layout.fillWidth: true
                                        content: pinRow.modelData.name
                                        elide: Text.ElideRight
                                        size: 13
                                    }
                                    M3Button {
                                        variant: pinRow.pinned ? "text" : "tonal"
                                        icon: pinRow.pinned ? "check" : "push_pin"
                                        label: pinRow.pinned ? "Pinned" : "Pin"
                                        onClicked: ServiceApps.togglePinById(pinRow.modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ScrollFade {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                flickable: flick
            }

            Rectangle {
                anchors.fill: parent
                radius: 24
                color: Colors.surfaceContainer
                opacity: drawer.dragOut ? 0.94 : 0
                visible: opacity > 0.01
                Behavior on opacity {
                    EffectsAnim { speed: "default" }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        radius: 32
                        color: drawer.hiding ? Colors.primary : Colors.surfaceContainerHighest
                        scale: drawer.hiding ? 1.1 : 1
                        Behavior on scale {
                            SpatialAnim { speed: "fast" }
                        }
                        Behavior on color {
                            EffectsColorAnim { speed: "default" }
                        }

                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: drawer.editor && drawer.editor.mode === "app" ? "keep_off" : "delete"
                            iconSize: 28
                            customColor: drawer.hiding ? Colors.primaryText : Colors.surfaceText
                        }
                    }

                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: !drawer.editor ? ""
                            : (drawer.hiding ? "Release to " : "Drop here to ")
                              + (drawer.editor.mode === "app" ? "unpin " : "hide ")
                              + drawer.editor.label
                        size: 14
                        weight: 600
                        customColor: drawer.hiding ? Colors.primary : Colors.surfaceText
                    }
                }
            }
        }
            }
        }
    }
}
