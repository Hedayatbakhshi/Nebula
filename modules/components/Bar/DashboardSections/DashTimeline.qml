import QtQuick
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services

DashItem {
    id: root

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Colors.surfaceContainerHigh
    }

    Component.onCompleted: ServiceEvents.retain()
    Component.onDestruction: ServiceEvents.release()

    readonly property int from: Math.max(0, Math.min(23, Number(root.opt("from") ?? 8)))
    readonly property int to: Math.max(root.from + 1, Math.min(24, Number(root.opt("to") ?? 23)))
    readonly property var now: ServiceEvents.now
    readonly property var events: {
        ServiceEvents.events
        return ServiceEvents.today()
    }
    readonly property var timed: root.events.filter(e => !e.allDay)
    readonly property var allDay: root.events.filter(e => e.allDay)
    readonly property bool linked: ServiceEvents.urls.length > 0

    readonly property real headH: 30
    readonly property real dayTop: root.pad + root.headH + (root.allDay.length > 0 ? 28 : 0)
    readonly property real hourH: (root.height - root.dayTop - root.pad) / (root.to - root.from)
    readonly property int labelEvery: root.hourH >= 22 ? 1 : root.hourH >= 11 ? 2 : 3
    readonly property real gutter: 44

    function yFor(ms) {
        const d = new Date(ms)
        const h = d.getHours() + d.getMinutes() / 60
        return root.dayTop + (Math.max(root.from, Math.min(root.to, h)) - root.from) * root.hourH
    }

    Row {
        x: root.pad
        y: root.pad
        width: root.width - root.pad * 2
        spacing: 8
        CustomText {
            content: "Today"
            size: 15
            weight: 600
        }
        CustomText {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            content: root.timed.length === 0 ? "" : root.timed.length === 1 ? "1 event" : root.timed.length + " events"
            size: 12
            customColor: Colors.outline
        }
    }

    Row {
        x: root.pad + root.gutter
        y: root.pad + root.headH
        spacing: 6
        visible: root.allDay.length > 0
        Repeater {
            model: root.allDay.slice(0, 3)
            delegate: Rectangle {
                required property var modelData
                height: 22
                width: Math.min(180, chipText.implicitWidth + 18)
                radius: 11
                color: modelData.holiday ? Colors.tertiaryContainer : Colors.secondaryContainer
                CustomText {
                    id: chipText
                    anchors.centerIn: parent
                    width: parent.width - 14
                    content: modelData.title
                    size: 11
                    weight: 600
                    elide: Text.ElideRight
                    customColor: modelData.holiday ? Colors.tertiaryContainerText : Colors.secondaryContainerText
                }
            }
        }
    }

    Repeater {
        model: root.to - root.from + 1
        delegate: Item {
            required property int index
            readonly property int hour: root.from + index
            x: root.pad
            y: root.dayTop + index * root.hourH - 8
            width: root.width - root.pad * 2
            height: 16
            visible: root.linked && index % root.labelEvery === 0

            CustomText {
                width: root.gutter - 8
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                content: String(parent.hour % 24).padStart(2, "0") + ":00"
                size: 11
                customColor: Colors.outline
            }
            Rectangle {
                x: root.gutter
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - root.gutter
                height: 1
                color: Qt.alpha(Colors.outlineVariant, 0.7)
            }
        }
    }

    Repeater {
        model: root.timed
        delegate: Rectangle {
            id: block
            required property var modelData
            readonly property real y0: root.yFor(block.modelData.start)
            readonly property real y1: root.yFor(block.modelData.end)
            readonly property bool past: block.modelData.end < root.now.getTime()
            readonly property color accent: [Colors.primary, Colors.tertiary, Colors.secondary][block.modelData.calendar % 3] ?? Colors.primary
            visible: block.y1 > block.y0
            x: root.pad + root.gutter + 4
            y: block.y0 + 1
            width: root.width - x - root.pad
            height: Math.max(20, block.y1 - block.y0 - 2)
            radius: 10
            color: block.past ? Colors.surfaceContainer : Colors.surfaceContainerHighest
            clip: true

            Rectangle {
                width: 4
                height: parent.height
                radius: 2
                color: block.accent
                opacity: block.past ? 0.5 : 1
            }

            Row {
                x: 12
                y: Math.min(4, (parent.height - 16) / 2)
                width: parent.width - 16
                spacing: 8
                CustomText {
                    content: block.modelData.title
                    size: 12
                    weight: 600
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, parent.width - timeLbl.implicitWidth - 8)
                    customColor: block.past ? Colors.outline : Colors.surfaceText
                }
                CustomText {
                    id: timeLbl
                    content: Qt.formatTime(new Date(block.modelData.start), "hh:mm")
                    size: 11
                    customColor: Colors.outline
                }
            }
        }
    }

    Rectangle {
        readonly property real h: root.now.getHours() + root.now.getMinutes() / 60
        visible: root.linked && h >= root.from && h <= root.to
        x: root.pad + root.gutter - 4
        y: root.dayTop + (h - root.from) * root.hourH - 1
        width: root.width - x - root.pad
        height: 2
        color: Colors.primary

        Rectangle {
            x: -4
            y: -4
            width: 10
            height: 10
            radius: 5
            color: Colors.primary
        }
    }

    Column {
        visible: !root.linked
        anchors.centerIn: parent
        width: root.width - root.pad * 4
        spacing: 6
        MaterialIconSymbol {
            anchors.horizontalCenter: parent.horizontalCenter
            content: "event_available"
            iconSize: 26
            customColor: Colors.outline
        }
        CustomText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            content: "Add a calendar in this item's options to see your day here. Any iCal link works, including the secret address from Google Calendar."
            size: 12
            customColor: Colors.outline
        }
    }
}
