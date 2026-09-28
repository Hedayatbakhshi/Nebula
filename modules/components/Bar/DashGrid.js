.pragma library

function overlaps(a, b) {
    return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h
}

function collides(items, cand, ignoreId) {
    for (let i = 0; i < items.length; i++) {
        const it = items[i]
        if (it.id === ignoreId)
            continue
        if (overlaps(it, cand))
            return true
    }
    return false
}

function clampSpan(v, lo, hi) {
    return Math.max(lo, Math.min(hi, Math.round(v)))
}

function clampItem(it, cols, spec) {
    const s = spec || {}
    const minW = Math.min(cols, s.minW || 1)
    const maxW = Math.min(cols, s.maxW || cols)
    const minH = s.minH || 1
    const maxH = s.maxH || 99
    const w = clampSpan(it.w || minW, minW, Math.max(minW, maxW))
    const h = clampSpan(it.h || minH, minH, Math.max(minH, maxH))
    const x = clampSpan(it.x || 0, 0, cols - w)
    const y = Math.max(0, Math.round(it.y || 0))
    return Object.assign({}, it, { x: x, y: y, w: w, h: h })
}

function rowsUsed(items) {
    let r = 0
    for (let i = 0; i < items.length; i++)
        r = Math.max(r, items[i].y + items[i].h)
    return r
}

function nearestFree(items, cand, cols, ignoreId) {
    const w = Math.min(cand.w, cols)
    const h = cand.h
    const tx = Math.max(0, Math.min(cols - w, cand.x))
    const ty = Math.max(0, cand.y)
    const maxY = rowsUsed(items.filter(it => it.id !== ignoreId)) + 1
    let best = null
    let bestD = Infinity
    for (let y = 0; y <= Math.max(maxY, ty); y++) {
        for (let x = 0; x <= cols - w; x++) {
            const c = { x: x, y: y, w: w, h: h }
            if (collides(items, c, ignoreId))
                continue
            const d = (x - tx) * (x - tx) + (y - ty) * (y - ty) * 1.2
            if (d < bestD) {
                bestD = d
                best = c
            }
        }
    }
    return best || { x: 0, y: maxY, w: w, h: h }
}

function firstFree(items, w, h, cols) {
    const ww = Math.min(w, cols)
    const maxY = rowsUsed(items)
    for (let y = 0; y <= maxY; y++) {
        for (let x = 0; x <= cols - ww; x++) {
            const c = { x: x, y: y, w: ww, h: h }
            if (!collides(items, c, null))
                return c
        }
    }
    return { x: 0, y: maxY, w: ww, h: h }
}

function fitSpan(items, it, w, h, cols, spec) {
    const s = spec || {}
    const minW = Math.min(cols, s.minW || 1)
    const minH = s.minH || 1
    const maxW = Math.min(cols - it.x, s.maxW || cols)
    const maxH = s.maxH || 99
    const tw = clampSpan(w, minW, Math.max(minW, maxW))
    const th = clampSpan(h, minH, Math.max(minH, maxH))
    let best = { w: Math.min(it.w, Math.max(minW, maxW)), h: it.h }
    let bestScore = -Infinity
    for (let ww = minW; ww <= tw; ww++) {
        for (let hh = minH; hh <= th; hh++) {
            const c = { x: it.x, y: it.y, w: ww, h: hh }
            if (collides(items, c, it.id))
                continue
            const score = ww * hh * 100 - Math.abs(tw - ww) - Math.abs(th - hh)
            if (score > bestScore) {
                bestScore = score
                best = { w: ww, h: hh }
            }
        }
    }
    return best
}

function normalize(items, cols, specFor) {
    const sorted = items.slice().sort((a, b) => (a.y - b.y) || (a.x - b.x))
    const out = []
    for (let i = 0; i < sorted.length; i++) {
        const c = clampItem(sorted[i], cols, specFor ? specFor(sorted[i].kind) : null)
        if (collides(out, c, c.id)) {
            const f = nearestFree(out, c, cols, c.id)
            c.x = f.x
            c.y = f.y
        }
        out.push(c)
    }
    return out
}

function stack(ids, cols, rowsFor) {
    const out = []
    let y = 0
    for (let i = 0; i < ids.length; i++) {
        const h = Math.max(1, rowsFor(ids[i]))
        out.push({ id: ids[i], kind: ids[i], x: 0, y: y, w: cols, h: h })
        y += h
    }
    return out
}

function move(items, id, x, y, cols) {
    const it = items.find(i => i.id === id)
    if (!it)
        return items
    const spot = nearestFree(items, { x: x, y: y, w: it.w, h: it.h }, cols, id)
    return items.map(i => i.id === id ? Object.assign({}, i, { x: spot.x, y: spot.y }) : i)
}

function resize(items, id, w, h, cols, spec) {
    const it = items.find(i => i.id === id)
    if (!it)
        return items
    const s = fitSpan(items, it, w, h, cols, spec)
    return items.map(i => i.id === id ? Object.assign({}, i, { w: s.w, h: s.h }) : i)
}

function newId(kind, items) {
    const taken = {}
    items.forEach(i => { taken[i.id] = true })
    if (!taken[kind])
        return kind
    let n = 2
    while (taken[kind + "-" + n])
        n++
    return kind + "-" + n
}

function compact(items, pinnedId) {
    const out = []
    const pinned = items.find(i => i.id === pinnedId)
    if (pinned)
        out.push(Object.assign({}, pinned))
    const rest = items.filter(i => i.id !== pinnedId).slice().sort((a, b) => (a.y - b.y) || (a.x - b.x))
    for (let i = 0; i < rest.length; i++) {
        const c = Object.assign({}, rest[i])
        while (c.y > 0 && !collides(out, { x: c.x, y: c.y - 1, w: c.w, h: c.h }, c.id))
            c.y--
        while (collides(out, c, c.id))
            c.y++
        out.push(c)
    }
    return out
}

function push(items, moving, cols) {
    const m = Object.assign({}, moving)
    m.w = Math.max(1, Math.min(cols, m.w))
    m.x = Math.max(0, Math.min(cols - m.w, m.x))
    m.y = Math.max(0, m.y)
    const out = [m]
    const rest = items.filter(i => i.id !== m.id).slice().sort((a, b) => (a.y - b.y) || (a.x - b.x))
    for (let i = 0; i < rest.length; i++) {
        const c = Object.assign({}, rest[i])
        let guard = 0
        while (collides(out, c, c.id) && guard++ < 500) {
            let down = c.y + 1
            for (let k = 0; k < out.length; k++)
                if (overlaps(out[k], c))
                    down = Math.max(down, out[k].y + out[k].h)
            c.y = down
        }
        out.push(c)
    }
    return compact(out, m.id)
}

function settle(items) {
    return compact(items, null)
}

function rowsFor(px, rowH, gap) {
    return Math.max(1, Math.ceil((px + gap) / (rowH + gap)))
}

if (typeof module !== "undefined")
    module.exports = { overlaps, collides, clampItem, rowsUsed, nearestFree, firstFree, fitSpan,
                       normalize, stack, move, resize, newId, rowsFor,
                       compact, push, settle }
