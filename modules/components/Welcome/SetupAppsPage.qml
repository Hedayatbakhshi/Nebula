import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

ColumnLayout {
    id: page

    required property var store
    property string filter: "all"

    readonly property var installed: page.store.installedApps
    readonly property int pickedCount: page.store.pickedApps.length

    function passes(app) {
        if (page.filter === "all")
            return true
        return page.store.isPicked(app.id) === (page.filter === "picked")
    }

    spacing: 16

    component AppGroup: ColumnLayout {
        id: group

        property string title: ""
        property string key: ""
        property var host: null

        readonly property var all: (group.host ? group.host.installed : []).filter(a => a.group === group.key)
        readonly property var rows: group.all.filter(a => group.host.passes(a))
        readonly property int onCount: group.all.filter(a => group.host.store.isPicked(a.id)).length

        Layout.fillWidth: true
        visible: group.rows.length > 0
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 8
            Layout.bottomMargin: 4

            CustomText {
                Layout.fillWidth: true
                content: group.title
                size: 12
                weight: 700
                font.letterSpacing: 0.6
                customColor: Colors.primary
            }

            CustomText {
                content: group.onCount + " of " + group.all.length
                size: 12
                weight: 400
                customColor: Colors.outline
            }
        }

        Repeater {
            model: group.rows

            SetupAppRow {
                required property var modelData
                required property int index

                app: modelData
                tint: index
                picked: group.host.store.isPicked(modelData.id)
                onToggled: on => group.host.store.setPicked(modelData.id, on)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        M3ButtonGroup {
            Layout.preferredWidth: 380
            Layout.preferredHeight: 36
            fillWidth: true
            textSize: 13
            iconSize: 16
            model: [
                { value: "all",    label: "All " + page.installed.length },
                { value: "picked", label: "Picked " + page.pickedCount },
                { value: "off",    label: "Not picked " + (page.installed.length - page.pickedCount) }
            ]
            activeCheck: v => page.filter === v
            onSegmentClicked: v => page.filter = v
        }

        Item { Layout.fillWidth: true }

        M3Button {
            size: "small"
            variant: "text"
            icon: "done_all"
            label: "Pick all"
            onClicked: page.store.pickAll()
        }

        M3IconButton {
            icon: "refresh"
            implicitWidth: 40
            implicitHeight: 40
            iconSize: 20
            enabledButton: !page.store.scanning
            onClicked: page.store.scan()
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.centerIn: parent
            visible: !page.store.scanned
            spacing: 14

            CustomCircularLoader {
                Layout.alignment: Qt.AlignHCenter
                size: 44
            }

            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: "Looking for your apps"
                size: 14
                weight: 500
                customColor: Colors.surfaceVariantText
            }
        }

        CustomText {
            anchors.centerIn: parent
            visible: page.store.scanned && page.installed.length === 0
            content: "None of the apps Nebula can theme are installed."
            size: 14
            weight: 400
            customColor: Colors.outline
        }

        SetupScroll {
            id: scroll
            anchors.fill: parent
            visible: page.store.scanned && page.installed.length > 0

            RowLayout {
                id: columns
                width: scroll.contentWidthAvail
                spacing: 28

                readonly property real colWidth: (columns.width - columns.spacing) / 2

                ColumnLayout {
                    Layout.preferredWidth: columns.colWidth
                    Layout.alignment: Qt.AlignTop
                    spacing: 18

                    AppGroup { title: "TERMINAL AND SHELL"; key: "terminal"; host: page }

                    Rectangle {
                        Layout.fillWidth: true
                        visible: page.store.missingApps.length > 0 && page.filter === "all"
                        implicitHeight: missingCol.implicitHeight + 24
                        radius: 14
                        color: Colors.surfaceContainerLow

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            MaterialIconSymbol {
                                Layout.alignment: Qt.AlignTop
                                content: "info"
                                iconSize: 18
                                customColor: Colors.outline
                            }

                            ColumnLayout {
                                id: missingCol
                                Layout.fillWidth: true
                                spacing: 4

                                CustomText {
                                    Layout.fillWidth: true
                                    content: "Not found on this system: " + page.store.missingApps.map(a => a.name).join(", ")
                                    size: 13
                                    weight: 400
                                    customColor: Colors.surfaceVariantText
                                    wrapMode: Text.WordWrap
                                }

                                Repeater {
                                    model: page.store.missingApps.filter(a => a.hint !== "")

                                    CustomText {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        content: modelData.name + ": " + modelData.hint
                                        size: 12
                                        weight: 400
                                        customColor: Colors.outline
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: columns.colWidth
                    Layout.alignment: Qt.AlignTop
                    spacing: 18

                    AppGroup { title: "DESKTOP"; key: "desktop"; host: page }
                    AppGroup { title: "APPS"; key: "apps"; host: page }
                }
            }
        }
    }
}
