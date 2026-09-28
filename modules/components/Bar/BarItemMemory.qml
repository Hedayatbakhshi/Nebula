import QtQuick
import qs.modules.services

BarStatItem {
    widthTemplate: "100%"
    icon: "memory_alt"
    shortLabel: "RAM"
    value: ServiceSystemInfo.memUsage
    secondary: ServiceSystemInfo.memCacheFrac
    stack: [ServiceSystemInfo.memUsage, ServiceSystemInfo.memCacheFrac, ServiceSystemInfo.memBuffersFrac]
    label: Math.round(ServiceSystemInfo.memUsage * 100) + "%"
    tip: "Memory " + ServiceSystemInfo.memUsedGb.toFixed(1) + " / " + ServiceSystemInfo.memTotalGb.toFixed(1) + " GB"
}
