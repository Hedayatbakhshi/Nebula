import QtQuick
import qs.modules.services

BarStatItem {
    widthTemplate: "100%"
    icon: "memory"
    shortLabel: "CPU"
    detail: Math.round(ServiceSystemInfo.cpuTemp) + "°C"
    detailTemplate: "100°C"
    value: ServiceSystemInfo.cpuUsage
    label: Math.round(ServiceSystemInfo.cpuUsage * 100) + "%"
    tip: "CPU " + Math.round(ServiceSystemInfo.cpuUsage * 100) + "%"
}
