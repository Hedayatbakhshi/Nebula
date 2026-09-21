import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn
import "../../MatrialShapes/shape-library.js" as ShapeLibrary

WidgetHost {
    id: root
    configKey: "statStack"
    tile: WidgetSizes.small
    resizable: true
    minSpan: Qt.size(2, 2)
    maxSpan: Qt.size(3, 3)
    defaultPos: Qt.point(880, 200)

    readonly property var si: root.preview ? PreviewData : ServiceSystemInfo

    Component.onCompleted: root.si.retain()
    Component.onDestruction: root.si.release()

    function fraction(key) {
        if (key === "cpu") return root.si.cpuUsage
        if (key === "ram") return root.si.memUsage
        if (key === "disk") return root.si.diskUsage
        return Math.min(1, root.si.cpuTemp / 100)
    }

    function reading(key) {
        if (key === "temp") return Math.round(root.si.cpuTemp) + "°"
        return Math.round(root.fraction(key) * 100) + "%"
    }

    function tint(key) {
        if (key === "ram") return Colors.tertiary
        if (key === "disk") return Colors.secondary
        return Colors.primary
    }

    readonly property string shapeLock: SettingsConfig.widgets.statStackShapeLock ?? ""

    optionsComponent: Component {
        ShapePicker {
            selected: root.shapeLock
            autoHint: "Each stat has its own shape"
            onPicked: name => SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets, { statStackShapeLock: name })
        }
    }

    function shapeFor(key) {
        if (root.shapeLock !== "") return ShapeLibrary.get(root.shapeLock) ?? MaterialShapeFn.getCircle()
        if (key === "cpu") return MaterialShapeFn.getClover4Leaf()
        if (key === "ram") return MaterialShapeFn.getPentagon()
        if (key === "disk") return MaterialShapeFn.getGem()
        return MaterialShapeFn.getCookie6Sided()
    }

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: WidgetSizes.cardColor

        GridLayout {
            anchors.fill: parent
            anchors.margins: 14
            columns: 2
            rowSpacing: 6
            columnSpacing: 10

            Repeater {
                model: ["cpu", "ram", "disk", "temp"]

                delegate: ColumnLayout {
                    id: cell
                    required property string modelData
                    readonly property real value: Math.max(0, Math.min(1, root.fraction(modelData)))
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2

                    Item {
                        id: holder
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        readonly property real side: Math.min(width, height)

                        MaterialShapes.ShapeCanvas {
                            id: track
                            anchors.centerIn: parent
                            width: holder.side
                            height: holder.side
                            roundedPolygon: root.shapeFor(cell.modelData)
                            color: Qt.alpha(root.tint(cell.modelData), 0.18)
                        }

                        Item {
                            x: track.x
                            width: track.width
                            height: track.height * cell.value
                            y: track.y + track.height - height
                            clip: true

                            Behavior on height { SpatialAnim { speed: "slow" } }

                            MaterialShapes.ShapeCanvas {
                                y: -parent.y + track.y
                                width: track.width
                                height: track.height
                                roundedPolygon: root.shapeFor(cell.modelData)
                                color: root.tint(cell.modelData)
                            }
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 5

                        CustomText {
                            content: cell.modelData.toUpperCase()
                            size: 10
                            weight: 600
                            customColor: Colors.outline
                            font.letterSpacing: 1
                        }
                        CustomText {
                            content: root.reading(cell.modelData)
                            size: 12
                            weight: 700
                            customColor: Colors.surfaceText
                        }
                    }
                }
            }
        }
    }
}
