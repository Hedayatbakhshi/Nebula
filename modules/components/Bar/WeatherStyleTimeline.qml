import QtQuick
import QtQuick.Layouts
import qs.modules.customComponents
import qs.modules.utils

ColumnLayout {
    id: root
    property Item panel: null
    spacing: 8

    readonly property int hourH: 38
    readonly property int eventH: 30
    readonly property bool wide: root.width >= 460

    readonly property var merged: {
        if (!root.panel) return []
        const hs = root.panel.upcoming
        if (hs.length === 0) return []
        const end = hs[hs.length - 1].abs
        const out = hs.map(h => ({ ev: false, abs: h.abs, h: h }))
        for (const e of root.panel.sunEvents)
            if (e.abs <= end) out.push({ ev: true, abs: e.abs, e: e })
        return out.sort((a, b) => a.abs - b.abs || (a.ev ? 1 : -1))
    }
    function rowH(r) {
        return r.ev ? root.eventH : root.hourH
    }
    readonly property real baseH: {
        if (!root.panel || root.panel.upcoming.length === 0) return 0
        const hs = root.panel.upcoming
        const end = hs[Math.min(7, hs.length - 1)].abs
        let t = 0
        for (const r of root.merged) if (r.abs <= end) t += root.rowH(r)
        return t
    }
    readonly property real allH: {
        let t = 0
        for (const r of root.merged) t += root.rowH(r)
        return t
    }
    readonly property real growRoom: Math.max(0, root.allH - root.baseH)
    readonly property var rows: {
        const room = Math.max(root.baseH, list.height - 20)
        const out = []
        let t = 0
        for (const r of root.merged) {
            if (t + root.rowH(r) > room + 0.5) break
            t += root.rowH(r)
            out.push(r)
        }
        return out
    }
    readonly property real tLo: {
        let v = Infinity
        for (const r of root.merged) if (!r.ev) v = Math.min(v, r.h.temp)
        return isFinite(v) ? v - 3 : 0
    }
    readonly property real tHi: {
        let v = -Infinity
        for (const r of root.merged) if (!r.ev) v = Math.max(v, r.h.temp)
        return isFinite(v) ? Math.max(v, root.tLo + 1) : 1
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(76, heroText.implicitHeight + 28)
        radius: 24
        color: Colors.surfaceContainer

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 14

            Image {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                source: root.panel ? root.panel.curIcon : ""
                sourceSize.width: 44
                sourceSize.height: 44
                asynchronous: true
            }
            ColumnLayout {
                id: heroText
                Layout.fillWidth: true
                spacing: 2
                CustomText {
                    Layout.fillWidth: true
                    content: root.panel ? root.panel.headline : ""
                    size: 13
                    weight: 600
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                CustomText {
                    Layout.fillWidth: true
                    content: root.panel ? "Feels " + root.panel.feels + "° · wind " + root.panel.stats[0].value + " " + root.panel.stats[0].unit : ""
                    size: 11
                    customColor: Colors.outline
                    elide: Text.ElideRight
                }
            }
            CustomText {
                content: root.panel ? root.panel.curTemp + "°" : ""
                size: 40
                weight: 700
                renderType: Text.QtRendering
                customColor: Colors.primary
            }
        }
    }

    Rectangle {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: root.baseH + 20
        Layout.minimumHeight: root.baseH + 20
        radius: 20
        color: Colors.surfaceContainer

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            anchors.leftMargin: 4
            anchors.rightMargin: 6

            Repeater {
                model: root.rows
                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool ev: row.modelData.ev
                    readonly property var h: row.modelData.h ?? null
                    readonly property bool isNow: !!row.h && row.h.isNow
                    readonly property bool last: row.index === root.rows.length - 1
                    width: parent.width
                    height: row.ev ? root.eventH : root.hourH

                    Rectangle {
                        anchors.fill: parent
                        visible: row.isNow
                        radius: 14
                        color: Colors.secondaryContainer
                    }

                    CustomText {
                        x: 0
                        width: 62
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        content: row.ev ? row.modelData.e.label : row.h.label
                        size: row.ev ? 11 : 12
                        weight: row.isNow ? 700 : 500
                        customColor: row.ev ? Colors.tertiary : row.isNow ? Colors.secondaryContainerText : Colors.outline
                    }

                    Rectangle {
                        x: 81
                        y: row.index === 0 ? parent.height / 2 : 0
                        width: 2
                        height: row.last ? parent.height / 2 : (row.index === 0 ? parent.height / 2 : parent.height)
                        color: Colors.outlineVariant
                    }
                    Rectangle {
                        x: 82 - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: row.ev ? 12 : 10
                        height: width
                        radius: width / 2
                        color: row.ev ? Colors.tertiary : row.isNow ? Colors.primary : Colors.surfaceContainerHighest
                        border.width: row.ev ? 0 : 2
                        border.color: Colors.primary
                    }

                    RowLayout {
                        visible: row.ev
                        x: 100
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        MaterialIconSymbol {
                            content: "wb_twilight"
                            iconSize: 16
                            customColor: Colors.tertiary
                        }
                        CustomText {
                            content: row.ev ? (row.modelData.e.sunrise ? "Sunrise" : "Sunset") : ""
                            size: 12
                            weight: 700
                            customColor: Colors.tertiary
                        }
                    }

                    RowLayout {
                        visible: !row.ev
                        anchors.left: parent.left
                        anchors.leftMargin: 98
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Image {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            source: row.h && root.panel ? root.panel.iconFor(row.h.code, row.h.night) : ""
                            sourceSize.width: 20
                            sourceSize.height: 20
                            asynchronous: true
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            radius: 4
                            color: Colors.surfaceContainerHigh
                            Rectangle {
                                width: row.h ? Math.max(8, parent.width * (row.h.temp - root.tLo) / (root.tHi - root.tLo)) : 0
                                height: parent.height
                                radius: 4
                                color: row.isNow ? Colors.primary : Colors.primaryContainer
                            }
                        }
                        CustomText {
                            Layout.preferredWidth: 30
                            content: row.h ? row.h.temp + "°" : ""
                            size: 14
                            weight: 700
                        }
                        CustomText {
                            Layout.preferredWidth: 30
                            content: row.h && row.h.rain > 0 ? row.h.rain + "%" : ""
                            size: 10
                            customColor: Colors.primary
                        }
                        CustomText {
                            visible: root.wide
                            Layout.preferredWidth: 42
                            content: row.h ? row.h.hum + "% rh" : ""
                            size: 10
                            customColor: Colors.outline
                        }
                        CustomText {
                            visible: root.wide
                            Layout.preferredWidth: 54
                            content: row.h ? row.h.wind + " km/h" : ""
                            size: 10
                            customColor: Colors.outline
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 54
        radius: 20
        color: Colors.surfaceContainer

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 0
            Repeater {
                model: root.panel ? root.panel.days : []
                delegate: ColumnLayout {
                    id: d
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    Layout.maximumWidth: Number.POSITIVE_INFINITY
                    spacing: 1
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: d.index === 0 ? "Today" : root.panel.dayShort(d.modelData.date, d.index)
                        size: 10
                        customColor: d.index === 0 ? Colors.primary : Colors.outline
                    }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: root.panel.dayHi(d.modelData) + "°"
                        size: 13
                        weight: 700
                    }
                }
            }
        }
    }
}
