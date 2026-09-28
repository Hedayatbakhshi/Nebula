import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "claudeCode"
    tile: Qt.size(WidgetSizes.span(4), WidgetSizes.span(2))
    resizable: true
    minSpan: Qt.size(3, 2)
    maxSpan: Qt.size(6, 2)
    defaultPos: Qt.point(620, 100)

    readonly property var canned: ({
        today: { tokens: 72900000, output: 464000, messages: 356, sessions: 3,
                 models: [{ name: "claude-opus-5", tokens: 61000000 },
                          { name: "claude-sonnet-5", tokens: 11900000 }] },
        series: [{ weekday: "S", tokens: 339000000 }, { weekday: "S", tokens: 161000000 },
                 { weekday: "M", tokens: 139000000 }, { weekday: "T", tokens: 89000000 },
                 { weekday: "W", tokens: 0 },         { weekday: "T", tokens: 24000000 },
                 { weekday: "F", tokens: 72900000 }],
        peak: 339000000, live: true, project: "quickshell",
        limits: [{ group: "session", percent: 86, severity: "warning", secondsLeft: 11812 },
                 { group: "weekly",  percent: 4,  severity: "normal",  secondsLeft: 602212 }]
    })

    readonly property var today:  root.preview ? root.canned.today  : ServiceClaudeCode.today
    readonly property var series: root.preview ? root.canned.series : ServiceClaudeCode.series
    readonly property int peak:   root.preview ? root.canned.peak   : ServiceClaudeCode.peak
    readonly property bool live:  root.preview ? root.canned.live   : ServiceClaudeCode.live
    readonly property string project: root.preview ? root.canned.project : ServiceClaudeCode.project
    readonly property bool ready: root.preview || ServiceClaudeCode.ready

    readonly property bool limitsStale: !root.preview && ServiceClaudeCode.limitsStale
    readonly property string staleNote: root.limitsStale
        ? ServiceClaudeCode.formatSpan(ServiceClaudeCode.limitsAgeSec) + " old"
        : ""

    readonly property var sessionLimit: root.preview
        ? root.canned.limits[0]
        : ServiceClaudeCode.limitFor("session")
    readonly property var weeklyLimit: root.preview
        ? root.canned.limits[1]
        : ServiceClaudeCode.limitFor("weekly")

    Component.onCompleted: if (!root.preview) ServiceClaudeCode.retain()
    Component.onDestruction: if (!root.preview) ServiceClaudeCode.release()

    function fmt(n) {
        if (n >= 1000000000) return (n / 1000000000).toFixed(1) + "B"
        if (n >= 1000000)    return (n / 1000000).toFixed(1) + "M"
        if (n >= 1000)       return Math.round(n / 1000) + "K"
        return String(n ?? 0)
    }

    function pct(limit) {
        return (limit !== null && limit !== undefined) ? (limit.percent ?? 0) : 0
    }

    // Colors.error is wallpaper-derived and can land on top of Colors.primary
    // (#ffb4ab vs #ffb4a6 under a warm theme), so severity carries its own hue.
    function tone(limit, fallback) {
        const sev = (limit !== null && limit !== undefined) ? (limit.severity ?? "normal") : "normal"
        if (sev === "normal") return fallback
        if (sev === "warning") return Qt.hsla(0.09, 0.85, 0.55, 1)
        return Qt.hsla(0.01, 0.78, 0.56, 1)
    }

    readonly property color sessionTone: root.tone(root.sessionLimit, Colors.primary)
    readonly property color weeklyTone: root.tone(root.weeklyLimit, Qt.alpha(Colors.surfaceText, 0.8))

    readonly property var topModels: (root.today.models ?? []).slice(0, 2)
    readonly property var dayMillions: (root.series ?? []).map(d => (d.tokens ?? 0) / 1000000)
    readonly property real peakM: root.peak / 1000000

    // TrapezoidChart turns N values into N-1 sloping segments, so the first
    // value is repeated to get a segment per day.
    readonly property var chartValues: {
        const v = root.dayMillions
        if (v.length < 2) return []
        return [v[0]].concat(v)
    }

    WidgetCard {
        anchors.fill: parent

        RowLayout {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: parent.pad
            anchors.rightMargin: parent.pad
            y: 13
            spacing: 6

            CustomText { content: "Claude Code"; size: 12; customColor: Colors.primary }

            CustomText {
                visible: root.limitsStale
                content: "· " + root.staleNote
                size: 10
                customColor: Qt.hsla(0.09, 0.85, 0.55, 1)
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 6; height: 6; radius: 3
                color: root.live ? Colors.primary : Colors.outline
                opacity: root.live ? 1 : 0.5
            }
            CustomText {
                content: root.live ? (root.project.length > 0 ? root.project : "active") : "idle"
                size: 10
                customColor: Colors.outline
                elide: Text.ElideRight
                Layout.maximumWidth: 96
            }
        }

        Item {
            id: rings
            x: 18
            y: 36
            width: 96
            height: 96
            visible: root.ready
            opacity: root.limitsStale ? 0.45 : 1
            Behavior on opacity { NumberAnimation { duration: 200 } }

            CustomCircularProgressBar {
                anchors.fill: parent
                progress: Math.min(1, root.pct(root.weeklyLimit) / 100)
                radius: 44
                thickness: 6
                showText: false
                baseColor: Qt.alpha(Colors.surfaceText, 0.10)
                lineColor: root.weeklyTone
            }

            CustomCircularProgressBar {
                anchors.fill: parent
                progress: Math.min(1, root.pct(root.sessionLimit) / 100)
                radius: 32
                thickness: 6
                showText: false
                baseColor: Qt.alpha(Colors.surfaceText, 0.10)
                lineColor: root.sessionTone
            }

            Column {
                anchors.centerIn: parent
                spacing: -2

                CustomText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    content: Math.round(root.pct(root.sessionLimit)) + "%"
                    size: 20
                    weight: 700
                    customColor: root.sessionTone
                }

                CustomText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    content: "5h"
                    size: 9
                    weight: 600
                    font.letterSpacing: 1
                    customColor: Colors.outline
                }
            }
        }

        component LimitLine: RowLayout {
            id: line

            property string label: ""
            property var limit: null
            property color tone: Colors.primary

            spacing: 6

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 6; height: 6; radius: 3
                color: line.tone
            }

            CustomText {
                Layout.preferredWidth: 18
                content: line.label
                size: 10
                weight: 600
                customColor: Colors.outline
            }

            CustomText {
                Layout.preferredWidth: 32
                content: (line.limit !== null && line.limit !== undefined)
                    ? Math.round(line.limit.percent ?? 0) + "%"
                    : "—"
                size: 11
                weight: 700
                customColor: line.tone
                // Only the percentage goes stale; the countdown beside it is
                // recomputed from the absolute reset time and stays correct.
                opacity: root.limitsStale ? 0.45 : 1
            }

            CustomText {
                Layout.fillWidth: true
                content: (line.limit !== null && line.limit !== undefined)
                    ? ServiceClaudeCode.formatSpan(line.limit.secondsLeft ?? 0)
                    : "no data"
                size: 10
                customColor: Colors.outline
            }
        }

        Column {
            id: stats
            x: 126
            y: 38
            width: parent.width - 126 - 18
            spacing: 5
            visible: root.ready

            RowLayout {
                width: parent.width
                spacing: 5

                CustomText {
                    content: root.fmt(root.today.tokens ?? 0)
                    size: 21
                    weight: 700
                    customColor: Colors.surfaceText
                }
                CustomText {
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 4
                    content: "today"
                    size: 10
                    customColor: Colors.outline
                }
                Item { Layout.fillWidth: true }
            }

            CustomText {
                content: (root.today.sessions ?? 0) + " sessions · " + (root.today.messages ?? 0) + " msgs"
                size: 10
                customColor: Colors.outline
            }

            LimitLine {
                width: parent.width
                label: "5h"
                limit: root.sessionLimit
                tone: root.sessionTone
            }

            LimitLine {
                width: parent.width
                label: "7d"
                limit: root.weeklyLimit
                tone: root.weeklyTone
            }

            RowLayout {
                width: parent.width
                spacing: 8
                visible: root.topModels.length > 0

                Repeater {
                    model: root.topModels

                    RowLayout {
                        required property var modelData

                        readonly property real share: {
                            const total = root.today.tokens ?? 0
                            return total > 0 ? (modelData.tokens ?? 0) / total : 0
                        }

                        spacing: 3

                        CustomText {
                            content: ServiceClaudeCode.shortModel(modelData.name)
                            size: 10
                            customColor: Qt.alpha(Colors.surfaceText, 0.7)
                        }
                        CustomText {
                            content: Math.round(share * 100) + "%"
                            size: 10
                            customColor: Colors.outline
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        // The M3 trapezoid chart, furniture painted out rather than switched
        // off: showAxis has to stay true or axisY collapses to `height` and the
        // weekday labels are drawn below the canvas. A transparent gridColor
        // plus a zero tick hides the axis while keeping the label band.
        TrapezoidChart {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.top: parent.top
            anchors.topMargin: 142
            visible: root.ready && root.chartValues.length >= 2

            values: root.chartValues
            labels: (root.series ?? []).map(d => d.weekday ?? "")

            lo: 0
            hi: root.peakM > 0 ? root.peakM * 1.08 : 1

            barColor: Colors.primary
            gridColor: "transparent"
            gridValues: []
            gridLabelWidth: 0
            tickHeight: 0
            bottomOffset: 0
            labelHeight: 13
            cornerRadius: 4
        }

        CustomText {
            anchors.centerIn: parent
            visible: !root.ready && !ServiceClaudeCode.failed
            content: "Reading transcripts…"
            size: 12
            customColor: Colors.outline
        }

        CustomText {
            anchors.centerIn: parent
            visible: !root.preview && ServiceClaudeCode.failed
            content: "No Claude Code data"
            size: 12
            customColor: Colors.outline
        }
    }
}
