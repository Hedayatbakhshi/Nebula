import QtQuick
import qs.modules.services

BarStatItem {
    widthTemplate: "100%"
    icon: "memory"
    shortLabel: "CPU"
    value: ServiceSystemInfo.cpuUsage
    secondary: ServiceSystemInfo.cpuTemp / 100
    cores: ServiceSystemInfo.cpuCores
    label: Math.round(ServiceSystemInfo.cpuUsage * 100) + "%"
    tip: "CPU " + Math.round(ServiceSystemInfo.cpuUsage * 100) + "%"
}
