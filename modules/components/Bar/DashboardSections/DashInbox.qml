import QtQuick
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services

DashItem {
    id: root

    readonly property bool counter: root.outerW < 200
    readonly property var list: ServiceNotification.allNotifications.slice().reverse()
    readonly property var apps: {
        const seen = []
        for (const n of root.list) {
            if (seen.every(s => s.appName !== n.appName))
                seen.push(n)
        }
        return seen
    }
    property real now: Date.now()

    card: root.counter

    Timer {
        interval: 30000
        running: root.visible && !root.counter
        repeat: true
        onTriggered: root.now = Date.now()
    }

    function ago(ts) {
        const mins = Math.floor((root.now - (ts ?? root.now)) / 60000)
        if (mins < 1) return "now"
        if (mins < 60) return mins + " min"
        const hrs = Math.floor(mins / 60)
        return hrs < 24 ? hrs + " h" : Math.floor(hrs / 24) + " d"
    }

    function symbolFor(n) {
        const ic = (n?.appIcon || "").toLowerCase()
        const ap = (n?.appName || "").toLowerCase()
        if (ic.includes("camera-photo") || ap.includes("screenshot")) return "photo_camera"
        if (ic.includes("camera-video") || ap.includes("record")) return "screen_record"
        if (ic.includes("error")) return "error_outline"
        if (ic.includes("bluetooth")) return "bluetooth"
        if (ic.includes("network") || ic.includes("wifi")) return "wifi"
        if (ic.includes("battery")) return "battery_std"
        if (ic.includes("volume") || ic.includes("audio")) return "volume_up"
        return ""
    }

    function open(n) {
        const act = (n?.notification?.actions ?? []).find(a => a.identifier === "default") ?? null
        if (act)
            act.invoke()
        ServiceNotification.removeNotification(n)
    }

    component AppIcon: Rectangle {
        id: chip
        property var notif: null
        property real side: 34
        readonly property string symbol: root.symbolFor(chip.notif)
        width: chip.side
        height: chip.side
        radius: chip.side * 0.35
        color: root.chipColor

        MaterialIconSymbol {
            anchors.centerIn: parent
            visible: chip.symbol !== "" || img.status !== Image.Ready
            content: chip.symbol !== "" ? chip.symbol : "notifications"
            iconSize: Math.round(chip.side * 0.55)
            customColor: Colors.primary
        }

        Image {
            id: img
            anchors.fill: parent
            anchors.margins: chip.side * 0.18
            visible: chip.symbol === "" && status === Image.Ready
            source: chip.symbol !== "" ? "" : IconUtil.getIconPath(chip.notif?.appIcon ?? "")
            sourceSize.width: 64
            sourceSize.height: 64
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
    }

    Item {
        visible: root.counter
        anchors.fill: parent
        anchors.margins: 12

        Row {
            spacing: 6
            MaterialIconSymbol {
                anchors.verticalCenter: parent.verticalCenter
                content: ServiceNotification.muted ? "notifications_off" : "notifications"
                iconSize: 16
                customColor: Colors.primary
            }
            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                content: "Notifications"
                size: 12
                weight: 500
                customColor: Colors.surfaceVariantText
            }
        }

        CustomText {
            anchors.verticalCenter: parent.verticalCenter
            content: root.list.length
            family: root.displayFont
            renderType: Text.QtRendering
            size: Math.min(40, parent.height * 0.4)
            weight: 400
            customColor: Colors.primary
        }

        Row {
            anchors.bottom: parent.bottom
            spacing: 4
            Repeater {
                model: root.apps.slice(0, Math.max(1, Math.floor((root.width - 24 + 4) / 28)))
                delegate: AppIcon {
                    required property var modelData
                    notif: modelData
                    side: 24
                }
            }
        }
    }

    Flickable {
        id: flick
        visible: !root.counter
        anchors.fill: parent
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
            id: col
            width: flick.width
            spacing: 3

            Repeater {
                model: root.list

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool first: row.index === 0
                    readonly property bool last: row.index === root.list.length - 1
                    width: col.width
                    height: body.implicitHeight + 18
                    topLeftRadius: row.first ? 20 : 5
                    topRightRadius: row.first ? 20 : 5
                    bottomLeftRadius: row.last ? 20 : 5
                    bottomRightRadius: row.last ? 20 : 5
                    color: rowArea.containsMouse ? root.chipColor : root.rowColor

                    AppIcon {
                        id: rowIcon
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        notif: row.modelData
                    }

                    Column {
                        id: body
                        anchors.left: rowIcon.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter

                        Item {
                            width: parent.width
                            height: 14
                            CustomText {
                                width: parent.width - when.width - 8
                                content: row.modelData.appName ?? ""
                                size: 11
                                weight: 500
                                customColor: Colors.outline
                            }
                            CustomText {
                                id: when
                                anchors.right: parent.right
                                content: root.ago(row.modelData.arrivalTimestamp)
                                size: 11
                                weight: 500
                                customColor: Colors.outline
                            }
                        }
                        CustomText {
                            width: parent.width
                            content: row.modelData.summary ?? ""
                            size: 13
                            weight: 700
                        }
                        CustomText {
                            width: parent.width
                            visible: (row.modelData.body ?? "") !== ""
                            content: (row.modelData.body ?? "").replace(/<[^>]*>/g, "").replace(/\n/g, " ")
                            textFormat: Text.PlainText
                            size: 12
                            weight: 500
                            customColor: Colors.surfaceVariantText
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.open(row.modelData)
                    }
                }
            }

            Rectangle {
                visible: root.list.length === 0
                width: col.width
                height: Math.max(56, flick.height)
                radius: 20
                color: root.rowColor

                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    MaterialIconSymbol {
                        anchors.horizontalCenter: parent.horizontalCenter
                        content: "notifications_none"
                        iconSize: 24
                        customColor: Colors.outline
                    }
                    CustomText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        content: "All caught up"
                        size: 12
                        weight: 600
                        customColor: Colors.outline
                    }
                }
            }
        }
    }

    ScrollFade { flickable: flick; color: root.fadeColor; visible: !root.counter }
}
