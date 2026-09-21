import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.modules.customComponents
import qs.modules.utils

ColumnLayout {
    id: root
    property Item panel: null
    readonly property real growRoom: 140
    spacing: 8

    readonly property int points: root.panel
        ? Math.max(2, Math.min(root.panel.upcoming.length, Math.floor((chart.width - 16) / 40) + 1)) : 0
    readonly property var pts: root.panel ? root.panel.upcoming.slice(0, root.points) : []
    readonly property real lo: {
        let v = Infinity
        for (const p of root.pts) v = Math.min(v, p.temp)
        return isFinite(v) ? v : 0
    }
    readonly property real hi: {
        let v = -Infinity
        for (const p of root.pts) v = Math.max(v, p.temp)
        return isFinite(v) ? Math.max(v, root.lo + 1) : 1
    }

    function px(i) {
        return 16 + i * (chart.width - 32) / Math.max(1, root.points - 1)
    }
    function py(t) {
        const top = 30
        const bot = chart.height - 30
        return bot - (t - root.lo) / (root.hi - root.lo) * (bot - top)
    }
    function xAt(abs) {
        if (root.pts.length < 2) return 0
        const a0 = root.pts[0].abs
        const a1 = root.pts[root.pts.length - 1].abs
        return 16 + (abs - a0) / Math.max(1, a1 - a0) * (chart.width - 32)
    }

    readonly property string linePath: {
        const n = root.pts.length
        if (n < 2 || chart.width <= 0) return ""
        const p = root.pts.map((e, i) => [root.px(i), root.py(e.temp)])
        let d = "M" + p[0][0] + "," + p[0][1]
        for (let i = 0; i < n - 1; i++) {
            const p0 = p[Math.max(0, i - 1)], p1 = p[i], p2 = p[i + 1], p3 = p[Math.min(n - 1, i + 2)]
            d += " C" + (p1[0] + (p2[0] - p0[0]) / 6) + "," + (p1[1] + (p2[1] - p0[1]) / 6)
               + " " + (p2[0] - (p3[0] - p1[0]) / 6) + "," + (p2[1] - (p3[1] - p1[1]) / 6)
               + " " + p2[0] + "," + p2[1]
        }
        return d
    }
    readonly property string areaPath: root.linePath === "" ? ""
        : root.linePath + " L" + root.px(root.points - 1) + "," + (chart.height - 18) + " L" + root.px(0) + "," + (chart.height - 18) + " Z"

    readonly property var nightBands: {
        if (!root.panel || root.pts.length < 2) return []
        const a0 = root.pts[0].abs
        const a1 = root.pts[root.pts.length - 1].abs
        const ev = root.panel.sunEvents
        const out = []
        let start = root.panel.night ? a0 : -1
        for (const e of ev) {
            if (e.abs > a1) break
            if (!e.sunrise) start = e.abs
            else if (start >= 0) {
                out.push({ x0: root.xAt(start), x1: root.xAt(e.abs) })
                start = -1
            }
        }
        if (start >= 0) out.push({ x0: root.xAt(start), x1: root.xAt(a1) })
        return out
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 12

        CustomText {
            content: root.panel ? root.panel.curTemp + "°" : ""
            size: 68
            weight: 300
            renderType: Text.QtRendering
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            CustomText {
                Layout.fillWidth: true
                content: root.panel ? root.panel.description : ""
                size: 15
                weight: 700
                customColor: Colors.primary
                elide: Text.ElideRight
            }
            CustomText {
                Layout.fillWidth: true
                content: root.panel ? "Feels " + root.panel.feels + "° · H " + root.panel.todayHi + "° L " + root.panel.todayLo + "°" : ""
                size: 12
                customColor: Colors.outline
                elide: Text.ElideRight
            }
        }
        Image {
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            source: root.panel ? root.panel.curIcon : ""
            sourceSize.width: 44
            sourceSize.height: 44
            asynchronous: true
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 164
        Layout.minimumHeight: 164
        radius: 20
        color: Colors.surfaceContainer

        RowLayout {
            id: chartHead
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            CustomText {
                Layout.fillWidth: true
                content: root.pts.length > 1 ? "Next " + Math.round((root.pts[root.pts.length - 1].abs - root.pts[0].abs) / 60) + " hours" : "Forecast"
                size: 11
                weight: 700
            }
            CustomText {
                content: root.panel ? root.panel.sunEventText : ""
                size: 11
                customColor: Colors.outline
            }
        }

        Item {
            id: chart
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: chartHead.bottom
            anchors.bottom: parent.bottom
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.bottomMargin: 6

            Repeater {
                model: root.nightBands
                delegate: Rectangle {
                    required property var modelData
                    x: modelData.x0
                    y: 0
                    width: Math.max(0, modelData.x1 - modelData.x0)
                    height: chart.height - 18
                    radius: 10
                    color: Colors.surfaceContainerLow
                }
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillColor: Qt.alpha(Colors.primary, 0.14)
                    PathSvg { path: root.areaPath }
                }
                ShapePath {
                    strokeWidth: 2.5
                    strokeColor: Colors.primary
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: root.linePath }
                }
            }

            Repeater {
                model: root.pts
                delegate: Item {
                    id: pt
                    required property var modelData
                    required property int index
                    x: root.px(pt.index)
                    y: root.py(pt.modelData.temp)

                    Rectangle {
                        visible: pt.modelData.isNow
                        x: -6
                        y: -6
                        width: 12
                        height: 12
                        radius: 6
                        color: Colors.primary
                        border.width: 2.5
                        border.color: Colors.surfaceContainer
                    }
                    CustomText {
                        x: -width / 2
                        y: -24
                        content: pt.modelData.temp + "°"
                        size: 11
                        weight: pt.modelData.isNow ? 700 : 600
                        customColor: pt.modelData.isNow ? Colors.primary : Colors.surfaceText
                    }
                    CustomText {
                        x: -width / 2
                        y: chart.height - 14 - pt.y
                        content: pt.modelData.label
                        size: 10
                        customColor: Colors.outline
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: weekCol.implicitHeight + 20
        radius: 20
        color: Colors.surfaceContainer

        ColumnLayout {
            id: weekCol
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            CustomText {
                Layout.leftMargin: 2
                content: (root.panel ? root.panel.days.length : 0) + " days"
                size: 11
                weight: 700
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: root.panel ? root.panel.days : []
                    delegate: Rectangle {
                        id: dayCell
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        Layout.maximumWidth: Number.POSITIVE_INFINITY
                        Layout.preferredHeight: 84
                        radius: 14
                        color: dayCell.index === 0 ? Colors.secondaryContainer : "transparent"

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 3
                            CustomText {
                                Layout.alignment: Qt.AlignHCenter
                                content: root.panel ? root.panel.dayShort(dayCell.modelData.date, dayCell.index) : ""
                                size: 10
                                weight: 700
                                customColor: dayCell.index === 0 ? Colors.secondaryContainerText : Colors.outline
                            }
                            Image {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                source: root.panel ? root.panel.iconFor(root.panel.dayCode(dayCell.modelData), false) : ""
                                sourceSize.width: 20
                                sourceSize.height: 20
                                asynchronous: true
                            }
                            CustomText {
                                Layout.alignment: Qt.AlignHCenter
                                content: root.panel ? root.panel.dayHi(dayCell.modelData) + "°" : ""
                                size: 12
                                weight: 700
                                customColor: dayCell.index === 0 ? Colors.secondaryContainerText : Colors.surfaceText
                            }
                            CustomText {
                                Layout.alignment: Qt.AlignHCenter
                                content: root.panel ? root.panel.dayLo(dayCell.modelData) + "°" : ""
                                size: 11
                                customColor: Colors.outline
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 70
        radius: 20
        color: Colors.surfaceContainer

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 0

            Repeater {
                model: root.panel ? root.panel.stats.slice(0, root.width >= 480 ? 6 : 4) : []
                delegate: ColumnLayout {
                    id: stat
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    Layout.maximumWidth: Number.POSITIVE_INFINITY
                    spacing: 2
                    MaterialIconSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        content: stat.modelData.icon
                        iconSize: 18
                        customColor: Colors.primary
                    }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: stat.modelData.value + (stat.modelData.unit === "%" ? "%" : "")
                        size: 13
                        weight: 700
                    }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: stat.modelData.short
                        size: 10
                        customColor: Colors.outline
                    }
                }
            }
        }
    }
}
