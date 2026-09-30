import QtQuick

Item {
    id: root

    property alias source: img.source
    property alias sourceSize: img.sourceSize
    property alias asynchronous: img.asynchronous
    property alias status: img.status
    property real radius: 28

    Image {
        id: img
        visible: false
        asynchronous: true
    }

    ShaderEffect {
        anchors.fill: parent
        visible: img.status === Image.Ready
        property var source: img
        property vector2d itemSize: Qt.vector2d(width, height)
        property vector2d imageSize: Qt.vector2d(img.implicitWidth, img.implicitHeight)
        property real radius: root.radius
        fragmentShader: Qt.resolvedUrl("../../shaders/qsb/roundimage.frag.qsb")
    }
}
