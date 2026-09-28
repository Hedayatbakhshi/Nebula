import QtQuick
import Quickshell
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services

DashItem {
    id: root

    readonly property string target: String(root.opt("target") ?? "volume")
    readonly property bool vertical: root.height > root.width * 1.15
    readonly property bool labelled: !root.vertical && root.width >= 380 && root.height >= 50 && root.opt("showLabel") !== false
    readonly property var monitor: root.target === "brightness"
        ? ServiceBrightness.getMonitorForScreen(root.QsWindow.window ? root.QsWindow.window.screen : Quickshell.screens[0]) : null
    readonly property real value: root.target === "brightness" ? (root.monitor ? root.monitor.brightness : 0)
        : root.target === "mic" ? ServicePipewire.micVolume : ServicePipewire.volume
    readonly property string tone: {
        const c = String(root.opt("color") ?? "auto")
        return c !== "auto" ? c : root.target === "brightness" ? "tertiary" : "primary"
    }
    readonly property color accent: root.tone === "secondary" ? Colors.secondary : root.tone === "tertiary" ? Colors.tertiary
        : root.tone === "error" ? Colors.error : Colors.primary
    readonly property color onAccent: root.tone === "secondary" ? Colors.secondaryText : root.tone === "tertiary" ? Colors.tertiaryText
        : root.tone === "error" ? Colors.errorText : Colors.primaryText
    readonly property string label: {
        if (root.target === "brightness")
            return "Brightness"
        const node = root.target === "mic" ? ServicePipewire.source : ServicePipewire.sink
        return node ? (node.description || node.nickname || node.name) : (root.target === "mic" ? "Microphone" : "Speakers")
    }

    Item {
        visible: root.labelled
        width: root.width
        height: 18

        CustomText {
            width: parent.width - pct.width - 8
            content: root.label
            size: 13
            weight: 700
        }
        CustomText {
            id: pct
            anchors.right: parent.right
            content: Math.round(root.value * 100) + "%"
            size: 12
            weight: 500
            customColor: Colors.surfaceVariantText
        }
    }

    M3Slider {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: root.labelled ? undefined : parent.verticalCenter
        anchors.bottom: root.labelled ? parent.bottom : undefined
        width: root.vertical ? Math.min(root.width, 56) : root.width
        height: root.vertical ? root.height : Math.min(root.labelled ? root.height - 22 : root.height, 56)
        vertical: root.vertical
        icon: root.target === "brightness" ? "brightness_7"
            : root.target === "mic" ? (ServicePipewire.micMuted ? "mic_off" : "mic")
            : (ServicePipewire.muted ? "volume_off" : "volume_up")
        iconAtEnd: true
        showStopIndicator: false
        trackOuterCorner: 14
        showValueLabel: !root.labelled && root.opt("showValue") !== false
        trackHeight: Math.min(40, (root.vertical ? width : height) - 8)
        handleHeight: root.vertical ? width : height
        handleWidth: 6
        pressedHandleWidth: 4
        handleGap: 4
        activeColor: root.accent
        handleColor: root.accent
        iconColor: root.onAccent
        progress: root.value
        onMoved: {
            if (root.target === "brightness") { if (root.monitor) root.monitor.setBrightness(progress) }
            else if (root.target === "mic") ServicePipewire.setMicVolume(progress)
            else ServicePipewire.setVolume(progress)
        }
    }
}
