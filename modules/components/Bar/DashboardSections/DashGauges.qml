import QtQuick
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.components.Bar

DashItem {
    id: root

    card: true

    Component.onCompleted: ServiceDashData.retainSystem()
    Component.onDestruction: ServiceDashData.releaseSystem()

    readonly property var metrics: DashLayout.listFor(root.instanceId, "metrics", DashLayout.metricCatalog, DashLayout.metricDefault)
    readonly property string face: String(root.opt("face") ?? "dial")
    readonly property bool combined: root.face === "rings"
    readonly property int fits: Math.max(1, Math.floor((root.width - 20) / 110))
    readonly property var shown: root.combined ? root.metrics.slice(0, 4) : root.metrics.slice(0, root.fits)
    readonly property bool single: root.shown.length === 1
    readonly property real dial: Math.max(40, Math.min(root.single ? 110 : 90, root.height - 42,
                                                        (root.width - 20) / Math.max(1, root.shown.length) - 12))

    function peakOf(id) {
        const h = DashLayout.metricHistory(id)
        let m = -1
        for (const v of h)
            m = Math.max(m, v)
        return m
    }

    Row {
        visible: root.combined
        anchors.centerIn: parent
        spacing: 16

        MeterRings {
            width: Math.max(48, Math.min(root.height - 24, root.width * 0.5))
            height: width
            thickness: Math.max(5, width * 0.085)
            values: root.shown.map(m => DashLayout.metricFraction(m))
            colors: root.shown.map(m => DashLayout.metricColor(m))
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: root.width >= 200

            Repeater {
                model: root.shown

                delegate: Row {
                    id: leg
                    required property string modelData
                    spacing: 8

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: DashLayout.metricColor(leg.modelData)
                    }
                    CustomText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 42
                        content: DashLayout.metricLabel(leg.modelData)
                        size: 12
                        weight: 500
                        customColor: Colors.surfaceVariantText
                    }
                    CustomText {
                        anchors.verticalCenter: parent.verticalCenter
                        content: DashLayout.metricText(leg.modelData) + (leg.modelData === "temp" ? "" : "%")
                        family: root.displayFont
                        renderType: Text.QtRendering
                        size: 17
                        weight: 400
                    }
                }
            }
        }
    }

    Row {
        visible: !root.combined
        anchors.centerIn: parent
        spacing: root.shown.length > 1 ? (root.width - 20 - root.shown.length * root.dial) / root.shown.length : 0

        Repeater {
            model: root.combined ? [] : root.shown

            delegate: Column {
                id: g
                required property string modelData
                readonly property real frac: DashLayout.metricFraction(g.modelData)
                readonly property color tint: DashLayout.metricColor(g.modelData)
                readonly property bool inkOnFill: root.face === "liquid" && g.frac > 0.55
                spacing: 4

                Item {
                    width: root.dial
                    height: root.face === "speedo" ? root.dial * 0.62 : root.dial

                    Loader {
                        anchors.fill: parent
                        active: root.bound
                        sourceComponent: {
                            switch (root.face) {
                            case "cookie":  return cookieFace
                            case "liquid":  return liquidFace
                            case "speedo":  return speedoFace
                            case "orbit":   return orbitFace
                            case "radial":  return radialFace
                            case "segring": return segFace
                            }
                            return dialFace
                        }

                        Component {
                            id: dialFace
                            MeterTickDial {
                                ticks: root.dial >= 80 ? 32 : 24
                                majorEvery: root.dial >= 80 ? 8 : 6
                                value: g.frac
                                peak: g.modelData === "disk" ? -1 : root.peakOf(g.modelData)
                                color: g.tint
                            }
                        }
                        Component {
                            id: cookieFace
                            MeterCookie {
                                value: g.frac
                                color: g.tint
                                faceColor: Colors.surfaceContainerHighest
                                trackColor: Colors.surfaceBright
                            }
                        }
                        Component {
                            id: liquidFace
                            MeterLiquid {
                                value: g.frac
                                color: g.tint
                                backColor: Qt.alpha(g.tint, 0.45)
                                trackColor: Colors.surfaceContainerHighest
                            }
                        }
                        Component {
                            id: speedoFace
                            MeterSpeedo {
                                value: g.frac
                                color: g.tint
                                hubHole: root.cardColor
                            }
                        }
                        Component {
                            id: orbitFace
                            MeterOrbit {
                                value: g.frac
                                color: g.tint
                                coreColor: Colors.surfaceContainerHighest
                            }
                        }
                        Component {
                            id: radialFace
                            MeterRadialHistory {
                                points: 32
                                history: DashLayout.metricHistory(g.modelData)
                                color: g.tint
                                dimColor: Qt.tint(Colors.surfaceContainerHighest, Qt.alpha(g.tint, 0.45))
                            }
                        }
                        Component {
                            id: segFace
                            MeterSegmentRing {
                                value: g.frac
                                color: g.tint
                                fillColor: Qt.tint(Colors.surfaceContainerHighest, Qt.alpha(g.tint, 0.6))
                            }
                        }
                    }

                    CustomText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: root.face === "speedo" ? undefined : parent.verticalCenter
                        anchors.bottom: root.face === "speedo" ? parent.bottom : undefined
                        anchors.bottomMargin: -root.dial * 0.2
                        visible: root.face !== "radial" || root.dial >= 70
                        content: DashLayout.metricText(g.modelData)
                        family: root.displayFont
                        renderType: Text.QtRendering
                        size: root.face === "radial" ? root.dial * 0.18 : root.face === "speedo" ? root.dial * 0.2 : root.dial * 0.24
                        weight: 400
                        customColor: g.inkOnFill ? Colors.primaryText : Colors.surfaceText
                    }
                }

                CustomText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: root.face === "speedo" ? root.dial * 0.22 : 0
                    content: DashLayout.metricLabel(g.modelData)
                    size: root.single ? 13 : 12
                    weight: root.single ? 700 : 500
                    customColor: root.single ? Colors.surfaceText : Colors.surfaceVariantText
                }
            }
        }
    }
}
