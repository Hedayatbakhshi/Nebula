import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.customComponents
import qs.modules.utils
import qs.modules.settings
import qs.modules.services

Item {
    id: root
    anchors.fill: parent
    signal closed

    implicitHeight: column.implicitHeight + 20

    opacity: 0
    property real _slideX: 400
    transform: Translate { x: root._slideX }

    NumberAnimation on opacity { from: 0; to: 1; duration: 300; easing.type: Easing.OutQuad;   running: true }
    NumberAnimation on _slideX { from: 400; to: 0; duration: 300; easing.type: Easing.OutCubic; running: true }

    readonly property string style: BarLayout.opt("weather", "panel") ?? "curve"
    readonly property bool fixedHeight: BarLayout.panelH("weather") >= 0
    readonly property real maxContentH: root.implicitHeight
        + (styleLoader.item && styleLoader.item.growRoom !== undefined ? styleLoader.item.growRoom : 0)

    readonly property bool metric: ServiceWeather.useMetric
    readonly property var cur: ServiceWeather.currentCondition
    readonly property var days: ServiceWeather.forecastDays ?? []
    readonly property var astro: ServiceWeather.astronomy

    property var now: new Date()

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    function pick(o, metricKey, imperialKey) {
        if (!o) return "--"
        return root.metric ? o[metricKey] : o[imperialKey]
    }

    function num(v) {
        const n = parseInt(v)
        return isNaN(n) ? 0 : n
    }

    function iconFor(code, night) {
        return IconUtil.getSystemIcon(ServiceWeather.getWeatherIcon(code, night).svg)
    }

    function dayName(dateStr, i) {
        if (i === 0) return "Today"
        if (i === 1) return "Tomorrow"
        return Qt.formatDate(new Date(dateStr + "T00:00:00"), "dddd")
    }

    function dayShort(dateStr, i) {
        if (i === 0) return "Today"
        return Qt.formatDate(new Date(dateStr + "T00:00:00"), "ddd")
    }

    function dayLetter(dateStr) {
        return Qt.formatDate(new Date(dateStr + "T00:00:00"), "ddd").charAt(0)
    }

    function dayCode(d) {
        const h = d ? d.hourly : null
        return h && h.length > 4 ? h[4].weatherCode : "113"
    }

    function dayRain(d) {
        let m = 0
        const h = d ? (d.hourly ?? []) : []
        for (let i = 0; i < h.length; i++)
            m = Math.max(m, parseInt(h[i].chanceofrain) || 0)
        return m
    }

    function dayHi(d) {
        return root.num(root.pick(d, "maxtempC", "maxtempF"))
    }

    function dayLo(d) {
        return root.num(root.pick(d, "mintempC", "mintempF"))
    }

    function minutesOf(s) {
        const m = /(\d+):(\d+)\s*(AM|PM)/i.exec(s ?? "")
        if (!m) return -1
        let h = parseInt(m[1]) % 12
        if (m[3].toUpperCase() === "PM") h += 12
        return h * 60 + parseInt(m[2])
    }

    function shortTime(s) {
        return (s ?? "--").replace(/^0/, "")
    }

    function hourLabel(h) {
        const hh = ((h % 24) + 24) % 24
        return (hh % 12 === 0 ? 12 : hh % 12) + (hh < 12 ? " AM" : " PM")
    }

    function uvLabel(v) {
        const n = parseInt(v)
        if (isNaN(n)) return ""
        if (n <= 2) return "Low"
        if (n <= 5) return "Moderate"
        if (n <= 7) return "High"
        if (n <= 10) return "Very high"
        return "Extreme"
    }

    function span(mins) {
        const h = Math.floor(mins / 60)
        const m = mins % 60
        if (h === 0) return m + " min"
        return m === 0 ? h + " h" : h + " h " + m + " min"
    }

    readonly property string updatedText: {
        root.now
        if (ServiceWeather.isLoading) return "Updating…"
        if (ServiceWeather.hasError && !root.cur) return "Offline"
        if (!ServiceWeather.lastUpdated) return "—"
        const mins = Math.floor((new Date() - ServiceWeather.lastUpdated) / 60000)
        if (mins < 1) return "Updated just now"
        if (mins < 60) return "Updated " + mins + "m ago"
        return "Updated " + Math.floor(mins / 60) + "h ago"
    }

    readonly property int nowMin: root.now.getHours() * 60 + root.now.getMinutes()
    readonly property int riseMin: root.minutesOf(root.astro ? root.astro.sunrise : "")
    readonly property int setMin: root.minutesOf(root.astro ? root.astro.sunset : "")
    readonly property bool sunKnown: root.riseMin >= 0 && root.setMin > root.riseMin
    readonly property bool night: root.sunKnown ? (root.nowMin < root.riseMin || root.nowMin >= root.setMin)
                                                : ServiceWeather.isNightTime()
    readonly property string sunriseText: root.shortTime(root.astro ? root.astro.sunrise : null)
    readonly property string sunsetText: root.shortTime(root.astro ? root.astro.sunset : null)

    readonly property real daylight: root.sunKnown
        ? Math.max(0, Math.min(1, (root.nowMin - root.riseMin) / (root.setMin - root.riseMin))) : 0

    readonly property real nightProgress: {
        if (!root.sunKnown) return 0
        const len = 1440 - root.setMin + root.riseMin
        const t = root.nowMin >= root.setMin ? root.nowMin - root.setMin : root.nowMin + 1440 - root.setMin
        return Math.max(0, Math.min(1, t / len))
    }

    readonly property string sunEventText: {
        if (!root.sunKnown) return ""
        if (!root.night) {
            const left = root.setMin - root.nowMin
            return left <= 180 ? "Sunset in " + root.span(left) : "Sunset at " + root.sunsetText
        }
        const left = root.nowMin < root.riseMin ? root.riseMin - root.nowMin : root.riseMin + 1440 - root.nowMin
        return left <= 180 ? "Sunrise in " + root.span(left) : "Sunrise at " + root.sunriseText
    }

    readonly property int curTemp: root.num(root.pick(root.cur, "temp_C", "temp_F"))
    readonly property int feels: root.num(root.pick(root.cur, "FeelsLikeC", "FeelsLikeF"))
    readonly property int todayHi: root.dayHi(root.days[0])
    readonly property int todayLo: root.dayLo(root.days[0])
    readonly property string curIcon: root.iconFor(ServiceWeather.weatherCode, root.night)
    readonly property string description: ServiceWeather.description.trim()

    readonly property var upcoming: {
        const out = []
        const cc = root.cur
        if (cc)
            out.push({ label: "Now", hour: root.now.getHours(), temp: root.curTemp, rain: root.num(cc.chanceofrain),
                       code: cc.weatherCode, night: root.night, abs: root.nowMin,
                       hum: root.num(cc.humidity), wind: root.num(cc.windspeedKmph), isNow: true })
        for (let d = 0; d < Math.min(3, root.days.length); d++) {
            const day = root.days[d]
            const a = day.astronomy ? day.astronomy[0] : null
            const rise = root.minutesOf(a ? a.sunrise : "")
            const set = root.minutesOf(a ? a.sunset : "")
            const hs = day.hourly ?? []
            for (let i = 0; i < hs.length; i++) {
                const h = hs[i]
                const hr = Math.floor(parseInt(h.time) / 100)
                const abs = d * 1440 + hr * 60
                if (abs <= root.nowMin)
                    continue
                const m = hr * 60
                out.push({ label: root.hourLabel(hr), hour: hr, temp: root.num(root.metric ? h.tempC : h.tempF),
                           rain: root.num(h.chanceofrain), code: h.weatherCode,
                           night: rise >= 0 && set > rise ? (m < rise || m >= set) : (hr < 6 || hr >= 18),
                           abs: abs, hum: root.num(h.humidity), wind: root.num(h.windspeedKmph), isNow: false })
            }
        }
        return out
    }

    readonly property var sunEvents: {
        const out = []
        for (let d = 0; d < Math.min(3, root.days.length); d++) {
            const a = root.days[d].astronomy ? root.days[d].astronomy[0] : null
            if (!a) continue
            const r = root.minutesOf(a.sunrise)
            const s = root.minutesOf(a.sunset)
            if (r >= 0 && d * 1440 + r > root.nowMin)
                out.push({ abs: d * 1440 + r, sunrise: true, label: root.shortTime(a.sunrise) })
            if (s >= 0 && d * 1440 + s > root.nowMin)
                out.push({ abs: d * 1440 + s, sunrise: false, label: root.shortTime(a.sunset) })
        }
        return out.sort((x, y) => x.abs - y.abs)
    }

    readonly property real weekLo: {
        let lo = Infinity
        for (let i = 0; i < root.days.length; i++) lo = Math.min(lo, root.dayLo(root.days[i]))
        return isFinite(lo) ? lo : 0
    }

    readonly property real weekHi: {
        let hi = -Infinity
        for (let i = 0; i < root.days.length; i++) hi = Math.max(hi, root.dayHi(root.days[i]))
        return isFinite(hi) ? hi : 1
    }

    readonly property string headline: {
        let mid = null
        let wet = null
        for (let i = 1; i < root.upcoming.length && root.upcoming[i].abs <= root.nowMin + 720; i++) {
            const e = root.upcoming[i]
            if (!mid && e.hour === 0) mid = e
            if (!wet && e.rain >= 40) wet = e
        }
        if (wet) return root.description + " now, rain likely around " + wet.label + "."
        if (mid) return root.description + " now, " + mid.temp + "° by midnight."
        return root.description + " now, feels like " + root.feels + "°."
    }

    readonly property string subline: {
        const t = root.days[1]
        let s = root.sunEventText !== "" ? root.sunEventText + ". " : ""
        if (t) {
            const r = root.dayRain(t)
            s += "Tomorrow " + root.dayLo(t) + "°–" + root.dayHi(t) + "°, " + (r >= 30 ? r + "% chance of rain." : "dry.")
        }
        return s
    }

    readonly property var stats: [
        { icon: "air", label: "Wind · " + ServiceWeather.windDirection, short: "Wind",
          value: String(root.pick(root.cur, "windspeedKmph", "windspeedMiles")), unit: root.metric ? "km/h" : "mph",
          frac: Math.min(1, root.num(root.cur ? root.cur.windspeedKmph : 0) / 40) },
        { icon: "humidity_percentage", label: "Humidity", short: "Humidity",
          value: String(root.cur ? root.cur.humidity : "--"), unit: "%",
          frac: root.num(root.cur ? root.cur.humidity : 0) / 100 },
        { icon: "umbrella", label: "Chance of rain", short: "Rain",
          value: String(root.cur ? (root.cur.chanceofrain ?? "0") : "--"), unit: "%",
          frac: root.num(root.cur ? root.cur.chanceofrain : 0) / 100 },
        { icon: "wb_sunny", label: "UV index", short: "UV",
          value: String(ServiceWeather.uvindex), unit: root.uvLabel(ServiceWeather.uvindex),
          frac: Math.min(1, root.num(ServiceWeather.uvindex) / 11) },
        { icon: "visibility", label: "Visibility", short: "Visibility",
          value: String(root.pick(root.cur, "visibility", "visibilityMiles")), unit: root.metric ? "km" : "mi",
          frac: Math.min(1, root.num(root.cur ? root.cur.visibility : 0) / 20) },
        { icon: "compress", label: "Pressure", short: "Pressure",
          value: String(root.pick(root.cur, "pressure", "pressureInches")), unit: root.metric ? "hPa" : "inHg",
          frac: Math.max(0, Math.min(1, ServiceWeather.pressure)) }
    ]

    Flickable {
        id: scroller
        anchors.fill: parent
        anchors.margins: 10
        contentWidth: width
        contentHeight: column.height
        interactive: column.implicitHeight > scroller.height + 1
        boundsBehavior: Flickable.StopAtBounds
        clip: interactive

        ColumnLayout {
            id: column
            width: scroller.width
            height: root.fixedHeight ? Math.max(column.implicitHeight, scroller.height) : column.implicitHeight
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.preferredHeight: 44
                spacing: 6

                MaterialIconSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    content: "location_on"
                    iconSize: 18
                    customColor: Colors.primary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    CustomText {
                        Layout.fillWidth: true
                        content: ServiceWeather.cityName !== "Unknown" ? ServiceWeather.cityName : ServiceWeather.location
                        size: 14
                        weight: 700
                        elide: Text.ElideRight
                    }
                    CustomText {
                        Layout.fillWidth: true
                        content: Qt.formatDate(root.now, "ddd, MMM d") + "  ·  " + root.updatedText
                        size: 11
                        customColor: Colors.outline
                        elide: Text.ElideRight
                    }
                }

                M3IconButton {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    icon: "refresh"
                    iconSize: 18
                    iconColor: ServiceWeather.isLoading ? Colors.primary : Colors.surfaceText
                    onClicked: ServiceWeather.refresh()
                }

                M3IconButton {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    icon: "close"
                    iconSize: 18
                    onClicked: root.closed()
                }
            }

            Loader {
                id: styleLoader
                Layout.fillWidth: true
                Layout.fillHeight: root.fixedHeight
                Layout.preferredHeight: item ? item.implicitHeight : 0
                sourceComponent: {
                    switch (root.style) {
                    case "dial":     return dialComp
                    case "shapes":   return shapesComp
                    case "timeline": return timelineComp
                    case "glance":   return glanceComp
                    }
                    return curveComp
                }
            }
        }
    }

    Component { id: curveComp;    WeatherStyleCurve    { panel: root } }
    Component { id: dialComp;     WeatherStyleDial     { panel: root } }
    Component { id: shapesComp;   WeatherStyleShapes   { panel: root } }
    Component { id: timelineComp; WeatherStyleTimeline { panel: root } }
    Component { id: glanceComp;   WeatherStyleGlance   { panel: root } }
}
