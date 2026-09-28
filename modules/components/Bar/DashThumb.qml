import QtQuick
import qs.modules.utils

Item {
    id: thumb

    property string instanceId: ""
    property string kindOverride: ""
    property var overrides: ({})
    property real srcW: 200
    property real srcH: 100

    readonly property string kind: thumb.kindOverride !== "" ? thumb.kindOverride : DashLayout.kindOf(thumb.instanceId)
    readonly property var entry: DashLayout.kindEntry(thumb.kind)
    readonly property bool legacy: thumb.entry ? thumb.entry.legacy === true : false
    readonly property bool framed: !thumb.legacy && (thumb.overrides.background !== undefined
        ? thumb.overrides.background !== false : DashLayout.opt(thumb.instanceId, "background") !== false)
    readonly property bool selfCarded: loader.item ? loader.item.card === true : false
    readonly property real inset: thumb.framed && !thumb.selfCarded ? 10 : 0
    readonly property real fit: Math.min(1, thumb.width / Math.max(1, thumb.srcW), thumb.height / Math.max(1, thumb.srcH))

    Item {
        id: stage
        width: thumb.srcW
        height: thumb.srcH
        anchors.centerIn: parent
        scale: thumb.fit
        enabled: false

        Rectangle {
            anchors.fill: parent
            radius: 20
            visible: thumb.framed
            color: thumb.selfCarded && loader.item.cardColor !== undefined ? loader.item.cardColor : Colors.surfaceContainerHigh
        }

        Loader {
            id: loader
            x: thumb.inset
            y: thumb.inset
            width: stage.width - thumb.inset * 2
            height: stage.height - thumb.inset * 2
            active: (thumb.instanceId !== "" || thumb.kindOverride !== "") && DashLayout.activeDash !== null
            sourceComponent: DashLayout.activeDash ? DashLayout.activeDash.componentFor(thumb.kind) : null
            onLoaded: {
                if ("instanceId" in item)
                    item.instanceId = thumb.instanceId
                if ("overrides" in item)
                    item.overrides = Qt.binding(() => thumb.overrides)
                if ("framed" in item)
                    item.framed = Qt.binding(() => thumb.framed)
                if ("outerW" in item) {
                    item.outerW = Qt.binding(() => thumb.srcW)
                    item.outerH = Qt.binding(() => thumb.srcH)
                }
            }
        }
    }
}
