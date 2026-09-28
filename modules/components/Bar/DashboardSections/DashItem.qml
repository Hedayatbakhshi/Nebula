import QtQuick
import qs.modules.settings
import qs.modules.utils
import qs.modules.components.Bar

Item {
    id: base

    property string instanceId: ""
    property bool card: false
    property bool framed: false
    property var overrides: ({})
    property real outerW: base.width
    property real outerH: base.height
    property color cardColor: Colors.surfaceContainerHigh
    readonly property color rowColor: base.framed ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
    readonly property color chipColor: base.framed ? Colors.surfaceBright : Colors.surfaceContainerHighest
    readonly property color fadeColor: base.framed ? Colors.surfaceContainerHigh : Colors.surface
    readonly property string displayFont: SettingsConfig.general?.displayFont || "Titan One"
    readonly property real pad: Math.min(16, Math.max(10, Math.min(width, height) * 0.09))
    readonly property bool tiny: base.width < 150 || base.height < 90
    readonly property bool bound: base.instanceId !== "" || Object.keys(base.overrides ?? {}).length > 0

    function opt(key) {
        const o = base.overrides
        if (o && o[key] !== undefined)
            return o[key]
        return DashLayout.opt(base.instanceId, key)
    }
}
