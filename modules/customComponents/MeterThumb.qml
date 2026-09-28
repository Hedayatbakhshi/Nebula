import QtQuick
import qs.modules.utils
import qs.modules.settings

Item {
    id: root

    property real value: 0
    property string text: ""
    property real trackHeight: root.height * 0.52
    property real textSize: root.height * 0.5
    property string family: SettingsConfig.general?.displayFont || "Titan One"
    property color color: Colors.primary
    property color fillColor: Colors.primaryContainer
    property color trackColor: Colors.surfaceContainerHighest
    property color inkColor: Colors.primaryText
    property color ringColor: "transparent"

    property real shown: Math.max(0, Math.min(1, root.value))

    Behavior on shown { SpatialAnim {} }

    readonly property real thumbW: Math.max(root.height * 1.5, label.implicitWidth + root.height * 0.7)
    readonly property real thumbX: Math.max(0, Math.min(root.width - root.thumbW, root.width * root.shown - root.thumbW / 2))

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackHeight
        radius: height / 2
        color: root.trackColor
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: root.thumbX + root.thumbW / 2
        height: root.trackHeight
        radius: height / 2
        color: root.fillColor
    }

    Rectangle {
        x: root.thumbX
        width: root.thumbW
        height: root.height
        radius: height / 2
        color: root.color
        border.width: root.ringColor.a > 0 ? Math.max(2, root.height * 0.1) : 0
        border.color: root.ringColor

        CustomText {
            id: label
            anchors.centerIn: parent
            content: root.text
            family: root.family
            renderType: Text.QtRendering
            font.features: { "tnum": 1 }
            size: root.textSize
            weight: 400
            customColor: root.inkColor
        }
    }
}
