import QtQuick
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root

    property Item host: null
    property string itemId: ""
    readonly property bool shown: true

    property string icon: ""
    property real value: 0
    property real secondary: 0
    property var stack: []
    property var cores: []
    property real graphValue: root.value
    property real altValue: 0
    property real graphMax: 1
    property string label: ""
    property string tip: ""
    property string widthTemplate: ""
    property string shortLabel: ""
    property string number: String(Math.round(Math.max(0, root.value) * 100))
    property string compactLabel: ""

    readonly property bool iconSizable: true
    readonly property real box: BarLayout.boxFor(root.itemId, root.host)
    readonly property real iconPx: BarLayout.iconPxFor(root.itemId, root.box, 16)
    readonly property real plate: BarLayout.platePxFor(root.box, root.iconPx, 16, 26)
    readonly property var legacyStyles: ({ ring: "dial", gauge: "dial", arc: "speedo", track: "splittrack", split: "tag",
                                           dual: "underline", segments: "rising", fill: "labelbar",
                                           graph: "heat", histogram: "heat", wave: "heat" })
    readonly property string style: {
        const s = BarLayout.opt(root.itemId, "style") ?? "text"
        return root.legacyStyles[s] ?? s
    }
    readonly property bool showIcon: BarLayout.opt(root.itemId, "showIcon") !== false
    readonly property bool showValue: BarLayout.opt(root.itemId, "showValue") !== false
    readonly property real k: root.iconPx / 16
    function px(v) { return Math.round(v * root.k) }

    readonly property var squareStyles: ["text", "dial", "rings", "cookie", "liquid", "orbit", "radial", "segring"]
    readonly property var iconInside: ["dial", "cookie", "orbit", "radial", "segring"]
    readonly property var ownText: ["thumb", "labelbar", "underline"]
    readonly property var historyStyles: ["radial", "heat", "mirror"]

    readonly property bool vertical: !!root.host && root.host.vertical === true
    readonly property bool verticalReady: root.vertical && root.squareStyles.indexOf(root.style) >= 0
    readonly property string shortValue: root.compactLabel !== "" ? root.compactLabel
        : root.label.replace("%", "").replace("°C", "°")

    implicitWidth: root.verticalReady ? Math.max(root.plate, content.implicitWidth + 6)
        : content.implicitWidth + BarLayout.scaleFor(root.iconPx, 16, 12, 6)
    implicitHeight: root.verticalReady ? content.implicitHeight + 8 : Math.max(root.plate, content.implicitHeight)

    Component.onCompleted: ServiceSystemInfo.retain()
    Component.onDestruction: ServiceSystemInfo.release()

    readonly property real load: Math.max(0, Math.min(1, root.value))
    readonly property color loadColor: root.load >= 0.9 ? Colors.error : root.load >= 0.7 ? Colors.tertiary : Colors.primary
    readonly property color onLoadColor: root.load >= 0.9 ? Colors.errorText : root.load >= 0.7 ? Colors.tertiaryText : Colors.primaryText

    property var history: []
    property var altHistory: []
    readonly property int historyPoints: 30

    function pushTo(list, v) {
        const out = list.length >= root.historyPoints ? list.slice(list.length - root.historyPoints + 1) : list.slice()
        out.push(v)
        return out
    }

    function peakOf(list) {
        let m = 0
        for (const v of list)
            m = Math.max(m, v)
        return m
    }

    readonly property real historyMax: root.graphMax > 0 ? root.graphMax : Math.max(1024, root.peakOf(root.history))
    readonly property real altMax: Math.max(1024, root.peakOf(root.altHistory))

    onGraphValueChanged: {
        if (root.historyStyles.indexOf(root.style) >= 0)
            root.history = root.pushTo(root.history, root.graphValue)
    }
    onAltValueChanged: {
        if (root.style === "mirror")
            root.altHistory = root.pushTo(root.altHistory, root.altValue)
    }

    Grid {
        id: content
        anchors.centerIn: parent
        spacing: root.verticalReady ? 2 : root.px(6)
        rows: root.verticalReady ? -1 : 1
        columns: root.verticalReady ? 1 : -1
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        MaterialIconSymbol {
            visible: root.showIcon && root.style !== "tag" && root.iconInside.indexOf(root.style) < 0
            content: root.icon
            iconSize: root.iconPx
            customColor: hov.containsMouse ? Colors.primary : Colors.surfaceText
        }

        CustomText {
            visible: root.style === "tag"
            content: root.shortLabel
            size: root.px(10.5)
            weight: 700
            font.letterSpacing: 0.6
            customColor: Colors.surfaceVariantText
        }

        Loader {
            id: meter
            active: root.style !== "text"
            visible: active
            sourceComponent: {
                switch (root.style) {
                case "dial":      return dialComp
                case "rings":     return ringsComp
                case "cookie":    return cookieComp
                case "liquid":    return liquidComp
                case "speedo":    return speedoComp
                case "orbit":     return orbitComp
                case "radial":    return radialComp
                case "segring":   return segringComp
                case "splittrack":
                case "tag":       return splitComp
                case "capsules":  return capsulesComp
                case "rising":    return risingComp
                case "stacked":   return stackedComp
                case "columns":   return columnsComp
                case "ruler":     return rulerComp
                case "dots":      return dotsComp
                case "heat":      return heatComp
                case "mirror":    return mirrorComp
                case "thumb":     return thumbComp
                case "labelbar":  return labelComp
                case "underline": return underlineComp
                }
                return null
            }
        }

        CustomText {
            id: valueText
            visible: root.ownText.indexOf(root.style) < 0 && root.showValue
            width: root.verticalReady ? valueText.implicitWidth : Math.max(valueText.implicitWidth, widthProbe.advanceWidth)
            font.features: { "tnum": 1 }
            content: root.verticalReady ? root.shortValue : root.label
            size: root.verticalReady ? root.px(11) : root.px(13)
            weight: 700
        }
    }

    TextMetrics {
        id: widthProbe
        font: valueText.font
        text: root.widthTemplate
    }

    MouseArea {
        id: hov
        anchors.fill: parent
        hoverEnabled: true
    }

    CustomToolTip {
        content: root.tip !== "" ? root.tip : root.label
        visible: hov.containsMouse
    }

    Component {
        id: dialComp
        MeterTickDial {
            implicitWidth: root.px(28)
            implicitHeight: root.px(28)
            ticks: 16
            majorEvery: 0
            tickWidth: Math.max(1.5, root.px(2))
            tickLength: root.px(4)
            value: root.load
            color: root.loadColor
            MaterialIconSymbol {
                anchors.centerIn: parent
                visible: root.showIcon
                content: root.icon
                iconSize: root.px(12)
                customColor: Colors.surfaceText
            }
        }
    }

    Component {
        id: ringsComp
        MeterRings {
            implicitWidth: root.px(26)
            implicitHeight: root.px(26)
            thickness: Math.max(2, root.px(3))
            gap: Math.max(1, root.px(1.5))
            values: [root.load, root.secondary]
            colors: [root.loadColor, Colors.secondary]
        }
    }

    Component {
        id: cookieComp
        MeterCookie {
            implicitWidth: root.px(28)
            implicitHeight: root.px(28)
            thickness: Math.max(2, root.px(2.5))
            faceColor: "transparent"
            value: root.load
            color: root.loadColor
            MaterialIconSymbol {
                anchors.centerIn: parent
                visible: root.showIcon
                content: root.icon
                iconSize: root.px(12)
                customColor: Colors.surfaceText
            }
        }
    }

    Component {
        id: liquidComp
        MeterLiquid {
            implicitWidth: root.px(24)
            implicitHeight: root.px(24)
            amplitude: Math.max(1, root.px(1.2))
            value: root.load
            color: root.loadColor
            backColor: Qt.alpha(root.loadColor, 0.45)
            trackColor: Colors.surfaceContainerHighest
        }
    }

    Component {
        id: speedoComp
        MeterSpeedo {
            implicitWidth: root.px(32)
            implicitHeight: root.px(21)
            thickness: Math.max(2.5, root.px(3.5))
            showTicks: false
            value: root.load
            color: root.loadColor
            hubHole: Colors.surfaceContainer
        }
    }

    Component {
        id: orbitComp
        MeterOrbit {
            implicitWidth: root.px(28)
            implicitHeight: root.px(28)
            thickness: Math.max(1.2, root.px(1.4))
            planet: root.px(4.5)
            coreScale: 0
            value: root.load
            color: root.loadColor
            MaterialIconSymbol {
                anchors.centerIn: parent
                visible: root.showIcon
                content: root.icon
                iconSize: root.px(12)
                customColor: Colors.surfaceText
            }
        }
    }

    Component {
        id: radialComp
        MeterRadialHistory {
            implicitWidth: root.px(28)
            implicitHeight: root.px(28)
            points: 24
            inner: 0.5
            barWidth: Math.max(1.2, root.px(1.4))
            history: root.history
            max: root.historyMax
            color: root.loadColor
            MaterialIconSymbol {
                anchors.centerIn: parent
                visible: root.showIcon
                content: root.icon
                iconSize: root.px(10)
                customColor: Colors.surfaceText
            }
        }
    }

    Component {
        id: segringComp
        MeterSegmentRing {
            implicitWidth: root.px(26)
            implicitHeight: root.px(26)
            segments: 8
            gapDegrees: 12
            thickness: Math.max(2.5, root.px(3.5))
            value: root.load
            color: root.loadColor
            MaterialIconSymbol {
                anchors.centerIn: parent
                visible: root.showIcon
                content: root.icon
                iconSize: root.px(11)
                customColor: Colors.surfaceText
            }
        }
    }

    Component {
        id: splitComp
        MeterSplitTrack {
            implicitWidth: root.style === "tag" ? root.px(40) : root.px(46)
            implicitHeight: root.px(6)
            gap: root.px(3)
            value: root.load
            color: root.loadColor
        }
    }

    Component {
        id: capsulesComp
        MeterCapsules {
            implicitWidth: root.px(52)
            implicitHeight: root.px(14)
            count: 10
            gap: Math.max(1, root.px(1.5))
            value: root.load
            color: root.loadColor
        }
    }

    Component {
        id: risingComp
        MeterCapsules {
            implicitWidth: root.px(40)
            implicitHeight: root.px(18)
            count: 8
            rising: true
            gap: Math.max(1, root.px(2))
            value: root.load
            color: root.loadColor
        }
    }

    Component {
        id: stackedComp
        MeterStacked {
            implicitWidth: root.px(52)
            implicitHeight: root.px(8)
            gap: Math.max(1, root.px(1.5))
            values: root.stack.length > 0 ? root.stack : [root.load]
            colors: [root.loadColor, Colors.tertiary, Colors.secondary]
        }
    }

    Component {
        id: columnsComp
        MeterColumns {
            readonly property var list: root.cores.length > 0 ? root.cores : [root.load]
            implicitWidth: Math.max(root.px(20), list.length * root.px(4.5))
            implicitHeight: root.px(20)
            gap: Math.max(1, root.px(1.5))
            radius: Math.max(1, root.px(1.5))
            values: list
        }
    }

    Component {
        id: rulerComp
        MeterRuler {
            implicitWidth: root.px(50)
            implicitHeight: root.px(14)
            barHeight: Math.max(3, root.px(4))
            showTicks: false
            value: root.load
        }
    }

    Component {
        id: dotsComp
        MeterDotMatrix {
            implicitWidth: root.px(48)
            implicitHeight: root.px(13)
            rows: 3
            dot: Math.max(2, root.px(3))
            gap: Math.max(1, root.px(2))
            value: root.load
            color: root.loadColor
        }
    }

    Component {
        id: heatComp
        MeterHeatStrip {
            implicitWidth: root.px(58)
            implicitHeight: root.px(16)
            points: 16
            gap: Math.max(1, root.px(1.2))
            radius: Math.max(1, root.px(1.5))
            history: root.history
            max: root.historyMax
            color: root.graphMax > 0 ? root.loadColor : Colors.primary
        }
    }

    Component {
        id: mirrorComp
        MeterMirror {
            implicitWidth: root.px(56)
            implicitHeight: root.px(12)
            leftValue: root.graphValue / root.historyMax
            rightValue: root.altValue / root.altMax
        }
    }

    Component {
        id: thumbComp
        MeterThumb {
            implicitWidth: root.px(70)
            implicitHeight: root.px(20)
            textSize: root.px(11)
            value: root.load
            text: root.showValue ? root.label : ""
            color: root.loadColor
            inkColor: root.onLoadColor
            fillColor: Qt.alpha(root.loadColor, 0.5)
        }
    }

    Component {
        id: labelComp
        MeterLabelBar {
            id: labelBar
            implicitWidth: Math.max(root.px(64), labelProbe.advanceWidth + root.px(24))
            implicitHeight: root.px(22)
            textSize: root.px(12)
            value: root.load
            text: root.showValue ? root.label : root.shortLabel
            color: root.loadColor
            inkColor: root.onLoadColor

            TextMetrics {
                id: labelProbe
                font.family: labelBar.family
                font.pixelSize: root.px(12)
                text: root.widthTemplate
            }
        }
    }

    Component {
        id: underlineComp
        Column {
            spacing: root.px(2)
            CustomText {
                id: ulText
                width: Math.max(ulText.implicitWidth, ulProbe.advanceWidth)
                horizontalAlignment: Text.AlignHCenter
                font.features: { "tnum": 1 }
                content: root.showValue ? root.label : root.shortLabel
                size: root.px(13)
                weight: 700
            }
            MeterSplitTrack {
                width: ulText.width
                height: Math.max(2, root.px(3))
                gap: root.px(2)
                stopDot: false
                value: root.load
                color: root.loadColor
            }
            TextMetrics {
                id: ulProbe
                font: ulText.font
                text: root.widthTemplate
            }
        }
    }
}
