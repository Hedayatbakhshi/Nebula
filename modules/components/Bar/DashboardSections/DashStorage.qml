import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services

DashItem {
    id: root

    readonly property int fits: Math.max(1, Math.floor((root.height + 3) / 101))

    Component.onCompleted: ServiceStorage.refreshDrives()

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: ServiceStorage.refreshDrives()
    }

    readonly property var drives: ServiceStorage.drives.filter(d => d.size > 1e9)

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        ColumnLayout {
            id: col
            width: flick.width
            spacing: 3

            Repeater {
                model: root.drives.slice(0, root.fits)

                delegate: CustomCard {
                    id: driveCard
                    color: root.rowColor
                    required property var modelData
                    required property int index

                    autoRadius: false
                    topRadius: driveCard.index === 0 ? 20 : 5
                    bottomRadius: driveCard.index === Math.min(root.fits, root.drives.length) - 1 ? 20 : 5

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            implicitWidth: 38
                            implicitHeight: 38
                            radius: 12
                            color: root.chipColor

                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: driveCard.modelData.target === "/" ? "hard_drive" : "sd_card"
                                iconSize: 19
                                customColor: Colors.primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            CustomText {
                                Layout.fillWidth: true
                                content: driveCard.modelData.target
                                size: 14
                                elide: Text.ElideRight
                            }
                            CustomText {
                                content: ServiceStorage.formatBytes(driveCard.modelData.used) + " of "
                                    + ServiceStorage.formatBytes(driveCard.modelData.size)
                                size: 12
                                customColor: Colors.outline
                            }
                        }
                    }

                    MeterLabelBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 20
                        value: driveCard.modelData.pct
                        text: Math.round(driveCard.modelData.pct * 100) + "%"
                        textSize: 11
                        trailing: ServiceStorage.formatBytes(driveCard.modelData.size - driveCard.modelData.used) + " free"
                        color: driveCard.modelData.pct > 0.9 ? Colors.error : Colors.primary
                        inkColor: driveCard.modelData.pct > 0.9 ? Colors.errorText : Colors.primaryText
                        trackColor: root.chipColor
                    }
                }
            }
        }
    }

    ScrollFade { flickable: flick; color: root.fadeColor }
}
