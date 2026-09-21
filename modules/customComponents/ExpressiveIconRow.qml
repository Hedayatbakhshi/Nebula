import QtQuick
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

Item {
    id: root

    property var model: []
    property var iconFor: function(modelData, active) { return modelData.icon ?? "" }
    property var activeCheck: function(index) { return false }
    signal triggered(int index)

    property int pressedIndex: -1
    readonly property int count: root.model.length
    readonly property real gap: 7
    readonly property real growth: 0.28
    property real minWidth: 46
    property real rowHeight: 40

    readonly property int perRow: root.count > 0
        ? Math.max(1, Math.min(root.count,
                               Math.floor((root.width + root.gap) / (root.minWidth + root.gap))))
        : 1
    readonly property int rowCount: root.count > 0 ? Math.ceil(root.count / root.perRow) : 0
    readonly property real baseW: root.perRow > 0
        ? (root.width - (root.perRow - 1) * root.gap) / root.perRow : 0

    implicitHeight: root.rowCount > 0
        ? root.rowCount * root.rowHeight + (root.rowCount - 1) * root.gap : 0

    Column {
        anchors.fill: parent
        spacing: root.gap

        Repeater {
            model: root.rowCount

            delegate: Row {
                id: line
                required property int index

                readonly property int from: line.index * root.perRow
                readonly property int n: Math.min(root.perRow, root.count - line.from)
                readonly property bool holdsPressed: root.pressedIndex >= line.from
                    && root.pressedIndex < line.from + line.n

                width: root.width
                height: root.rowHeight
                spacing: root.gap

                Repeater {
                    model: line.n

                    delegate: Rectangle {
                        id: btn
                        required property int index

                        readonly property int slot: line.from + btn.index
                        readonly property var entry: root.model[btn.slot]
                        readonly property bool active: root.activeCheck(btn.slot)
                        readonly property bool isPressed: root.pressedIndex === btn.slot

                        width: {
                            if (!line.holdsPressed || line.n < 2)
                                return root.baseW
                            if (btn.isPressed)
                                return root.baseW * (1 + root.growth)
                            return root.baseW * (1 - root.growth / (line.n - 1))
                        }
                        height: root.rowHeight
                        Behavior on width { SpatialAnim { speed: "fast" } }

                        radius: btn.isPressed ? btn.height * 0.22
                              : btn.active ? btn.height * 0.32
                              : btn.height / 2
                        Behavior on radius { SpatialAnim { speed: "fast" } }

                        color: btn.active ? Colors.primary
                             : btnArea.containsMouse ? Colors.surfaceContainerHighest
                             : Colors.surfaceContainerHigh
                        Behavior on color { EffectsColorAnim { speed: "fast" } }

                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: btn.entry ? root.iconFor(btn.entry, btn.active) : ""
                            iconSize: 19
                            customColor: btn.active ? Colors.primaryText : Colors.surfaceText
                            fill: btn.active ? 1 : 0
                            Behavior on fill { EffectsAnim { speed: "fast" } }
                            scale: btn.isPressed ? 0.86 : 1
                            Behavior on scale { SpatialAnim { speed: "fast" } }
                        }

                        MouseArea {
                            id: btnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: root.pressedIndex = btn.slot
                            onReleased: root.pressedIndex = -1
                            onCanceled: root.pressedIndex = -1
                            onClicked: root.triggered(btn.slot)
                        }
                    }
                }
            }
        }
    }
}
