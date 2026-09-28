import QtQuick
import qs.modules.services

BarStatItem {
    widthTemplate: "100°"
    icon: "device_thermostat"
    shortLabel: "TEMP"
    number: String(Math.round(ServiceSystemInfo.cpuTemp))
    value: ServiceSystemInfo.cpuTemp / 100
    secondary: ServiceSystemInfo.gpuTemp / 100
    label: Math.round(ServiceSystemInfo.cpuTemp) + "°"
    tip: "CPU " + Math.round(ServiceSystemInfo.cpuTemp) + " °C"
}
