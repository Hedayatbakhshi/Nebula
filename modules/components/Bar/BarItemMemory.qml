import QtQuick
import qs.modules.services

BarStatItem {
    widthTemplate: "100%"
    icon: "memory_alt"
    shortLabel: "RAM"
    detail: ServiceSystemInfo.memUsedGb.toFixed(1) + " / " + ServiceSystemInfo.memTotalGb.toFixed(1) + " GB"
    detailTemplate: "00.0 / 00.0 GB"
    value: ServiceSystemInfo.memUsage
    label: Math.round(ServiceSystemInfo.memUsage * 100) + "%"
    tip: "Memory " + ServiceSystemInfo.memUsedGb.toFixed(1) + " / " + ServiceSystemInfo.memTotalGb.toFixed(1) + " GB"
}
