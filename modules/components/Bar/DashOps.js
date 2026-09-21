.pragma library

function dropIndex(rects, from, center) {
    let k = 0
    for (let i = 0; i < rects.length; i++) {
        if (i === from)
            continue
        const r = rects[i]
        if (r && center > r.y + r.h / 2)
            k++
    }
    return k
}

function shiftFor(i, from, to, step) {
    if (i === from)
        return 0
    if (i > from && i <= to)
        return -step
    if (i < from && i >= to)
        return step
    return 0
}

function beforeId(ids, key, to) {
    const reduced = ids.filter(x => x !== key)
    return to < reduced.length ? reduced[to] : ""
}

function reorder(order, id, before) {
    const list = order.filter(x => x !== id)
    const k = before ? list.indexOf(before) : -1
    if (k < 0)
        list.push(id)
    else
        list.splice(k, 0, id)
    return list
}

function sanitizeOrder(saved, ids) {
    if (!saved || saved.length === 0)
        return ids.slice()
    const known = saved.filter(k => ids.indexOf(k) >= 0)
    const missing = ids.filter(k => known.indexOf(k) < 0)
    return known.concat(missing)
}
