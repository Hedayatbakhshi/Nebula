import QtQuick
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.components.Bar

DashItem {
    id: root

    card: true

    Component.onCompleted: ServiceDashData.retainSystem()
    Component.onDestruction: ServiceDashData.releaseSystem()

    readonly property string face: String(root.opt("face") ?? "heat")
    readonly property string metric: root.face === "mirror" ? "net" : String(root.opt("metric") ?? "cpu")
    readonly property bool isNet: root.metric === "net"
    readonly property color tint: root.isNet ? Colors.primary : DashLayout.metricColor(root.metric)
    readonly property real netPeak: Math.max(1024, ...ServiceDashData.netDownHist, ...ServiceDashData.netUpHist)
    readonly property real upPeak: Math.max(1024, ...ServiceDashData.netUpHist)
    readonly property real downPeak: Math.max(1024, ...ServiceDashData.netDownHist)
    readonly property real frac: root.isNet ? ServiceSystemInfo.netDownloadBps / root.downPeak : DashLayout.metricFraction(root.metric)
    readonly property var history: root.isNet ? ServiceDashData.netDownHist.map(v => v / root.downPeak) : DashLayout.metricHistory(root.metric)
    readonly property string bigText: root.isNet ? ServiceSystemInfo.formatNetSpeed(ServiceSystemInfo.netDownloadBps)
        : DashLayout.metricText(root.metric) + (root.metric === "temp" ? "" : "%")
    readonly property string label: root.isNet ? "Network" : DashLayout.metricLabel(root.metric)
    readonly property string detail: root.isNet ? "↑ " + ServiceSystemInfo.formatNetSpeed(ServiceSystemInfo.netUploadBps)
        : DashLayout.metricDetail(root.metric)
    readonly property bool textInMeter: root.face === "thumb" || root.face === "labelbar"

    Item {
        id: box
        anchors.fill: parent
        anchors.margins: 12

        CustomText {
            content: root.label
            size: 12
            weight: 500
            customColor: Colors.surfaceVariantText
        }

        CustomText {
            anchors.right: parent.right
            content: root.detail
            size: 12
            weight: 500
            customColor: Colors.surfaceVariantText
        }

        CustomText {
            id: big
            y: 18
            visible: !root.textInMeter
            content: root.bigText
            family: root.displayFont
            renderType: Text.QtRendering
            size: Math.min(34, Math.max(20, root.height * 0.23))
            weight: 400
            customColor: root.tint
        }

        Loader {
            id: meter
            active: root.bound
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            readonly property real room: root.textInMeter ? box.height - 24 : box.height - big.y - big.implicitHeight - 8
            readonly property real want: {
                switch (root.face) {
                case "splittrack": return 12
                case "stacked":    return 14
                case "capsules":   return 26
                case "ruler":      return 28
                case "dots":       return Math.min(34, room)
                case "thumb":      return 32
                case "labelbar":   return 38
                case "mirror":     return 18
                }
                return Math.min(56, room)
            }
            height: Math.max(0, Math.min(meter.room, meter.want))
            visible: height >= 6
            sourceComponent: {
                switch (root.face) {
                case "splittrack": return splitFace
                case "capsules":   return capsFace
                case "stacked":    return stackFace
                case "columns":    return colsFace
                case "ruler":      return rulerFace
                case "dots":       return dotsFace
                case "thumb":      return thumbFace
                case "mirror":     return mirrorFace
                case "labelbar":   return labelFace
                }
                return heatFace
            }
        }
    }

    Component {
        id: splitFace
        MeterSplitTrack {
            value: root.frac
            color: root.tint
        }
    }

    Component {
        id: capsFace
        MeterCapsules {
            count: Math.max(8, Math.min(24, Math.round(box.width / 16)))
            gap: 4
            radius: 7
            value: root.frac
            color: root.tint
        }
    }

    Component {
        id: stackFace
        MeterStacked {
            values: root.metric === "ram" ? [ServiceSystemInfo.memUsage, ServiceSystemInfo.memCacheFrac, ServiceSystemInfo.memBuffersFrac] : [root.frac]
            colors: [root.tint, Colors.tertiary, Colors.secondary]
        }
    }

    Component {
        id: colsFace
        MeterColumns {
            readonly property int fit: Math.max(4, Math.floor(box.width / 12))
            values: root.metric === "cpu" && ServiceSystemInfo.cpuCores.length > 0 ? ServiceSystemInfo.cpuCores
                  : root.history.slice(Math.max(0, root.history.length - fit))
            minCount: root.metric === "cpu" ? 0 : fit
            gap: 4
            color: root.tint
        }
    }

    Component {
        id: rulerFace
        MeterRuler {
            value: root.frac
            barHeight: 8
            zones: root.metric === "temp" ? [0.6, 0.85] : [0.7, 0.9]
        }
    }

    Component {
        id: dotsFace
        MeterDotMatrix {
            rows: 3
            value: root.frac
            color: root.tint
        }
    }

    Component {
        id: heatFace
        MeterHeatStrip {
            points: Math.max(12, Math.min(ServiceDashData.historyPoints, Math.floor(box.width / 8)))
            gap: 3
            history: root.history
            color: root.tint
            bars: root.height >= 150
        }
    }

    Component {
        id: thumbFace
        MeterThumb {
            value: root.frac
            text: root.bigText
            color: root.tint
            fillColor: Qt.alpha(root.tint, 0.5)
            inkColor: root.metric === "gpu" ? Colors.tertiaryText : root.metric === "temp" ? Colors.secondaryText : Colors.primaryText
            ringColor: root.cardColor
        }
    }

    Component {
        id: mirrorFace
        MeterMirror {
            leftValue: ServiceSystemInfo.netDownloadBps / root.downPeak
            rightValue: ServiceSystemInfo.netUploadBps / root.upPeak
        }
    }

    Component {
        id: labelFace
        MeterLabelBar {
            value: root.frac
            text: root.bigText
            detail: root.width >= 240 ? root.detail : ""
            color: root.tint
            inkColor: root.metric === "gpu" ? Colors.tertiaryText : root.metric === "temp" ? Colors.secondaryText : Colors.primaryText
        }
    }
}
