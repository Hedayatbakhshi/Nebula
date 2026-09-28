import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "yearAgo"
    tile: WidgetSizes.tall
    defaultPos: Qt.point(145, 385)

    readonly property var pick: root.preview ? null : ServicePersonal.photos.pick
    readonly property string when: {
        if (!root.pick) return ""
        const p = root.pick.date.split("-")
        return Qt.formatDate(new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2])), "d MMM yyyy")
    }

    WidgetCard {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            ClippingRectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: WidgetSizes.radius - 10
                color: Colors.surfaceContainerHigh

                Image {
                    id: shot
                    anchors.fill: parent
                    source: root.pick ? "file://" + root.pick.path : (root.preview ? WallpaperTheme.wallpaper : "")
                    sourceSize.width: 480
                    sourceSize.height: 480
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    visible: !root.preview && !root.pick
                    content: "photo_library"
                    iconSize: 34
                    customColor: Colors.outline
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.preview && !!root.pick
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ServicePersonal.openFile(root.pick.path)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.bottomMargin: 4
                spacing: 0

                CustomText {
                    content: "A year ago"
                    size: 18
                    weight: 500
                    family: "Noto Serif Display"
                }
                CustomText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    size: 12
                    customColor: Colors.surfaceVariantText
                    content: root.preview ? "22 Sep 2025 · 5 screenshots"
                        : root.pick ? root.when + " · " + (root.pick.count === 1 ? "1 screenshot" : root.pick.count + " screenshots")
                        : "Nothing from this week last year"
                }
                CustomText {
                    size: 11
                    customColor: Colors.outline
                    content: root.preview ? "469 since then" : (ServicePersonal.photos.since ?? 0) + " since then"
                    visible: root.preview || !!root.pick
                }
            }
        }
    }
}
