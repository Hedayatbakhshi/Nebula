import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.customComponents
import qs.modules.utils
import qs.modules.settings

Item {
    id: root
    readonly property int cardWidth: 180
    readonly property int cardSpacing: 6
    readonly property int layoutMargins: 8

    property var appEntry: null
    property bool capturing: true
    property real maxWidth: 100000

    signal activated

    readonly property var tops: root.appEntry?.toplevels ?? []
    readonly property int count: Math.max(1, root.tops.length)
    readonly property real rowWidth: root.count * (root.cardWidth + root.cardSpacing) - root.cardSpacing
    readonly property real naturalWidth: root.layoutMargins * 2 + root.rowWidth
    readonly property bool overflowing: root.naturalWidth > root.maxWidth + 0.5

    implicitWidth: Math.min(root.naturalWidth, root.maxWidth)
    implicitHeight: 180

    onAppEntryChanged: {
        wheelAnim.stop()
        strip.contentX = 0
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.layoutMargins
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Image {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                source: Quickshell.iconPath(
                    DesktopEntries.heuristicLookup(root.appEntry?.appId ?? "")?.icon,
                    "image-missing")
                sourceSize.width: 18
                sourceSize.height: 18
                fillMode: Image.PreserveAspectFit
            }

            CustomText {
                Layout.fillWidth: true
                content: DesktopEntries.heuristicLookup(root.appEntry?.appId ?? "")?.name
                         ?? root.appEntry?.appId ?? ""
                size: 12
                weight: 700
                elide: Text.ElideRight
                customColor: Colors.outline
            }

            CustomText {
                visible: root.overflowing
                content: root.tops.length + " windows"
                size: 10
                weight: 600
                customColor: Colors.outline
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: strip
                anchors.fill: parent
                contentWidth: root.rowWidth
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                interactive: root.overflowing
                clip: true

                Row {
                    height: strip.height
                    spacing: root.cardSpacing

                    Repeater {
                        model: root.tops

                        delegate: Rectangle {
                            id: card
                            required property var modelData
                            readonly property bool inView: card.x + card.width > strip.contentX
                                && card.x < strip.contentX + strip.width
                            width: root.cardWidth
                            height: strip.height
                            color: Colors.surfaceContainerHigh
                            radius: 14
                            clip: true

                            RippleEffect {
                                anchors.fill: parent
                                radius: 14
                                onClicked: {
                                    card.modelData.activate()
                                    root.activated()
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    CustomText {
                                        Layout.fillWidth: true
                                        content: card.modelData.title ?? ""
                                        size: 10
                                        weight: 600
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        radius: 11
                                        color: closeRipple.containsMouse
                                               ? Colors.surfaceContainerHighest : "transparent"

                                        MaterialIconSymbol {
                                            anchors.centerIn: parent
                                            content: "close"
                                            iconSize: 13
                                            customColor: closeRipple.containsMouse ? Colors.error : Colors.outline
                                        }

                                        RippleEffect {
                                            id: closeRipple
                                            anchors.fill: parent
                                            radius: 11
                                            onClicked: card.modelData.close()
                                        }
                                    }
                                }

                                ScreencopyView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    captureSource: root.capturing && card.inView ? card.modelData : null
                                    live: true
                                    paintCursor: false
                                    constraintSize: Qt.size(root.cardWidth, 120)
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => {
                    wheel.accepted = false
                    if (!root.overflowing)
                        return
                    const maxX = Math.max(0, strip.contentWidth - strip.width)
                    if (wheel.pixelDelta.x !== 0 || wheel.pixelDelta.y !== 0) {
                        const d = wheel.pixelDelta.x !== 0 ? wheel.pixelDelta.x : wheel.pixelDelta.y
                        wheelAnim.stop()
                        strip.contentX = Math.max(0, Math.min(maxX, strip.contentX - d))
                        wheel.accepted = true
                        return
                    }
                    const a = wheel.angleDelta.x !== 0 ? wheel.angleDelta.x : wheel.angleDelta.y
                    if (a === 0)
                        return
                    const step = -a / 120 * (root.cardWidth + root.cardSpacing)
                    const from = wheelAnim.running ? wheelAnim.to : strip.contentX
                    strip.cancelFlick()
                    wheelAnim.stop()
                    wheelAnim.to = Math.max(0, Math.min(maxX, from + step))
                    wheelAnim.start()
                    wheel.accepted = true
                }
            }

            NumberAnimation {
                id: wheelAnim
                target: strip
                property: "contentX"
                duration: 380
                easing.type: Easing.OutCubic
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 28
                visible: root.overflowing && !strip.atXBeginning
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Colors.surface }
                    GradientStop { position: 1.0; color: Qt.alpha(Colors.surface, 0) }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 28
                visible: root.overflowing && !strip.atXEnd
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.alpha(Colors.surface, 0) }
                    GradientStop { position: 1.0; color: Colors.surface }
                }
            }
        }

        Rectangle {
            id: track
            visible: root.overflowing
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            radius: 2
            color: Colors.surfaceContainerHigh

            Rectangle {
                readonly property real ratio: strip.width / Math.max(1, strip.contentWidth)
                width: Math.max(24, track.width * ratio)
                height: parent.height
                radius: 2
                x: (track.width - width) * (strip.contentX / Math.max(1, strip.contentWidth - strip.width))
                color: Colors.primary
            }

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -6
                anchors.bottomMargin: -6
                cursorShape: Qt.PointingHandCursor
                function seek(mx) {
                    const maxX = Math.max(0, strip.contentWidth - strip.width)
                    wheelAnim.stop()
                    strip.contentX = Math.max(0, Math.min(maxX, mx / track.width * maxX))
                }
                onPressed: mouse => seek(mouse.x)
                onPositionChanged: mouse => { if (pressed) seek(mouse.x) }
            }
        }
    }
}
