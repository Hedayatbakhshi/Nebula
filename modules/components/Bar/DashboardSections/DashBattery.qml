import QtQuick
import Quickshell.Services.UPower
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services

DashItem {
    id: root

    card: true

    readonly property bool present: UPower.displayDevice.isLaptopBattery
    readonly property real level: ServiceUPower.powerLevel
    readonly property bool charging: ServiceUPower.isCharging
    readonly property color tint: root.level < 0.2 && !root.charging ? Colors.error : Colors.primary

    function span(seconds) {
        if (!seconds || seconds <= 0)
            return ""
        const h = Math.floor(seconds / 3600)
        const m = Math.floor((seconds % 3600) / 60)
        return h > 0 ? h + " h " + m + " min" : m + " min"
    }

    readonly property string note: {
        if (!root.present)
            return "No battery"
        if (root.charging) {
            const t = root.span(UPower.displayDevice.timeToFull)
            return t !== "" ? t + " to full" : "Charging"
        }
        const t = root.span(UPower.displayDevice.timeToEmpty)
        return t !== "" ? t + " left" : Math.round(root.level * 100) + "%"
    }

    readonly property string face: String(root.opt("face") ?? "liquid")
    readonly property real ring: Math.max(36, Math.min(96, root.height - 46, root.width - 30))

    Column {
        anchors.centerIn: parent
        spacing: 6

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.ring
            height: root.ring

            Loader {
                anchors.fill: parent
                active: root.bound
                sourceComponent: root.face === "cookie" ? cookieFace : root.face === "orbit" ? orbitFace
                               : root.face === "dial" ? dialFace : root.face === "segring" ? segFace : liquidFace

                Component {
                    id: liquidFace
                    MeterLiquid {
                        value: root.present ? root.level : 0
                        color: root.tint
                        backColor: Qt.alpha(root.tint, 0.45)
                        trackColor: Colors.surfaceContainerHighest
                    }
                }
                Component {
                    id: cookieFace
                    MeterCookie {
                        value: root.present ? root.level : 0
                        color: root.tint
                        faceColor: Colors.surfaceContainerHighest
                        trackColor: Colors.surfaceBright
                    }
                }
                Component {
                    id: orbitFace
                    MeterOrbit {
                        value: root.present ? root.level : 0
                        color: root.tint
                        coreColor: Colors.surfaceContainerHighest
                    }
                }
                Component {
                    id: dialFace
                    MeterTickDial {
                        ticks: 24
                        majorEvery: 6
                        value: root.present ? root.level : 0
                        color: root.tint
                    }
                }
                Component {
                    id: segFace
                    MeterSegmentRing {
                        segments: 10
                        value: root.present ? root.level : 0
                        color: root.tint
                        fillColor: Qt.tint(Colors.surfaceContainerHighest, Qt.alpha(root.tint, 0.6))
                    }
                }
            }

            CustomText {
                anchors.centerIn: parent
                visible: root.present
                content: Math.round(root.level * 100)
                family: root.displayFont
                renderType: Text.QtRendering
                size: root.ring * 0.3
                weight: 400
                customColor: root.face === "liquid" && root.level > 0.55 ? (root.tint === Colors.error ? Colors.errorText : Colors.primaryText) : Colors.surfaceText
            }

            MaterialIconSymbol {
                anchors.centerIn: parent
                visible: !root.present || root.charging && root.ring < 50
                content: root.present ? "bolt" : "power"
                iconSize: root.ring * 0.4
                customColor: Colors.outline
            }

            Rectangle {
                visible: root.present && root.charging && root.ring >= 50
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -2
                width: 20
                height: 20
                radius: 10
                color: Colors.primary
                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "bolt"
                    iconSize: 14
                    customColor: Colors.primaryText
                }
            }
        }

        CustomText {
            anchors.horizontalCenter: parent.horizontalCenter
            content: root.note
            size: 12
            weight: 500
            customColor: Colors.surfaceVariantText
        }
    }
}
