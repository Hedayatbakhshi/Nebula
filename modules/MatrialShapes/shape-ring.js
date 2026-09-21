.pragma library

function ringPoints(cubics, size, strokeWidth) {
    const inset = strokeWidth / 2
    const span = size - strokeWidth
    const steps = 16
    const pts = []
    for (let k = 0; k < cubics.length; k++) {
        const c = cubics[k]
        for (let i = 0; i < steps; i++) {
            const t = i / steps
            const u = 1 - t
            const x = u * u * u * c.anchor0X + 3 * u * u * t * c.control0X
                    + 3 * u * t * t * c.control1X + t * t * t * c.anchor1X
            const y = u * u * u * c.anchor0Y + 3 * u * u * t * c.control0Y
                    + 3 * u * t * t * c.control1Y + t * t * t * c.anchor1Y
            pts.push({ x: inset + x * span, y: inset + y * span })
        }
    }
    if (pts.length < 3)
        return []

    let area = 0
    for (let i = 0; i < pts.length; i++) {
        const a = pts[i]
        const b = pts[(i + 1) % pts.length]
        area += a.x * b.y - b.x * a.y
    }
    if (area < 0) pts.reverse()

    let top = Infinity
    for (let i = 0; i < pts.length; i++) top = Math.min(top, pts[i].y)
    const cx = inset + span / 2
    let start = 0
    let best = Infinity
    for (let i = 0; i < pts.length; i++) {
        const d = (pts[i].x - cx) * (pts[i].x - cx) + (pts[i].y - top) * (pts[i].y - top)
        if (d < best) { best = d; start = i }
    }
    const ring = pts.slice(start).concat(pts.slice(0, start))
    ring.push(ring[0])
    return ring
}

function cumulative(ring) {
    const lens = [0]
    let total = 0
    for (let i = 1; i < ring.length; i++) {
        total += Math.hypot(ring[i].x - ring[i - 1].x, ring[i].y - ring[i - 1].y)
        lens.push(total)
    }
    return { lens: lens, total: total }
}

function progressAt(ring, px, py) {
    if (!ring || ring.length < 3)
        return -1
    const cum = cumulative(ring)
    if (cum.total <= 0)
        return -1

    let bestD = Infinity
    let bestLen = 0
    for (let i = 1; i < ring.length; i++) {
        const a = ring[i - 1]
        const b = ring[i]
        const dx = b.x - a.x
        const dy = b.y - a.y
        const seg = dx * dx + dy * dy
        let t = seg > 0 ? ((px - a.x) * dx + (py - a.y) * dy) / seg : 0
        t = Math.max(0, Math.min(1, t))
        const qx = a.x + dx * t
        const qy = a.y + dy * t
        const d = (px - qx) * (px - qx) + (py - qy) * (py - qy)
        if (d < bestD) {
            bestD = d
            bestLen = cum.lens[i - 1] + Math.hypot(qx - a.x, qy - a.y)
        }
    }
    return Math.max(0, Math.min(1, bestLen / cum.total))
}

function pointAt(ring, progress) {
    if (!ring || ring.length < 2)
        return null
    const cum = cumulative(ring)
    if (cum.total <= 0)
        return null
    const want = Math.max(0, Math.min(1, progress)) * cum.total
    for (let i = 1; i < ring.length; i++) {
        if (cum.lens[i] >= want) {
            const a = ring[i - 1]
            const b = ring[i]
            const segLen = cum.lens[i] - cum.lens[i - 1]
            const t = segLen > 0 ? (want - cum.lens[i - 1]) / segLen : 0
            return { x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t }
        }
    }
    return ring[ring.length - 1]
}

function nearRing(ring, px, py, tolerance) {
    if (!ring || ring.length < 3)
        return false
    let bestD = Infinity
    for (let i = 1; i < ring.length; i++) {
        const a = ring[i - 1]
        const b = ring[i]
        const dx = b.x - a.x
        const dy = b.y - a.y
        const seg = dx * dx + dy * dy
        let t = seg > 0 ? ((px - a.x) * dx + (py - a.y) * dy) / seg : 0
        t = Math.max(0, Math.min(1, t))
        const qx = a.x + dx * t
        const qy = a.y + dy * t
        bestD = Math.min(bestD, Math.hypot(px - qx, py - qy))
    }
    return bestD <= tolerance
}
