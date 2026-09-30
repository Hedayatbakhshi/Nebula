import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root

    property Item host: null
    property string itemId: ""
    property string fallbackStyle: "pill"

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

    readonly property var panelKinds: ({ side: "music", wave: "musicWave", island: "musicIsland",
                                         fill: "musicFill", type: "musicType", sources: "musicSources" })

    readonly property bool inDock: root.host && root.host.iconSize ? true : false
    readonly property real h: root.inDock ? root.host.iconSize + 14 : Appearance.size.barHeight
    readonly property real art: Math.max(20, Math.min(30, root.h - 18))

    readonly property bool shown: root.hasTrack || !root.hideIdle
    readonly property bool vertical: !!root.host && root.host.vertical === true
    readonly property bool verticalReady: true

    implicitWidth: root.vertical ? root.h : face.item ? face.item.implicitWidth : 0
    implicitHeight: root.vertical ? (face.item ? face.item.implicitHeight : 0) : root.h

    Loader {
        id: face
        anchors.centerIn: parent
        sourceComponent: {
            if (root.vertical)
                return root.hasTrack ? columnComp : columnIdleComp
            if (!root.hasTrack)
                return root.style === "island" ? islandComp : idleComp
            switch (root.style) {
            case "wave":    return waveComp
            case "island":  return islandComp
            case "fill":    return fillComp
            case "type":    return typeComp
            case "sources": return sourcesComp
            }
            return pillComp
        }
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered && root.host)
                root.host.hoverOpen(root.panelKinds[root.panelStyle] ?? "music", root)
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
        id: columnComp
        Rectangle {
            implicitWidth: root.h - 10
            implicitHeight: col.implicitHeight + 8
            radius: implicitWidth / 2
            color: Colors.surfaceContainerHigh

            Column {
                id: col
                anchors.centerIn: parent
                spacing: 4
                Art {
                    anchors.horizontalCenter: parent.horizontalCenter
                    side: root.h - 18
                    radius: (root.h - 18) / 2
                }
                Btn {
                    anchors.horizontalCenter: parent.horizontalCenter
                    icon: root.playing ? "pause" : "play_arrow"
                    primary: true
                    side: root.h - 18
                    onTapped: ServiceMusic.togglePlaying()
                }
            }
        }
    }

    Component {
        id: columnIdleComp
        Rectangle {
            implicitWidth: 24
            implicitHeight: 24
            radius: 12
            color: Colors.surfaceContainerHigh
            MaterialIconSymbol {
                anchors.centerIn: parent
                content: "music_off"
                iconSize: 14
                customColor: Colors.outline
            }
        }
    }

    Component {
        id: waveComp
        RowLayout {
            spacing: 9
            Btn {
                icon: root.playing ? "pause" : "play_arrow"
                primary: true
                side: 28
                onTapped: ServiceMusic.togglePlaying()
            }
            MusicWaveform {
                Layout.preferredHeight: root.h - 18
                bars: 26
                barWidth: 3
                gap: 2
            }
            CustomText {
                id: waveTime
                Layout.preferredWidth: Math.ceil(waveTimeSlot.width) + 2
                content: ServiceMusic.formatTime(ServiceMusic.activePlayer?.position ?? 0)
                size: 11
                weight: 500
                customColor: Colors.outline
                elide: Text.ElideNone
                font.features: { "tnum": 1 }

                TextMetrics {
                    id: waveTimeSlot
                    font: waveTime.font
                    text: waveTime.text.replace(/[0-9]/g, "0")
                }
            }
        }
    }

    Component {
        id: islandComp
        Rectangle {
            implicitWidth: islandRow.implicitWidth + 16
            implicitHeight: root.h - 10
            radius: implicitHeight / 2
            color: "#000000"

            RowLayout {
                id: islandRow
                anchors.verticalCenter: parent.verticalCenter
                x: 5
                spacing: 8

                Art {
                    visible: root.hasTrack
                    side: root.h - 18
                    radius: (root.h - 18) / 2
                }

                MaterialIconSymbol {
                    visible: !root.hasTrack
                    Layout.leftMargin: 4
                    content: "music_off"
                    iconSize: 14
                    customColor: Colors.outline
                }

                MusicEqualizer {
                    Layout.rightMargin: 2
                    barColor: Colors.tertiary
                    active: root.playing
                }
            }
        }
    }

    Component {
        id: fillComp
        ClippingRectangle {
            implicitWidth: 210
            implicitHeight: root.h - 10
            radius: implicitHeight / 2
            color: Colors.surfaceContainerHighest

            Rectangle {
                width: parent.width * root.progress
                height: parent.height
                color: Colors.secondaryContainer
                Behavior on width {
                    enabled: root.playing
                    SmoothedAnimation { velocity: 240 }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                spacing: 8

                Art {
                    side: root.h - 18
                    radius: (root.h - 18) / 2
                }
                CustomText {
                    Layout.maximumWidth: 120
                    content: root.title
                    size: 12
                    weight: 600
                    customColor: Colors.secondaryContainerText
                    elide: Text.ElideRight
                }
                CustomText {
                    Layout.fillWidth: true
                    visible: root.artist !== ""
                    content: root.artist
                    size: 11
                    customColor: Colors.outline
                    elide: Text.ElideRight
                }
                Item {
                    Layout.fillWidth: true
                    visible: root.artist === ""
                }
                Btn {
                    icon: root.playing ? "pause" : "play_arrow"
                    primary: true
                    side: root.h - 18
                    onTapped: ServiceMusic.togglePlaying()
                }
            }
        }
    }

    Component {
        id: typeComp
        RowLayout {
            spacing: 8

            MusicEqualizer {
                Layout.preferredHeight: 12
                bars: 3
                barWidth: 3
                barSpacing: 2
                active: root.playing
            }

            Item {
                id: typeTitle
                Layout.preferredWidth: Math.min(typeBase.implicitWidth, 170)
                Layout.preferredHeight: typeBase.implicitHeight

                CustomText {
                    id: typeBase
                    width: parent.width
                    content: root.title
                    size: 13
                    weight: 700
                    customColor: Colors.outline
                    elide: Text.ElideRight
                }

                Item {
                    width: typeTitle.width * root.progress
                    height: parent.height
                    clip: true
                    Behavior on width {
                        enabled: root.playing
                        SmoothedAnimation { velocity: 240 }
                    }

                    CustomText {
                        width: typeTitle.width
                        content: root.title
                        size: 13
                        weight: 700
                        customColor: Colors.primary
                        elide: Text.ElideRight
                    }
                }
            }

            CustomText {
                Layout.maximumWidth: 90
                visible: root.artist !== ""
                content: root.artist
                size: 11
                customColor: Colors.outline
                elide: Text.ElideRight
            }
        }
    }

    Component {
        id: sourcesComp
        Rectangle {
            id: src
            readonly property var ordered: {
                const all = Mpris.players.values
                const act = ServiceMusic.activePlayer
                const rest = all.filter(p => p !== act)
                return act ? [act].concat(rest) : rest
            }
            implicitWidth: srcRow.implicitWidth + 13
            implicitHeight: root.h - 10
            radius: implicitHeight / 2
            color: Colors.surfaceContainerHigh

            RowLayout {
                id: srcRow
                anchors.verticalCenter: parent.verticalCenter
                x: 3
                spacing: 8

                Row {
                    spacing: -8
                    Repeater {
                        model: src.ordered
                        delegate: Rectangle {
                            id: av
                            required property var modelData
                            required property int index
                            width: root.h - 16
                            height: width
                            radius: width / 2
                            z: 10 - av.index
                            color: av.index === 0 ? Colors.primary : Colors.surfaceContainerHighest
                            border.width: 2
                            border.color: Colors.surfaceContainerHigh

                            MusicPlayerIcon {
                                anchors.centerIn: parent
                                player: av.modelData
                                side: Math.round(av.width * 0.56)
                                glyphColor: av.index === 0 ? Colors.primaryText : Colors.surfaceVariantText
                            }

                            Rectangle {
                                visible: av.modelData.isPlaying
                                x: av.width - 7
                                y: av.height - 7
                                width: 8
                                height: 8
                                radius: 4
                                color: Colors.tertiary
                                border.width: 1.5
                                border.color: Colors.surfaceContainerHigh
                            }
                        }
                    }
                }

                CustomText {
                    Layout.maximumWidth: 150
                    content: root.title
                    size: 12
                    weight: 600
                    customColor: Colors.surfaceText
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: src.ordered.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: src.ordered.length > 1
                onClicked: ServiceMusic.setActivePlayer(src.ordered[1])
            }
        }
    }
}
