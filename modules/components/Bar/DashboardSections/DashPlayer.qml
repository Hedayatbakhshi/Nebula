import QtQuick
import Quickshell.Widgets
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services

DashItem {
    id: root

    card: true
    cardColor: root.hasTrack ? Colors.secondaryContainer : Colors.surfaceContainerHigh

    readonly property bool hasTrack: ServiceMusic.activePlayer !== null
    readonly property string title: root.hasTrack ? (ServiceMusic.activeTrack?.title ?? "") : "Nothing playing"
    readonly property string artist: root.hasTrack ? (ServiceMusic.activeTrack?.artist ?? "") : "Start something to see it here"
    readonly property string album: ServiceMusic.activeTrack?.album ?? ""
    readonly property string artUrl: ServiceMusic.activeTrack?.artUrl ?? ""
    readonly property real position: ServiceMusic.activePlayer?.position ?? 0
    readonly property real progress: ServiceMusic.trackLength > 0
        ? Math.max(0, Math.min(1, root.position / ServiceMusic.trackLength)) : 0

    readonly property string mode: root.height < 90 ? "strip" : root.width >= 380 && root.height >= 150 ? "large" : "card"
    readonly property color onCard: root.hasTrack ? Colors.secondaryContainerText : Colors.surfaceText

    component Art: ClippingRectangle {
        id: art
        property real side: 40
        width: art.side
        height: art.side
        radius: art.side >= 120 ? 20 : art.side >= 50 ? 14 : 12
        color: Colors.surfaceContainerHighest

        MaterialIconSymbol {
            anchors.centerIn: parent
            visible: root.artUrl === ""
            content: "music_note"
            iconSize: Math.round(art.side * 0.5)
            customColor: Colors.outline
        }

        Image {
            anchors.fill: parent
            visible: root.artUrl !== ""
            source: root.artUrl
            sourceSize.width: 320
            sourceSize.height: 320
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
        }
    }

    component Btn: Rectangle {
        id: btn
        property string icon: ""
        property bool main: false
        property bool can: true
        signal hit
        implicitHeight: 44
        radius: height / 2
        opacity: btn.can ? 1 : 0.4
        color: btn.main ? Colors.primary
            : btnArea.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh

        MaterialIconSymbol {
            anchors.centerIn: parent
            content: btn.icon
            iconSize: btn.main ? 24 : 22
            customColor: btn.main ? Colors.primaryText : Colors.surfaceText
        }

        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.can && root.hasTrack
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.hit()
        }
    }

    component Transport: Row {
        id: tr
        property real avail: 200
        readonly property real side: Math.min(64, (tr.avail - 12) / 4.2)
        spacing: 6

        Btn {
            width: tr.side
            height: Math.min(44, tr.side * 0.8 + 8)
            icon: "skip_previous"
            can: ServiceMusic.canGoPrevious
            onHit: ServiceMusic.previous()
        }
        Btn {
            width: tr.avail - tr.side * 2 - 12
            height: Math.min(44, tr.side * 0.8 + 8)
            main: true
            icon: ServiceMusic.isPlaying ? "pause" : "play_arrow"
            can: ServiceMusic.canTogglePlaying
            onHit: ServiceMusic.togglePlaying()
        }
        Btn {
            width: tr.side
            height: Math.min(44, tr.side * 0.8 + 8)
            icon: "skip_next"
            can: ServiceMusic.canGoNext
            onHit: ServiceMusic.next()
        }
    }

    component Wave: M3WavyProgressBar {
        height: 14
        progress: root.progress
        activeThickness: 4
        trackThickness: 4
        waveAmplitude: ServiceMusic.isPlaying ? 3 : 0
        activeColor: Colors.primary
        trackColor: Qt.alpha(root.onCard, 0.18)
    }

    Item {
        visible: root.mode === "strip"
        anchors.fill: parent
        anchors.margins: 8

        Art {
            id: stripArt
            anchors.verticalCenter: parent.verticalCenter
            side: Math.min(40, parent.height)
        }

        Column {
            anchors.left: stripArt.right
            anchors.leftMargin: 10
            anchors.right: stripPlay.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter

            CustomText {
                width: parent.width
                content: root.title
                size: 13
                weight: 700
                customColor: root.onCard
            }
            CustomText {
                width: parent.width
                content: root.artist
                size: 11
                weight: 500
                customColor: Qt.alpha(root.onCard, 0.75)
            }
        }

        Btn {
            id: stripPlay
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 52
            height: Math.min(38, parent.height)
            main: true
            icon: ServiceMusic.isPlaying ? "pause" : "play_arrow"
            can: ServiceMusic.canTogglePlaying
            onHit: ServiceMusic.togglePlaying()
        }
    }

    Item {
        visible: root.mode === "card"
        anchors.fill: parent
        anchors.margins: 14

        Art {
            id: cardArt
            side: Math.min(52, parent.height * 0.34)
        }

        Column {
            anchors.left: cardArt.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.verticalCenter: cardArt.verticalCenter

            CustomText {
                width: parent.width
                content: root.title
                size: 16
                weight: 700
                customColor: root.onCard
            }
            CustomText {
                width: parent.width
                content: root.artist
                size: 12
                weight: 500
                customColor: Qt.alpha(root.onCard, 0.75)
            }
        }

        Column {
            visible: root.hasTrack && parent.height >= 130
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: cardTransport.top
            anchors.bottomMargin: 8
            spacing: 2

            Wave { width: parent.width }

            Item {
                visible: ServiceMusic.trackLength > 0
                width: parent.width
                height: 14
                CustomText {
                    content: ServiceMusic.formatTime(root.position)
                    size: 11
                    weight: 500
                    customColor: Qt.alpha(root.onCard, 0.75)
                }
                CustomText {
                    anchors.right: parent.right
                    content: ServiceMusic.formatTime(ServiceMusic.trackLength)
                    size: 11
                    weight: 500
                    customColor: Qt.alpha(root.onCard, 0.75)
                }
            }
        }

        Transport {
            id: cardTransport
            anchors.bottom: parent.bottom
            avail: parent.width
        }
    }

    Item {
        visible: root.mode === "large"
        anchors.fill: parent
        anchors.margins: 14

        Art {
            id: largeArt
            side: parent.height
        }

        Item {
            anchors.left: largeArt.right
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Column {
                width: parent.width
                spacing: 4

                Row {
                    visible: root.hasTrack
                    spacing: 5
                    MaterialIconSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        content: "music_note"
                        iconSize: 14
                        customColor: Qt.alpha(root.onCard, 0.75)
                    }
                    CustomText {
                        anchors.verticalCenter: parent.verticalCenter
                        content: ServiceMusic.activeTrack?.identity ?? ""
                        size: 12
                        weight: 500
                        customColor: Qt.alpha(root.onCard, 0.75)
                    }
                }
                CustomText {
                    width: parent.width
                    content: root.title
                    size: 19
                    weight: 700
                    customColor: root.onCard
                }
                CustomText {
                    width: parent.width
                    content: root.album !== "" && root.hasTrack ? root.artist + ", " + root.album : root.artist
                    size: 13
                    weight: 500
                    customColor: Qt.alpha(root.onCard, 0.75)
                }
            }

            Wave {
                visible: root.hasTrack
                anchors.bottom: largeTransport.top
                anchors.bottomMargin: 10
                width: Math.min(parent.width, 220)
            }

            Transport {
                id: largeTransport
                anchors.bottom: parent.bottom
                avail: Math.min(parent.width, 220)
            }
        }
    }
}
