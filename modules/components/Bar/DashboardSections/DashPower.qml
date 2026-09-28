import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services

DashItem {
    id: root

    property Item coordSpace: null
    property string panelMode: ""
    signal openPanel(string mode, var parentPos, var pos, var srcSize, real srcRadius)

    readonly property string style: String(root.opt("style") ?? "buttons")
    readonly property var profile: ServiceUPower.powerProfiles[ServiceUPower.powerProfile] ?? ServiceUPower.powerProfiles[0]

    M3ButtonGroup {
        visible: root.style === "buttons"
        anchors.centerIn: parent
        width: root.width
        height: Math.min(root.height, 44)
        fillWidth: true
        iconSize: 18
        textSize: 12
        model: ServiceUPower.powerProfiles.map((p, i) => ({ value: i, icon: p.icon, label: root.width >= 360 ? p.name : "" }))
        activeCheck: function(v) { return ServiceUPower.powerProfile === v }
        onSegmentClicked: v => ServiceUPower.setPowerProfile(v)
    }

    Rectangle {
        id: pill
        visible: root.style === "button"
        anchors.centerIn: parent
        width: root.width
        height: Math.min(root.height, 54)
        radius: area.pressed ? pill.height * 0.22 : pill.height / 2
        color: area.containsMouse ? Colors.surfaceContainerHighest
            : root.framed ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
        opacity: root.panelMode === "modes" ? 0 : 1
        Behavior on radius { SpatialAnim { speed: "fast" } }
        Behavior on color { EffectsColorAnim { speed: "fast" } }
        Behavior on opacity { EffectsAnim { speed: "fast" } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 12
            spacing: 10

            Rectangle {
                Layout.preferredWidth: pill.height - 10
                Layout.preferredHeight: pill.height - 10
                radius: height / 2
                color: Colors.primary

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: root.profile.icon
                    iconSize: Math.min(20, parent.height * 0.5)
                    customColor: Colors.primaryText
                }
            }

            ColumnLayout {
                visible: pill.width >= 120
                Layout.fillWidth: true
                spacing: 0
                CustomText {
                    Layout.fillWidth: true
                    content: root.profile.name
                    size: 13
                    weight: 600
                }
                CustomText {
                    Layout.fillWidth: true
                    visible: pill.height >= 46
                    content: "Power mode"
                    size: 11
                    weight: 400
                    customColor: Colors.outline
                }
            }

            MaterialIconSymbol {
                visible: pill.width >= 160
                content: "chevron_right"
                iconSize: 20
                customColor: Colors.surfaceVariantText
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const space = root.coordSpace ?? root
                root.openPanel("modes", root.mapToItem(space, 0, 0), pill.mapToItem(space, 0, 0),
                               Qt.size(pill.width, pill.height), pill.radius)
            }
        }
    }
}
