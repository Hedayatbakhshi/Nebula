import QtQuick
import qs.modules.utils

Canvas {
    id: root

    property real value: 0
    property color color: Colors.primary
    property color backColor: Colors.primaryContainer
    property color trackColor: Colors.surfaceContainerHigh
    property color ringColor: Colors.surfaceContainerHighest
    property real ringWidth: 0
    property real amplitude: Math.max(1, root.size * 0.03)
    property real phase: 0

    readonly property real size: Math.min(root.width, root.height)
    property real shown: Math.max(0, Math.min(1, root.value))

    Behavior on shown { SpatialAnim {} }

    onShownChanged: root.requestPaint()
    onColorChanged: root.requestPaint()
    onBackColorChanged: root.requestPaint()
    onTrackColorChanged: root.requestPaint()
    onRingColorChanged: root.requestPaint()
    onPhaseChanged: root.requestPaint()
    onWidthChanged: root.requestPaint()
    onHeightChanged: root.requestPaint()
    onVisibleChanged: if (root.visible) root.requestPaint()

    function wave(ctx, x0, d, level, amp, shift) {
        ctx.beginPath()
        ctx.moveTo(x0, level)
        const steps = 36
        for (let i = 0; i <= steps; i++) {
            const x = x0 + d * i / steps
            ctx.lineTo(x, level + amp * Math.sin((i / steps) * Math.PI * 4 + shift))
        }
        ctx.lineTo(x0 + d, x0 + d + 2)
        ctx.lineTo(x0, x0 + d + 2)
        ctx.closePath()
        ctx.fill()
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const s = root.size
        if (s <= 0)
            return
        const ox = (root.width - s) / 2
        const oy = (root.height - s) / 2
        ctx.translate(ox, oy)
        const rw = root.ringWidth
        if (rw > 0) {
            ctx.fillStyle = root.ringColor
            ctx.beginPath()
            ctx.arc(s / 2, s / 2, s / 2, 0, Math.PI * 2)
            ctx.fill()
        }
        const inner = s / 2 - (rw > 0 ? rw * 2 : 0)
        ctx.save()
        ctx.beginPath()
        ctx.arc(s / 2, s / 2, inner, 0, Math.PI * 2)
        ctx.clip()
        ctx.fillStyle = root.trackColor
        ctx.fillRect(0, 0, s, s)
        const x0 = s / 2 - inner
        const d = inner * 2
        const level = x0 + d * (1 - root.shown)
        const amp = root.shown <= 0.001 || root.shown >= 0.999 ? 0 : root.amplitude
        ctx.fillStyle = root.backColor
        root.wave(ctx, x0, d, level + amp * 0.6, amp, root.phase + Math.PI * 0.7)
        ctx.fillStyle = root.color
        root.wave(ctx, x0, d, level + amp, amp, root.phase)
        ctx.restore()
    }
}
