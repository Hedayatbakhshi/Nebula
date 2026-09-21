import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents
import "../Widgets" as W
import QtQuick.Controls
import qs.modules.components.Widgets as WM

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 5

    readonly property bool panelOn: SettingsConfig.widgets.showWidgets ?? true

    // ── Reusable section header ───────────────────────────────────────────
    component SectionLabel: CustomText {
        Layout.topMargin: 20
        size: 13
        customColor: Colors.primary
    }

    readonly property var networkWindows: [
        { name: "1 min" }, { name: "3 min" }, { name: "5 min" },
        { name: "10 min" }, { name: "15 min" }, { name: "30 min" }
    ]
    readonly property var networkIntervals: [
        { name: "1 s" }, { name: "2 s" }, { name: "5 s" }, { name: "10 s" }, { name: "30 s" }
    ]

    readonly property var visualizerStyles: [
        { name: "Wave" }, { name: "Chart" }
    ]
    readonly property var visualizerColors: [
        { name: "Primary" }, { name: "Secondary" }, { name: "Tertiary" },
        { name: "Two-tone" }, { name: "Deep" }, { name: "Warm" }
    ]
    readonly property var visualizerFps: [
        { name: "15 fps" }, { name: "30 fps" }, { name: "60 fps" },
        { name: "90 fps" }, { name: "120 fps" }
    ]

    function isActive(item) {
        if (!(SettingsConfig.widgets[item.show] ?? false)) return false
        if (!item.styleKey) return true
        return WM.WidgetCatalog.styleValue(item) === item.style
    }

    // One click both enables the family and picks the variant; clicking the
    // active card switches the family off.
    function selectItem(item) {
        var patch = {}
        if (root.isActive(item)) {
            patch[item.show] = false
        } else {
            patch[item.show] = true
            if (item.styleKey) patch[item.styleKey] = item.style
        }
        SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets, patch)
    }

    Flickable {
        ScrollBar.vertical: CustomScrollBar {}
        id: flick
        anchors.fill: parent
        contentHeight: column.implicitHeight
        contentWidth: width
        clip: true

        ColumnLayout {
            id: column
            width: parent.width
            anchors { top: parent.top; left: parent.left; right: parent.right }
            anchors { leftMargin: 5; rightMargin: 5; topMargin: 5 }
            spacing: 0

            // ── Page header ──────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                MaterialIconSymbol { content: "widgets"; iconSize: 20 }
                CustomText { content: "Widgets"; size: 20; customColor: Colors.primary }

                Item { Layout.fillWidth: true }

                CustomToogle {
                    isToggleOn: root.panelOn
                    onToggled: function(state) {
                        SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets, { showWidgets: state })
                    }
                }

                Rectangle {
                    implicitWidth: arrangeRow.implicitWidth + 26
                    implicitHeight: 34
                    radius: 17
                    opacity: root.panelOn ? 1 : 0.4
                    Behavior on opacity { EffectsAnim { speed: "fast" } }
                    color: Colors.primary

                    RowLayout {
                        id: arrangeRow
                        anchors.centerIn: parent
                        spacing: 7
                        MaterialIconSymbol { content: "drag_pan"; iconSize: 16; customColor: Colors.primaryText }
                        CustomText { content: "Arrange"; size: 13; customColor: Colors.primaryText }
                    }

                    RippleEffect {
                        anchors.fill: parent
                        radius: 17
                        enabled: root.panelOn
                        hoverColor: Qt.alpha(Colors.primaryText, 0.10)
                        rippleColor: Qt.alpha(Colors.primaryText, 0.24)
                        // Settings is a separate window sitting over the desktop —
                        // it has to get out of the way of what you're arranging.
                        onClicked: {
                            GlobalStates.settingsOpen = false
                            GlobalStates.widgetEditMode = true
                        }
                    }
                }
            }

            CustomText {
                Layout.topMargin: 6
                content: root.panelOn
                    ? "Click a widget to place it on the desktop. Click it again to remove it."
                    : "The desktop panel is off. Widgets you pick here appear when you switch it back on."
                size: 12
                customColor: Colors.outline
            }

            SectionLabel { content: "Appearance" }

            ColumnLayout {
                Layout.topMargin: 6
                Layout.fillWidth: true
                spacing: 3

                CustomCard {
                    autoRadius: false
                    topRadius: 20
                    bottomRadius: WidgetSizes.cardStyle !== "flat" ? 5 : 20
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Card Surface"; size: 14 }
                            CustomText {
                                content: "How widget backgrounds treat the wallpaper"
                                size: 12
                                customColor: Colors.outline
                            }
                        }
                        Item { Layout.fillWidth: true }
                        M3ButtonGroup {
                            model: [
                                { value: "flat",    label: "Solid",  icon: "square" },
                                { value: "frosted", label: "Frost",  icon: "blur_on" },
                                { value: "liquid",  label: "Glass",  icon: "water_drop" }
                            ]
                            activeCheck: function(v) { return WidgetSizes.cardStyle === v }
                            onSegmentClicked: function(v) {
                                SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets, { cardStyle: v })
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false
                    topRadius: 5
                    bottomRadius: 5
                    visible: WidgetSizes.liquidGlass
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Glass Strength"; size: 14 }
                            CustomText {
                                content: "How much the edges bend the wallpaper"
                                size: 12
                                customColor: Colors.outline
                            }
                        }
                        Item { Layout.fillWidth: true }
                        M3Slider {
                            Layout.preferredWidth: 160
                            Layout.preferredHeight: 30
                            stepCount: 5
                            stepLabels: ["flat", "subtle", "normal", "thick", "heavy"]
                            currentStep: {
                                const vals = [0.35, 0.7, 1.0, 1.5, 2.2]
                                const cur = SettingsConfig.widgets.glassStrength ?? 1.0
                                let best = 0
                                for (var i = 1; i < vals.length; i++)
                                    if (Math.abs(vals[i] - cur) < Math.abs(vals[best] - cur)) best = i
                                return best
                            }
                            onStepChanged: step => {
                                const vals = [0.35, 0.7, 1.0, 1.5, 2.2]
                                SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets, { glassStrength: vals[step] })
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false
                    topRadius: 5
                    bottomRadius: 20
                    visible: WidgetSizes.cardStyle !== "flat"
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Card Opacity"; size: 14 }
                            CustomText {
                                content: WidgetSizes.liquidGlass
                                    ? "How much the glass is tinted toward the surface"
                                    : "How much wallpaper shows through"
                                size: 12
                                customColor: Colors.outline
                            }
                        }
                        Item { Layout.fillWidth: true }
                        M3Slider {
                            Layout.preferredWidth: 160
                            Layout.preferredHeight: 30
                            stepCount: 5
                            stepLabels: ["glass", "frosted", "hazy", "light", "solid"]
                            currentStep: {
                                const vals = [0.30, 0.45, 0.60, 0.75, 0.90]
                                const cur = SettingsConfig.widgets.cardOpacity ?? 0.60
                                let best = 0
                                for (var i = 1; i < vals.length; i++)
                                    if (Math.abs(vals[i] - cur) < Math.abs(vals[best] - cur)) best = i
                                return best
                            }
                            onStepChanged: step => {
                                const vals = [0.30, 0.45, 0.60, 0.75, 0.90]
                                SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets, { cardOpacity: vals[step] })
                            }
                        }
                    }
                }
            }

            // ── Gallery ──────────────────────────────────────────────────
            Repeater {
                model: WM.WidgetCatalog.catalog

                delegate: ColumnLayout {
                    id: sectionDelegate
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0

                    SectionLabel { content: sectionDelegate.modelData.section }

                    Flow {
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        spacing: 10

                        Repeater {
                            model: sectionDelegate.modelData.items

                            delegate: Rectangle {
                                id: card
                                required property var modelData

                                readonly property bool active: root.isActive(modelData)

                                width: 184
                                height: 158
                                radius: 18
                                color: active ? Qt.alpha(Colors.primary, 0.13)
                                              : Colors.surfaceContainerHigh
                                border.width: active ? 2 : 0
                                border.color: Colors.primary

                                Behavior on color { ColorAnimation { duration: 150 } }

                                // ── Preview ──────────────────────────────
                                Item {
                                    id: box
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: 10
                                    height: 110
                                    clip: true

                                    Loader {
                                        id: pv
                                        sourceComponent: card.modelData.comp

                                        // Only build previews near the viewport — 28 live
                                        // widgets with their own timers is a real cost.
                                        active: {
                                            const y = card.mapToItem(flick.contentItem, 0, 0).y
                                            return y + card.height > flick.contentY - 300
                                                && y < flick.contentY + flick.height + 300
                                        }

                                        transformOrigin: Item.TopLeft
                                        scale: (item && item.implicitWidth > 0 && item.implicitHeight > 0)
                                            ? Math.min(box.width / item.implicitWidth,
                                                       box.height / item.implicitHeight, 1)
                                            : 1
                                        x: (box.width  - width  * scale) / 2
                                        y: (box.height - height * scale) / 2
                                    }
                                }

                                // ── Label ────────────────────────────────
                                RowLayout {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    anchors.bottomMargin: 10
                                    spacing: 5

                                    CustomText {
                                        Layout.fillWidth: true
                                        content: card.modelData.label
                                        size: 12
                                        weight: card.active ? 700 : 500
                                        customColor: card.active ? Colors.primary : Colors.surfaceText
                                    }

                                    MaterialIconSymbol {
                                        visible: card.active
                                        content: "check_circle"
                                        iconSize: 15
                                        fill: 1
                                        customColor: Colors.primary
                                    }
                                }

                                RippleEffect {
                                    anchors.fill: parent
                                    radius: 18
                                    onClicked: root.selectItem(card.modelData)
                                }
                            }
                        }
                    }
                }
            }

            // ── Visualizer options (not widgets) ─────────────────────────
            SectionLabel { content: "Visualizer" }

            ColumnLayout {
                Layout.fillWidth: true; Layout.topMargin: 6; spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Cava Visualizer"; size: 14 }
                            CustomText { content: "Audio bar overlay alongside the circular player"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomToogle {
                            isToggleOn: SettingsConfig.general.musicVisOn
                            onToggled: function(state) {
                                SettingsConfig.general = Object.assign({}, SettingsConfig.general, { musicVisOn: state })
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Visualizer Style"; size: 14 }
                            CustomText { content: "Smooth wave or segmented trapezoid chart"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomListNew {
                            Layout.preferredHeight: 30; Layout.preferredWidth: 160
                            color: Colors.surfaceContainerHighest
                            currentVal: SettingsConfig.general.musicVisStyle ?? "Wave"
                            list: root.visualizerStyles
                            onCurrentValChanged: {
                                if (currentVal && currentVal !== SettingsConfig.general.musicVisStyle)
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general,
                                                                           { musicVisStyle: currentVal })
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Visualizer Color"; size: 14 }
                            CustomText { content: "Theme role for the bars and their ghost cap"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomListNew {
                            Layout.preferredHeight: 30; Layout.preferredWidth: 160
                            color: Colors.surfaceContainerHighest
                            currentVal: SettingsConfig.general.musicVisColor ?? "Primary"
                            list: root.visualizerColors
                            onCurrentValChanged: {
                                if (currentVal && currentVal !== SettingsConfig.general.musicVisColor)
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general,
                                                                           { musicVisColor: currentVal })
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Visualizer Frame Rate"; size: 14 }
                            CustomText { content: "Higher is smoother and costs more CPU"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomListNew {
                            Layout.preferredHeight: 30; Layout.preferredWidth: 160
                            color: Colors.surfaceContainerHighest
                            currentVal: SettingsConfig.general.musicVisFps ?? "30 fps"
                            list: root.visualizerFps
                            onCurrentValChanged: {
                                if (currentVal && currentVal !== SettingsConfig.general.musicVisFps)
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general,
                                                                           { musicVisFps: currentVal })
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 20
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Visualizer Bars"; size: 14 }
                            CustomText { content: "Number of frequency bands to render"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomSpinBox {
                            color: Colors.surfaceContainerHighest
                            value: SettingsConfig.general.musicVisBars ?? 60
                            onValChanged: {
                                if (val !== value)
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general, { musicVisBars: val })
                            }
                        }
                    }
                }
            }

            // ── Network options (not widgets) ────────────────────────────
            SectionLabel { content: "Network" }

            ColumnLayout {
                Layout.fillWidth: true; Layout.topMargin: 6; spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Stats Duration"; size: 14 }
                            CustomText {
                                content: "How much history the network graph spans"
                                size: 12
                                customColor: Colors.outline
                            }
                        }
                        Item { Layout.fillWidth: true }
                        CustomListNew {
                            Layout.preferredHeight: 30; Layout.preferredWidth: 160
                            color: Colors.surfaceContainerHighest
                            currentVal: SettingsConfig.widgets.networkGraphWindow ?? "3 min"
                            list: root.networkWindows
                            onCurrentValChanged: {
                                if (currentVal && currentVal !== SettingsConfig.widgets.networkGraphWindow)
                                    SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets,
                                                                           { networkGraphWindow: currentVal })
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 20
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Update Interval"; size: 14 }
                            CustomText {
                                content: "How often the speeds are re-read"
                                size: 12
                                customColor: Colors.outline
                            }
                        }
                        Item { Layout.fillWidth: true }
                        CustomListNew {
                            Layout.preferredHeight: 30; Layout.preferredWidth: 160
                            color: Colors.surfaceContainerHighest
                            currentVal: SettingsConfig.widgets.networkGraphInterval ?? "2 s"
                            list: root.networkIntervals
                            onCurrentValChanged: {
                                if (currentVal && currentVal !== SettingsConfig.widgets.networkGraphInterval)
                                    SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets,
                                                                           { networkGraphInterval: currentVal })
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
    ScrollFade {
        anchors.fill: parent
        flickable: flick
    }
}
