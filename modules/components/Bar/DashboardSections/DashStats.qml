import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents
import qs.modules.components.Bar

Rectangle {
    id: root

    property bool compact: false

    function shows(key) { return DashLayout.opt("stats", key) !== false }

    readonly property bool showCpu:  root.shows("cpu")
    readonly property bool showMem:  root.shows("memory")
    readonly property bool showTemp: root.shows("temp")
    readonly property bool showGpu:  DashLayout.opt("stats", "gpu") === true
    readonly property bool showDisk: root.shows("disk")
    readonly property bool showNet:  root.shows("net")

    readonly property int meterCount: (root.showCpu ? 1 : 0) + (root.showMem ? 1 : 0)
                                    + (root.showTemp ? 1 : 0) + (root.showGpu ? 1 : 0)

    readonly property int columnSetting: Number(DashLayout.opt("stats", "columns") ?? 0) || 0

    readonly property int meterColumns: {
        if (root.meterCount === 0) return 1
        if (root.columnSetting > 0) return Math.min(root.meterCount, root.columnSetting)
        const fits = Math.max(1, Math.floor(root.width / 104))
        return Math.min(root.meterCount, fits)
    }

    function rate(bps) {
        const v = Number(bps) || 0
        if (v < 1024) return Math.round(v) + " B/s"
        if (v < 1024 * 1024) return (v / 1024).toFixed(0) + " kB/s"
        return (v / (1024 * 1024)).toFixed(1) + " MB/s"
    }

    implicitHeight: colu.implicitHeight
    color: "transparent"

    ColumnLayout {
        id: colu
        anchors.fill: parent
        spacing: root.compact ? 6 : 8

        GridLayout {
            Layout.fillWidth: true
            visible: root.meterCount > 0
            columns: root.meterColumns
            columnSpacing: root.compact ? 6 : 8
            rowSpacing: root.compact ? 6 : 8

            Meter {
                visible: root.showCpu
                label: "CPU"
                value: Math.round(ServiceSystemInfo.cpuUsage * 100) + "%"
                fraction: ServiceSystemInfo.cpuUsage
                tint: Colors.primary
            }

            Meter {
                visible: root.showMem
                label: "RAM"
                value: ServiceSystemInfo.memUsedGb.toFixed(1) + "G"
                fraction: ServiceSystemInfo.memUsage
                tint: Colors.tertiary
            }

            Meter {
                visible: root.showTemp
                label: "TEMP"
                value: Math.round(ServiceSystemInfo.cpuTemp) + "°"
                fraction: Math.max(0, Math.min(1, ServiceSystemInfo.cpuTemp / 100))
                tint: Colors.primaryContainer
            }

            Meter {
                visible: root.showGpu
                label: "GPU"
                value: Math.round(ServiceSystemInfo.gpuUsage * 100) + "%"
                fraction: ServiceSystemInfo.gpuUsage
                tint: Colors.secondaryContainer
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: diskCol.implicitHeight + 22
            visible: root.showDisk || root.showNet
            radius: 16
            color: Colors.surfaceContainerHigh

            ColumnLayout {
                id: diskCol
                anchors { fill: parent; margins: 11 }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    visible: root.showDisk
                    spacing: 6

                    CustomText { content: "DISK"; size: 11; weight: 700; customColor: Colors.surfaceVariantText }
                    Item { Layout.fillWidth: true }
                    CustomText {
                        content: (ServiceSystemInfo.diskTotalGb - ServiceSystemInfo.diskUsedGb).toFixed(0)
                                 + " GB free of " + ServiceSystemInfo.diskTotalGb.toFixed(0) + " GB"
                        size: 11
                        customColor: Colors.outline
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    visible: root.showDisk
                    radius: 4
                    color: Colors.surfaceContainerHighest

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, ServiceSystemInfo.diskUsage))
                        height: parent.height
                        radius: parent.radius
                        color: Colors.primary
                        Behavior on width { SpatialAnim { speed: "default" } }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: root.showNet
                    spacing: 8

                    MaterialIconSymbol { content: "swap_vert"; iconSize: 15; customColor: Colors.outline }
                    CustomText {
                        Layout.fillWidth: true
                        content: root.rate(ServiceSystemInfo.netDownloadBps) + " down · "
                                 + root.rate(ServiceSystemInfo.netUploadBps) + " up"
                        size: 11
                        customColor: Colors.surfaceVariantText
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    component Meter: Rectangle {
        id: m

        property string label: ""
        property string value: ""
        property real fraction: 0
        property color tint: Colors.primary

        Layout.fillWidth: true
        Layout.preferredHeight: root.compact ? 54 : 62
        radius: 16
        color: Colors.surfaceContainerHigh

        ColumnLayout {
            anchors { fill: parent; leftMargin: 11; rightMargin: 11; topMargin: 9; bottomMargin: 9 }
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                CustomText { content: m.label; size: 11; weight: 700; customColor: Colors.surfaceVariantText }
                Item { Layout.fillWidth: true }
                CustomText { content: m.value; size: 13; weight: 700 }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: Colors.surfaceContainerHighest

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, m.fraction))
                    height: parent.height
                    radius: parent.radius
                    color: m.tint
                    Behavior on width { SpatialAnim { speed: "default" } }
                }
            }
        }
    }
}
