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
    id: controleRectangle
    property bool compact: false

    function shows(key) {
        return DashLayout.opt("controls", key) !== false
    }

    readonly property bool showBrightness: controleRectangle.shows("brightness")
    readonly property bool showVolume: controleRectangle.shows("volume")
    readonly property bool showNetwork: controleRectangle.shows("network")
    readonly property bool showBluetooth: controleRectangle.shows("bluetooth")
    readonly property bool showGameMode: controleRectangle.shows("gameMode")
    readonly property bool showPower: controleRectangle.shows("power")
    readonly property bool showRecording: controleRectangle.shows("recording")
    readonly property int tileColumnSetting: DashLayout.opt("controls", "tileColumns") ?? 0
    readonly property int tileColumns: controleRectangle.tileColumnSetting > 0
        ? controleRectangle.tileColumnSetting
        : (controleRectangle.width >= 360 ? 2 : 1)
    property Item coordSpace: null
    property string panelMode: ""
    signal openPanel(string mode, var parentPos, var pos, var srcSize, real srcRadius)
    signal toggleDashboard()
    property int modeRowPressed: -1

    implicitHeight: colu.implicitHeight
    color: "transparent"
    radius: 20

    Behavior on implicitHeight { SpatialAnim { speed: "default" } }

    ColumnLayout{
        id: colu
        anchors.fill: parent
        anchors.margins: 0
        spacing: controleRectangle.compact ? 7 : 9

        RowLayout{
            Layout.fillWidth: true
            visible: controleRectangle.showBrightness || controleRectangle.showVolume
            spacing: controleRectangle.compact ? 6 : 8

            M3Slider {
                property var brightnessMonitor: ServiceBrightness.getMonitorForScreen(screen)
                visible: controleRectangle.showBrightness
                Layout.fillWidth: true
                Layout.preferredHeight: controleRectangle.compact ? 42 : 48
                icon: "brightness_7"
                iconAtEnd: true
                showStopIndicator: false
                trackOuterCorner: 14
                showValueLabel: true
                trackHeight: Math.min(40, height - 8)
                handleHeight: height
                handleWidth: 6
                pressedHandleWidth: 4
                handleGap: 4
                progress: ServiceBrightness.getMonitorForScreen(screen).brightness
                onMoved: brightnessMonitor.setBrightness(progress)
            }

            M3Slider {
                visible: controleRectangle.showVolume
                Layout.fillWidth: true
                Layout.preferredHeight: controleRectangle.compact ? 42 : 48
                icon: ServicePipewire.muted ? "volume_off" : "volume_up"
                iconAtEnd: true
                showStopIndicator: false
                trackOuterCorner: 14
                showValueLabel: true
                trackHeight: Math.min(40, height - 8)
                handleHeight: height
                handleWidth: 6
                pressedHandleWidth: 4
                handleGap: 4
                progress: ServicePipewire.volume
                onMoved: ServicePipewire.setVolume(progress)
            }
        }

        GridLayout{
            Layout.fillWidth: true
            visible: controleRectangle.showNetwork || controleRectangle.showBluetooth
            columns: controleRectangle.tileColumns
            columnSpacing: controleRectangle.compact ? 6 : 8
            rowSpacing: controleRectangle.compact ? 6 : 8

            DashTile{
                id: wifi
                compact: controleRectangle.compact
                visible: controleRectangle.showNetwork
                title: ServiceNetwork.connectionType === "ethernet" ? "Ethernet" : "Wi-Fi"
                subtitle: ServiceNetwork.connectionType === "ethernet" ? "Wired"
                    : ServiceNetwork.currentSSID || (ServiceNetwork.wifiEnabled ? "Not connected" : "Off")
                icon: ServiceNetwork.icon
                on: ServiceNetwork.wifiEnabled
                opacity: controleRectangle.panelMode === "wifi" ? 0 : 1
                onActivated: {
                    const space = controleRectangle.coordSpace ?? controleRectangle
                    controleRectangle.openPanel("wifi",
                        controleRectangle.mapToItem(space, 0, 0),
                        wifi.mapToItem(space, 0, 0),
                        Qt.size(wifi.width, wifi.height),
                        wifi.radius)
                }
            }

            DashTile{
                id: bluetooth
                compact: controleRectangle.compact
                visible: controleRectangle.showBluetooth
                title: "Bluetooth"
                subtitle: ServiceBluetooth.connectedDevices === 0 ? "No devices"
                    : ServiceBluetooth.connectedDevices === 1 ? "1 device"
                    : ServiceBluetooth.connectedDevices + " devices"
                icon: ServiceBluetooth.connectedDevices > 0 ? "bluetooth" : "bluetooth_disabled"
                on: ServiceBluetooth.connectedDevices > 0
                opacity: controleRectangle.panelMode === "bluetooth" ? 0 : 1
                onActivated: {
                    const space = controleRectangle.coordSpace ?? controleRectangle
                    controleRectangle.openPanel("bluetooth",
                        controleRectangle.mapToItem(space, 0, 0),
                        bluetooth.mapToItem(space, 0, 0),
                        Qt.size(bluetooth.width, bluetooth.height),
                        bluetooth.radius)
                }
            }
        }

        RowLayout{
            Layout.fillWidth: true
            visible: controleRectangle.showGameMode || controleRectangle.showPower || controleRectangle.showRecording
            spacing: controleRectangle.compact ? 6 : 8

            component SideButton: Rectangle {
                id: side
                property string icon: ""
                property bool on: false
                signal activated

                property int slot: 0
                readonly property real baseW: controleRectangle.compact ? 60 : 72
                readonly property bool isPressed: controleRectangle.modeRowPressed === side.slot

                Layout.preferredHeight: controleRectangle.compact ? 46 : 54
                Layout.preferredWidth: {
                    if (controleRectangle.modeRowPressed < 0) return side.baseW
                    return side.isPressed ? side.baseW * 1.26 : side.baseW * 0.86
                }
                Behavior on Layout.preferredWidth { SpatialAnim { speed: "fast" } }
                radius: side.isPressed ? side.height * 0.22
                      : side.on ? side.height * 0.32
                      : side.height / 2
                Behavior on radius { SpatialAnim { speed: "fast" } }
                color: side.on ? Colors.primary
                     : sideArea.containsMouse ? Colors.surfaceContainerHighest
                     : Colors.surfaceContainerHigh
                Behavior on color { EffectsColorAnim { speed: "fast" } }

                MaterialIconSymbol{
                    anchors.centerIn: parent
                    iconSize: 23
                    content: side.icon
                    customColor: side.on ? Colors.primaryText : Colors.surfaceText
                    fill: side.on ? 1 : 0
                    Behavior on fill { EffectsAnim { speed: "fast" } }
                    scale: sideArea.pressed ? 0.86 : 1
                    Behavior on scale { SpatialAnim { speed: "fast" } }
                }

                MouseArea{
                    id: sideArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: controleRectangle.modeRowPressed = side.slot
                    onReleased: controleRectangle.modeRowPressed = -1
                    onCanceled: controleRectangle.modeRowPressed = -1
                    onClicked: side.activated()
                }
            }

            SideButton{
                slot: 0
                visible: controleRectangle.showGameMode
                icon: "sports_esports"
                on: ServiceGameMode.active
                onActivated: ServiceGameMode.toggle()
            }

            Rectangle{
                id: modes
                readonly property bool isPressed: controleRectangle.modeRowPressed === 1

                visible: controleRectangle.showPower
                Layout.fillWidth: true
                Layout.preferredHeight: controleRectangle.compact ? 46 : 54
                radius: modes.isPressed ? modes.height * 0.22 : modes.height / 2
                Behavior on radius { SpatialAnim { speed: "fast" } }
                color: modeArea.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
                Behavior on color { EffectsColorAnim { speed: "fast" } }
                opacity: controleRectangle.panelMode === "modes" ? 0 : 1
                Behavior on opacity { EffectsAnim { speed: "fast" } }

                readonly property var profile: ServiceUPower.powerProfiles[ServiceUPower.powerProfile]
                    ?? ServiceUPower.powerProfiles[0]

                RowLayout{
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    anchors.rightMargin: 14
                    spacing: 10

                    Rectangle{
                        Layout.preferredHeight: controleRectangle.compact ? 38 : 44
                        Layout.preferredWidth:  controleRectangle.compact ? 38 : 44
                        radius: height / 2
                        color: Colors.primary

                        MaterialIconSymbol{
                            anchors.centerIn: parent
                            iconSize: controleRectangle.compact ? 18 : 20
                            content: modes.profile.icon
                            customColor: Colors.primaryText
                        }
                    }

                    CustomText{
                        Layout.fillWidth: true
                        content: modes.profile.name
                        size: 13
                        weight: 600
                        elide: Text.ElideRight
                    }
                }

                MouseArea{
                    id: modeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: controleRectangle.modeRowPressed = 1
                    onReleased: controleRectangle.modeRowPressed = -1
                    onCanceled: controleRectangle.modeRowPressed = -1
                    onClicked: {
                        const space = controleRectangle.coordSpace ?? controleRectangle
                        controleRectangle.openPanel("modes",
                            controleRectangle.mapToItem(space, 0, 0),
                            modes.mapToItem(space, 0, 0),
                            Qt.size(modes.width, modes.height),
                            modes.height / 2)
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                visible: !controleRectangle.showPower
            }

            SideButton{
                slot: 2
                visible: controleRectangle.showRecording
                icon: ServiceTools.isRecording ? "stop_circle" : "screen_record"
                on: ServiceTools.isRecording
                onActivated: {
                    GlobalStates.toolsWidgetOpen = true
                    controleRectangle.toggleDashboard()
                }
            }
        }
    }
}
