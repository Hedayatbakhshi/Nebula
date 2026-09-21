import QtQuick
import qs.modules.services

BarStatItem {
    widthTemplate: "100%"
    icon: "developer_board"
    shortLabel: "GPU"
    detail: Math.round(ServiceSystemInfo.gpuTemp) + "°C · " + ServiceSystemInfo.gpuVramUsedGb.toFixed(1) + " GB"
    detailTemplate: "100°C · 00.0 GB"
    value: ServiceSystemInfo.gpuUsage
    label: Math.round(ServiceSystemInfo.gpuUsage * 100) + "%"
    tip: (ServiceSystemInfo.gpuName !== "" ? ServiceSystemInfo.gpuName : "GPU")
        + " · " + Math.round(ServiceSystemInfo.gpuUsage * 100) + "% · " + Math.round(ServiceSystemInfo.gpuTemp) + " °C"
}
