pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents

Item {
    id: slot

    required property string sectionKey
    required property int listIndex
    property Item dash: null
    property Component content: null
    property bool movable: true

    readonly property bool editing: slot.dash ? slot.dash.editing : false
    readonly property bool selected: slot.editing && slot.dash.selectedKey === slot.sectionKey
    readonly property bool dragging: slot.editing && slot.dash.dragKey === slot.sectionKey
    readonly property bool fills: slot.dash ? slot.dash.fillsFor(slot.sectionKey) : false
    readonly property bool chromeShown: slot.editing && !slot.dash.dragActive
        && (editArea.containsMouse || slot.selected)

    property real shift: 0
    property real dragY: 0
    property bool landing: false

    function settleFrom(fromY) {
        slot.landing = false
        slot.dragY = fromY - slot.y
        Qt.callLater(() => {
            slot.landing = true
            slot.dragY = 0
        })
    }

    Layout.fillWidth: true
    Layout.fillHeight: slot.fills
    Layout.minimumHeight: slot.fills ? 120 : 0
    Layout.preferredHeight: loader.item ? loader.item.implicitHeight + slot.cardPad * 2 + slot.cardHead : 0

    z: slot.dragging || slot.landing ? 20 : 0
    opacity: slot.dragging ? 0.96 : 1
    scale: slot.dragging ? 1.015 : 1

    Behavior on scale { SpatialAnim { speed: "fast" } }
    Behavior on opacity { EffectsAnim { speed: "fast" } }

    Behavior on dragY {
        enabled: slot.landing && !slot.dragging
        SpatialAnim { speed: "fast" }
    }

    transform: Translate { y: slot.shift + slot.dragY }

    Behavior on shift {
        enabled: !slot.dragging
        SpatialAnim { speed: "fast" }
    }

    readonly property bool carded: DashLayout.cards && slot.sectionKey !== "profile"
    readonly property bool ownsHeader: loader.item ? loader.item.ownsHeader === true : false
    readonly property string cardTitle: {
        const e = DashLayout.entry(slot.sectionKey)
        return e ? e.label : ""
    }
    readonly property real cardPad: slot.carded ? 10 : 0
    readonly property real cardHead: slot.carded && !slot.ownsHeader ? 24 : 0

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Colors.surfaceContainer
        visible: slot.carded
        opacity: slot.carded ? 1 : 0
        Behavior on opacity { EffectsAnim { speed: "fast" } }
    }

    CustomText {
        x: slot.cardPad + 4
        y: slot.cardPad
        visible: slot.carded && !slot.ownsHeader
        content: slot.cardTitle
        size: 11
        weight: 700
        customColor: Colors.outline
    }

    Loader {
        id: loader
        anchors.fill: parent
        anchors.margins: slot.cardPad
        anchors.topMargin: slot.cardPad + slot.cardHead
        enabled: !slot.editing
        sourceComponent: slot.content
    }

    Shape {
        anchors.fill: parent
        z: 40
        visible: slot.editing
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeColor: Colors.primary
            strokeWidth: slot.selected || slot.dragging ? 2 : 1.5
            strokeStyle: ShapePath.DashLine
            dashPattern: [3, 3]
            fillColor: Qt.alpha(Colors.primary, slot.selected ? 0.16
                : slot.dragging ? 0.2 : editArea.containsMouse ? 0.12 : 0.06)

            PathRectangle {
                x: 1
                y: 1
                width: Math.max(0, slot.width - 2)
                height: Math.max(0, slot.height - 2)
                radius: 18
            }
        }
    }

    MouseArea {
        id: editArea
        anchors.fill: parent
        z: 50
        enabled: slot.editing
        visible: slot.editing
        hoverEnabled: true
        cursorShape: slot.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        property real pressY: 0
        property bool moved: false

        function trackY(mouse) {
            return editArea.mapToItem(slot.dash, 0, mouse.y).y
        }

        onPressed: mouse => {
            editArea.pressY = editArea.trackY(mouse)
            editArea.moved = false
        }
        onPositionChanged: mouse => {
            if (!editArea.pressed)
                return
            const dy = editArea.trackY(mouse) - editArea.pressY
            if (!slot.movable)
                return
            if (!editArea.moved && Math.abs(dy) > 4) {
                editArea.moved = true
                slot.dash.beginDrag(slot.sectionKey, slot.listIndex, slot.height)
            }
            if (editArea.moved)
                slot.dash.updateDrag(dy)
        }
        onReleased: {
            if (editArea.moved)
                slot.dash.endDrag()
            else
                slot.dash.selectSection(slot.sectionKey)
            editArea.moved = false
        }
        onCanceled: {
            if (editArea.moved)
                slot.dash.cancelDrag()
            editArea.moved = false
        }
    }

    Rectangle {
        z: 60
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 8
        anchors.topMargin: 6
        visible: slot.chromeShown
        width: handleRow.implicitWidth + 8
        height: 26
        radius: 13
        color: Colors.surfaceContainerHighest

        Row {
            id: handleRow
            anchors.centerIn: parent
            spacing: 2

            Rectangle {
                width: 22
                height: 22
                radius: 11
                color: "transparent"

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "drag_indicator"
                    iconSize: 15
                    customColor: Colors.surfaceText
                }
            }

            Rectangle {
                width: 22
                height: 22
                radius: 11
                color: removeArea.containsMouse ? Qt.alpha(Colors.error, 0.16) : "transparent"

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "close"
                    iconSize: 15
                    customColor: removeArea.containsMouse ? Colors.error : Colors.surfaceText
                }

                MouseArea {
                    id: removeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const k = slot.sectionKey
                        const d = slot.dash
                        Qt.callLater(() => d.hideSection(k))
                    }
                }

                CustomToolTip { content: "Hide this section"; visible: removeArea.containsMouse }
            }
        }
    }

    Rectangle {
        z: 60
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 8
        anchors.topMargin: 6
        visible: slot.chromeShown
        width: label.implicitWidth + 16
        height: 22
        radius: 11
        color: slot.selected ? Colors.primary : Colors.surfaceContainerHighest

        CustomText {
            id: label
            anchors.centerIn: parent
            content: slot.dash ? slot.dash.labelFor(slot.sectionKey) : ""
            size: 11
            weight: 700
            customColor: slot.selected ? Colors.primaryText : Colors.surfaceText
        }
    }
}
