import QtQuick
import QtQuick.Effects
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
    property real graphValue: root.value
    property real graphMax: 1
    property string label: ""
    property string tip: ""
    property string widthTemplate: ""
    property string shortLabel: ""
    property string detail: ""
    property string detailTemplate: ""
    property string number: String(Math.round(Math.max(0, root.value) * 100))

    readonly property bool iconSizable: true
    readonly property real box: BarLayout.boxFor(root.itemId, root.host)
    readonly property real iconPx: BarLayout.iconPxFor(root.itemId, root.box, 16)
    readonly property real plate: BarLayout.platePxFor(root.box, root.iconPx, 16, 26)
    readonly property string style: BarLayout.opt(root.itemId, "style") ?? "text"
    readonly property bool showIcon: BarLayout.opt(root.itemId, "showIcon") !== false

    implicitWidth: content.implicitWidth + BarLayout.scaleFor(root.iconPx, 16, 12, 6)
    implicitHeight: root.plate

    Component.onCompleted: ServiceSystemInfo.retain()
    Component.onDestruction: ServiceSystemInfo.release()

    readonly property bool historyStyle: root.style === "graph" || root.style === "histogram" || root.style === "wave"
    readonly property real load: Math.max(0, Math.min(1, root.value))
    readonly property color loadColor: root.load >= 0.9 ? Colors.error : root.load >= 0.7 ? Colors.tertiary : Colors.primary
    readonly property color onLoadColor: root.load >= 0.9 ? Colors.errorText : root.load >= 0.7 ? Colors.tertiaryText : Colors.primaryText
    readonly property bool ownText: ["ring", "split", "dual", "arc", "wave"].indexOf(root.style) >= 0

    onGraphValueChanged: {
        if (root.style === "wave") {
            if (waveLoader.item)
                waveLoader.item.push(root.graphValue)
        }
        else if (root.historyStyle)
            spark.addValue(root.graphValue)
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 5

        MaterialIconSymbol {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showIcon && ["ring", "gauge", "split", "arc", "wave"].indexOf(root.style) < 0
            content: root.icon
            iconSize: root.iconPx
            customColor: root.style === "dual" ? root.loadColor : hov.containsMouse ? Colors.primary : Colors.surfaceText
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.style === "ring"
            width: 24
            height: 24

            CustomCircularProgressBar {
                anchors.fill: parent
                progress: Math.max(0, Math.min(1, root.value))
                thickness: 2.5
                showText: false
            }

            MaterialIconSymbol {
                anchors.centerIn: parent
                visible: root.showIcon
                content: root.icon
                iconSize: BarLayout.scaleFor(root.iconPx, 16, 12, 8)
                customColor: Colors.surfaceText
            }
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.style === "gauge"
            width: 26
            height: 26

            CustomGaugeProgress {
                anchors.fill: parent
                showData: false
                progress: Math.max(0, Math.min(1, root.value))
                thickness: 3
                baseColor: Colors.surfaceContainerHighest
                lineColor: Colors.primary
            }

            MaterialIconSymbol {
                anchors.centerIn: parent
                visible: root.showIcon
                content: root.icon
                iconSize: BarLayout.scaleFor(root.iconPx, 16, 11, 8)
                customColor: Colors.surfaceText
            }
        }

        CustomProgressBar {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.style === "track"
            value: Math.max(0, Math.min(1, root.value))
            valueBarWidth: 46
            valueBarHeight: 5
            highlightColor: Colors.primary
            trackColor: Colors.surfaceContainerHighest
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.style === "split"
            width: splitRow.implicitWidth
            height: 24
            radius: 12
            color: root.loadColor

            Behavior on color { EffectsColorAnim {} }

            Row {
                id: splitRow
                height: parent.height

                Rectangle {
                    width: splitLabel.implicitWidth + 14
                    height: parent.height
                    topLeftRadius: height / 2
                    bottomLeftRadius: height / 2
                    color: Colors.secondaryContainer
                    CustomText {
                        id: splitLabel
                        anchors.centerIn: parent
                        content: root.shortLabel
                        size: 10
                        weight: 700
                        font.letterSpacing: 0.6
                        customColor: Colors.secondaryContainerText
                    }
                }
                Item {
                    width: splitValue.width + 16
                    height: parent.height
                    CustomText {
                        id: splitValue
                        anchors.centerIn: parent
                        width: Math.max(splitValue.implicitWidth, splitProbe.advanceWidth)
                        horizontalAlignment: Text.AlignHCenter
                        font.features: { "tnum": 1 }
                        content: root.label
                        size: 12
                        weight: 800
                        customColor: root.onLoadColor
                    }
                    TextMetrics {
                        id: splitProbe
                        font: splitValue.font
                        text: root.widthTemplate
                    }
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.style === "dual"
            spacing: 1

            CustomText {
                id: dualValue
                width: Math.max(dualValue.implicitWidth, dualProbe.advanceWidth)
                font.features: { "tnum": 1 }
                content: root.label
                size: 13
                weight: 800
            }
            CustomText {
                id: dualDetail
                width: Math.max(dualDetail.implicitWidth, detailProbe.advanceWidth)
                font.features: { "tnum": 1 }
                content: root.detail
                size: 9
                weight: 500
                customColor: Colors.outline
            }
            TextMetrics {
                id: dualProbe
                font: dualValue.font
                text: root.widthTemplate
            }
            TextMetrics {
                id: detailProbe
                font: dualDetail.font
                text: root.detailTemplate
            }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.style === "segments"
            height: 18
            spacing: 2

            Repeater {
                model: 8
                delegate: Rectangle {
                    required property int index
                    anchors.bottom: parent.bottom
                    width: 4
                    height: 8 + index * 1.4
                    radius: 2
                    color: index < Math.round(root.load * 8) ? root.loadColor : Colors.surfaceContainerHighest
                    Behavior on color { EffectsColorAnim {} }
                }
            }
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.style === "arc"
            width: 32
            height: 32

            CustomGaugeProgress {
                anchors.fill: parent
                showData: false
                progress: root.load
                thickness: 3
                baseColor: Colors.surfaceContainerHighest
                lineColor: root.loadColor
            }
            Column {
                anchors.centerIn: parent
                spacing: 0
                CustomText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.features: { "tnum": 1 }
                    content: root.number
                    size: 10
                    weight: 800
                }
                CustomText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    content: root.shortLabel
                    size: 7
                    weight: 700
                    customColor: Colors.outline
                }
            }
        }

        Loader {
            id: waveLoader
            anchors.verticalCenter: parent.verticalCenter
            active: root.style === "wave"
            visible: active
            sourceComponent: waveComp
        }

        CustomSparkline {
            id: spark
            anchors.verticalCenter: parent.verticalCenter
            visible: root.style === "graph" || root.style === "histogram"
            width: 44
            height: 20
            maxPoints: 30
            maxOverride: root.graphMax
            lineWidth: 1.5
            cornerRadius: 4
            bars: root.style === "histogram"
            barWidth: 2
            barGap: 1.5
        }

        CustomText {
            id: valueText
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.ownText
            width: Math.max(valueText.implicitWidth, widthProbe.advanceWidth)
            font.features: { "tnum": 1 }
            content: root.label
            size: 12
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
        id: waveComp

        Item {
            id: waveBox
            property bool seeded: false
            function push(v) {
                if (!waveBox.seeded) {
                    waveSpark.values = new Array(30).fill(v)
                    waveBox.seeded = true
                } else {
                    waveSpark.addValue(v)
                }
            }
            implicitWidth: Math.max(78, waveRow.implicitWidth + 20)
            implicitHeight: 32

            Item {
                id: waveBg
                anchors.fill: parent
                visible: false
                layer.enabled: true

                Rectangle {
                    anchors.fill: parent
                    color: Colors.surfaceContainer
                }

                CustomSparkline {
                    id: waveSpark
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 11
                    opacity: 0.85
                    maxPoints: 30
                    maxOverride: root.graphMax
                    lineWidth: 1.2
                    cornerRadius: 4
                    filled: true
                    gradientFill: false
                    lineColor: root.loadColor
                    fillColor: Qt.alpha(root.loadColor, 0.22)
                }
            }

            Rectangle {
                id: waveMask
                anchors.fill: parent
                radius: height / 2
                visible: false
                layer.enabled: true
            }

            MultiEffect {
                anchors.fill: parent
                source: waveBg
                maskEnabled: true
                maskSource: waveMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }

            Row {
                id: waveRow
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -4
                spacing: 8
                CustomText {
                    id: waveLabel
                    anchors.verticalCenter: parent.verticalCenter
                    content: root.shortLabel
                    size: 10
                    weight: 700
                    customColor: Colors.outline
                }
                CustomText {
                    id: waveValue
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(waveValue.implicitWidth, waveProbe.advanceWidth)
                    horizontalAlignment: Text.AlignRight
                    font.features: { "tnum": 1 }
                    content: root.label
                    size: 12
                    weight: 800
                }
                TextMetrics {
                    id: waveProbe
                    font: waveValue.font
                    text: root.widthTemplate
                }
            }
        }
    }
}
