import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

Item {
    id: root

    required property Item launcher
    readonly property Item appView: grid

    readonly property bool showFavs: root.height >= 520 && !root.launcher.searching && root.launcher.isApps
    readonly property int favCount: Math.max(3, Math.min(6, Math.floor(root.width / 86)))
    readonly property var favs: root.launcher.favourites(root.favCount)
    readonly property var shapes: [
        MaterialShapeFn.getCookie9Sided(), MaterialShapeFn.getClover4Leaf(), MaterialShapeFn.getCircle(),
        MaterialShapeFn.getCookie6Sided(), MaterialShapeFn.getSoftBurst(), MaterialShapeFn.getPuffy()
    ]
    readonly property var fills: [Colors.primaryContainer, Colors.tertiaryContainer, Colors.secondaryContainer,
                                  Colors.primaryContainer, Colors.tertiaryContainer, Colors.secondaryContainer]

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            LauncherSearch {
                launcher: root.launcher
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                radius: 28
                fontSize: 16
            }

            Rectangle {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                radius: 18
                color: sortArea.containsMouse ? Colors.primaryContainer : Colors.secondaryContainer

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: ServiceLauncher.sortMode === "used" ? "trending_up" : "sort_by_alpha"
                    iconSize: 22
                    customColor: sortArea.containsMouse ? Colors.primaryContainerText : Colors.secondaryContainerText
                }

                MouseArea {
                    id: sortArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SettingsConfig.general = Object.assign({}, SettingsConfig.general,
                        { launcherSort: ServiceLauncher.sortMode === "used" ? "az" : "used" })
                }

                CustomToolTip {
                    content: ServiceLauncher.sortMode === "used" ? "Most used first" : "A to Z"
                    visible: sortArea.containsMouse
                }
            }
        }

        ColumnLayout {
            visible: root.showFavs && root.favs.length > 0
            Layout.fillWidth: true
            spacing: 10

            CustomText {
                content: "Favourites"
                size: 26
                weight: 800
                renderType: Text.QtRendering
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: root.favs
                    delegate: Item {
                        id: fav
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        Layout.maximumWidth: Number.POSITIVE_INFINITY
                        Layout.preferredHeight: 100

                        MaterialShapes.ShapeCanvas {
                            id: shape
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: (76 - height) / 2
                            width: favArea.containsMouse ? 82 : 76
                            height: width
                            Behavior on width { SpatialAnim { speed: "fast" } }
                            roundedPolygon: root.shapes[fav.index % root.shapes.length]
                            color: root.fills[fav.index % root.fills.length]
                        }
                        LauncherIcon {
                            anchors.centerIn: shape
                            app: fav.modelData
                            size: 48
                            width: favArea.containsMouse ? 44 : 40
                            height: width
                            mipmap: true
                            Behavior on width { SpatialAnim { speed: "fast" } }
                        }
                        CustomText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            width: parent.width - 4
                            horizontalAlignment: Text.AlignHCenter
                            content: fav.modelData.name.split(" ")[0]
                            size: 11
                            weight: 600
                            elide: Text.ElideRight
                        }
                        MouseArea {
                            id: favArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: event => {
                                if (event.button === Qt.RightButton) root.launcher.openMenu(favArea, event.x, event.y, fav.modelData)
                                else root.launcher.launch(fav.modelData)
                            }
                        }
                    }
                }
            }
        }

        Flickable {
            visible: root.launcher.isApps && root.launcher.availableCategories.length > 1
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            contentWidth: chips.implicitWidth
            contentHeight: height
            clip: true
            interactive: contentWidth > width
            boundsBehavior: Flickable.StopAtBounds

            M3ButtonGroup {
                id: chips
                height: 34
                model: root.launcher.availableCategories
                activeCheck: function(value) { return value === root.launcher.selectedCategory }
                onSegmentClicked: value => root.launcher.selectCategory(value)
                inactiveColor: Colors.surfaceContainerHigh
            }
        }

        LauncherModeArea {
            launcher: root.launcher
            visible: !root.launcher.isApps
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        LauncherGrid {
            id: grid
            visible: root.launcher.isApps
            launcher: root.launcher
            Layout.fillWidth: true
            Layout.fillHeight: true
            apps: root.launcher.filteredApps
            iconSize: ServiceLauncher.iconSize + 10
            minCell: iconSize + 56
            plate: "shape"
        }
    }
}
