import QtQuick
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import "../../../MatrialShapes/" as MaterialShapes
import "../../../MatrialShapes/material-shapes.js" as MaterialShapeFn

DashItem {
    id: root

    card: true

    readonly property bool metric: ServiceWeather.useMetric
    readonly property bool ready: ServiceWeather.currentCondition !== null
    readonly property string mode: root.width >= 380 ? "wide" : root.width >= 220 && root.height >= 150 ? "medium" : "small"
    readonly property string summary: root.ready
        ? ServiceWeather.description + ", feels " + ServiceWeather.feelsLike
        : ServiceWeather.isLoading ? "Loading weather" : "No weather yet"
    readonly property var hours: ServiceWeather.todayHourly.slice(0, 6)
    readonly property var days: ServiceWeather.forecastDays.slice(0, 3)

    function icon(code) {
        return ServiceWeather.getWeatherIcon(code ?? "113").icon
    }

    function hour24(label) {
        const m = /(\d+)\s*(AM|PM)/i.exec(label ?? "")
        if (!m)
            return label
        let h = parseInt(m[1]) % 12
        if (m[2].toUpperCase() === "PM")
            h += 12
        return (h < 10 ? "0" + h : h) + ":00"
    }

    function num(v) {
        const n = parseInt(v)
        return isNaN(n) ? 0 : n
    }

    function hi(d) { return root.num(root.metric ? d.maxtempC : d.maxtempF) }
    function lo(d) { return root.num(root.metric ? d.mintempC : d.mintempF) }

    function dayCode(d) {
        const h = d ? d.hourly : null
        return h && h.length > 4 ? h[4].weatherCode : "113"
    }

    function dayLabel(d, i) {
        return i === 0 ? "Today" : Qt.formatDate(new Date(d.date + "T00:00:00"), "ddd")
    }

    readonly property string rainNote: {
        for (let i = 1; i < root.hours.length; i++) {
            if (root.num(root.hours[i].chanceofrain) >= 50)
                return "Rain from " + root.hour24(root.hours[i].time)
        }
        return root.ready ? "Humidity " + ServiceWeather.humidity + "%" : ""
    }

    readonly property real weekLo: root.days.reduce((m, d) => Math.min(m, root.lo(d)), 999)
    readonly property real weekHi: root.days.reduce((m, d) => Math.max(m, root.hi(d)), -999)

    component Temp: CustomText {
        content: ServiceWeather.temperature
        family: root.displayFont
        renderType: Text.QtRendering
        weight: 400
        customColor: Colors.tertiary
    }

    Item {
        visible: root.mode === "small"
        anchors.fill: parent
        anchors.margins: 12

        Temp {
            size: Math.min(36, parent.width * 0.34)
        }

        MaterialIconSymbol {
            anchors.right: parent.right
            content: root.icon(ServiceWeather.weatherCode)
            iconSize: 26
            customColor: Colors.tertiary
        }

        CustomText {
            anchors.bottom: parent.bottom
            width: parent.width
            content: root.summary
            size: 12
            weight: 500
            maximumLineCount: 2
            wrapMode: Text.WordWrap
            customColor: Colors.surfaceVariantText
        }
    }

    Item {
        visible: root.mode === "medium"
        anchors.fill: parent
        anchors.margins: 14

        Column {
            spacing: 2
            Temp { size: 40 }
            CustomText {
                content: root.summary
                size: 12
                weight: 500
                customColor: Colors.surfaceVariantText
            }
        }

        Item {
            anchors.right: parent.right
            width: 62
            height: 62

            MaterialShapes.ShapeCanvas {
                anchors.fill: parent
                roundedPolygon: MaterialShapeFn.getCookie12Sided()
                color: Colors.tertiaryContainer
            }

            MaterialIconSymbol {
                anchors.centerIn: parent
                content: root.icon(ServiceWeather.weatherCode)
                iconSize: 30
                customColor: Colors.tertiaryContainerText
            }
        }

        Row {
            id: hourRow
            anchors.bottom: parent.bottom
            width: parent.width
            spacing: 6
            readonly property int n: Math.max(1, Math.min(root.hours.length, Math.floor((width + 6) / 58)))
            readonly property real pillW: (width - (n - 1) * 6) / n
            readonly property real pillH: Math.min(86, parent.height - 70)
            visible: pillH >= 56

            Repeater {
                model: root.hours.slice(0, hourRow.n)

                delegate: Rectangle {
                    id: pill
                    required property var modelData
                    required property int index
                    width: hourRow.pillW
                    height: hourRow.pillH
                    radius: width / 2
                    color: pill.index === 0 ? Colors.primary : Colors.surfaceContainerHighest

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        CustomText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            content: pill.index === 0 ? "Now" : root.hour24(pill.modelData.time)
                            size: 11
                            weight: 500
                            customColor: pill.index === 0 ? Colors.primaryText : Colors.surfaceText
                        }
                        MaterialIconSymbol {
                            anchors.horizontalCenter: parent.horizontalCenter
                            content: root.icon(pill.modelData.weatherCode)
                            iconSize: 18
                            customColor: pill.index === 0 ? Colors.primaryText : Colors.surfaceText
                        }
                        CustomText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            content: root.metric ? pill.modelData.tempC : pill.modelData.tempF
                            size: 12
                            weight: 700
                            customColor: pill.index === 0 ? Colors.primaryText : Colors.surfaceText
                        }
                    }
                }
            }
        }
    }

    Item {
        visible: root.mode === "wide"
        anchors.fill: parent
        anchors.margins: 16

        Item {
            id: wideLeft
            width: Math.min(170, parent.width * 0.4)
            height: parent.height

            CustomText {
                content: root.ready ? ServiceWeather.cityName : ""
                width: parent.width
                size: 12
                weight: 500
                customColor: Colors.outline
            }

            Temp {
                anchors.verticalCenter: parent.verticalCenter
                size: Math.min(64, parent.height * 0.4)
            }

            Column {
                anchors.bottom: parent.bottom
                width: parent.width
                CustomText {
                    width: parent.width
                    content: root.summary
                    size: 13
                    weight: 500
                    customColor: Colors.surfaceVariantText
                }
                CustomText {
                    width: parent.width
                    visible: root.rainNote !== ""
                    content: root.rainNote
                    size: 13
                    weight: 500
                    customColor: Colors.surfaceVariantText
                }
            }
        }

        Column {
            anchors.left: wideLeft.right
            anchors.leftMargin: 18
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Repeater {
                model: root.days

                delegate: Row {
                    id: dayRow
                    required property var modelData
                    required property int index
                    width: parent.width
                    height: 22
                    spacing: 8
                    readonly property real barW: Math.max(20, dayRow.width - 44 - 22 - 30 - 30 - 32)
                    readonly property real range: Math.max(1, root.weekHi - root.weekLo)

                    CustomText {
                        width: 44
                        anchors.verticalCenter: parent.verticalCenter
                        content: root.dayLabel(dayRow.modelData, dayRow.index)
                        size: 13
                        weight: 500
                    }
                    MaterialIconSymbol {
                        width: 22
                        anchors.verticalCenter: parent.verticalCenter
                        content: root.icon(root.dayCode(dayRow.modelData))
                        iconSize: 18
                        customColor: Colors.tertiary
                    }
                    CustomText {
                        width: 30
                        anchors.verticalCenter: parent.verticalCenter
                        content: root.lo(dayRow.modelData) + "°"
                        size: 12
                        weight: 500
                        customColor: Colors.outline
                    }
                    Rectangle {
                        width: dayRow.barW
                        height: 6
                        radius: 3
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colors.surfaceContainerHighest

                        Rectangle {
                            x: (root.lo(dayRow.modelData) - root.weekLo) / dayRow.range * parent.width
                            width: Math.max(6, (root.hi(dayRow.modelData) - root.lo(dayRow.modelData)) / dayRow.range * parent.width)
                            height: parent.height
                            radius: 3
                            color: Colors.tertiary
                        }
                    }
                    CustomText {
                        width: 30
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        content: root.hi(dayRow.modelData) + "°"
                        size: 12
                        weight: 700
                    }
                }
            }
        }
    }
}
