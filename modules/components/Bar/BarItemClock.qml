import QtQuick
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root

    property Item host: null
    property string itemId: ""
    readonly property bool shown: true

    readonly property string style: BarLayout.opt(root.itemId, "style") ?? "display"
    readonly property bool use24: BarLayout.opt(root.itemId, "use24") === true
    readonly property bool showDate: BarLayout.opt(root.itemId, "showDate") !== false

    readonly property string hh: {
        const h = parseInt(ServiceClock.hour)
        if (root.use24)
            return String(h).padStart(2, "0")
        const m = h % 12
        return String(m === 0 ? 12 : m)
    }
    readonly property string timeText: root.hh + ":" + ServiceClock.minute
    readonly property string secondsText: root.timeText + ":" + ServiceClock.seconds
    readonly property string dowText: String(ServiceClock.day).slice(0, 3)
    readonly property string dayMonText: parseInt(ServiceClock.date) + " " + String(ServiceClock.month).slice(0, 3)
    readonly property string dateText: root.dowText + " " + root.dayMonText
    readonly property string jpTime: ServiceJp.count(parseInt(root.hh)) + "時"
        + ServiceJp.count(parseInt(ServiceClock.minute)) + "分"
    readonly property string jpDate: ServiceJp.monthDay + "（" + String(ServiceJp.weekday).charAt(0) + "）"

    implicitWidth: face.item ? face.item.implicitWidth : 0
    implicitHeight: Appearance.size.clockHeight

    Loader {
        id: face
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: {
            switch (root.style) {
            case "plain":    return inlineComp
            case "led":      return ledComp
            case "stacked":  return columnComp
            case "pill":     return splitComp
            case "pilldate": return pillDateComp
            case "seconds":  return tickerComp
            case "jp":       return jpComp
            }
            return displayComp
        }
    }

    Component {
        id: displayComp
        Item {
            implicitWidth: clockText.implicitWidth
            implicitHeight: Appearance.size.clockHeight
            CustomClock {
                id: clockText
                use24: root.use24
            }
        }
    }

    Component {
        id: inlineComp
        Row {
            spacing: 8

            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                content: root.timeText
                size: 15
                weight: 800
                elide: Text.ElideNone
                font.features: { "tnum": 1 }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showDate
                width: 3
                height: 3
                radius: 1.5
                color: Colors.outline
            }
            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showDate
                content: root.dateText
                size: 12
                weight: 500
                customColor: Colors.outline
                elide: Text.ElideNone
            }
        }
    }

    Component {
        id: ledComp
        Row {
            spacing: 9

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showDate
                width: dowChip.implicitWidth + 12
                height: dowChip.implicitHeight + 4
                radius: 5
                color: Colors.primary

                CustomText {
                    id: dowChip
                    anchors.centerIn: parent
                    content: root.dowText.toUpperCase()
                    size: 10
                    weight: 600
                    customColor: Colors.primaryText
                    font.letterSpacing: 1.4
                    elide: Text.ElideNone
                }
            }
            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                content: root.timeText
                size: 15
                weight: 800
                elide: Text.ElideNone
                font.features: { "tnum": 1 }
            }
            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showDate
                content: root.dayMonText
                size: 12
                weight: 500
                customColor: Colors.outline
                elide: Text.ElideNone
            }
        }
    }

    Component {
        id: columnComp
        Row {
            spacing: 10

            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                content: root.timeText
                size: 18
                weight: 800
                elide: Text.ElideNone
                font.features: { "tnum": 1 }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showDate
                spacing: 1

                CustomText {
                    content: root.dowText.toUpperCase()
                    size: 9
                    weight: 600
                    customColor: Colors.primary
                    font.letterSpacing: 1.4
                    elide: Text.ElideNone
                }
                CustomText {
                    content: root.dayMonText.toUpperCase()
                    size: 9
                    weight: 500
                    customColor: Colors.outline
                    font.letterSpacing: 0.9
                    elide: Text.ElideNone
                }
            }
        }
    }

    Component {
        id: splitComp
        Rectangle {
            implicitWidth: splitRow.implicitWidth + (root.showDate ? 16 : 8)
            implicitHeight: 30
            radius: height / 2
            color: root.showDate ? Colors.surfaceContainerHigh : "transparent"

            Row {
                id: splitRow
                anchors.verticalCenter: parent.verticalCenter
                x: root.showDate ? 12 : 4
                spacing: 8

                CustomText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.showDate
                    content: root.dayMonText.toUpperCase()
                    size: 10
                    weight: 600
                    customColor: Colors.outline
                    font.letterSpacing: 1.2
                    elide: Text.ElideNone
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: splitTime.implicitWidth + 22
                    height: 24
                    radius: height / 2
                    color: Colors.primaryContainer

                    CustomText {
                        id: splitTime
                        anchors.centerIn: parent
                        content: root.timeText
                        size: 13
                        weight: 800
                        customColor: Colors.primaryContainerText
                        elide: Text.ElideNone
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }
    }

    Component {
        id: pillDateComp
        Row {
            spacing: 9

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: pdTime.implicitWidth + 26
                height: 26
                radius: height / 2
                color: Colors.primaryContainer

                CustomText {
                    id: pdTime
                    anchors.centerIn: parent
                    content: root.timeText
                    size: 13
                    weight: 800
                    customColor: Colors.primaryContainerText
                    elide: Text.ElideNone
                    font.features: { "tnum": 1 }
                }
            }
            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showDate
                content: root.dateText
                size: 11
                weight: 500
                customColor: Colors.outline
                elide: Text.ElideNone
            }
        }
    }

    Component {
        id: tickerComp
        Row {
            spacing: 9

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                CustomText {
                    anchors.verticalCenter: parent.verticalCenter
                    content: root.timeText
                    size: 16
                    weight: 800
                    elide: Text.ElideNone
                    font.features: { "tnum": 1 }
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: secsText.implicitWidth + 9
                    height: secsText.implicitHeight + 3
                    radius: 4
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.alpha(Colors.primary, 0.4)

                    CustomText {
                        id: secsText
                        anchors.centerIn: parent
                        content: ServiceClock.seconds
                        size: 10
                        weight: 600
                        customColor: Colors.primary
                        elide: Text.ElideNone
                        font.features: { "tnum": 1 }
                    }
                }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showDate
                width: 1
                height: 16
                color: Colors.surfaceContainerHigh
            }
            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showDate
                content: root.dateText
                size: 11
                weight: 500
                customColor: Colors.outline
                elide: Text.ElideNone
            }
        }
    }

    Component {
        id: jpComp
        Row {
            spacing: 10

            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                content: root.jpTime
                family: ServiceJp.serif
                size: 15
                weight: 600
                font.letterSpacing: 0.6
                elide: Text.ElideNone
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showDate
                width: 1
                height: 18
                color: Colors.surfaceContainerHigh
            }
            CustomText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showDate
                content: root.jpDate
                family: ServiceJp.serif
                size: 11
                weight: 400
                customColor: Colors.outline
                font.letterSpacing: 0.6
                elide: Text.ElideNone
            }
        }
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered && root.host)
                root.host.hoverOpen("calendar", root)
        }
    }
}
