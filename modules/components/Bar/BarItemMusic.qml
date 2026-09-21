import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root

    property Item host: null
    property string itemId: ""
    property string fallbackStyle: "chip"

    readonly property string style: BarLayout.opt(root.itemId, "style") ?? root.fallbackStyle
    readonly property string panelStyle: BarLayout.opt(root.itemId, "panel") ?? "side"
    readonly property bool hideIdle: BarLayout.opt(root.itemId, "hideIdle") === true

    readonly property bool hasTrack: ServiceMusic.activePlayer !== null
    readonly property bool playing: ServiceMusic.isPlaying
    readonly property string title: ServiceMusic.activeTrack?.title ?? ""
    readonly property string artist: ServiceMusic.activeTrack?.artist ?? ""
    readonly property string artUrl: ServiceMusic.activeTrack?.artUrl ?? ""
    readonly property real progress: {
        const len = ServiceMusic.trackLength
        if (len <= 0)
            return 0
        return Math.max(0, Math.min(1, (ServiceMusic.activePlayer?.position ?? 0) / len))
    }

    readonly property bool inDock: root.host && root.host.iconSize ? true : false
    readonly property real h: root.inDock ? root.host.iconSize + 14 : Appearance.size.barHeight
    readonly property real art: Math.max(20, Math.min(30, root.h - 18))

    readonly property bool shown: root.hasTrack || !root.hideIdle

    implicitWidth: face.item ? face.item.implicitWidth : 0
    implicitHeight: root.h

    Loader {
        id: face
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: {
            if (!root.hasTrack)
                return root.style === "disc" ? discComp : idleComp
            switch (root.style) {
            case "ring":      return ringComp
            case "pill":      return pillComp
            case "vis":       return visComp
            case "underline": return underlineComp
            case "disc":      return discComp
            }
            return chipComp
        }
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered && root.host)
                root.host.hoverOpen(root.panelStyle === "backdrop" ? "musicArt" : "music", root)
        }
    }

    component Art: ClippingWrapperRectangle {
        id: artBox
        property real side: root.art
        implicitWidth: artBox.side
        implicitHeight: artBox.side
        radius: 8
        color: Colors.surfaceContainerHighest

        Item {
            MaterialIconSymbol {
                anchors.centerIn: parent
                content: "music_note"
                iconSize: Math.round(artBox.side * 0.55)
                customColor: Colors.outline
                visible: root.artUrl === ""
            }

            Image {
                anchors.fill: parent
                source: root.artUrl
                sourceSize.width: 96
                sourceSize.height: 96
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                visible: root.artUrl !== ""
            }
        }
    }

    component Btn: Rectangle {
        id: btn
        property string icon: ""
        property bool primary: false
        property real side: 26
        signal tapped

        implicitWidth: btn.side
        implicitHeight: btn.side
        radius: btn.side / 2
        color: btn.primary ? (btnArea.containsMouse ? Colors.primary : Colors.primaryContainer)
                           : (btnArea.containsMouse ? Qt.alpha(Colors.primary, 0.14) : "transparent")
        Behavior on color { EffectsColorAnim {} }

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: btn.icon
            iconSize: Math.round(btn.side * 0.62)
            customColor: btn.primary ? (btnArea.containsMouse ? Colors.primaryText : Colors.primaryContainerText)
                                     : (btnArea.containsMouse ? Colors.primary : Colors.outline)
        }

        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.tapped()
        }
    }

    Component {
        id: idleComp
        RowLayout {
            spacing: 8
            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                color: Colors.surfaceContainerHigh
                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "music_off"
                    iconSize: 14
                    customColor: Colors.outline
                }
            }
            CustomText {
                content: "Nothing playing"
                size: 12
                weight: 500
                customColor: Colors.outline
            }
        }
    }

    Component {
        id: chipComp
        RowLayout {
            spacing: 8
            Art {}
            CustomMarqueeText {
                Layout.preferredWidth: Math.min(implicitWidth, 130)
                content: root.artist !== "" ? root.title + "  —  " + root.artist : root.title
                size: 12
                weight: 600
                customColor: Colors.surfaceText
                scrolling: root.playing
            }
            Btn {
                icon: root.playing ? "pause" : "play_arrow"
                primary: true
                side: 28
                onTapped: ServiceMusic.togglePlaying()
            }
        }
    }

    Component {
        id: ringComp
        RowLayout {
            spacing: 9
            Item {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                CustomCircularProgressBar {
                    anchors.fill: parent
                    progress: root.progress
                    thickness: 2
                    showText: false
                    baseColor: Colors.surfaceContainerHighest
                    lineColor: Colors.primary
                }
                Art {
                    anchors.centerIn: parent
                    side: 22
                    radius: 7
                }
            }
            ColumnLayout {
                spacing: -1
                CustomMarqueeText {
                    Layout.preferredWidth: Math.min(implicitWidth, 150)
                    content: root.title
                    size: 12
                    weight: 600
                    customColor: Colors.surfaceText
                    scrolling: root.playing
                }
                CustomText {
                    Layout.maximumWidth: 150
                    visible: root.artist !== ""
                    content: root.artist
                    size: 10
                    weight: 500
                    customColor: Colors.outline
                    elide: Text.ElideRight
                }
            }
        }
    }

    Component {
        id: pillComp
        Rectangle {
            implicitWidth: pillRow.implicitWidth + 10
            implicitHeight: root.h - 10
            radius: implicitHeight / 2
            color: Colors.surfaceContainerHigh

            RowLayout {
                id: pillRow
                anchors.verticalCenter: parent.verticalCenter
                x: 5
                spacing: 6
                Art {
                    side: root.h - 18
                    radius: (root.h - 18) / 2
                }
                ColumnLayout {
                    spacing: -1
                    CustomMarqueeText {
                        Layout.preferredWidth: Math.min(implicitWidth, 110)
                        content: root.inDock || root.artist === "" ? root.title : root.title + "  —  " + root.artist
                        size: 12
                        weight: 600
                        customColor: Colors.surfaceText
                        scrolling: root.playing
                    }
                    CustomText {
                        Layout.maximumWidth: 110
                        visible: root.inDock && root.artist !== ""
                        content: root.artist
                        size: 10
                        customColor: Colors.outline
                        elide: Text.ElideRight
                    }
                }
                Btn { icon: "skip_previous"; onTapped: ServiceMusic.previous() }
                Btn {
                    icon: root.playing ? "pause" : "play_arrow"
                    primary: true
                    side: 28
                    onTapped: ServiceMusic.togglePlaying()
                }
                Btn { icon: "skip_next"; onTapped: ServiceMusic.next() }
            }
        }
    }

    Component {
        id: visComp
        RowLayout {
            id: vis
            spacing: 9
            readonly property int bars: 5
            Component.onCompleted: ServiceCava.retain()
            Component.onDestruction: ServiceCava.release()

            Row {
                Layout.preferredHeight: 20
                spacing: 2.5
                Repeater {
                    model: vis.bars
                    Rectangle {
                        required property int index
                        readonly property var data: ServiceCava.cavaData
                        readonly property real level: {
                            const n = data.length
                            if (!root.playing || n === 0)
                                return 0
                            const lo = Math.floor(index * n / vis.bars)
                            const hi = Math.max(lo + 1, Math.floor((index + 1) * n / vis.bars))
                            let s = 0
                            for (let i = lo; i < hi; i++)
                                s += data[i]
                            return s / (hi - lo)
                        }
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: 3 + 17 * Math.min(1, level)
                        radius: 1.5
                        color: Colors.primary
                    }
                }
            }
            CustomMarqueeText {
                Layout.preferredWidth: Math.min(implicitWidth, 130)
                content: root.artist !== "" ? root.title + "  —  " + root.artist : root.title
                size: 12
                weight: 600
                customColor: Colors.surfaceText
                scrolling: root.playing
            }
        }
    }

    Component {
        id: underlineComp
        ColumnLayout {
            spacing: 5
            Row {
                spacing: 6
                CustomText {
                    id: uTitle
                    content: root.title
                    size: 12
                    weight: 600
                    customColor: Colors.surfaceText
                    width: Math.min(implicitWidth, 140)
                    elide: Text.ElideRight
                }
                CustomText {
                    visible: root.artist !== ""
                    content: "·  " + root.artist
                    size: 12
                    weight: 500
                    customColor: Colors.outline
                    width: Math.min(implicitWidth, 90)
                    elide: Text.ElideRight
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumWidth: 120
                implicitHeight: 3
                radius: 1.5
                color: Colors.surfaceContainerHighest
                Rectangle {
                    width: parent.width * root.progress
                    height: parent.height
                    radius: 1.5
                    color: Colors.primary
                }
            }
        }
    }

    Component {
        id: discComp
        Item {
            implicitWidth: 34
            implicitHeight: 34

            Item {
                id: disc
                anchors.fill: parent

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Colors.surfaceContainerHighest
                    border.width: 1
                    border.color: Colors.outlineVariant
                }
                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        anchors.centerIn: parent
                        width: 30 - index * 5
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.alpha(Colors.outline, 0.18)
                    }
                }
                ClippingWrapperRectangle {
                    anchors.centerIn: parent
                    implicitWidth: 16
                    implicitHeight: 16
                    radius: 8
                    visible: root.hasTrack
                    color: Colors.primaryContainer
                    Image {
                        source: root.artUrl
                        sourceSize.width: 48
                        sourceSize.height: 48
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        visible: root.artUrl !== ""
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 4
                    height: 4
                    radius: 2
                    color: Colors.surface
                }

                RotationAnimator {
                    target: disc
                    from: disc.rotation
                    to: disc.rotation + 360
                    duration: 6000
                    loops: Animation.Infinite
                    running: root.playing
                }
            }

            MaterialIconSymbol {
                anchors.centerIn: parent
                visible: !root.hasTrack
                content: "music_off"
                iconSize: 14
                customColor: Colors.outline
            }
        }
    }
}
