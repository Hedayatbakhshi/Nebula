import QtQuick
import qs.modules.utils
import qs.modules.settings

Item {
    id: root

    property real value: 0
    property string text: ""
    property string detail: ""
    property string trailing: ""
    property real textSize: root.height * 0.45
    property string family: SettingsConfig.general?.displayFont || "Titan One"
    property color color: Colors.primary
    property color inkColor: Colors.primaryText
    property color trackColor: Colors.surfaceContainerHighest
    property color trailingColor: Colors.surfaceVariantText

    property real shown: Math.max(0, Math.min(1, root.value))

    Behavior on shown { SpatialAnim {} }

    readonly property real pad: root.height * 0.42
    readonly property real fillW: Math.min(root.width, Math.max(root.height, valueLabel.implicitWidth + root.pad * 2, root.width * root.shown))

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.trackColor
    }

    CustomText {
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        anchors.verticalCenter: parent.verticalCenter
        visible: root.trailing !== "" && root.width - root.fillW > implicitWidth + root.pad * 2
        content: root.trailing
        size: root.textSize * 0.72
        weight: 500
        customColor: root.trailingColor
    }

    Rectangle {
        width: root.fillW
        height: root.height
        radius: height / 2
        color: root.color
        clip: true

        Row {
            anchors.left: parent.left
            anchors.leftMargin: root.pad
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.pad * 0.5

            CustomText {
                id: valueLabel
                anchors.verticalCenter: parent.verticalCenter
                content: root.text
                family: root.family
                renderType: Text.QtRendering
                font.features: { "tnum": 1 }
                size: root.textSize
                weight: 400
                customColor: root.inkColor
            }
            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.detail !== ""
                content: root.detail
                size: root.textSize * 0.72
                weight: 500
                customColor: Qt.alpha(root.inkColor, 0.72)
            }
        }
    }
}
