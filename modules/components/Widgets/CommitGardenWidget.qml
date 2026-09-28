import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "commitGarden"
    tile: Qt.size(WidgetSizes.span(4), WidgetSizes.span(2))
    resizable: true
    minSpan: Qt.size(3, 2)
    maxSpan: Qt.size(6, 2)
    defaultPos: Qt.point(145, 165)

    readonly property var days: {
        if (!root.preview) return ServicePersonal.git.days ?? {}
        const out = {}
        const d = new Date()
        for (let i = 0; i < 182; i++) {
            const k = Qt.formatDate(new Date(d.getFullYear(), d.getMonth(), d.getDate() - i), "yyyy-MM-dd")
            const v = (i * 7919) % 11
            if (v > 4) out[k] = v - 4
        }
        return out
    }
    readonly property var repos: root.preview ? [["orbit", 223], ["fitforge", 128]] : (ServicePersonal.git.repos ?? [])

    readonly property real gap: 3
    readonly property real cell: Math.max(8, Math.min(14, (grid.height - 6 * root.gap) / 7))
    readonly property int weeks: Math.max(4, Math.min(26, Math.floor((grid.width + root.gap) / (root.cell + root.gap))))

    readonly property date today: {
        ServiceClock.date
        const n = new Date()
        return new Date(n.getFullYear(), n.getMonth(), n.getDate())
    }
    readonly property date start: {
        const wd = (root.today.getDay() + 6) % 7
        return new Date(root.today.getFullYear(), root.today.getMonth(), root.today.getDate() - wd - 7 * (root.weeks - 1))
    }

    function dayAt(i) {
        return new Date(root.start.getFullYear(), root.start.getMonth(), root.start.getDate() + i)
    }

    function level(n) {
        return n === 0 ? 0 : n <= 2 ? 1 : n <= 5 ? 2 : n <= 10 ? 3 : 4
    }

    readonly property var streaks: {
        const has = k => (root.days[k] ?? 0) > 0
        let d = new Date(root.today)
        if (!has(Qt.formatDate(d, "yyyy-MM-dd"))) d.setDate(d.getDate() - 1)
        let cur = 0
        while (has(Qt.formatDate(d, "yyyy-MM-dd"))) { cur++; d.setDate(d.getDate() - 1) }
        let best = 0, run = 0
        for (let i = 0; i < root.weeks * 7; i++) {
            run = has(Qt.formatDate(root.dayAt(i), "yyyy-MM-dd")) ? run + 1 : 0
            best = Math.max(best, run)
        }
        const keys = Object.keys(root.days).filter(k => root.days[k] > 0).sort()
        const last = keys.length ? keys[keys.length - 1] : ""
        let ago = -1
        if (last !== "") {
            const p = last.split("-")
            ago = Math.round((root.today - new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]))) / 86400000)
        }
        return { cur: cur, best: best, ago: ago }
    }

    readonly property int total: {
        let t = 0
        for (let i = 0; i < root.weeks * 7; i++) t += root.days[Qt.formatDate(root.dayAt(i), "yyyy-MM-dd")] ?? 0
        return t
    }

    property int hover: -1

    WidgetCard {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: parent.pad
            spacing: 10

            WidgetTitle {
                Layout.fillWidth: true
                icon: "forest"
                title: "Commit garden"
                detail: root.total + " commits · " + root.weeks + " weeks"
            }

            Item {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true

                Repeater {
                    model: root.weeks * 7
                    delegate: Rectangle {
                        required property int index
                        readonly property date day: root.dayAt(index)
                        readonly property int n: root.days[Qt.formatDate(day, "yyyy-MM-dd")] ?? 0
                        readonly property int lv: root.level(n)
                        visible: day <= root.today
                        x: Math.floor(index / 7) * (root.cell + root.gap) + (grid.width - (root.weeks * (root.cell + root.gap) - root.gap)) / 2
                        y: (index % 7) * (root.cell + root.gap)
                        width: root.cell
                        height: root.cell
                        radius: 3
                        color: lv === 0 ? Colors.surfaceContainerHigh
                             : lv === 4 ? Colors.primary
                             : Qt.tint(Colors.surfaceContainerHigh, Qt.alpha(Colors.primary, [0, 0.3, 0.55, 0.8][lv]))
                        border.width: root.hover === index ? 2 : 0
                        border.color: Colors.surfaceText
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPositionChanged: mouse => {
                        const x0 = (grid.width - (root.weeks * (root.cell + root.gap) - root.gap)) / 2
                        const c = Math.floor((mouse.x - x0) / (root.cell + root.gap))
                        const r = Math.floor(mouse.y / (root.cell + root.gap))
                        const i = c * 7 + r
                        root.hover = c >= 0 && c < root.weeks && r >= 0 && r < 7 && root.dayAt(i) <= root.today ? i : -1
                    }
                    onExited: root.hover = -1
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                MaterialIconSymbol {
                    content: root.hover >= 0 ? "event" : "local_fire_department"
                    iconSize: 15
                    customColor: Colors.tertiary
                }
                CustomText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    size: 12
                    customColor: Colors.surfaceVariantText
                    content: {
                        if (root.hover >= 0) {
                            const d = root.dayAt(root.hover)
                            const n = root.days[Qt.formatDate(d, "yyyy-MM-dd")] ?? 0
                            return Qt.formatDate(d, "ddd d MMM") + " · " + (n === 1 ? "1 commit" : n + " commits")
                        }
                        const s = root.streaks
                        if (s.cur > 0) return s.cur + " day streak · best " + s.best
                        if (s.ago >= 0) return "Last commit " + (s.ago === 0 ? "today" : s.ago === 1 ? "yesterday" : s.ago + " days ago") + " · best streak " + s.best
                        return ServicePersonal.loaded || root.preview ? "No commits yet in this window" : "Reading your repos…"
                    }
                }
                CustomText {
                    visible: root.hover < 0 && root.repos.length > 0 && root.cols >= 5
                    content: root.repos.slice(0, 2).map(r => r[0] + " " + r[1]).join(" · ")
                    size: 11
                    family: "Fira Code"
                    customColor: Colors.outline
                }
            }
        }
    }
}
