pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property var variants: [
        { value: "veil",     label: "Veil",     role: "Default",    blurb: "Sharp wallpaper, clock and sign-in on a bottom scrim", backdrop: "veil" },
        { value: "bloom",    label: "Bloom",    role: "Shapes",     blurb: "The time set in morphing Material shapes",              backdrop: "bloom" },
        { value: "orbit",    label: "Orbit",    role: "Watch face", blurb: "A dial with a seconds ring and orbiting status",       backdrop: "orbit" },
        { value: "darkroom", label: "Darkroom", role: "Photo",      blurb: "Your wallpaper as an instant print that develops",     backdrop: "darkroom" },
        { value: "deck",     label: "Deck",     role: "Music",      blurb: "Album art in a cookie with the progress on its edge",  backdrop: "deck" },
        { value: "tessera",  label: "Tessera",  role: "Tiles",      blurb: "A mosaic of Material tone tiles",                      backdrop: "tessera" },
        { value: "tear",     label: "Tear-off", role: "Paper",      blurb: "A paper day calendar; unlocking tears off the page",   backdrop: "tear" }
    ]

    readonly property string fallback: "veil"

    readonly property var _legacy: ({
        "aurora": "veil", "terminal": "veil", "marquee": "veil", "seijaku": "veil",
        "yakou": "veil", "kaisatsu": "veil", "broadsheet": "veil",
        "centered": "veil", "sheet": "veil", "card": "veil", "split": "veil",
        "panel": "veil", "frosted": "veil", "minimal": "veil", "halo": "veil"
    })

    function normalize(value) {
        const legacy = root._legacy[value ?? ""]
        if (legacy !== undefined)
            return legacy
        for (let i = 0; i < root.variants.length; i++)
            if (root.variants[i].value === value)
                return value
        return root.fallback
    }

    function indexOf(value) {
        const v = root.normalize(value)
        for (let i = 0; i < root.variants.length; i++)
            if (root.variants[i].value === v)
                return i
        return 0
    }

    function entry(value) {
        return root.variants[root.indexOf(value)]
    }

    function backdropFor(value) {
        return root.entry(value).backdrop
    }
}
