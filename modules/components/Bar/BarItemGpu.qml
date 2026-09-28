import QtQuick
import qs.modules.services

BarStatItem {
    widthTemplate: "100%"
    icon: "developer_board"
    shortLabel: "GPU"
    value: ServiceSystemInfo.gpuUsage
    secondary: ServiceSystemInfo.gpuVramUsage
    label: Math.round(ServiceSystemInfo.gpuUsage * 100) + "%"
    tip: (ServiceSystemInfo.gpuName !== "" ? ServiceSystemInfo.gpuName : "GPU")
        + " · " + Math.round(ServiceSystemInfo.gpuUsage * 100) + "% · " + Math.round(ServiceSystemInfo.gpuTemp) + " °C"
}
