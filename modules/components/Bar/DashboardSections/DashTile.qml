import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents

Rectangle {
    id: tile

    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property bool on: false
    property bool compact: false
    signal activated

    Layout.fillWidth: true
    Layout.preferredHeight: tile.compact ? 54 : 62
    radius: 26
    property color baseColor: Colors.surfaceContainerHigh
    property color chipColor: Colors.surfaceContainerHighest
    color: tile.baseColor
    Behavior on opacity { EffectsAnim { speed: "fast" } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 7
        anchors.rightMargin: 10
        spacing: 8

        Rectangle {
            Layout.preferredHeight: tile.compact ? 36 : 42
            Layout.preferredWidth:  tile.compact ? 36 : 42
            radius: 14
            color: tile.on ? Colors.primary : tile.chipColor
            Behavior on color { EffectsColorAnim { speed: "fast" } }

            MaterialIconSymbol {
                anchors.centerIn: parent
                iconSize: tile.compact ? 19 : 22
                content: tile.icon
                customColor: tile.on ? Colors.primaryText : Colors.surfaceVariantText
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            CustomText {
                Layout.fillWidth: true
                content: tile.title
                size: 13
                weight: 700
                elide: Text.ElideRight
            }

            CustomText {
                Layout.fillWidth: true
                visible: tile.subtitle !== ""
                content: tile.subtitle
                size: 11
                customColor: Colors.outline
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.activated()
    }
}
