import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "dayRibbon"
    tile: Qt.size(WidgetSizes.span(4), WidgetSizes.span(2))
    resizable: true
    minSpan: Qt.size(3, 2)
    maxSpan: Qt.size(6, 3)
    defaultPos: Qt.point(365, 420)

    readonly property var sample: {
        const d = new Date()
        d.setHours(8, 40, 0, 0)
        const plan = [["code", 22], ["zen", 6], ["code", 31], ["kitty", 9], ["code", 14], ["discord", 5], ["", 12], ["zen", 18],
                      ["kitty", 4], ["code", 46], ["spotify", 3], ["code", 19], ["discord", 8], ["", 30], ["zen", 11], ["code", 38]]
        const out = []
        let t = d.getTime()
        for (const p of plan) {
            if (p[0] !== "")
                out.push([p[0], t, t + p[1] * 60000])
            t += p[1] * 60000
        }
        return out
    }
    readonly property var segs: root.preview ? root.sample : ServiceScreenTime.segments
    readonly property real endMs: root.preview ? (root.segs.length ? root.segs[root.segs.length - 1][2] : Date.now()) : ServiceScreenTime.now
    readonly property real startMs: root.segs.length ? root.segs[0][1] : root.endMs - 3600000
    readonly property real spanMs: Math.max(60000, root.endMs - root.startMs)

    readonly property var totals: {
        const m = {}
        for (const s of root.segs)
            m[s[0]] = (m[s[0]] ?? 0) + (s[2] - s[1])
        return Object.keys(m).map(k => ({ app: k, ms: m[k] })).sort((a, b) => b.ms - a.ms)
    }
    readonly property var rank: {
        const r = {}
        root.totals.forEach((t, i) => r[t.app] = i)
        return r
    }
    readonly property real activeMs: root.totals.reduce((a, t) => a + t.ms, 0)
    readonly property real longestMs: {
        let best = 0, run = 0, prev = null
        for (const s of root.segs) {
            if (prev && prev[0] === s[0] && s[1] - prev[2] < 60000)
                run += s[2] - s[1]
            else
                run = s[2] - s[1]
            best = Math.max(best, run)
            prev = s
        }
        return best
    }
    readonly property int switches: {
        let n = 0, prev = ""
        for (const s of root.segs) {
            if (s[0] !== prev)
                n++
            prev = s[0]
        }
        return Math.max(0, n - 1)
    }
    readonly property var palette: [Colors.primary, Colors.tertiary, Colors.secondary, Colors.primaryContainer,
                                    Colors.tertiaryContainer, Colors.surfaceVariantText]
    property string tip: ""

    function colorFor(app) {
        const i = root.rank[app] ?? 99
        return i < root.palette.length ? root.palette[i] : Colors.outline
    }
    function nameFor(app) {
        const e = DesktopEntries.heuristicLookup(app)
        return e?.name ?? (app.length ? app.charAt(0).toUpperCase() + app.slice(1) : "Unknown")
    }
    function dur(ms) {
        const m = Math.round(ms / 60000)
        return m >= 60 ? Math.floor(m / 60) + "h " + (m % 60) + "m" : m + "m"
    }
    function hm(ms) {
        return Qt.formatTime(new Date(ms), "hh:mm")
    }

    WidgetCard {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: parent.pad
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                CustomText {
                    Layout.fillWidth: true
                    content: "Your day so far"
                    size: 17
                    weight: 600
                    elide: Text.ElideRight
                }
                CustomText {
                    content: root.segs.length ? root.hm(root.startMs) + " to " + root.hm(root.endMs) : "Nothing logged yet"
                    size: 11
                    customColor: Colors.outline
                }
            }

            Item {
                id: ribbon
                Layout.fillWidth: true
                Layout.preferredHeight: 36

                ClippingRectangle {
                    anchors.fill: parent
                    radius: 10
                    color: Colors.surfaceContainerLow

                    Repeater {
                        model: root.segs
                        Rectangle {
                            required property var modelData
                            x: (modelData[1] - root.startMs) / root.spanMs * ribbon.width
                            width: Math.max(1, (modelData[2] - modelData[1]) / root.spanMs * ribbon.width)
                            height: ribbon.height
                            color: root.colorFor(modelData[0])
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPositionChanged: mouse => {
                        const t = root.startMs + mouse.x / width * root.spanMs
                        const s = root.segs.find(x => x[1] <= t && t <= x[2])
                        root.tip = s ? root.nameFor(s[0]) + ", " + root.hm(s[1]) + " to " + root.hm(s[2]) + ", " + root.dur(s[2] - s[1])
                                     : "Away at " + root.hm(t)
                    }
                    onExited: root.tip = ""
                }
            }

            CustomText {
                Layout.fillWidth: true
                Layout.topMargin: -4
                content: root.tip !== "" ? root.tip : "Hover the ribbon to see what you were in"
                size: 11
                customColor: root.tip !== "" ? Colors.surfaceVariantText : Colors.outline
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: [[root.dur(root.activeMs), "at the screen"], [root.dur(root.longestMs), "longest focus"], [root.switches.toString(), "app switches"]]
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: statCol.implicitHeight + 14
                        radius: 14
                        color: Colors.surfaceContainerLow
                        Column {
                            id: statCol
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            CustomText { content: modelData[0]; size: 16; weight: 600 }
                            CustomText { content: modelData[1]; size: 10; customColor: Colors.outline }
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: 18
                rowSpacing: 6
                visible: root.height > 260

                Repeater {
                    model: root.totals.slice(0, root.height > 330 ? 6 : 4)
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: 3
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Rectangle { width: 10; height: 10; radius: 3; color: root.colorFor(modelData.app) }
                            CustomText {
                                Layout.fillWidth: true
                                content: root.nameFor(modelData.app)
                                size: 12
                                elide: Text.ElideRight
                            }
                            CustomText { content: root.dur(modelData.ms); size: 11; customColor: Colors.outline }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 18
                            implicitHeight: 4
                            radius: 2
                            color: Colors.surfaceContainerHighest
                            Rectangle {
                                width: parent.width * (root.totals.length ? modelData.ms / root.totals[0].ms : 0)
                                height: parent.height
                                radius: 2
                                color: root.colorFor(modelData.app)
                            }
                        }
                    }
                }
            }
        }
    }
}
