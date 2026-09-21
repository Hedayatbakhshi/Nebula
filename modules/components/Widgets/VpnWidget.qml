import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// VPN state, and a one-tap toggle.
//
// The whole tile is the button — a small target inside a 200px square would be
// the only interactive thing on it, which is worse than just making the card
// itself the control.
WidgetHost {
    id: root
    configKey: "vpn"
    tile: WidgetSizes.small
    defaultPos: Qt.point(620, 340)

    readonly property bool installed: root.preview ? true : ServiceVpn.installed
    readonly property bool connected: root.preview ? true : ServiceVpn.connected
    readonly property bool busy:      root.preview ? false : ServiceVpn.busy
    readonly property string country: root.preview ? "Netherlands" : ServiceVpn.country
    readonly property string city:    root.preview ? "Amsterdam"   : ServiceVpn.city
    readonly property string server:  root.preview ? "NL#42"       : ServiceVpn.serverId
    readonly property string ip:      root.preview ? "185.159.157.42" : ServiceVpn.ip
    readonly property string error:   root.preview ? "" : ServiceVpn.error
    readonly property string protocol: root.preview ? "wireguard" : ServiceVpn.protocol
    readonly property int load:       root.preview ? 42 : ServiceVpn.load

    readonly property bool hasLoad: root.connected && !root.busy && root.load >= 0
    readonly property color loadColor: root.load >= 90 ? Colors.error : Colors.primary

    readonly property string headline: {
        if (!root.installed) return "Not installed"
        if (root.busy) return root.connected ? "Disconnecting" : "Connecting"
        if (root.connected) return root.country.length > 0 ? root.country : "Connected"
        return "Not connected"
    }

    // city · server, with whichever half is actually known
    readonly property string detail: {
        if (!root.connected || root.busy) return ""
        const parts = []
        if (root.city.length > 0) parts.push(root.city)
        if (root.server.length > 0) parts.push(root.server)
        return parts.join(" · ")
    }

    function toggle() {
        if (root.preview || !root.installed || root.busy) return
        if (root.connected) ServiceVpn.disconnectVpn()
        else ServiceVpn.connectFastest()
    }

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: WidgetSizes.cardColor

        MouseArea {
            id: press
            anchors.fill: parent
            enabled: !root.preview && root.installed && !root.busy
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.toggle()
        }

        // Pressing the card dips it slightly — the only feedback available when
        // the whole tile is the control.
        scale: press.pressed ? 0.98 : 1.0
        Behavior on scale { EffectsAnim { property: "scale"; speed: "fast" } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                CustomText { content: "VPN"; size: 13; customColor: Colors.primary }

                Item { Layout.fillWidth: true }

                CustomText {
                    visible: root.connected && !root.busy && root.protocol.length > 0
                    content: root.protocol
                    size: 10
                    customColor: Colors.outline
                }

                Rectangle {
                    width: 7; height: 7; radius: 4
                    color: root.connected ? Colors.primary : Colors.outline
                    opacity: root.connected ? 1 : 0.5
                    Behavior on color { EffectsColorAnim {} }
                }
            }

            Item { Layout.fillHeight: true }

            // ── Shield ────────────────────────────────────────────────
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 62
                implicitHeight: 62

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: root.connected ? Qt.alpha(Colors.primary, 0.16) : Colors.surfaceContainerHigh
                    Behavior on color { EffectsColorAnim {} }
                }

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: root.connected ? "vpn_lock" : "vpn_key_off"
                    iconSize: 28
                    customColor: root.connected ? Colors.primary : Colors.outline
                    visible: !root.busy
                    Behavior on customColor { EffectsColorAnim {} }
                }

                CustomCircularLoader {
                    anchors.centerIn: parent
                    size: 44
                    trackWidth: 3
                    visible: root.busy
                    highlightColor: Colors.primary
                    trackColor: Colors.surfaceContainerHighest
                }
            }

            Item { Layout.fillHeight: true }

            // ── Where ─────────────────────────────────────────────────
            CustomText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                content: root.headline
                size: 15
                weight: 700
                customColor: root.connected ? Colors.surfaceText : Colors.outline
                elide: Text.ElideRight
            }

            CustomText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                visible: root.detail.length > 0
                content: root.detail
                size: 11
                customColor: Colors.outline
                elide: Text.ElideRight
            }

            CustomText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                visible: root.connected && !root.busy && root.ip.length > 0
                content: root.ip
                size: 11
                customColor: Colors.outline
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 6
                visible: root.hasLoad

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 3

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Colors.outlineVariant
                        opacity: 0.5
                    }

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.load / 100))
                        height: parent.height
                        radius: height / 2
                        color: root.loadColor

                        Behavior on width { SpatialAnim { speed: "slow" } }
                        Behavior on color { EffectsColorAnim {} }
                    }
                }

                CustomText {
                    content: root.load + "%"
                    size: 10
                    customColor: root.loadColor
                }
            }

            // Failures are the one thing worth spending two lines on: "not signed
            // in" is otherwise indistinguishable from "it just didn't work".
            CustomText {
                Layout.fillWidth: true
                Layout.topMargin: 2
                visible: !root.connected && !root.busy && root.error.length > 0
                content: root.error
                size: 10
                customColor: Colors.error
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 2
            }

            CustomText {
                Layout.fillWidth: true
                Layout.topMargin: 2
                visible: root.installed && root.connected === false && !root.busy && root.error.length === 0
                content: "Tap to connect"
                size: 10
                customColor: Colors.outline
                opacity: 0.7
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
