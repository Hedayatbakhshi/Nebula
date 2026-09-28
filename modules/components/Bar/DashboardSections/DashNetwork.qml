import QtQuick
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services

DashItem {
    id: root

    card: true

    Component.onCompleted: ServiceDashData.retainSystem()
    Component.onDestruction: ServiceDashData.releaseSystem()

    readonly property real peak: Math.max(1024, ...ServiceDashData.netDownHist, ...ServiceDashData.netUpHist)
    readonly property bool narrow: root.width < 260

    Item {
        anchors.fill: parent
        anchors.margins: 14

        CustomText {
            visible: !root.narrow
            content: ServiceNetwork.connectionLabel || "Network"
            width: parent.width - speeds.width - 12
            size: 15
            weight: 600
        }

        Row {
            id: speeds
            anchors.right: parent.right
            spacing: root.narrow ? 10 : 16

            Repeater {
                model: [{ icon: "arrow_downward", bps: ServiceSystemInfo.netDownloadBps, tint: Colors.primary },
                        { icon: "arrow_upward", bps: ServiceSystemInfo.netUploadBps, tint: Colors.tertiary }]

                delegate: Row {
                    id: sp
                    required property var modelData
                    spacing: 3
                    MaterialIconSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        content: sp.modelData.icon
                        iconSize: 16
                        customColor: sp.modelData.tint
                    }
                    CustomText {
                        anchors.verticalCenter: parent.verticalCenter
                        content: ServiceSystemInfo.formatNetSpeed(sp.modelData.bps)
                        size: 13
                        weight: 600
                    }
                }
            }
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: speeds.bottom
            anchors.topMargin: 8

            Column {
                anchors.fill: parent
                spacing: 6

                MeterHeatStrip {
                    width: parent.width
                    height: (parent.height - 6) * 0.6
                    points: Math.max(12, Math.min(ServiceDashData.historyPoints, Math.floor(width / 8)))
                    gap: 3
                    bars: true
                    history: ServiceDashData.netDownHist.map(v => Math.log(1 + v) / Math.log(1 + root.peak))
                    color: Colors.primary
                }

                MeterHeatStrip {
                    width: parent.width
                    height: (parent.height - 6) * 0.4
                    points: Math.max(12, Math.min(ServiceDashData.historyPoints, Math.floor(width / 8)))
                    gap: 3
                    bars: true
                    history: ServiceDashData.netUpHist.map(v => Math.log(1 + v) / Math.log(1 + root.peak))
                    color: Colors.tertiary
                    leadColor: Colors.primary
                }
            }
        }
    }
}
