import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

Item {
    id: root
    anchors.fill: parent

    property string tab: "all"
    property int cur: 0

    readonly property var items: root.tab === "favorites" ? ServiceWallpaper.favoritedWallpapers : ServiceWallpaper.filteredWallpapers
    readonly property int itemCount: root.items ? root.items.length : 0
    readonly property var picked: root.itemCount > 0 ? root.items[Math.min(root.cur, root.itemCount - 1)] : null
    readonly property string pickedFile: root.picked ? ServiceWallpaper.getOriginalPath(root.picked) : ""
    readonly property var pickedInfo: ServiceWallpaper.infoFor(root.pickedFile)
    readonly property bool pickedIsCurrent: root.picked !== null && root.picked === ServiceWallpaper.currentCachePath
    readonly property var preview: root.picked ? ServiceWallpaper.previewFor(root.picked) : null
    readonly property bool isFavorite: root.picked !== null && ServiceWallpaper.favoritedWallpapers.indexOf(root.picked) >= 0
    readonly property var keylines: [3, 5, 8, 18, 8, 5, 3]

    readonly property string metaText: {
        if (!root.pickedInfo) return ""
        const ext = root.pickedFile.split(".").pop().toUpperCase()
        return [root.pickedInfo.width + " × " + root.pickedInfo.height,
                ServiceWallpaper.formatBytes(root.pickedInfo.bytes),
                ext === "JPEG" ? "JPG" : ext].filter(p => p !== "").join("  ·  ")
    }

    onPickedFileChanged: ServiceWallpaper.requestInfo(root.pickedFile)
    onPickedChanged: if (root.picked) previewTimer.restart()

    function nameOf(it) {
        if (!it) return ""
        const f = ServiceWallpaper.getOriginalPath(it).split("/").pop()
        const dot = f.lastIndexOf(".")
        return dot > 0 ? f.slice(0, dot) : f
    }

    function step(d) {
        if (root.itemCount === 0) return
        root.cur = (root.cur + d + root.itemCount) % root.itemCount
    }

    function wrap(i) {
        return root.itemCount > 0 ? ((i % root.itemCount) + root.itemCount) % root.itemCount : 0
    }

    function shuffle() {
        if (root.itemCount < 2) return
        let i = Math.floor(Math.random() * root.itemCount)
        if (i === root.cur) i = root.wrap(i + 1)
        root.cur = i
    }

    function setTab(t) {
        root.tab = t
        root.cur = 0
        root.pickCurrent()
    }

    function pickCurrent() {
        const i = root.items ? root.items.indexOf(ServiceWallpaper.currentCachePath) : -1
        root.cur = i >= 0 ? i : 0
    }

    Timer {
        id: previewTimer
        interval: 120
        onTriggered: ServiceWallpaper.requestPreview(root.picked)
    }

    Component.onCompleted: {
        if (ServiceWallpaper.onlineMode) ServiceWallpaper.onlineMode = false
        ServiceWallpaper.updateSearch("")
        root.pickCurrent()
        if (!GlobalStates.barEditMode) root.forceActiveFocus()
    }

    focus: true
    Keys.onLeftPressed: root.step(-1)
    Keys.onRightPressed: root.step(1)
    Keys.onReturnPressed: if (root.picked && !root.pickedIsCurrent) ServiceWallpaper.setWallpaper(root.picked)
    Keys.onEnterPressed: if (root.picked && !root.pickedIsCurrent) ServiceWallpaper.setWallpaper(root.picked)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_F && root.picked) {
            ServiceWallpaper.toggleFavorite(root.picked)
            event.accepted = true
        } else if (event.key === Qt.Key_Home) {
            root.cur = 0
            event.accepted = true
        } else if (event.key === Qt.Key_End) {
            root.cur = Math.max(0, root.itemCount - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_R) {
            root.shuffle()
            event.accepted = true
        }
    }

    Item {
        id: pal
        visible: false
        property color primary: root.preview ? root.preview.primary : Colors.primary
        property color primaryText: root.preview ? root.preview.primaryText : Colors.primaryText
        property color secondaryContainer: root.preview ? root.preview.secondaryContainer : Colors.secondaryContainer
        property color secondaryContainerText: root.preview ? root.preview.secondaryContainerText : Colors.secondaryContainerText
        property color surface: root.preview ? root.preview.surface : Colors.surface
        property color container: root.preview ? root.preview.surfaceContainer : Colors.surfaceContainer
        property color containerHigh: root.preview ? root.preview.surfaceContainerHigh : Colors.surfaceContainerHigh
        property color containerHighest: root.preview ? root.preview.surfaceContainerHighest : Colors.surfaceContainerHighest
        property color text: root.preview ? root.preview.surfaceText : Colors.surfaceText
        property color subtext: root.preview ? root.preview.surfaceVariantText : Colors.surfaceVariantText

        Behavior on primary { EffectsColorAnim { speed: "slow" } }
        Behavior on primaryText { EffectsColorAnim { speed: "slow" } }
        Behavior on secondaryContainer { EffectsColorAnim { speed: "slow" } }
        Behavior on secondaryContainerText { EffectsColorAnim { speed: "slow" } }
        Behavior on surface { EffectsColorAnim { speed: "slow" } }
        Behavior on container { EffectsColorAnim { speed: "slow" } }
        Behavior on containerHigh { EffectsColorAnim { speed: "slow" } }
        Behavior on containerHighest { EffectsColorAnim { speed: "slow" } }
        Behavior on text { EffectsColorAnim { speed: "slow" } }
        Behavior on subtext { EffectsColorAnim { speed: "slow" } }
    }

    component StageButton: Rectangle {
        id: sb
        property string icon: ""
        property bool lit: false
        signal clicked
        implicitWidth: 44
        implicitHeight: 44
        radius: sbArea.pressed ? 12 : 22
        color: sb.lit ? pal.secondaryContainer : sbArea.containsMouse ? pal.containerHighest : pal.containerHigh
        Behavior on radius { SpatialAnim { speed: "fast" } }
        Behavior on color { EffectsColorAnim { speed: "fast" } }
        MaterialIconSymbol {
            anchors.centerIn: parent
            content: sb.icon
            iconSize: 20
            customColor: sb.lit ? pal.secondaryContainerText : pal.text
        }
        CustomMouseArea {
            id: sbArea
            radius: sb.radius
            hoverEnabled: true
            onClicked: sb.clicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            M3ButtonGroup {
                Layout.preferredHeight: 38
                model: [{ value: "all", label: "All", icon: "photo_library" }, { value: "favorites", label: "Favourites", icon: "favorite" }]
                activeCheck: v => root.tab === v
                onSegmentClicked: v => root.setTab(v)
                activeColor: pal.primary
                activeTextColor: pal.primaryText
                inactiveColor: pal.containerHigh
                inactiveTextColor: pal.text
                iconSize: 16
                textSize: 12
            }

            Item { Layout.fillWidth: true }

            CustomText {
                content: root.itemCount > 0 ? (root.cur + 1) + " of " + root.itemCount : ""
                size: 12
                weight: 500
                customColor: pal.subtext
            }

            StageButton {
                icon: "refresh"
                onClicked: ServiceWallpaper.refresh()
            }
        }

        Rectangle {
            id: hero
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 28
            color: pal.container
            antialiasing: true

            Item {
                id: heroFull
                anchors.fill: parent

                readonly property string wanted: root.pickedFile !== "" ? "file://" + root.pickedFile : ""
                property Item front: null

                function other(img) {
                    return img === fullA ? fullB : fullA
                }

                function show(img) {
                    if (img === heroFull.front || img.source.toString() !== heroFull.wanted)
                        return
                    const old = heroFull.front
                    img.z = 1
                    if (old)
                        old.z = 0
                    heroFull.front = img
                    heroFade.stop()
                    img.opacity = 0
                    heroFade.target = img
                    heroFade.start()
                }

                function settle() {
                    if (heroFull.front)
                        heroFull.other(heroFull.front).opacity = 0
                }

                onWantedChanged: {
                    if (heroFull.wanted === "") {
                        heroFade.stop()
                        fullA.source = ""
                        fullB.source = ""
                        fullA.opacity = 0
                        fullB.opacity = 0
                        heroFull.front = null
                        return
                    }
                    if (heroFull.front && heroFull.front.source.toString() === heroFull.wanted) {
                        heroFull.other(heroFull.front).source = ""
                        return
                    }
                    if (heroFade.running) {
                        heroFade.complete()
                        heroFull.settle()
                    }
                    const back = heroFull.front ? heroFull.other(heroFull.front) : fullA
                    back.source = heroFull.wanted
                    if (back.status === Image.Ready)
                        heroFull.show(back)
                }

                Component.onCompleted: if (heroFull.wanted !== "") fullA.source = heroFull.wanted

                EffectsAnim {
                    id: heroFade
                    property: "opacity"
                    from: 0
                    to: 1
                    speed: "default"
                    onFinished: heroFull.settle()
                }

                RoundedImage {
                    id: fullA
                    anchors.fill: parent
                    radius: hero.radius
                    sourceSize.width: 1600
                    sourceSize.height: 900
                    opacity: 0
                    onStatusChanged: if (status === Image.Ready) heroFull.show(fullA)
                }

                RoundedImage {
                    id: fullB
                    anchors.fill: parent
                    radius: hero.radius
                    sourceSize.width: 1600
                    sourceSize.height: 900
                    opacity: 0
                    onStatusChanged: if (status === Image.Ready) heroFull.show(fullB)
                }
            }

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                height: 26
                spacing: 0
                opacity: 0.92

                Rectangle { Layout.preferredWidth: hero.width * 0.2; Layout.fillHeight: true; radius: 13; color: pal.surface }
                Item { Layout.fillWidth: true }
                Rectangle { Layout.preferredWidth: hero.width * 0.14; Layout.fillHeight: true; radius: 13; color: pal.surface }
                Item { Layout.fillWidth: true }
                Rectangle { Layout.preferredWidth: hero.width * 0.18; Layout.fillHeight: true; radius: 13; color: pal.surface }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 16
                width: Math.min(infoCol.implicitWidth + 32, hero.width * 0.5)
                height: infoCol.implicitHeight + 26
                radius: 22
                color: Qt.alpha(pal.surface, 0.86)
                visible: root.picked !== null

                ColumnLayout {
                    id: infoCol
                    anchors.fill: parent
                    anchors.margins: 13
                    anchors.leftMargin: 16
                    spacing: 6

                    CustomText {
                        Layout.fillWidth: true
                        content: root.nameOf(root.picked)
                        size: 17
                        weight: 600
                        elide: Text.ElideRight
                        customColor: pal.text
                    }

                    CustomText {
                        visible: root.metaText !== ""
                        content: root.metaText
                        size: 12
                        weight: 500
                        customColor: pal.subtext
                    }

                    SeedSwatches {
                        id: stageSeeds
                        visible: !ServiceWallpaper.gowallActive && stageSeeds.seeds.length > 1
                        path: root.pickedFile
                        disc: 24
                        ring: pal.primary
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16
                width: actions.implicitWidth + 16
                height: 60
                radius: 30
                color: Qt.alpha(pal.surface, 0.86)
                visible: root.picked !== null

                RowLayout {
                    id: actions
                    anchors.centerIn: parent
                    spacing: 8

                    StageButton {
                        icon: "favorite"
                        lit: root.isFavorite
                        onClicked: ServiceWallpaper.toggleFavorite(root.picked)
                    }

                    StageButton {
                        icon: "shuffle"
                        onClicked: root.shuffle()
                    }

                    Rectangle {
                        id: applyBtn
                        readonly property bool usable: root.picked !== null && !root.pickedIsCurrent
                        implicitHeight: 44
                        implicitWidth: applyRow.implicitWidth + 36
                        radius: applyArea.pressed ? 12 : 22
                        color: applyBtn.usable ? pal.primary : pal.containerHighest
                        Behavior on radius { SpatialAnim { speed: "fast" } }

                        RowLayout {
                            id: applyRow
                            anchors.centerIn: parent
                            spacing: 8
                            MaterialIconSymbol {
                                content: "check"
                                iconSize: 20
                                customColor: applyBtn.usable ? pal.primaryText : pal.subtext
                            }
                            CustomText {
                                content: root.pickedIsCurrent ? "In use" : "Apply"
                                size: 14
                                weight: 600
                                customColor: applyBtn.usable ? pal.primaryText : pal.subtext
                            }
                        }

                        CustomMouseArea {
                            id: applyArea
                            radius: applyBtn.radius
                            enabled: applyBtn.usable
                            onClicked: ServiceWallpaper.setWallpaper(root.picked)
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: root.itemCount === 0
                spacing: 10
                MaterialIconSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    content: root.tab === "favorites" ? "favorite" : "image_not_supported"
                    iconSize: 32
                    customColor: pal.subtext
                }
                CustomText {
                    Layout.alignment: Qt.AlignHCenter
                    content: root.tab === "favorites" ? "No favourites yet — press F on a wallpaper"
                        : ServiceWallpaper.isProcessing ? "Loading wallpapers…" : "No wallpapers in " + ServiceWallpaper.wallpaperDir
                    size: 13
                    customColor: pal.subtext
                }
            }
        }

        Item {
            id: strip
            Layout.fillWidth: true
            Layout.preferredHeight: 116
            visible: root.itemCount > 0
            clip: true

            readonly property real gap: 10
            readonly property var widths: {
                const total = root.keylines.reduce((x, y) => x + y, 0)
                const unit = Math.max(0, strip.width - (root.keylines.length - 1) * strip.gap) / total
                return root.keylines.map(k => k * unit)
            }

            function wOf(d) {
                return Math.abs(d) <= 3 ? strip.widths[d + 3] : 24
            }

            function xOf(d) {
                if (d < -3) return -strip.gap - 24
                if (d > 3) return strip.width + strip.gap
                let x = 0
                for (let k = -3; k < d; k++) x += strip.widths[k + 3] + strip.gap
                return x
            }

            Repeater {
                model: root.items

                Item {
                    id: slot
                    required property int index
                    required property var modelData
                    readonly property int d: slot.index - root.cur
                    readonly property bool near: slot.d >= -4 && slot.d <= 4
                    readonly property real corner: Math.min(28, slot.width / 2)

                    visible: slot.near
                    x: strip.xOf(slot.d)
                    width: strip.wOf(slot.d)
                    height: strip.height
                    Behavior on x { SpatialAnim { speed: "default" } }
                    Behavior on width { SpatialAnim { speed: "default" } }

                    Loader {
                        anchors.fill: parent
                        active: slot.near
                        sourceComponent: Item {
                            RoundedImage {
                                anchors.fill: parent
                                radius: slot.corner
                                source: "file://" + slot.modelData
                                sourceSize.width: 320
                                sourceSize.height: 320
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: slot.corner
                                antialiasing: true
                                color: "transparent"
                                border.width: 3
                                border.color: pal.primary
                                opacity: slot.d === 0 ? 1 : 0
                                Behavior on opacity { EffectsAnim { speed: "fast" } }
                            }

                            MaterialIconSymbol {
                                visible: slot.width > 60 && ServiceWallpaper.favoritedWallpapers.indexOf(slot.modelData) >= 0
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.margins: 10
                                content: "favorite"
                                iconSize: 15
                                customColor: "white"
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: slot.near
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cur = slot.index
                        onDoubleClicked: ServiceWallpaper.setWallpaper(slot.modelData)
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => {
                    const dlt = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : -wheel.angleDelta.x
                    if (dlt !== 0) root.step(dlt > 0 ? -1 : 1)
                }
            }
        }
    }
}
