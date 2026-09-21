import QtQuick
import "shapes/morph.js" as Morph
import "shape-ring.js" as Ring

Canvas {
    id: root
    property color color: "#685496"
    property var roundedPolygon: null
    property bool polygonIsNormalized: true
    property real borderWidth: 0
    property color borderColor: color
    property bool debug: false
    // When true, scales the normalized shape to fill the full width × height instead of min(w,h) × min(w,h)
    property bool stretchToFill: false

    property real strokeProgress: -1
    property real strokeWidth: 4
    property color strokeColor: color
    property color strokeTrackColor: "transparent"

    function ringFor(size) {
        if (!root.roundedPolygon)
            return []
        const cubics = root.morph.asCubics(root.progress)
        if (!cubics || cubics.length === 0)
            return []
        return Ring.ringPoints(cubics, size, root.strokeWidth)
    }

    function progressAt(px, py) {
        return Ring.progressAt(root.ringFor(Math.min(root.width, root.height)), px, py)
    }

    function pointAtProgress(p) {
        return Ring.pointAt(root.ringFor(Math.min(root.width, root.height)), p)
    }

    function nearRing(px, py, tolerance) {
        return Ring.nearRing(root.ringFor(Math.min(root.width, root.height)), px, py, tolerance)
    }

    function paintRing(ctx, cubics, size) {
        const ring = Ring.ringPoints(cubics, size, root.strokeWidth)
        if (ring.length < 3) return

        ctx.lineWidth = root.strokeWidth
        ctx.lineCap = "round"
        ctx.lineJoin = "round"

        ctx.strokeStyle = root.strokeTrackColor
        ctx.beginPath()
        ctx.moveTo(ring[0].x, ring[0].y)
        for (let i = 1; i < ring.length; i++) ctx.lineTo(ring[i].x, ring[i].y)
        ctx.stroke()

        const progress = Math.max(0, Math.min(1, root.strokeProgress))
        if (progress <= 0) return

        const lengths = []
        let total = 0
        for (let i = 1; i < ring.length; i++) {
            const l = Math.hypot(ring[i].x - ring[i - 1].x, ring[i].y - ring[i - 1].y)
            lengths.push(l)
            total += l
        }

        let remaining = total * progress
        ctx.strokeStyle = root.strokeColor
        ctx.beginPath()
        ctx.moveTo(ring[0].x, ring[0].y)
        for (let i = 1; i < ring.length && remaining > 0; i++) {
            const l = lengths[i - 1]
            if (l <= remaining) {
                ctx.lineTo(ring[i].x, ring[i].y)
                remaining -= l
            } else {
                const f = remaining / l
                ctx.lineTo(ring[i - 1].x + f * (ring[i].x - ring[i - 1].x),
                           ring[i - 1].y + f * (ring[i].y - ring[i - 1].y))
                remaining = 0
            }
        }
        ctx.stroke()
    }

    // Internals: size
    property var bounds: roundedPolygon.calculateBounds()
    implicitWidth: bounds[2] - bounds[0]
    implicitHeight: bounds[3] - bounds[1]

    // Internals: anim
    property var prevRoundedPolygon: null
    property double progress: 1
    property var morph: new Morph.Morph(roundedPolygon, roundedPolygon)
    property Animation animation: NumberAnimation {
        duration: 350
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.42, 1.67, 0.21, 0.90, 1, 1] // Material 3 Expressive fast spatial (https://m3.material.io/styles/motion/overview/specs)
    }
    
    onRoundedPolygonChanged: {
        delete root.morph
        root.morph = new Morph.Morph(root.prevRoundedPolygon ?? root.roundedPolygon, root.roundedPolygon)
        morphBehavior.enabled = false;
        root.progress = 0
        morphBehavior.enabled = true;
        root.progress = 1
        root.prevRoundedPolygon = root.roundedPolygon
    }

    Behavior on progress {
        id: morphBehavior
        animation: root.animation
    }

    Component.onCompleted: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()
    onProgressChanged: requestPaint()
    onColorChanged: requestPaint()
    onBorderWidthChanged: requestPaint()
    onBorderColorChanged: requestPaint()
    onDebugChanged: requestPaint()
    onStrokeProgressChanged: requestPaint()
    onStrokeColorChanged: requestPaint()
    onStrokeTrackColorChanged: requestPaint()
    onStrokeWidthChanged: requestPaint()
    onPaint: {
        var ctx = getContext("2d")
        ctx.fillStyle = root.color
        ctx.clearRect(0, 0, width, height)
        if (!root.morph) return
        const cubics = root.morph.asCubics(root.progress)
        if (cubics.length === 0) return

        const size = Math.min(root.width, root.height)

        if (root.strokeProgress >= 0) {
            root.paintRing(ctx, cubics, size)
            return
        }

        ctx.save()
        if (root.polygonIsNormalized) {
            if (root.stretchToFill)
                ctx.scale(root.width, root.height)
            else
                ctx.scale(size, size)
        }

        ctx.beginPath()
        ctx.moveTo(cubics[0].anchor0X, cubics[0].anchor0Y)
        for (const cubic of cubics) {
            ctx.bezierCurveTo(
                cubic.control0X, cubic.control0Y,
                cubic.control1X, cubic.control1Y,
                cubic.anchor1X, cubic.anchor1Y
            )
        }
        ctx.closePath()
        ctx.fill()

        if (root.borderWidth > 0) {
            ctx.strokeStyle = root.borderColor
            ctx.lineWidth = root.borderWidth
            ctx.stroke()
        }

        if (root.debug) {
            const points = []
            for (let i = 0; i < cubics.length; ++i) {
                const c = cubics[i]
                if (i === 0)
                    points.push({ x: c.anchor0X, y: c.anchor0Y })
                points.push({ x: c.anchor1X, y: c.anchor1Y })
            }

            let radius = 2

            ctx.fillStyle = "red"
            for (const p of points) {
                ctx.beginPath()
                ctx.arc(p.x, p.y, radius, 0, Math.PI * 2)
                ctx.fill()
            }
        }

        ctx.restore()
    }
}