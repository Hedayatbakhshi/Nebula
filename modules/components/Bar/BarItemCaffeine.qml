import QtQuick
import qs.modules.services

BarButtonItem {
    icon: "coffee"
    active: ServiceIdleInhibit.active
    label: "Caffeine"
    tip: ServiceIdleInhibit.active ? "Staying awake" : "Caffeine off"
    onActivated: ServiceIdleInhibit.toggle()
}
