import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property bool isCustomCard: true
    property int topRadius: 0
    property int bottomRadius: 0
    property bool autoRadius: false
    property color color: "transparent"

    default property alias content: _layout.data

    Layout.fillWidth: true
    implicitHeight: _layout.implicitHeight + 12

    ColumnLayout {
        id: _layout
        anchors.fill: parent
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        spacing: 12
    }
}
