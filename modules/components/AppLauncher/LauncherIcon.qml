import QtQuick
import QtQuick.Layouts
import qs.modules.utils

Image {
    id: root

    property var app: null
    property int size: 32

    Layout.preferredWidth: root.size
    Layout.preferredHeight: root.size
    width: root.size
    height: root.size
    sourceSize.width: root.size
    sourceSize.height: root.size
    source: IconUtil.getIconPath(root.app?.icon ?? "")
    fillMode: Image.PreserveAspectFit
    asynchronous: true
}
