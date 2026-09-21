pragma Singleton

import Quickshell
import QtQuick
import qs.modules.settings

Singleton {
    id: root

    readonly property int cell: 90
    readonly property int gutter: 20
    readonly property int pitch: cell + gutter

    function span(n) { return n * pitch - gutter }
    function cellsFor(px) { return Math.max(1, Math.round((px + gutter) / pitch)) }
    function cellsCovering(px) { return Math.max(1, Math.ceil((px + gutter) / pitch - 0.001)) }

    readonly property int rowStep: pitch / 2
    function rowsFor(px) { return Math.max(0.5, Math.round((px + gutter) / rowStep) / 2) }
    function halvesCovering(px) { return Math.max(1, Math.ceil((px + gutter) / rowStep - 0.001)) }

    readonly property vector2d screenSize: GlobalStates.widgetScreenSize
    readonly property int gridCols: Math.max(1, Math.floor((screenSize.x - gutter) / pitch))
    readonly property int gridRows: Math.max(1, Math.floor((screenSize.y - gutter) / pitch))
    readonly property int originX: Math.round((screenSize.x - span(gridCols)) / 2)
    readonly property int originY: Math.round((screenSize.y - span(gridRows)) / 2)

    function colAt(x) { return Math.round((x - originX) / pitch) }
    function rowAt(y) { return Math.round((y - originY) / rowStep) / 2 }

    function snapX(x, w) {
        const c = Math.max(0, Math.min(colAt(x), gridCols - cellsCovering(w)))
        return originX + c * pitch
    }
    function snapY(y, h) {
        const r = Math.max(0, Math.min(Math.round((y - originY) / rowStep),
                                       gridRows * 2 - halvesCovering(h)))
        return originY + r * rowStep
    }

    // Shared corner radius, so tiles read as one family
    readonly property int radius: 24

    readonly property string cardStyle: SettingsConfig.widgets.cardStyle
        ?? ((SettingsConfig.widgets.blurBackground ?? false) ? "frosted" : "flat")

    readonly property bool blurBackground: root.cardStyle !== "flat"
    readonly property bool liquidGlass: root.cardStyle === "liquid"
    readonly property real cardOpacity: SettingsConfig.widgets.cardOpacity ?? 0.60
    readonly property real glassStrength: SettingsConfig.widgets.glassStrength ?? 1.0

    readonly property color cardColor: root.cardStyle === "liquid"
        ? Qt.rgba(0, 0, 0, 0)
        : (root.cardStyle === "frosted"
            ? Qt.alpha(Colors.surface, root.cardOpacity)
            : Colors.surface)

    // ── Named tiles ───────────────────────────────────────────────────
    readonly property size small: Qt.size(span(2), span(2))
    readonly property size wide:  Qt.size(span(3), span(2))
    readonly property size strip: Qt.size(span(3), span(1.5))
    readonly property size tall:  Qt.size(span(2), span(3))
    readonly property size large: Qt.size(span(3), span(3))
}
