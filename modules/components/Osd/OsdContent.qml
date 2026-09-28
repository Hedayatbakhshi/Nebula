import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Rectangle {
    id: osdRoot
    implicitHeight: parent.height
    implicitWidth: 300
    color: Settings.layoutColor
    radius: 20
    opacity: 0
    scale: 0.88

    NumberAnimation on opacity { from: 0; to: 1; duration: 220; running: true; easing.type: Easing.OutCubic }
    NumberAnimation on scale   { from: 0.88; to: 1; duration: 220; running: true; easing.type: Easing.OutCubic }

    property bool vertical: false
    readonly property string glyph: ServicePipewire.muted ? "volume_off"
        : ServicePipewire.volume > 0.6 ? "volume_up"
        : ServicePipewire.volume > 0.2 ? "volume_down"
        : "volume_mute"
    readonly property real level: ServicePipewire.muted ? 0 : Math.min(ServicePipewire.volume, 1)
    readonly property string label: ServicePipewire.muted ? (osdRoot.vertical ? "Mute" : "Muted")
        : Math.round(osdRoot.level * 100) + (osdRoot.vertical ? "" : "%")

    component Badge: Rectangle {
        implicitWidth: 36
        implicitHeight: 36
        radius: 10
        color: Colors.primaryContainer

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: osdRoot.glyph
            iconSize: 20
            customColor: Colors.primaryContainerText
        }
    }

    RowLayout {
        visible: !osdRoot.vertical
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Badge {}

        M3Slider {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            interactive: false
            progress: osdRoot.level
        }

        CustomText {
            content: osdRoot.label
            size: 12
            weight: 600
            customColor: Colors.outline
            Layout.preferredWidth: 38
        }
    }

    ColumnLayout {
        visible: osdRoot.vertical
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Badge { Layout.alignment: Qt.AlignHCenter }

        M3Slider {
            Layout.fillHeight: true
            Layout.preferredWidth: 6
            Layout.alignment: Qt.AlignHCenter
            vertical: true
            interactive: false
            progress: osdRoot.level
        }

        CustomText {
            Layout.alignment: Qt.AlignHCenter
            content: osdRoot.label
            size: 12
            weight: 600
            customColor: Colors.outline
        }
    }
}
