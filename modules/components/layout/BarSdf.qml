import QtQuick
import qs.modules.utils

ShaderEffect {
    id: sdf

    property Item bar: null
    property Item dock: null

    readonly property var barField: sdf.bar && sdf.bar.sdfOn ? sdf.bar.sdfField : null
    readonly property var dockField: sdf.dock && sdf.dock.visible && sdf.dock.sdfOn ? sdf.dock.sdfField : null

    readonly property var packed: {
        const pills = []
        const segs = []
        const flares = []
        const take = (f, space) => {
            if (!f)
                return
            for (const q of f.pills)
                pills.push({ l: q.l, r: q.r, bot: q.bot, sp: space,
                             rtl: q.rtl, rtr: q.rtr, rbl: q.rbl, rbr: q.rbr })
            for (const s of f.segs) {
                s.sp = space
                segs.push(s)
            }
            for (const c of f.flares)
                flares.push({ x: c.x, y: c.y, r: c.r, mode: c.mode + space * 8 })
        }
        take(sdf.barField, 0)
        take(sdf.dockField, 1)
        return { pills: pills, segs: segs, flares: flares }
    }

    function pill(i) {
        const q = sdf.packed.pills[i]
        return q ? Qt.vector4d(q.l, q.r, q.bot, q.sp) : Qt.vector4d(0, 0, 0, 0)
    }
    function pillRad(i) {
        const q = sdf.packed.pills[i]
        return q ? Qt.vector4d(q.rtl, q.rtr, q.rbl, q.rbr) : Qt.vector4d(0, 0, 0, 0)
    }
    function seg(i) {
        const s = sdf.packed.segs[i]
        return s ? Qt.vector4d(s.x, s.w, s.sp ? -s.bot : s.bot, s.gap) : Qt.vector4d(0, 0, 0, 0)
    }
    function fil(i) {
        const s = sdf.packed.segs[i]
        return s ? Qt.vector4d(s.lineL, s.raL, s.lineR, s.raR) : Qt.vector4d(0, 0, 0, 0)
    }
    function rad(k) {
        const a = sdf.packed.segs[k * 2]
        const b = sdf.packed.segs[k * 2 + 1]
        return Qt.vector4d(a ? a.rl : 0, a ? a.rr : 0, b ? b.rl : 0, b ? b.rr : 0)
    }
    function flare(i) {
        const c = sdf.packed.flares[i]
        return c ? Qt.vector4d(c.x, c.y, c.r, c.mode) : Qt.vector4d(0, 0, 0, 0)
    }

    visible: sdf.barField !== null || sdf.dockField !== null
    blending: true
    fragmentShader: Qt.resolvedUrl("../../../shaders/qsb/barsdf.frag.qsb")

    property vector2d itemSize: Qt.vector2d(sdf.width, sdf.height)
    property color fillColor: Colors.surface
    property real pillCount: sdf.packed.pills.length
    property real segCount: sdf.packed.segs.length
    property real flareCount: sdf.packed.flares.length
    property real topA: sdf.barField ? sdf.bar.sdfTop : 0
    property real rMaxA: sdf.barField ? sdf.bar.sdfRMax : 1
    property real botA: sdf.barField ? sdf.bar.sdfBot : 0
    property real topB: sdf.dockField ? sdf.dock.sdfTop : 0
    property real rMaxB: sdf.dockField ? sdf.dock.sdfRMax : 1
    property real botB: sdf.dockField ? sdf.dock.sdfBot : 0
    property real flipY: sdf.dockField ? sdf.dock.sdfFlip : 0
    property real cutA: sdf.barField ? sdf.bar.sdfCut : -1
    property real cutB: sdf.dockField ? sdf.dock.sdfFlip - sdf.dock.sdfCut : sdf.height + 10
    property real blend: sdf.barField && sdf.dockField ? Math.min(sdf.rMaxA, sdf.rMaxB) : 0
    property vector4d pil0: sdf.pill(0)
    property vector4d pil1: sdf.pill(1)
    property vector4d pil2: sdf.pill(2)
    property vector4d pil3: sdf.pill(3)
    property vector4d pil4: sdf.pill(4)
    property vector4d pil5: sdf.pill(5)
    property vector4d pil6: sdf.pill(6)
    property vector4d pil7: sdf.pill(7)
    property vector4d pir0: sdf.pillRad(0)
    property vector4d pir1: sdf.pillRad(1)
    property vector4d pir2: sdf.pillRad(2)
    property vector4d pir3: sdf.pillRad(3)
    property vector4d pir4: sdf.pillRad(4)
    property vector4d pir5: sdf.pillRad(5)
    property vector4d pir6: sdf.pillRad(6)
    property vector4d pir7: sdf.pillRad(7)
    property vector4d seg0: sdf.seg(0)
    property vector4d seg1: sdf.seg(1)
    property vector4d seg2: sdf.seg(2)
    property vector4d seg3: sdf.seg(3)
    property vector4d seg4: sdf.seg(4)
    property vector4d seg5: sdf.seg(5)
    property vector4d seg6: sdf.seg(6)
    property vector4d seg7: sdf.seg(7)
    property vector4d seg8: sdf.seg(8)
    property vector4d seg9: sdf.seg(9)
    property vector4d seg10: sdf.seg(10)
    property vector4d seg11: sdf.seg(11)
    property vector4d seg12: sdf.seg(12)
    property vector4d seg13: sdf.seg(13)
    property vector4d seg14: sdf.seg(14)
    property vector4d seg15: sdf.seg(15)
    property vector4d seg16: sdf.seg(16)
    property vector4d seg17: sdf.seg(17)
    property vector4d seg18: sdf.seg(18)
    property vector4d seg19: sdf.seg(19)
    property vector4d seg20: sdf.seg(20)
    property vector4d seg21: sdf.seg(21)
    property vector4d seg22: sdf.seg(22)
    property vector4d seg23: sdf.seg(23)
    property vector4d fil0: sdf.fil(0)
    property vector4d fil1: sdf.fil(1)
    property vector4d fil2: sdf.fil(2)
    property vector4d fil3: sdf.fil(3)
    property vector4d fil4: sdf.fil(4)
    property vector4d fil5: sdf.fil(5)
    property vector4d fil6: sdf.fil(6)
    property vector4d fil7: sdf.fil(7)
    property vector4d fil8: sdf.fil(8)
    property vector4d fil9: sdf.fil(9)
    property vector4d fil10: sdf.fil(10)
    property vector4d fil11: sdf.fil(11)
    property vector4d fil12: sdf.fil(12)
    property vector4d fil13: sdf.fil(13)
    property vector4d fil14: sdf.fil(14)
    property vector4d fil15: sdf.fil(15)
    property vector4d fil16: sdf.fil(16)
    property vector4d fil17: sdf.fil(17)
    property vector4d fil18: sdf.fil(18)
    property vector4d fil19: sdf.fil(19)
    property vector4d fil20: sdf.fil(20)
    property vector4d fil21: sdf.fil(21)
    property vector4d fil22: sdf.fil(22)
    property vector4d fil23: sdf.fil(23)
    property vector4d rad0: sdf.rad(0)
    property vector4d rad1: sdf.rad(1)
    property vector4d rad2: sdf.rad(2)
    property vector4d rad3: sdf.rad(3)
    property vector4d rad4: sdf.rad(4)
    property vector4d rad5: sdf.rad(5)
    property vector4d rad6: sdf.rad(6)
    property vector4d rad7: sdf.rad(7)
    property vector4d rad8: sdf.rad(8)
    property vector4d rad9: sdf.rad(9)
    property vector4d rad10: sdf.rad(10)
    property vector4d rad11: sdf.rad(11)
    property vector4d fc0: sdf.flare(0)
    property vector4d fc1: sdf.flare(1)
    property vector4d fc2: sdf.flare(2)
    property vector4d fc3: sdf.flare(3)
    property vector4d fc4: sdf.flare(4)
    property vector4d fc5: sdf.flare(5)
    property vector4d fc6: sdf.flare(6)
    property vector4d fc7: sdf.flare(7)
    property vector4d fc8: sdf.flare(8)
    property vector4d fc9: sdf.flare(9)
    property vector4d fc10: sdf.flare(10)
    property vector4d fc11: sdf.flare(11)
}
