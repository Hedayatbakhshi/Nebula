import QtQuick

Item {
    id: root
    visible: false

    property string artUrl: ""
    property string trackKey: ""
    property string bestUrl: ""
    property real bestArea: 0

    function reset() {
        root.bestUrl = ""
        root.bestArea = 0
        root.consider()
    }

    function consider() {
        if (root.artUrl === "") {
            root.bestUrl = ""
            root.bestArea = 0
            return
        }
        if (probe.status !== Image.Ready || probe.source.toString() !== root.artUrl) return
        const area = probe.implicitWidth * probe.implicitHeight
        if (area >= root.bestArea) {
            root.bestArea = area
            root.bestUrl = root.artUrl
        }
    }

    onTrackKeyChanged: root.reset()
    onArtUrlChanged: if (root.artUrl === "") root.reset()

    Image {
        id: probe
        source: root.artUrl
        asynchronous: true
        onStatusChanged: root.consider()
    }
}
