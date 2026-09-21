import QtQuick
import qs.modules.services

BarStatItem {
    widthTemplate: "100°"
    icon: "device_thermostat"
    shortLabel: "TEMP"
    number: String(Math.round(ServiceSystemInfo.cpuTemp))
    detail: "GPU " + Math.round(ServiceSystemInfo.gpuTemp) + "°C"
    detailTemplate: "GPU 100°C"
    value: ServiceSystemInfo.cpuTemp / 100
    label: Math.round(ServiceSystemInfo.cpuTemp) + "°"
    tip: "CPU " + Math.round(ServiceSystemInfo.cpuTemp) + " °C"
}
