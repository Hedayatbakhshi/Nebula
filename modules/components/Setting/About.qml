import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import QtQuick.Controls
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 5

    property var info: ({})

    readonly property string home: Quickshell.env("HOME") ?? ""
    readonly property string shellDir: Quickshell.shellDir ?? ""
    readonly property string prettyDir: root.home !== "" && root.shellDir.startsWith(root.home)
        ? "~" + root.shellDir.slice(root.home.length) : root.shellDir

    readonly property string revision: root.info.revision ?? ""
    readonly property bool dirty: root.revision.endsWith("*")

    readonly property var links: [
        { icon: "code",       label: "GitHub",       url: "https://github.com/iamSt3el/Nebula" },
        { icon: "bug_report", label: "Report issue", url: "https://github.com/iamSt3el/Nebula/issues/new" },
        { icon: "star",       label: "Star",         url: "https://github.com/iamSt3el/Nebula" }
    ]

    function shown(v) {
        return (v === undefined || v === null || v === "") ? "—" : v
    }

    readonly property var envTiles: [
        { icon: "deployed_code", label: "Quickshell", value: root.shown(root.info.quickshell) },
        { icon: "grid_view",     label: "Compositor", value: root.shown(root.info.compositor) },
        { icon: "memory",        label: "Kernel",     value: root.shown(root.info.kernel) },
        { icon: "computer",      label: "Distro",     value: root.shown(root.info.distro) }
    ]

    Process {
        id: infoProcess
        command: [Quickshell.shellDir + "/bin/nebula", "about", root.shellDir]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.info = JSON.parse(text)
                } catch (e) {
                    root.info = ({})
                }
            }
        }
    }

    Component.onCompleted: {
        infoProcess.running = true
        ServiceSystemInfo.getUptime()
    }

    Flickable {
        id: pageFlick
        ScrollBar.vertical: CustomScrollBar {}
        anchors.fill: parent
        contentHeight: column.implicitHeight
        contentWidth: width
        clip: true

        ColumnLayout {
            id: column
            width: parent.width
            spacing: 3

            Rectangle {
                Layout.fillWidth: true
                Layout.margins: 5
                implicitHeight: 190
                radius: 28
                color: Colors.primaryContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 28
                    anchors.rightMargin: 28
                    spacing: 24

                    Item {
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 120
                        Layout.alignment: Qt.AlignVCenter

                        MaterialShapes.ShapeCanvas {
                            anchors.fill: parent
                            roundedPolygon: MaterialShapeFn.getCookie9Sided()
                            color: Colors.primaryContainerText
                        }

                        NebulaLogo {
                            anchors.centerIn: parent
                            width: 62
                            height: 62
                            color: Colors.primaryContainer
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 6

                        CustomText {
                            content: "Nebula"
                            size: 44
                            weight: 800
                            customColor: Colors.primaryContainerText
                        }

                        CustomText {
                            Layout.fillWidth: true
                            content: "A modern desktop shell for Wayland"
                            size: 14
                            customColor: Qt.alpha(Colors.primaryContainerText, 0.85)
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.topMargin: 8
                            spacing: 8

                            Rectangle {
                                implicitWidth: versionText.implicitWidth + 24
                                implicitHeight: 30
                                radius: 15
                                color: Colors.primaryContainerText

                                CustomText {
                                    id: versionText
                                    anchors.centerIn: parent
                                    content: "v1.0.0"
                                    size: 12
                                    weight: 700
                                    customColor: Colors.primaryContainer
                                }
                            }

                            Rectangle {
                                visible: root.revision !== ""
                                implicitWidth: revisionRow.implicitWidth + 24
                                implicitHeight: 30
                                radius: 15
                                color: "transparent"
                                border.width: 1
                                border.color: Colors.primaryContainerText

                                RowLayout {
                                    id: revisionRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    MaterialIconSymbol {
                                        content: "commit"
                                        iconSize: 15
                                        customColor: Colors.primaryContainerText
                                    }

                                    CustomText {
                                        content: root.revision.replace("*", "") + (root.dirty ? " · local changes" : "")
                                        size: 12
                                        weight: 600
                                        customColor: Colors.primaryContainerText
                                    }
                                }
                            }
                        }
                    }
                }
            }

            CustomText {
                Layout.topMargin: 18
                Layout.leftMargin: 5
                content: "Running on"
                size: 13
                customColor: Colors.primary
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 5
                Layout.rightMargin: 5
                Layout.topMargin: 3
                columns: 2
                rowSpacing: 3
                columnSpacing: 3

                Repeater {
                    model: root.envTiles
                    delegate: EnvTile {
                        required property var modelData
                        required property int index
                        tile: modelData
                        cell: index
                    }
                }
            }

            CustomText {
                Layout.topMargin: 16
                Layout.leftMargin: 5
                content: "Config"
                size: 13
                customColor: Colors.primary
            }

            CustomCard {
                id: configCard
                Layout.leftMargin: 5
                Layout.rightMargin: 5
                Layout.topMargin: 3
                autoRadius: false
                topRadius: 20
                bottomRadius: 20

                property bool copied: false

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    MaterialIconSymbol {
                        content: "folder"
                        iconSize: 20
                        customColor: Colors.outline
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        CustomText {
                            content: "Location" + (ServiceSystemInfo.uptime ? " · up " + ServiceSystemInfo.uptime : "")
                            size: 11
                            customColor: Colors.outline
                        }

                        CustomText {
                            Layout.fillWidth: true
                            content: root.shown(root.prettyDir)
                            size: 14
                            weight: 600
                            elide: Text.ElideMiddle
                        }
                    }

                    M3IconButton {
                        icon: configCard.copied ? "check" : "content_copy"
                        iconSize: 18
                        implicitWidth: 36
                        implicitHeight: 36
                        onClicked: {
                            Quickshell.clipboardText = root.shellDir
                            configCard.copied = true
                            copyReset.restart()
                        }
                    }

                    M3IconButton {
                        icon: "folder_open"
                        iconSize: 18
                        implicitWidth: 36
                        implicitHeight: 36
                        onClicked: Quickshell.execDetached(["xdg-open", root.shellDir])
                    }
                }

                Timer {
                    id: copyReset
                    interval: 1400
                    onTriggered: configCard.copied = false
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.leftMargin: 5
                Layout.rightMargin: 5
                Layout.bottomMargin: 5
                spacing: 8

                Repeater {
                    model: root.links
                    delegate: M3Button {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        size: "xsmall"
                        variant: "tonal"
                        icon: modelData.icon
                        label: modelData.label
                        onClicked: Quickshell.execDetached(["xdg-open", modelData.url])
                    }
                }

                M3Button {
                    size: "xsmall"
                    variant: "outlined"
                    icon: "restart_alt"
                    label: "Setup"
                    onClicked: {
                        GlobalStates.settingsOpen = false
                        Quickshell.execDetached([Quickshell.shellDir + "/bin/nebula", "setup"])
                    }
                }

                M3Button {
                    size: "xsmall"
                    variant: "outlined"
                    icon: "refresh"
                    label: "Restart"
                    onClicked: Quickshell.reload(true)
                }
            }
        }
    }
    ScrollFade {
        anchors.fill: parent
        flickable: pageFlick
    }

    component EnvTile: Rectangle {
        id: tileRect

        property var tile: ({})
        property int cell: 0

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 68
        color: Colors.surfaceContainerHigh
        topLeftRadius: tileRect.cell === 0 ? 20 : 5
        topRightRadius: tileRect.cell === 1 ? 20 : 5
        bottomLeftRadius: tileRect.cell === 2 ? 20 : 5
        bottomRightRadius: tileRect.cell === 3 ? 20 : 5

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: Colors.secondaryContainer

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: tileRect.tile.icon ?? ""
                    iconSize: 20
                    customColor: Colors.secondaryContainerText
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                CustomText {
                    content: tileRect.tile.label ?? ""
                    size: 11
                    customColor: Colors.outline
                }

                CustomText {
                    Layout.fillWidth: true
                    content: tileRect.tile.value ?? ""
                    size: 15
                    weight: 600
                    elide: Text.ElideRight
                }
            }
        }
    }
}
