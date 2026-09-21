import QtQuick
import QtQuick.Layouts
import qs.modules.customComponents
import qs.modules.utils
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

ColumnLayout {
    id: root
    property Item panel: null
    readonly property real growRoom: 120
    spacing: 8

    readonly property int capCount: root.panel
        ? Math.max(4, Math.min(root.panel.upcoming.length, Math.floor((root.width - 16) / 40))) : 0
    readonly property var caps: root.panel ? root.panel.upcoming.slice(0, root.capCount) : []
    readonly property real capLo: {
        let v = Infinity
        for (const p of root.caps) v = Math.min(v, p.temp)
        return isFinite(v) ? v : 0
    }
    readonly property real capHi: {
        let v = -Infinity
        for (const p of root.caps) v = Math.max(v, p.temp)
        return isFinite(v) ? Math.max(v, root.capLo + 1) : 1
    }

    component Pill: Rectangle {
        id: pill
        property string label: ""
        property string value: ""
        property bool tonal: false
        Layout.fillWidth: true
        Layout.preferredHeight: 38
        radius: 19
        color: pill.tonal ? Colors.secondaryContainer : Colors.surfaceContainerHigh
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            CustomText {
                Layout.fillWidth: true
                content: pill.label
                size: 11
                customColor: pill.tonal ? Colors.secondaryContainerText : Colors.outline
            }
            CustomText { content: pill.value; size: 16; weight: 700 }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Item {
            Layout.preferredWidth: 150
            Layout.preferredHeight: 150
            MaterialShapes.ShapeCanvas {
                anchors.fill: parent
                roundedPolygon: MaterialShapeFn.getCookie9Sided()
                color: Colors.primaryContainer
            }
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0
                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: root.panel ? root.panel.curTemp + "°" : ""
                    size: 52
                    weight: 800
                    renderType: Text.QtRendering
                    customColor: Colors.primaryContainerText
                }
                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: 110
                    content: root.panel ? root.panel.description : ""
                    size: 12
                    weight: 700
                    elide: Text.ElideRight
                    customColor: Colors.primaryContainerText
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Pill { label: "High"; value: root.panel ? root.panel.todayHi + "°" : "" }
            Pill { label: "Low"; value: root.panel ? root.panel.todayLo + "°" : "" }
            Pill { label: "Feels"; value: root.panel ? root.panel.feels + "°" : ""; tonal: true }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 164
        Layout.minimumHeight: 164
        radius: 24
        color: Colors.surfaceContainer

        RowLayout {
            id: capRow
            anchors.fill: parent
            anchors.margins: 10
            anchors.topMargin: 12
            spacing: 4

            Repeater {
                model: root.caps
                delegate: ColumnLayout {
                    id: cap
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    Layout.maximumWidth: Number.POSITIVE_INFINITY
                    spacing: 4

                    Item { Layout.fillHeight: true }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: cap.modelData.temp + "°"
                        size: 11
                        weight: 700
                    }
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 44 + (cap.modelData.temp - root.capLo) / (root.capHi - root.capLo)
                                                * Math.max(20, capRow.height - 44 - 40)
                        radius: 14
                        color: cap.modelData.isNow ? Colors.primary
                             : cap.modelData.night ? Colors.surfaceContainerHigh : Colors.secondaryContainer
                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 5
                            width: 18
                            height: 18
                            source: root.panel ? root.panel.iconFor(cap.modelData.code, cap.modelData.night) : ""
                            sourceSize.width: 18
                            sourceSize.height: 18
                            asynchronous: true
                        }
                    }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: cap.modelData.label
                        size: 9
                        customColor: cap.modelData.isNow ? Colors.primary : Colors.outline
                    }
                }
            }
        }
    }

    GridLayout {
        id: tiles
        readonly property int cols: root.width >= 520 ? 6 : 3
        readonly property real tile: Math.min(92, (root.width - (tiles.cols - 1) * 6) / tiles.cols)
        readonly property var shapes: [
            MaterialShapeFn.getCookie9Sided(), MaterialShapeFn.getCircle(), MaterialShapeFn.getClover4Leaf(),
            MaterialShapeFn.getSquare(), MaterialShapeFn.getSoftBurst(), MaterialShapeFn.getPuffy()
        ]
        readonly property var fills: [Colors.surfaceContainerHigh, Colors.surfaceContainer, Colors.secondaryContainer,
                                      Colors.surfaceContainer, Colors.surfaceContainerHigh, Colors.surfaceContainer]
        Layout.fillWidth: true
        columns: tiles.cols
        rowSpacing: 6
        columnSpacing: 6

        Repeater {
            model: root.panel ? root.panel.stats : []
            delegate: Item {
                id: tile
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.preferredHeight: tiles.tile

                MaterialShapes.ShapeCanvas {
                    anchors.centerIn: parent
                    width: tiles.tile
                    height: tiles.tile
                    roundedPolygon: tiles.shapes[tile.index % tiles.shapes.length]
                    color: tiles.fills[tile.index % tiles.fills.length]
                }
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: tile.modelData.value + (tile.modelData.unit === "%" ? "%" : "")
                        size: tile.modelData.value.length > 3 ? 15 : 18
                        weight: 800
                    }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: tile.modelData.short
                        size: 10
                        customColor: tile.index % tiles.fills.length === 2 ? Colors.secondaryContainerText : Colors.outline
                    }
                }
            }
        }
    }

    Flow {
        id: chips
        readonly property int count: root.panel ? Math.max(1, Math.min(root.panel.days.length - 1, Math.floor((root.width + 6) / 108))) : 0
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        spacing: 6

        Repeater {
            model: root.panel ? root.panel.days.slice(1, 1 + chips.count) : []
            delegate: Rectangle {
                id: chip
                required property var modelData
                required property int index
                width: (chips.width - (chips.count - 1) * 6) / chips.count
                height: 34
                radius: 17
                color: "transparent"
                border.width: 1
                border.color: Colors.outlineVariant
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    CustomText { content: root.panel.dayShort(chip.modelData.date, chip.index + 1); size: 12; weight: 700 }
                    CustomText {
                        content: root.panel.dayHi(chip.modelData) + "°/" + root.panel.dayLo(chip.modelData) + "°"
                        size: 12
                        customColor: Colors.outline
                    }
                }
            }
        }
    }
}
