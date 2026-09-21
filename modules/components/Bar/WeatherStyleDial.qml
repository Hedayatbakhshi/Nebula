import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.modules.customComponents
import qs.modules.utils

ColumnLayout {
    id: root
    property Item panel: null
    readonly property real growRoom: 160
    spacing: 8

    readonly property bool night: root.panel ? root.panel.night : false
    readonly property real progress: root.panel ? (root.night ? root.panel.nightProgress : root.panel.daylight) : 0
    readonly property color arcColor: root.night ? Colors.secondary : Colors.tertiary

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: dial.height + 70
        radius: 28
        color: Colors.surfaceContainer

        Item {
            id: dial
            readonly property real r: Math.min(parent.width - 60, 340) / 2
            anchors.horizontalCenter: parent.horizontalCenter
            y: 18
            width: dial.r * 2 + 20
            height: dial.r + 22

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Colors.surfaceContainerHighest
                    strokeWidth: 10
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: dial.width / 2
                        centerY: dial.r + 10
                        radiusX: dial.r
                        radiusY: dial.r
                        startAngle: 180
                        sweepAngle: 180
                    }
                }
                ShapePath {
                    strokeColor: root.arcColor
                    strokeWidth: 10
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: dial.width / 2
                        centerY: dial.r + 10
                        radiusX: dial.r
                        radiusY: dial.r
                        startAngle: 180
                        sweepAngle: 180 * Math.max(0.001, root.progress)
                    }
                }
            }

            Rectangle {
                readonly property real a: Math.PI * (1 - root.progress)
                x: dial.width / 2 + dial.r * Math.cos(a) - width / 2
                y: dial.r + 10 - dial.r * Math.sin(a) - height / 2
                width: 26
                height: 26
                radius: 13
                color: root.arcColor
                border.width: 4
                border.color: Colors.surfaceContainer
            }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                spacing: 0
                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: root.panel ? root.panel.curTemp + "°" : ""
                    size: Math.round(Math.min(72, dial.r * 0.52))
                    weight: 700
                    renderType: Text.QtRendering
                }
                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: root.panel ? root.panel.description + " · feels " + root.panel.feels + "°" : ""
                    size: 13
                    weight: 600
                    customColor: Colors.primary
                }
            }
        }

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16
            anchors.bottomMargin: 14
            spacing: 8

            ColumnLayout {
                spacing: 0
                CustomText { content: root.night ? "Sunset" : "Sunrise"; size: 10; customColor: Colors.outline }
                CustomText { content: root.panel ? (root.night ? root.panel.sunsetText : root.panel.sunriseText) : ""; size: 13; weight: 700 }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                visible: root.panel && root.panel.sunEventText !== ""
                Layout.preferredHeight: 26
                Layout.preferredWidth: chipText.implicitWidth + 20
                radius: 13
                color: root.night ? Colors.secondaryContainer : Colors.tertiary
                CustomText {
                    id: chipText
                    anchors.centerIn: parent
                    content: root.panel ? root.panel.sunEventText : ""
                    size: 11
                    weight: 700
                    customColor: root.night ? Colors.secondaryContainerText : Colors.tertiaryText
                }
            }
            Item { Layout.fillWidth: true }
            ColumnLayout {
                spacing: 0
                CustomText { Layout.alignment: Qt.AlignRight; content: root.night ? "Sunrise" : "Sunset"; size: 10; customColor: Colors.outline }
                CustomText { Layout.alignment: Qt.AlignRight; content: root.panel ? (root.night ? root.panel.sunriseText : root.panel.sunsetText) : ""; size: 13; weight: 700 }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 236
        Layout.minimumHeight: 236
        radius: 20
        color: Colors.surfaceContainer

        RowLayout {
            id: weekHead
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            CustomText { Layout.fillWidth: true; content: "This week"; size: 11; weight: 700 }
            CustomText {
                content: root.panel ? Math.round(root.panel.weekLo) + "° – " + Math.round(root.panel.weekHi) + "°" : ""
                size: 11
                customColor: Colors.outline
            }
        }

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: weekHead.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 10
            anchors.topMargin: 8
            spacing: 4

            Repeater {
                model: root.panel ? root.panel.days : []
                delegate: ColumnLayout {
                    id: col
                    required property var modelData
                    required property int index
                    readonly property int lo: root.panel.dayLo(col.modelData)
                    readonly property int hi: root.panel.dayHi(col.modelData)
                    readonly property int rain: root.panel.dayRain(col.modelData)
                    readonly property real span: Math.max(1, root.panel.weekHi - root.panel.weekLo)
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    Layout.maximumWidth: Number.POSITIVE_INFINITY
                    spacing: 4

                    CustomText { Layout.alignment: Qt.AlignHCenter; content: col.hi + "°"; size: 11; weight: 700 }
                    Item {
                        id: track
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 18
                            radius: 9
                            y: (root.panel.weekHi - col.hi) / col.span * track.height
                            height: Math.max(18, (col.hi - col.lo) / col.span * track.height)
                            color: col.index === 0 ? Colors.primary : Colors.secondaryContainer
                        }
                    }
                    CustomText { Layout.alignment: Qt.AlignHCenter; content: col.lo + "°"; size: 11; customColor: Colors.outline }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: col.index === 0 ? "Today" : root.panel.dayLetter(col.modelData.date)
                        size: 11
                        weight: 700
                        customColor: col.index === 0 ? Colors.primary : Colors.surfaceText
                    }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 12
                        content: col.rain > 0 ? col.rain + "%" : ""
                        size: 9
                        customColor: Colors.primary
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 88
        radius: 20
        color: Colors.surfaceContainer

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 0

            Repeater {
                model: root.panel ? root.panel.stats.slice(0, root.width >= 480 ? 6 : 4) : []
                delegate: ColumnLayout {
                    id: ring
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    Layout.maximumWidth: Number.POSITIVE_INFINITY
                    spacing: 4

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 50
                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeColor: Colors.surfaceContainerHighest
                                strokeWidth: 5
                                fillColor: "transparent"
                                PathAngleArc { centerX: 25; centerY: 25; radiusX: 20; radiusY: 20; startAngle: 0; sweepAngle: 360 }
                            }
                            ShapePath {
                                strokeColor: Colors.primary
                                strokeWidth: 5
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                PathAngleArc {
                                    centerX: 25; centerY: 25; radiusX: 20; radiusY: 20
                                    startAngle: -90
                                    sweepAngle: 360 * Math.max(0.001, Math.min(0.999, ring.modelData.frac))
                                }
                            }
                        }
                        CustomText {
                            anchors.centerIn: parent
                            content: ring.modelData.value.length > 4 ? ring.modelData.value.slice(0, 4) : ring.modelData.value
                            size: 12
                            weight: 700
                        }
                    }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: ring.modelData.short
                        size: 10
                        customColor: Colors.outline
                    }
                }
            }
        }
    }
}
