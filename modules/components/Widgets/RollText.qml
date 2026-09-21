import QtQuick
import qs.modules.utils

Item {
    id: root

    property string text: ""
    property string family: "Rubik"
    property int pixelSize: 40
    property int weight: 600
    property color color: Colors.surfaceText
    property real letterSpacing: 0
    property real lineHeight: 1
    property real travel: root.pixelSize * 0.32
    property bool animated: true
    property int horizontalAlignment: Text.AlignLeft

    property bool _b: false
    property bool _ready: false
    readonly property Text _cur: root._b ? tb : ta

    implicitWidth: root._cur.implicitWidth
    implicitHeight: root._cur.implicitHeight
    clip: false

    component Face: Text {
        width: root.width
        horizontalAlignment: root.horizontalAlignment
        color: root.color
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        font.letterSpacing: root.letterSpacing
        font.features: { "tnum": 1 }
        lineHeight: root.lineHeight
        renderType: Text.QtRendering
    }

    Face { id: ta }
    Face { id: tb; opacity: 0 }

    Component.onCompleted: {
        ta.text = root.text
        root._ready = true
    }

    onTextChanged: {
        if (!root._ready)
            return
        const out = root._cur
        const inn = root._b ? ta : tb
        inn.text = root.text
        if (!root.animated) {
            out.opacity = 0
            inn.opacity = 1
            inn.y = 0
            root._b = !root._b
            return
        }
        outY.target = out; outO.target = out
        inY.target = inn; inO.target = inn
        root._b = !root._b
        swap.restart()
    }

    ParallelAnimation {
        id: swap
        NumberAnimation { id: outY; property: "y"; from: 0; to: -root.travel; duration: 260; easing.type: Easing.InCubic }
        NumberAnimation { id: outO; property: "opacity"; from: 1; to: 0; duration: 200; easing.type: Easing.InCubic }
        NumberAnimation { id: inY; property: "y"; from: root.travel; to: 0; duration: 520; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1, 1] }
        NumberAnimation { id: inO; property: "opacity"; from: 0; to: 1; duration: 360; easing.type: Easing.OutCubic }
    }
}
