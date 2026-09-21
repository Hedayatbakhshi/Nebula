import QtQuick
import qs.modules.services

BarButtonItem {
    icon: ServicePipewire.micMuted ? "mic_off" : "mic"
    active: ServicePipewire.micMuted
    label: ServicePipewire.micMuted ? "Mic off" : "Mic"
    tip: ServicePipewire.micMuted ? "Microphone muted" : "Microphone on"
    onActivated: ServicePipewire.toggleMicMute()
}
