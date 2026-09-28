import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services

DashItem {
    id: root

    readonly property int fits: Math.max(1, Math.floor((root.height + 3) / 73))

    Component.onCompleted: ServiceEvents.retain()
    Component.onDestruction: ServiceEvents.release()

    readonly property int count: Math.max(1, Number(root.opt("count") ?? 3))
    readonly property bool holidays: root.opt("holidays") !== false
    readonly property var list: {
        ServiceEvents.events
        ServiceClock.holidayData
        return ServiceEvents.upcoming(root.count, root.holidays)
    }

    function whenOf(e) {
        const s = new Date(ServiceEvents.startMs(e))
        const n = ServiceEvents.now
        const today = new Date(n.getFullYear(), n.getMonth(), n.getDate())
        const days = Math.round((new Date(s.getFullYear(), s.getMonth(), s.getDate()) - today) / 86400000)
        const day = days <= 0 ? "Today" : days === 1 ? "Tomorrow" : days < 7 ? Qt.formatDate(s, "dddd") : Qt.formatDate(s, "d MMMM")
        return e.allDay ? day : day + ", " + Qt.formatTime(s, "hh:mm")
    }

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
                model: root.list.slice(0, root.fits)

                delegate: CustomCard {
                    id: ev
                    color: root.rowColor
                    required property var modelData
                    required property int index
                    readonly property date d: new Date(ServiceEvents.startMs(ev.modelData))

                    autoRadius: false
                    topRadius: ev.index === 0 ? 20 : 5
                    bottomRadius: ev.index === Math.min(root.fits, root.list.length) - 1 ? 20 : 5

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            implicitWidth: 42
                            implicitHeight: 42
                            radius: 12
                            color: ev.modelData.holiday ? Colors.tertiaryContainer : root.chipColor

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: -2
                                CustomText {
                                    Layout.alignment: Qt.AlignHCenter
                                    content: Qt.formatDate(ev.d, "MMM")
                                    size: 10
                                    customColor: ev.modelData.holiday ? Colors.tertiaryContainerText : Colors.primary
                                }
                                CustomText {
                                    Layout.alignment: Qt.AlignHCenter
                                    content: Qt.formatDate(ev.d, "d")
                                    size: 15
                                    weight: 700
                                    customColor: ev.modelData.holiday ? Colors.tertiaryContainerText : Colors.surfaceText
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            CustomText {
                                Layout.fillWidth: true
                                content: ev.modelData.title
                                size: 14
                                elide: Text.ElideRight
                            }
                            CustomText {
                                Layout.fillWidth: true
                                content: root.whenOf(ev.modelData)
                                size: 12
                                elide: Text.ElideRight
                                customColor: Colors.outline
                            }
                        }
                    }
                }
            }

            CustomCard {
                color: root.rowColor
                visible: root.list.length === 0
                CustomText {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    content: ServiceEvents.urls.length === 0
                        ? "Nothing coming up. Add a calendar in this item's options."
                        : "Nothing in the next 60 days."
                    size: 12
                    customColor: Colors.outline
                }
            }
        }
    }

    ScrollFade { flickable: flick; color: root.fadeColor }
}
