import QtQuick
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services

DashItem {
    id: root

    card: true

    Component.onCompleted: {
        ServiceEvents.retain()
        ServiceClock.ensureHolidaysForYear(root.viewYear)
    }
    Component.onDestruction: ServiceEvents.release()

    property int viewYear: ServiceEvents.now.getFullYear()
    property int viewMonth: ServiceEvents.now.getMonth()
    onViewYearChanged: ServiceClock.ensureHolidaysForYear(root.viewYear)

    readonly property int startDay: Number(root.opt("startDay") ?? 1) === 0 ? 0 : 1
    readonly property bool holidays: root.opt("holidays") !== false
    readonly property var names: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    readonly property int lead: (new Date(root.viewYear, root.viewMonth, 1).getDay() - root.startDay + 7) % 7
    readonly property int days: new Date(root.viewYear, root.viewMonth + 1, 0).getDate()
    readonly property int rows: Math.ceil((root.lead + root.days) / 7)

    readonly property var marks: {
        ServiceEvents.events
        ServiceClock.holidayData
        const from = new Date(root.viewYear, root.viewMonth, 1).getTime()
        const to = new Date(root.viewYear, root.viewMonth + 1, 1).getTime()
        const out = {}
        for (const e of ServiceEvents.between(from, to, root.holidays)) {
            const s = Math.max(from, ServiceEvents.startMs(e))
            const end = Math.min(to, Math.max(s + 1, ServiceEvents.endMs(e)))
            for (let t = s; t < end; t += 86400000) {
                const d = new Date(t).getDate()
                const m = out[d] ?? (out[d] = { event: false, holiday: false })
                if (e.holiday) m.holiday = true
                else m.event = true
            }
        }
        return out
    }

    function step(delta) {
        let m = root.viewMonth + delta
        let y = root.viewYear
        if (m < 0) { m = 11; y-- }
        else if (m > 11) { m = 0; y++ }
        root.viewMonth = m
        root.viewYear = y
    }

    function isToday(day) {
        const n = ServiceEvents.now
        return n.getFullYear() === root.viewYear && n.getMonth() === root.viewMonth && n.getDate() === day
    }

    function isPast(day) {
        const n = ServiceEvents.now
        return new Date(root.viewYear, root.viewMonth, day) < new Date(n.getFullYear(), n.getMonth(), n.getDate())
    }

    Item {
        id: head
        x: root.pad
        y: root.pad - 2
        width: root.width - root.pad * 2
        height: 30

        CustomText {
            anchors.verticalCenter: parent.verticalCenter
            content: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1),
                                   root.viewYear === ServiceEvents.now.getFullYear() ? "MMMM" : "MMMM yyyy")
            size: 15
            weight: 600
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Repeater {
                model: [{ icon: "chevron_left", d: -1 }, { icon: "chevron_right", d: 1 }]

                delegate: Rectangle {
                    id: nav
                    required property var modelData
                    width: 28
                    height: 28
                    radius: 14
                    color: navArea.containsMouse ? Colors.surfaceBright : Colors.surfaceContainerHighest

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: nav.modelData.icon
                        iconSize: 16
                        customColor: Colors.surfaceText
                    }

                    MouseArea {
                        id: navArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.step(nav.modelData.d)
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: head
        acceptedButtons: Qt.NoButton
        onWheel: w => root.step(w.angleDelta.y > 0 ? -1 : 1)
        z: -1
    }

    Grid {
        id: grid
        x: root.pad
        y: head.y + head.height + 6
        columns: 7
        readonly property real cw: (root.width - root.pad * 2) / 7
        readonly property real ch: Math.max(14, Math.min(36, (root.height - grid.y - root.pad + 4) / (root.rows + 1)))

        Repeater {
            model: 7
            delegate: CustomText {
                required property int index
                width: grid.cw
                height: grid.ch
                horizontalAlignment: Text.AlignHCenter
                content: root.names[(index + root.startDay) % 7]
                size: 12
                weight: 500
                customColor: Colors.outline
            }
        }

        Repeater {
            model: root.lead + root.days

            delegate: Item {
                id: cell
                required property int index
                readonly property int day: cell.index - root.lead + 1
                readonly property var mark: root.marks[cell.day] ?? null
                readonly property bool today: root.isToday(cell.day)
                width: grid.cw
                height: grid.ch

                Rectangle {
                    visible: cell.today
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height + 6)
                    height: parent.height
                    radius: height / 2
                    color: Colors.primary
                }

                CustomText {
                    visible: cell.day > 0
                    anchors.centerIn: parent
                    content: cell.day
                    size: 12
                    weight: cell.today ? 700 : 500
                    customColor: cell.today ? Colors.primaryText
                        : cell.mark && cell.mark.holiday ? Colors.tertiary
                        : root.isPast(cell.day) ? Colors.outline : Colors.surfaceText
                }

                Rectangle {
                    visible: cell.day > 0 && !cell.today && cell.mark !== null && cell.mark.event
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Math.max(1, grid.ch * 0.08)
                    width: 4
                    height: 4
                    radius: 2
                    color: Colors.tertiary
                }
            }
        }
    }
}
