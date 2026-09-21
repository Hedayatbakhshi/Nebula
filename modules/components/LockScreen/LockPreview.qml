import QtQuick

Item {
    id: root

    property string layoutStyle: "veil"
    property bool greeter: false
    property bool live: false

    readonly property real designWidth: 1920
    readonly property real designHeight: 1080
    readonly property real _scale: Math.min(root.width / root.designWidth, root.height / root.designHeight)
    readonly property string _variant: LockCatalog.normalize(root.layoutStyle)

    clip: true

    Item {
        width: root.designWidth
        height: root.designHeight
        transformOrigin: Item.TopLeft
        scale: root._scale

        LockBackdrop {
            anchors.fill: parent
            preview: !root.live
            style: LockCatalog.backdropFor(root._variant)
        }

        LockLayoutLoader {
            anchors.fill: parent
            variant: root._variant
            preview: !root.live
            greeter: root.greeter
        }
    }
}
