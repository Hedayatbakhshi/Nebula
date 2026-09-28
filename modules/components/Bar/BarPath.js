.pragma library

function clamp(v, lo, hi) {
    return Math.max(lo, Math.min(hi, v))
}

function smooth(t) {
    const c = clamp(t, 0, 1)
    return c * c * (3 - 2 * c)
}

function sdfEmpty() {
    return { pills: [], segs: [], flares: [] }
}

function sdfShape(bs, o, out) {
    const rMax = o.rMax
    const T = o.top
    const B = o.top + o.bridge
    const L = o.left
    const R = o.right
    const n = bs.length
    const e = clamp(o.endR, -rMax, Math.max(0, (B - T) / 2))
    const ec = Math.max(0, e)
    if (!n) {
        out.pills.push({ l: L, r: R, bot: B, rtl: ec, rtr: ec, rbl: ec, rbr: ec })
        return out
    }

    const edgeFlare = clamp(-o.endR / rMax, 0, 1)
    const bot = i => Math.max(B, bs[i].bot)

    const gaps = []
    const lines = []
    const reach = []
    for (let k = 0; k <= n; k++) {
        const leftX = k === 0 ? L : bs[k - 1].x + bs[k - 1].w
        const rightX = k === n ? R : bs[k].x
        const g = Math.max(0, rightX - leftX)
        const inner = k > 0 && k < n
        const m = inner ? smooth((o.needGap - g) / 24) : 0
        gaps.push(g)
        lines.push(inner ? B + (Math.min(bot(k - 1), bot(k)) - B) * m : B)
        reach.push(g / 2 + m * rMax)
    }

    const endFactor = (gap, h) => {
        const g = clamp(gap / (2 * rMax), 0, 1)
        return e >= 0 ? Math.max(g, clamp(1 - h / rMax, 0, 1)) : g
    }
    const es = e * endFactor(gaps[0], bot(0) - B)
    const ee = e * endFactor(gaps[n], bot(n - 1) - B)
    const esA = Math.abs(es)
    const eeA = Math.abs(ee)

    if (B - T > 0.5)
        out.pills.push({ l: L, r: R, bot: B,
                         rtl: ec, rtr: ec,
                         rbl: Math.max(0, es), rbr: Math.max(0, ee) })
    if (es < -0.01)
        out.flares.push({ x: L, y: B, r: esA, mode: 1 })
    if (ee < -0.01)
        out.flares.push({ x: R, y: B, r: eeA, mode: 3 })

    const share = []
    for (let k = 0; k <= n; k++) {
        const prevW = k > 0 ? bs[k - 1].w : Infinity
        const nextW = k < n ? bs[k].w : Infinity
        share.push(Math.min(prevW, nextW) / 2)
    }

    const lefts = []
    const entry = []
    for (let i = 0; i < n; i++) {
        lefts.push(i === 0 ? Math.max(bs[i].x, L + esA) : bs[i].x)
        entry.push(Math.min(rMax, Math.max(0, bot(i) - lines[i]) / 2, reach[i], share[i]))
    }

    const sideTouch = px => Math.max(clamp(1 - px / rMax, 0, 1),
                                     clamp(1 - (o.screenW - px) / rMax, 0, 1))

    const factor = (edgeTouch, b, px, melt) => {
        const fE = edgeFlare * edgeTouch
        const fB = o.bottomFlare * clamp(1 - (o.screenH - b) / rMax, 0, 1)
            * (melt ? 1 : sideTouch(px))
        return { s: 1 - 2 * Math.max(fE, fB), vertical: fE >= fB }
    }

    let curX = L + esA
    for (let i = 0; i < n; i++) {
        const b = bs[i]
        const y = bot(i)
        const x = lefts[i]
        const limit = i === n - 1 ? R - eeA : lefts[i + 1] - entry[i + 1]
        const X = Math.max(x, Math.min(b.x + b.w, limit))
        const w = Math.max(0, X - x)
        const lineL = lines[i]
        const lineR = lines[i + 1]
        const hL = Math.max(0, y - lineL)
        const hR = Math.max(0, y - lineR)
        const raL = Math.max(0, Math.min(entry[i], x - curX))
        const raR = Math.min(rMax, hR / 2, reach[i + 1], share[i + 1])
        const melt = b.melt === true

        let rl = 0
        let rr = 0
        const cl = factor(i === 0 ? clamp(1 - gaps[0] / rMax, 0, 1) : 0, y, x, melt)
        if (cl.s >= 0) {
            rl = Math.min(rMax, hL - raL, w / 2) * cl.s
        } else {
            const r = cl.vertical ? Math.min(rMax * -cl.s, w)
                                  : Math.min(rMax, hL - raL) * -cl.s
            if (r > 0.01)
                out.flares.push({ x: x, y: y, r: r, mode: cl.vertical ? 1 : 2 })
        }
        const cr = factor(i === n - 1 ? clamp(1 - gaps[n] / rMax, 0, 1) : 0, y, X, melt)
        if (cr.s >= 0) {
            rr = Math.min(rMax, hR - raR, w / 2) * cr.s
        } else {
            const r = cr.vertical ? Math.min(rMax * -cr.s, w)
                                  : Math.min(rMax, hR - raR) * -cr.s
            if (r > 0.01)
                out.flares.push({ x: X, y: y, r: r, mode: cr.vertical ? 3 : 4 })
        }

        out.segs.push({ x: x, w: w, bot: y, top: T, rl: Math.max(0, rl), rr: Math.max(0, rr),
                        lineL: lineL, raL: raL > 0.01 ? raL : 0,
                        lineR: lineR, raR: raR > 0.01 ? raR : 0,
                        gap: i < n - 1 ? Math.max(0, lefts[i + 1] - X) : -1 })
        curX = X + raR
    }

    out.flares.sort((a, b) => b.r - a.r)
    return out
}

function sdfData(bs, o) {
    return sdfShape(bs, o, sdfEmpty())
}

function sdfIslands(groups, o) {
    const out = sdfEmpty()
    const T = o.top
    const B = o.top + o.bridge
    const e = clamp(o.endR, 0, (B - T) / 2)
    for (const g of groups) {
        if (!g || !g.length)
            continue
        let L = Infinity
        let R = -Infinity
        for (const s of g) {
            L = Math.min(L, s.x)
            R = Math.max(R, s.x + s.w)
        }
        if (R - L < 0.5)
            continue
        if (g.length === 1 && g[0].bot > B + 0.01) {
            const seg = g[0]
            const bot = Math.max(B, seg.bot)
            const t = clamp((bot - B) / o.rMax, 0, 1)
            const half = (R - L) / 2
            const rTop = Math.min(e, half)
            const rBot = Math.max(0, Math.min(e + (o.rMax - e) * t, half, (bot - T) - rTop))
            out.pills.push({ l: L, r: R, bot: bot, rtl: rTop, rtr: rTop, rbl: rBot, rbr: rBot })
            continue
        }
        sdfShape(g, Object.assign({}, o, { left: L, right: R }), out)
    }
    return out
}
