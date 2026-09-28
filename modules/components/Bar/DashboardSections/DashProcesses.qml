import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services

DashItem {
    id: root

    readonly property int fits: Math.max(1, Math.floor((root.height + 3) / 46))

    Component.onCompleted: ServiceDashData.retainProcesses()
    Component.onDestruction: ServiceDashData.releaseProcesses()

    readonly property bool byMem: root.opt("sort") === "mem"
    readonly property int want: Math.max(1, Number(root.opt("count") ?? 5))
    readonly property var rows: ServiceDashData.processes.slice()
        .sort((a, b) => root.byMem ? b.mem - a.mem : b.cpu - a.cpu)
        .slice(0, root.want)
    readonly property real peak: Math.max(1, root.rows.length ? (root.byMem ? root.rows[0].mem : root.rows[0].cpu) : 1)

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
                model: root.rows.slice(0, root.fits)

                delegate: CustomCard {
                    id: pcard
                    color: root.rowColor
                    required property var modelData
                    required property int index
                    readonly property real v: root.byMem ? pcard.modelData.mem : pcard.modelData.cpu

                    autoRadius: false
                    topRadius: pcard.index === 0 ? 20 : 5
                    bottomRadius: pcard.index === Math.min(root.fits, root.rows.length) - 1 ? 20 : 5
                    implicitHeight: prow.implicitHeight + 22

                    RowLayout {
                        id: prow
                        Layout.fillWidth: true
                        Layout.topMargin: -3
                        Layout.bottomMargin: -3
                        spacing: 10

                        CustomText {
                            Layout.fillWidth: true
                            content: pcard.modelData.name
                            size: 13
                            elide: Text.ElideRight
                        }

                        MeterSplitTrack {
                            visible: root.width >= 220
                            Layout.preferredWidth: Math.min(110, root.width * 0.3)
                            Layout.preferredHeight: 6
                            gap: 3
                            stopDot: false
                            value: Math.min(1, pcard.v / root.peak)
                            color: root.byMem ? Colors.secondary : Colors.primary
                            trackColor: root.chipColor
                        }

                        CustomText {
                            Layout.preferredWidth: 46
                            horizontalAlignment: Text.AlignRight
                            content: pcard.v.toFixed(1) + "%"
                            size: 12
                            weight: 600
                            customColor: Colors.surfaceVariantText
                        }
                    }
                }
            }
        }
    }

    ScrollFade { flickable: flick; color: root.fadeColor }
}
