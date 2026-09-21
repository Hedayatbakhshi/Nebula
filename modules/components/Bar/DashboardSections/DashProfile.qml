import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.settings
import qs.modules.components.Bar

Rectangle{
    id: root
    property bool compact: false

    readonly property bool showAvatar: DashLayout.opt("profile", "showAvatar") !== false
    readonly property bool showUptime: DashLayout.opt("profile", "showUptime") !== false
    readonly property bool showSettings: DashLayout.opt("profile", "showSettings") !== false
    readonly property bool showReload: DashLayout.opt("profile", "showReload") !== false
    readonly property bool showPower: DashLayout.opt("profile", "showPower") !== false
    readonly property bool showClose: DashLayout.opt("profile", "showClose") !== false
    signal toggleDashboard()
    implicitHeight: root.compact ? 44 : 52
    color: "transparent"
    RowLayout{
        anchors.fill: parent
        anchors.leftMargin: 2
        anchors.rightMargin: 0
        spacing: 10

        ClippingWrapperRectangle{
            visible: root.showAvatar
            Layout.preferredWidth: root.compact ? 34 : 40
            Layout.preferredHeight: root.compact ? 34 : 40
            radius: height
            color: Colors.surfaceContainerHigh

            Image{
                anchors.fill: parent
                sourceSize.width: 80
                sourceSize.height: 80
                source: SettingsConfig.general.profile
            }
        }

        ColumnLayout{
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 0
            CustomText{
                Layout.fillWidth: true
                content: "St3el"
                size: 15
                weight: 700
                elide: Text.ElideRight
            }
            CustomText{
                Layout.fillWidth: true
                visible: root.showUptime
                content: root.showUptime ? "up " + ServiceSystemInfo.getUptime() : ""
                size: 11
                customColor: Colors.outline
                elide: Text.ElideRight
            }
        }

        // MaterialIconSymbol{
        //     content: "settings"
        //     iconSize: 20 
        //     MouseArea{
        //         cursorShape: Qt.PointingHandCursor
        //         anchors.fill: parent
        //         onClicked: {
        //             GlobalStates.settingsOpen = true
        //             root.toggleDashboard()
        //         }
        //     }
        // }
        M3IconButton {
            icon: "settings"
            visible: root.showSettings
            iconSize: 18
            Layout.preferredHeight: 34
            Layout.preferredWidth: 34
            radius: 17
            onClicked: {
                root.toggleDashboard()
                GlobalStates.settingsPage = 9
                GlobalStates.settingsOpen = true
            }
        }

        M3IconButton {
            icon: "refresh"
            visible: root.showReload
            iconSize: 18
            Layout.preferredHeight: 34
            Layout.preferredWidth: 34
            radius: 17
            onClicked: {
                root.toggleDashboard()
                Quickshell.reload(true)
            }
        }

        M3IconButton {
            icon: "power_settings_new"
            visible: root.showPower
            iconSize: 18
            Layout.preferredHeight: 34
            Layout.preferredWidth: 34
            radius: 17
            onClicked: {
                root.toggleDashboard()
                GlobalStates.shutdownWindow = true
            }
        }
        M3IconButton {
            icon: "close"
            visible: root.showClose
            iconSize: 18
            Layout.preferredHeight: 34
            Layout.preferredWidth: 34
            radius: 17

            onClicked: {
                root.toggleDashboard()
            }
        }
       
        // MaterialIconSymbol{
        //     content: "close"
        //     iconSize: 20
        //     MouseArea{
        //         cursorShape: Qt.PointingHandCursor
        //         anchors.fill: parent
        //         onClicked: root.toggleDashboard()
        //     }
        // }


    }
}

