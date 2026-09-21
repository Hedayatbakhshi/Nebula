pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

Scope {
    id: scope

    IpcHandler {
        target: "lockscreen"
        function choose(): void { GlobalStates.lockSelectorOpen = true }
        function close(): void { GlobalStates.lockSelectorOpen = false }
    }

    LazyLoader {
        active: GlobalStates.lockSelectorOpen

        PanelWindow {
            id: win

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            anchors { left: true; right: true; top: true; bottom: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:lockSelector"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            FocusScope {
                id: root
                anchors.fill: parent
                focus: true

                readonly property real u: Math.min(width / 1920, height / 1080)
                readonly property var styles: LockCatalog.variants
                property bool greeterInstalled: false
                property string target: "lock"
                readonly property bool targetGreeter: root.greeterInstalled && root.target === "greeter"
                readonly property int appliedIndex: LockCatalog.indexOf(
                    (root.targetGreeter ? SettingsConfig.greeter : SettingsConfig.lockscreen)?.layout)
                property int sel: LockCatalog.indexOf(SettingsConfig.lockscreen?.layout)
                property int shown: root.sel
                property bool open: false
                property bool leaving: false

                readonly property var geo: root.open
                    ? { x: 392, y: 112, w: 1136, h: 639, strip: 776 }
                    : { x: 160, y: 112, w: 1600, h: 900, strip: 1030 }

                function select(i) {
                    const n = root.styles.length
                    root.sel = ((i % n) + n) % n
                }

                function apply() {
                    const v = root.styles[root.sel].value
                    if (root.targetGreeter) {
                        SettingsConfig.greeter = Object.assign({}, SettingsConfig.greeter, { layout: v })
                    } else {
                        const base = Object.assign({}, SettingsConfig.lockscreen)
                        delete base.clockStyle
                        delete base.placement
                        SettingsConfig.lockscreen = Object.assign(base, { layout: v })
                    }
                    if (root.leaving)
                        return
                    root.leaving = true
                    inAnim.stop()
                    root.enter = 1
                    root.growing = true
                    growAnim.start()
                }

                function dismiss() {
                    if (root.leaving)
                        return
                    root.leaving = true
                    inAnim.stop()
                    outAnim.start()
                }

                function band(a, b) {
                    return Math.max(0, Math.min(1, (root.enter - a) / (b - a)))
                }

                function lerp(a, b, t) {
                    return a + (b - a) * t
                }

                onSelChanged: swapAnim.restart()
                onTargetChanged: root.sel = root.appliedIndex

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Left) root.select(root.sel - 1)
                    else if (event.key === Qt.Key_Right) root.select(root.sel + 1)
                    else if (event.key === Qt.Key_Up) root.open = true
                    else if (event.key === Qt.Key_Down) root.open = false
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.apply()
                    else if (event.key === Qt.Key_Escape) root.dismiss()
                    else return
                    event.accepted = true
                }

                Process {
                    running: true
                    command: ["bash", "-c", "systemctl is-enabled greetd >/dev/null 2>&1 && grep -rqs -e greeter.qml /etc/greetd/ && echo yes || echo no"]
                    stdout: StdioCollector { onStreamFinished: root.greeterInstalled = text.trim() === "yes" }
                }

                property real enter: 0
                property real grow: 0
                property bool growing: false
                readonly property real e: Math.max(0, Math.min(1, root.enter))

                NumberAnimation on enter {
                    id: inAnim
                    running: true
                    from: 0
                    to: 1
                    duration: 640
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1, 1]
                }

                NumberAnimation {
                    id: outAnim
                    target: root
                    property: "enter"
                    to: 0
                    duration: 320
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.3, 0.0, 0.8, 0.15, 1, 1]
                    onFinished: GlobalStates.lockSelectorOpen = false
                }

                SequentialAnimation {
                    id: growAnim
                    NumberAnimation {
                        target: root
                        property: "grow"
                        to: 1
                        duration: 560
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.2, 0.0, 0.0, 1.0, 1, 1]
                    }
                    PauseAnimation { duration: 140 }
                    NumberAnimation { target: root; property: "opacity"; to: 0; duration: 280; easing.type: Easing.InCubic }
                    ScriptAction { script: GlobalStates.lockSelectorOpen = false }
                }

                Image {
                    anchors.fill: parent
                    opacity: root.band(0, 0.55)
                    source: WallpaperTheme.wallpaper
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 960
                    asynchronous: true
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: 1.0
                        blurMax: 64
                        autoPaddingEnabled: false
                        brightness: -0.5
                        saturation: 0.2
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    opacity: root.band(0, 0.55)
                    color: Qt.alpha(Colors.surface, 0.35)
                }


                RowLayout {
                    x: 64 * root.u
                    y: 28 * root.u
                    opacity: root.band(0.25, 1) * (1 - root.grow)
                    transform: Translate { y: (1 - root.e) * -30 * root.u }
                    width: parent.width - 128 * root.u
                    height: 60 * root.u
                    spacing: 22 * root.u

                    MaterialIconSymbol { content: "lock"; iconSize: Math.round(30 * root.u); customColor: Colors.primary }
                    CustomText { content: "Lock screen style"; size: Math.round(24 * root.u); weight: 600 }

                    M3ButtonGroup {
                        visible: root.greeterInstalled
                        Layout.preferredHeight: 46 * root.u
                        iconSize: Math.round(20 * root.u)
                        textSize: Math.round(17 * root.u)
                        model: [
                            { value: "lock",    label: "Lock screen",  icon: "lock" },
                            { value: "greeter", label: "Login screen", icon: "login" }
                        ]
                        activeCheck: v => root.target === v
                        onSegmentClicked: v => root.target = v
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 10 * root.u
                        CustomText { content: root.styles[root.sel].label; size: Math.round(22 * root.u); weight: 600 }
                        CustomText { content: root.styles[root.sel].role; size: Math.round(18 * root.u); weight: 400; customColor: Colors.surfaceVariantText }
                    }

                    Item { Layout.fillWidth: true }

                    M3IconButton {
                        implicitWidth: 52 * root.u
                        implicitHeight: 52 * root.u
                        icon: "close"
                        iconSize: Math.round(24 * root.u)
                        color: Qt.alpha(Colors.surfaceContainerHighest, 0.85)
                        onClicked: root.dismiss()
                    }

                    Rectangle {
                        implicitWidth: applyRow.implicitWidth + 56 * root.u
                        implicitHeight: 52 * root.u
                        radius: applyArea.containsMouse ? 16 * root.u : height / 2
                        color: Colors.primary
                        Behavior on radius { SpatialAnim { speed: "fast" } }

                        RowLayout {
                            id: applyRow
                            anchors.centerIn: parent
                            spacing: 10 * root.u
                            MaterialIconSymbol { content: "check"; iconSize: Math.round(24 * root.u); customColor: Colors.primaryText }
                            CustomText { content: "Apply"; size: Math.round(19 * root.u); weight: 600; customColor: Colors.primaryText }
                        }

                        MouseArea {
                            id: applyArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.apply()
                        }
                    }
                }

                ClippingRectangle {
                    id: frame
                    x: root.lerp(root.geo.x * root.u, 0, root.grow)
                    y: root.lerp(root.geo.y * root.u, 0, root.grow)
                    width: root.lerp(root.geo.w * root.u, root.width, root.grow)
                    height: root.lerp(root.geo.h * root.u, root.height, root.grow)
                    radius: 34 * root.u * (1 - root.grow)
                    color: "black"
                    opacity: root.band(0, 0.4)
                    transform: [
                        Scale {
                            origin.x: frame.width / 2
                            origin.y: frame.height / 2
                            xScale: 0.88 + 0.12 * root.e
                            yScale: 0.88 + 0.12 * root.e
                        },
                        Translate { y: (1 - root.e) * 70 * root.u }
                    ]

                    Behavior on x { enabled: !root.growing; SpatialAnim {} }
                    Behavior on y { enabled: !root.growing; SpatialAnim {} }
                    Behavior on width { enabled: !root.growing; SpatialAnim {} }
                    Behavior on height { enabled: !root.growing; SpatialAnim {} }

                    LockPreview {
                        id: big
                        anchors.fill: parent
                        live: true
                        layoutStyle: root.styles[root.shown].value
                        greeter: root.targetGreeter

                        property real k: 1
                        transform: Scale { origin.x: big.width / 2; origin.y: big.height / 2; xScale: big.k; yScale: big.k }
                    }

                    Rectangle {
                        x: 24 * root.u
                        y: 22 * root.u
                        width: badgeRow.implicitWidth + 30 * root.u
                        height: 40 * root.u
                        radius: height / 2
                        color: Qt.alpha(Colors.surface, 0.75)
                        visible: !root.growing
                        opacity: root.appliedIndex === root.sel ? 1 : 0
                        Behavior on opacity { EffectsAnim { speed: "fast" } }

                        RowLayout {
                            id: badgeRow
                            anchors.centerIn: parent
                            spacing: 8 * root.u
                            MaterialIconSymbol { content: "check_circle"; iconSize: Math.round(20 * root.u); customColor: Colors.primary }
                            CustomText { content: "In use"; size: Math.round(17 * root.u); weight: 600 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: 10
                        acceptedButtons: Qt.AllButtons
                        onWheel: wheel => wheel.accepted = true
                    }
                }

                SequentialAnimation {
                    id: swapAnim
                    ParallelAnimation {
                        NumberAnimation { target: big; property: "opacity"; to: 0; duration: 140; easing.type: Easing.InCubic }
                        NumberAnimation { target: big; property: "k"; to: 0.97; duration: 140; easing.type: Easing.InCubic }
                    }
                    ScriptAction { script: { root.shown = root.sel; big.k = 1.035 } }
                    ParallelAnimation {
                        NumberAnimation { target: big; property: "opacity"; to: 1; duration: 320; easing.type: Easing.OutCubic }
                        SpatialAnim { target: big; property: "k"; to: 1 }
                    }
                }

                component NavButton: M3IconButton {
                    y: frame.y + frame.height / 2 - height / 2
                    opacity: root.band(0.35, 1) * (1 - root.grow)
                    scale: 0.6 + 0.4 * root.band(0.35, 1)
                    implicitWidth: 64 * root.u
                    implicitHeight: 64 * root.u
                    iconSize: Math.round(34 * root.u)
                    color: Qt.alpha(Colors.surfaceContainerHighest, 0.8)
                }

                NavButton { x: 52 * root.u; icon: "chevron_left"; onClicked: root.select(root.sel - 1) }
                NavButton { x: parent.width - width - 52 * root.u; icon: "chevron_right"; onClicked: root.select(root.sel + 1) }

                Item {
                    id: strip
                    x: 0
                    opacity: root.band(0.3, 1) * (1 - root.grow)
                    transform: Translate { y: (1 - root.e) * 110 * root.u }
                    y: root.geo.strip * root.u
                    width: parent.width
                    height: 300 * root.u
                    Behavior on y { SpatialAnim {} }

                    HoverHandler {
                        id: stripHover
                        onHoveredChanged: {
                            if (hovered) {
                                closeTimer.stop()
                                root.open = true
                            } else {
                                closeTimer.restart()
                            }
                        }
                    }

                    Timer {
                        id: closeTimer
                        interval: 500
                        onTriggered: root.open = false
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: handleRow.implicitWidth + 48 * root.u
                        height: 44 * root.u
                        radius: height / 2
                        color: Qt.alpha(Colors.surfaceContainerHighest, 0.8)

                        RowLayout {
                            id: handleRow
                            anchors.centerIn: parent
                            spacing: 12 * root.u
                            MaterialIconSymbol {
                                content: "expand_less"
                                iconSize: Math.round(24 * root.u)
                                rotation: root.open ? 180 : 0
                                Behavior on rotation { SpatialAnim {} }
                            }
                            CustomText { content: root.styles.length + " styles"; size: Math.round(17 * root.u); weight: 600; customColor: Colors.surfaceVariantText }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.open = !root.open
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 66 * root.u
                        spacing: 22 * root.u

                        Repeater {
                            model: root.styles

                            delegate: Item {
                                id: thumb
                                required property var modelData
                                required property int index
                                readonly property bool isSel: thumb.index === root.sel

                                width: 256 * root.u
                                height: 190 * root.u
                                opacity: root.open ? 1 : 0
                                Behavior on opacity { EffectsAnim {} }
                                transform: Translate {
                                    y: root.open ? 0 : 24 * root.u
                                    Behavior on y { SpatialAnim {} }
                                }

                                ClippingRectangle {
                                    id: pic
                                    width: parent.width
                                    height: 144 * root.u
                                    radius: (thumb.isSel ? 30 : 20) * root.u
                                    color: "black"
                                    Behavior on radius { SpatialAnim { speed: "fast" } }

                                    LockPreview {
                                        anchors.fill: parent
                                        layoutStyle: thumb.modelData.value
                                        greeter: root.targetGreeter
                                    }
                                }

                                Rectangle {
                                    anchors.fill: pic
                                    anchors.margins: -4 * root.u
                                    radius: pic.radius + 4 * root.u
                                    color: "transparent"
                                    border.width: 4 * root.u
                                    border.color: Colors.primary
                                    opacity: thumb.isSel ? 1 : 0
                                    Behavior on opacity { EffectsAnim { speed: "fast" } }
                                }

                                RowLayout {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 6 * root.u
                                    anchors.rightMargin: 6 * root.u
                                    y: pic.height + 12 * root.u

                                    CustomText {
                                        content: thumb.modelData.label
                                        size: Math.round(19 * root.u)
                                        weight: 600
                                        customColor: thumb.isSel ? Colors.primary : Colors.surfaceText
                                    }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        visible: thumb.index === root.appliedIndex
                                        implicitWidth: inUse.implicitWidth + 20 * root.u
                                        implicitHeight: 26 * root.u
                                        radius: height / 2
                                        color: Colors.secondaryContainer
                                        CustomText {
                                            id: inUse
                                            anchors.centerIn: parent
                                            content: "In use"
                                            size: Math.round(14 * root.u)
                                            weight: 600
                                            customColor: Colors.secondaryContainerText
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.select(thumb.index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
