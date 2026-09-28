import QtQuick
import Quickshell
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services

DashItem {
    id: root

    readonly property var monitor: ServiceBrightness.getMonitorForScreen(root.QsWindow.window ? root.QsWindow.window.screen : Quickshell.screens[0])
    readonly property bool vertical: root.height >= root.width * 0.9
    readonly property real gap: 10

    readonly property var levels: [
        { id: "volume", icon: ServicePipewire.muted ? "volume_off" : "volume_up", value: ServicePipewire.volume,
          active: Colors.primary, on: Colors.primaryText },
        { id: "brightness", icon: "brightness_7", value: root.monitor ? root.monitor.brightness : 0,
          active: Colors.tertiary, on: Colors.tertiaryText }
    ]

    function set(id, v) {
        if (id === "brightness") { if (root.monitor) root.monitor.setBrightness(v) }
        else ServicePipewire.setVolume(v)
    }

    Repeater {
        model: root.levels

        delegate: M3Slider {
            id: s
            required property var modelData
            required property int index
            readonly property real side: ((root.vertical ? root.width : root.height) - root.gap) / 2
            x: root.vertical ? s.index * (s.side + root.gap) : 0
            y: root.vertical ? 0 : s.index * (s.side + root.gap)
            width: root.vertical ? s.side : root.width
            height: root.vertical ? root.height : s.side
            vertical: root.vertical
            icon: s.modelData.icon
            iconAtEnd: !root.vertical
            showStopIndicator: false
            showValueLabel: false
            trackOuterCorner: 14
            trackHeight: Math.min(56, s.side)
            handleHeight: s.side
            handleWidth: 6
            pressedHandleWidth: 4
            handleGap: 4
            activeColor: s.modelData.active
            handleColor: s.modelData.active
            iconColor: s.modelData.on
            progress: s.modelData.value
            onMoved: root.set(s.modelData.id, progress)
        }
    }
}
