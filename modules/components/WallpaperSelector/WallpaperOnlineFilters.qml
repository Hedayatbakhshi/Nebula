import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

Flickable {
    id: root

    property Item tone: null
    property int chipHeight: 32

    readonly property color cSel: root.tone ? root.tone.secondaryContainer : Colors.secondaryContainer
    readonly property color cSelText: root.tone ? root.tone.secondaryContainerText : Colors.secondaryContainerText
    readonly property color cText: root.tone ? root.tone.subtext : Colors.surfaceVariantText
    readonly property color cHover: root.tone ? root.tone.container : Colors.surfaceContainer
    readonly property color cLine: root.tone ? root.tone.outlineVariant : Colors.outlineVariant

    readonly property var wh: SettingsConfig.wallhaven
    readonly property var sorts: [
        { label: "Latest",   value: "date_added" },
        { label: "Top",      value: "toplist" },
        { label: "Views",    value: "views" },
        { label: "Favs",     value: "favorites" },
        { label: "Random",   value: "random" },
        { label: "Relevant", value: "relevance" }
    ]
    readonly property var ranges: ["1d", "3d", "1w", "1M", "3M", "6M", "1y"]

    function patch(p) {
        SettingsConfig.wallhaven = Object.assign({}, SettingsConfig.wallhaven, p)
        ServiceWallpaper.fetchWallhaven(true)
    }

    function flip(key, pos) {
        const bits = String(root.wh[key]).split("")
        bits[pos] = bits[pos] === "1" ? "0" : "1"
        if (!bits.includes("1")) return
        const p = {}
        p[key] = bits.join("")
        root.patch(p)
    }

    implicitHeight: root.chipHeight
    contentWidth: row.implicitWidth
    contentHeight: height
    clip: true
    interactive: contentWidth > width
    boundsBehavior: Flickable.StopAtBounds

    component FilterChip: Rectangle {
        id: fc
        property Item host: null
        property string label: ""
        property string icon: ""
        property bool lit: false
        property bool danger: false
        signal clicked
        implicitHeight: host.chipHeight
        implicitWidth: fcRow.implicitWidth + 24
        radius: 9
        color: fc.lit ? (fc.danger ? Colors.error : host.cSel) : fcArea.containsMouse ? host.cHover : "transparent"
        border.width: fc.lit ? 0 : 1
        border.color: host.cLine
        Behavior on color { EffectsColorAnim { speed: "fast" } }
        RowLayout {
            id: fcRow
            anchors.centerIn: parent
            spacing: 4
            MaterialIconSymbol {
                visible: fc.icon !== "" || fc.lit
                content: fc.icon !== "" ? fc.icon : "check"
                iconSize: 15
                customColor: fc.lit ? (fc.danger ? Colors.errorText : host.cSelText) : host.cText
            }
            CustomText {
                visible: fc.label !== ""
                content: fc.label
                size: 12
                weight: 500
                customColor: fc.lit ? (fc.danger ? Colors.errorText : host.cSelText) : host.cText
            }
        }
        CustomMouseArea {
            id: fcArea
            radius: fc.radius
            hoverEnabled: true
            onClicked: fc.clicked()
        }
    }

    component Divider: Rectangle {
        property Item host: null
        implicitWidth: 1
        implicitHeight: 18
        color: host.cLine
    }

    RowLayout {
        id: row
        height: root.height
        spacing: 6

        Repeater {
            model: root.sorts
            FilterChip {
                host: root
                required property var modelData
                label: modelData.label
                lit: root.wh.sorting === modelData.value
                onClicked: root.patch({ sorting: modelData.value })
            }
        }

        Divider {
            host: root
            visible: root.wh.sorting === "toplist"
        }

        Repeater {
            model: root.wh.sorting === "toplist" ? root.ranges : []
            FilterChip {
                host: root
                required property string modelData
                label: modelData
                lit: root.wh.topRange === modelData
                onClicked: root.patch({ topRange: modelData })
            }
        }

        Divider { host: root }

        FilterChip {
            host: root
            icon: root.wh.order === "asc" ? "arrow_upward" : "arrow_downward"
            label: root.wh.order === "asc" ? "Oldest" : "Newest"
            onClicked: root.patch({ order: root.wh.order === "asc" ? "desc" : "asc" })
        }

        Divider { host: root }

        Repeater {
            model: ["General", "Anime", "People"]
            FilterChip {
                host: root
                required property string modelData
                required property int index
                label: modelData
                lit: String(root.wh.categories)[index] === "1"
                onClicked: root.flip("categories", index)
            }
        }

        Divider { host: root }

        FilterChip {
            host: root
            label: "SFW"
            lit: String(root.wh.purity)[0] === "1"
            onClicked: root.flip("purity", 0)
        }
        FilterChip {
            host: root
            label: "Sketchy"
            lit: String(root.wh.purity)[1] === "1"
            onClicked: root.flip("purity", 1)
        }
        FilterChip {
            host: root
            visible: String(root.wh.apiKey ?? "").length > 0
            label: "NSFW"
            danger: true
            lit: String(root.wh.purity)[2] === "1"
            onClicked: root.flip("purity", 2)
        }
    }
}
