import QtQuick
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import "../../../MatrialShapes/" as MaterialShapes
import "../../../MatrialShapes/material-shapes.js" as MaterialShapeFn

DashItem {
    id: root

    readonly property string face: {
        const f = String(root.opt("face") ?? "auto")
        if (f !== "auto")
            return f
        if (root.outerW >= 340)
            return "card"
        return root.outerW >= 240 && root.outerH >= 120 ? "shapes" : "plain"
    }
    readonly property string digits: ServiceClock.hour + ServiceClock.minute
    readonly property string sunset: ServiceWeather.astronomy ? String(ServiceWeather.astronomy.sunset ?? "") : ""

    function sunsetText() {
        const m = /(\d+):(\d+)\s*(AM|PM)/i.exec(root.sunset)
        if (!m)
            return ""
        let h = parseInt(m[1]) % 12
        if (m[3].toUpperCase() === "PM")
            h += 12
        return "Sunset " + (h < 10 ? "0" + h : h) + ":" + m[2]
    }

    card: root.face === "card"

    Column {
        visible: root.face === "plain"
        anchors.verticalCenter: parent.verticalCenter
        x: root.pad
        width: root.width - root.pad * 2
        spacing: 4

        CustomText {
            width: parent.width
            content: ServiceClock.hour + ":" + ServiceClock.minute
            family: root.displayFont
            renderType: Text.QtRendering
            size: Math.max(20, Math.min(root.height * 0.42, parent.width / 2.9))
            weight: 400
            customColor: Colors.primary
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 16
        }

        CustomText {
            width: parent.width
            content: ServiceClock.day + " " + Number(ServiceClock.date)
            size: 13
            weight: 500
            customColor: Colors.surfaceVariantText
        }
    }

    Column {
        visible: root.face === "shapes"
        anchors.centerIn: parent
        spacing: 8

        Row {
            id: shapeRow
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property real cell: Math.max(28, Math.min(84, (root.width - 24) / 4.5, root.height - 44))
            spacing: 2

            Repeater {
                model: 4

                delegate: Row {
                    id: slot
                    required property int index
                    spacing: 2

                    CustomText {
                        visible: slot.index === 2
                        anchors.verticalCenter: parent.verticalCenter
                        content: ":"
                        family: root.displayFont
                        renderType: Text.QtRendering
                        size: shapeRow.cell * 0.5
                        weight: 400
                        customColor: Colors.primary
                    }

                    Item {
                        width: shapeRow.cell
                        height: shapeRow.cell

                        MaterialShapes.ShapeCanvas {
                            anchors.fill: parent
                            roundedPolygon: MaterialShapeFn.getCookie12Sided()
                            color: slot.index % 2 === 0 ? Colors.primary : Colors.primaryContainer
                        }

                        CustomText {
                            anchors.centerIn: parent
                            content: root.digits.charAt(slot.index)
                            family: root.displayFont
                            renderType: Text.QtRendering
                            size: shapeRow.cell * 0.6
                            weight: 400
                            customColor: slot.index % 2 === 0 ? Colors.primaryText : Colors.primaryContainerText
                        }
                    }
                }
            }
        }

        CustomText {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.width - 8
            horizontalAlignment: Text.AlignHCenter
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 9
            content: ServiceClock.day + ", " + Number(ServiceClock.date) + " " + ServiceClock.month
            size: 14
            weight: 500
            customColor: Colors.surfaceVariantText
        }
    }

    Row {
        visible: root.face === "card"
        anchors.verticalCenter: parent.verticalCenter
        x: root.pad
        spacing: 18

        CustomText {
            id: bigTime
            anchors.verticalCenter: parent.verticalCenter
            content: ServiceClock.hour + ":" + ServiceClock.minute
            family: root.displayFont
            renderType: Text.QtRendering
            size: Math.max(28, Math.min(root.height * 0.66, (root.width - root.pad * 2 - 150) / 2.8))
            weight: 400
            customColor: Colors.primary
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            CustomText {
                content: ServiceClock.day
                size: 17
                weight: 600
            }

            CustomText {
                content: Number(ServiceClock.date) + " " + ServiceClock.month
                size: 13
                weight: 500
                customColor: Colors.surfaceVariantText
            }

            Row {
                visible: root.sunsetText() !== "" && root.height >= 90
                spacing: 4

                MaterialIconSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    content: "wb_twilight"
                    iconSize: 15
                    customColor: Colors.outline
                }

                CustomText {
                    anchors.verticalCenter: parent.verticalCenter
                    content: root.sunsetText()
                    size: 12
                    weight: 500
                    customColor: Colors.outline
                }
            }
        }
    }
}
