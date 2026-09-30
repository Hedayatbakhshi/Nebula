import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

Item {
    id: root
    anchors.fill: parent

    property string tab: "all"
    property bool railOpen: false
    property var picked: null

    readonly property bool online: ServiceWallpaper.onlineMode
    readonly property var items: root.online ? ServiceWallpaper.onlineWallpapers
        : root.tab === "favorites" ? ServiceWallpaper.favoritedWallpapers
        : ServiceWallpaper.filteredWallpapers
    readonly property int itemCount: root.items ? root.items.length : 0

    readonly property string pickedLocal: root.online ? ServiceWallpaper.localFor(root.picked) : ""
    readonly property string pickedFile: root.online ? root.pickedLocal
        : root.picked ? ServiceWallpaper.getOriginalPath(root.picked) : ""
    readonly property var pickedInfo: ServiceWallpaper.infoFor(root.pickedFile)
    onPickedFileChanged: ServiceWallpaper.requestInfo(root.pickedFile)

    readonly property string metaText: {
        if (!root.online && !root.pickedInfo) return ""
        const parts = []
        if (root.pickedInfo) {
            parts.push(root.pickedInfo.width + " × " + root.pickedInfo.height)
            parts.push(ServiceWallpaper.formatBytes(root.pickedInfo.bytes))
        } else if (root.online && root.idOf(root.picked) !== "") {
            parts.push((root.picked.resolution || "").replace("x", " × "))
            parts.push(ServiceWallpaper.formatBytes(root.picked.fileSize))
        }
        const f = root.online ? (root.picked && root.picked.fullUrl ? root.picked.fullUrl : "") : root.pickedFile
        const ext = f.split("?")[0].split(".").pop().toUpperCase()
        if (f && ext.length <= 4) parts.push(ext === "JPEG" ? "JPG" : ext)
        if (root.online && root.pickedLocal !== "") parts.push("Downloaded")
        return parts.filter(p => p !== "").join("  ·  ")
    }

    readonly property bool pickedIsCurrent: root.online
        ? root.pickedLocal !== "" && root.pickedLocal === ServiceWallpaper.currentSource
        : root.picked !== null && root.picked === ServiceWallpaper.currentCachePath
    readonly property var preview: !root.online && root.picked ? ServiceWallpaper.previewFor(root.picked) : null
    readonly property bool downloading: root.online && root.idOf(root.picked) !== ""
        && ServiceWallpaper.downloadingId === root.idOf(root.picked)

    function idOf(it) {
        return it && typeof it === "object" && it.id !== undefined ? it.id : ""
    }

    function nameOf(it) {
        if (!it) return ""
        if (root.online) return root.idOf(it) !== "" ? "wallhaven-" + it.id : ""
        const p = ServiceWallpaper.getOriginalPath(it)
        const f = p.split("/").pop()
        const dot = f.lastIndexOf(".")
        return dot > 0 ? f.slice(0, dot) : f
    }

    function thumbOf(it) {
        if (!it) return ""
        if (root.online) return typeof it === "object" && it.thumbUrl ? it.thumbUrl : ""
        return typeof it === "string" ? "file://" + it : ""
    }

    function apply(it) {
        if (!it) return
        const local = root.online ? ServiceWallpaper.localFor(it) : ""
        if (local !== "") ServiceWallpaper.applyFile(local)
        else if (root.online) ServiceWallpaper.downloadAndSetWallpaper(it)
        else ServiceWallpaper.setWallpaper(it)
    }

    function pick(i) {
        if (i < 0 || i >= root.itemCount) return
        grid.currentIndex = i
        root.picked = root.items[i]
    }

    function revealRow(i) {
        const maxY = Math.max(0, grid.contentHeight - grid.height)
        grid.contentY = Math.min(maxY, Math.floor(i / grid.cols) * grid.cellHeight)
    }

    function shuffle() {
        if (root.itemCount < 2) return
        let i = Math.floor(Math.random() * root.itemCount)
        if (root.items[i] === root.picked) i = (i + 1) % root.itemCount
        root.pick(i)
        grid.positionViewAtIndex(i, GridView.Contain)
    }

    function setTab(t) {
        if (t === "online") {
            if (!root.online) {
                search.text = ""
                ServiceWallpaper.updateSearch("")
                ServiceWallpaper.onlineMode = true
                ServiceWallpaper.fetchWallhaven(true)
            }
        } else {
            if (root.online) {
                search.text = ""
                ServiceWallpaper.onlineMode = false
            }
            root.tab = t
        }
        grid.currentIndex = -1
    }

    onPickedChanged: if (!root.online && root.picked) previewTimer.restart()

    function syncOnline() {
        if (!root.online) {
            onlineModel.clear()
            return
        }
        const n = ServiceWallpaper.onlineWallpapers.length
        if (n < onlineModel.count) onlineModel.clear()
        for (let i = onlineModel.count; i < n; i++) onlineModel.append({})
        if (root.idOf(root.picked) === "" && n > 0) root.picked = ServiceWallpaper.onlineWallpapers[0]
    }

    function pickDefault() {
        const cur = ServiceWallpaper.currentCachePath
        const i = root.online ? -1 : root.items.indexOf(cur)
        if (i >= 0) {
            root.pick(i)
            Qt.callLater(root.revealRow, i)
        } else if (!root.online && ServiceWallpaper.wallpapers.indexOf(cur) >= 0) {
            root.picked = cur
        } else if (root.itemCount > 0) {
            root.picked = root.items[0]
        }
    }

    ListModel { id: onlineModel }

    Connections {
        target: ServiceWallpaper
        function onOnlineWallpapersChanged() { root.syncOnline() }
        function onOnlineModeChanged() {
            root.picked = null
            grid.currentIndex = -1
            root.syncOnline()
            if (!root.online) root.pickDefault()
        }
    }

    Timer {
        id: previewTimer
        interval: 120
        onTriggered: ServiceWallpaper.requestPreview(root.picked)
    }

    Component.onCompleted: {
        root.syncOnline()
        root.pickDefault()
        if (!GlobalStates.barEditMode) search.forceActiveFocus()
    }

    Item {
        id: pal
        visible: false
        property color primary: root.preview ? root.preview.primary : Colors.primary
        property color primaryText: root.preview ? root.preview.primaryText : Colors.primaryText
        property color secondary: root.preview ? root.preview.secondary : Colors.secondary
        property color secondaryContainer: root.preview ? root.preview.secondaryContainer : Colors.secondaryContainer
        property color secondaryContainerText: root.preview ? root.preview.secondaryContainerText : Colors.secondaryContainerText
        property color primaryContainer: root.preview ? root.preview.primaryContainer : Colors.primaryContainer
        property color tertiary: root.preview ? root.preview.tertiary : Colors.tertiary
        property color tertiaryContainer: root.preview ? root.preview.tertiaryContainer : Colors.tertiaryContainer
        property color container: root.preview ? root.preview.surfaceContainer : Colors.surfaceContainer
        property color containerHigh: root.preview ? root.preview.surfaceContainerHigh : Colors.surfaceContainerHigh
        property color containerHighest: root.preview ? root.preview.surfaceContainerHighest : Colors.surfaceContainerHighest
        property color text: root.preview ? root.preview.surfaceText : Colors.surfaceText
        property color subtext: root.preview ? root.preview.surfaceVariantText : Colors.surfaceVariantText
        property color outlineVariant: root.preview ? root.preview.outlineVariant : Colors.outlineVariant

        Behavior on primary { EffectsColorAnim { speed: "slow" } }
        Behavior on primaryText { EffectsColorAnim { speed: "slow" } }
        Behavior on secondary { EffectsColorAnim { speed: "slow" } }
        Behavior on secondaryContainer { EffectsColorAnim { speed: "slow" } }
        Behavior on secondaryContainerText { EffectsColorAnim { speed: "slow" } }
        Behavior on primaryContainer { EffectsColorAnim { speed: "slow" } }
        Behavior on tertiary { EffectsColorAnim { speed: "slow" } }
        Behavior on tertiaryContainer { EffectsColorAnim { speed: "slow" } }
        Behavior on container { EffectsColorAnim { speed: "slow" } }
        Behavior on containerHigh { EffectsColorAnim { speed: "slow" } }
        Behavior on containerHighest { EffectsColorAnim { speed: "slow" } }
        Behavior on text { EffectsColorAnim { speed: "slow" } }
        Behavior on subtext { EffectsColorAnim { speed: "slow" } }
        Behavior on outlineVariant { EffectsColorAnim { speed: "slow" } }
    }

    component PalIconButton: Rectangle {
        id: pib
        property Item tone: null
        property string icon: ""
        property bool lit: false
        property int box: 44
        signal clicked
        implicitWidth: box
        implicitHeight: box
        radius: pibArea.pressed ? 12 : box / 2
        color: pib.lit ? tone.secondaryContainer : pibArea.containsMouse ? tone.containerHighest : tone.containerHigh
        Behavior on radius { SpatialAnim { speed: "fast" } }
        Behavior on color { EffectsColorAnim { speed: "fast" } }
        MaterialIconSymbol {
            anchors.centerIn: parent
            content: pib.icon
            iconSize: 20
            customColor: pib.lit ? tone.secondaryContainerText : tone.text
        }
        CustomMouseArea {
            id: pibArea
            radius: pib.radius
            hoverEnabled: true
            onClicked: pib.clicked()
        }
    }

    component PalChip: Rectangle {
        id: pc
        property Item tone: null
        property string icon: ""
        property string label: ""
        property bool lit: false
        signal clicked
        implicitHeight: 36
        implicitWidth: pcRow.implicitWidth + 28
        radius: 10
        color: pc.lit ? tone.secondaryContainer : pcArea.containsMouse ? tone.container : "transparent"
        border.width: pc.lit ? 0 : 1
        border.color: tone.outlineVariant
        Behavior on color { EffectsColorAnim { speed: "fast" } }
        RowLayout {
            id: pcRow
            anchors.centerIn: parent
            spacing: 6
            MaterialIconSymbol {
                visible: pc.lit || pc.icon !== ""
                content: pc.lit ? "check" : pc.icon
                iconSize: 16
                customColor: pc.lit ? tone.secondaryContainerText : tone.subtext
            }
            CustomText {
                content: pc.label
                size: 13
                weight: 500
                customColor: pc.lit ? tone.secondaryContainerText : tone.subtext
            }
        }
        CustomMouseArea {
            id: pcArea
            radius: pc.radius
            hoverEnabled: true
            onClicked: pc.clicked()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 20

        ColumnLayout {
            Layout.preferredWidth: 200
            Layout.maximumWidth: 200
            Layout.fillHeight: true
            spacing: 4

            CustomText {
                Layout.leftMargin: 14
                Layout.bottomMargin: 6
                content: "Browse"
                size: 12
                weight: 600
                customColor: pal.subtext
            }

            Repeater {
                model: [
                    { key: "all", icon: "photo_library", label: "All" },
                    { key: "favorites", icon: "favorite", label: "Favourites" },
                    { key: "online", icon: "public", label: "Online" }
                ]

                Rectangle {
                    id: railItem
                    required property var modelData
                    readonly property bool lit: railItem.modelData.key === "online" ? root.online
                        : !root.online && root.tab === railItem.modelData.key
                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: railArea.pressed ? 14 : 23
                    color: railItem.lit ? pal.secondaryContainer : railArea.containsMouse ? pal.containerHigh : "transparent"
                    Behavior on color { EffectsColorAnim { speed: "fast" } }
                    Behavior on radius { SpatialAnim { speed: "fast" } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        MaterialIconSymbol {
                            content: railItem.modelData.icon
                            iconSize: 20
                            customColor: railItem.lit ? pal.secondaryContainerText : pal.subtext
                        }

                        CustomText {
                            Layout.fillWidth: true
                            content: railItem.modelData.label
                            size: 14
                            weight: 500
                            customColor: railItem.lit ? pal.secondaryContainerText : pal.text
                        }

                        CustomText {
                            content: railItem.modelData.key === "all" ? String(ServiceWallpaper.wallpapers.length)
                                : railItem.modelData.key === "favorites" ? String(ServiceWallpaper.favoritedWallpapers.length)
                                : root.online ? String(root.itemCount) : ""
                            size: 12
                            weight: 500
                            customColor: railItem.lit ? pal.secondaryContainerText : pal.subtext
                        }
                    }

                    CustomMouseArea {
                        id: railArea
                        radius: railItem.radius
                        hoverEnabled: true
                        onClicked: root.setTab(railItem.modelData.key)
                    }
                }
            }

            Item { Layout.fillHeight: true }

            CustomText {
                Layout.leftMargin: 14
                content: "Folder"
                size: 12
                weight: 600
                customColor: pal.subtext
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 14
                spacing: 8

                MaterialIconSymbol {
                    content: "folder"
                    iconSize: 18
                    customColor: pal.primary
                }

                CustomText {
                    Layout.fillWidth: true
                    content: ServiceWallpaper.wallpaperDir.replace(Quickshell.env("HOME"), "~")
                    size: 13
                    weight: 500
                    elide: Text.ElideMiddle
                    customColor: pal.text
                }

                PalIconButton {
                    tone: pal
                    icon: "refresh"
                    box: 36
                    onClicked: ServiceWallpaper.refresh()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: 22
                    color: pal.containerHigh
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 12
                        spacing: 10
                        MaterialIconSymbol {
                            content: "search"
                            iconSize: 18
                            customColor: pal.subtext
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            CustomText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: search.text.length === 0
                                content: root.online ? "Search Wallhaven, press Enter"
                                    : "Search " + ServiceWallpaper.wallpapers.length + " wallpapers"
                                size: 14
                                weight: 400
                                customColor: pal.subtext
                            }
                            TextInput {
                                id: search
                                anchors.fill: parent
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true
                                font.pixelSize: 14
                                font.family: SettingsConfig.general.defaultFont ?? "Rubik"
                                color: pal.text
                                onTextChanged: if (!root.online) {
                                    if (root.tab === "favorites" && text.length > 0) root.tab = "all"
                                    ServiceWallpaper.updateSearch(text)
                                }
                                Keys.onReturnPressed: {
                                    if (root.online) {
                                        if (!ServiceWallpaper.isFetchingOnline) {
                                            ServiceWallpaper.currentSearchText = text
                                            ServiceWallpaper.fetchWallhaven(true)
                                        }
                                    } else if (root.itemCount > 0) {
                                        root.pick(0)
                                        grid.forceActiveFocus()
                                    }
                                }
                                Keys.onEscapePressed: text = ""
                                Keys.onDownPressed: {
                                    grid.forceActiveFocus()
                                    if (grid.currentIndex < 0) root.pick(0)
                                }
                            }
                        }
                        MaterialIconSymbol {
                            visible: search.text.length > 0
                            content: "close"
                            iconSize: 16
                            customColor: pal.subtext
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: search.text = ""
                            }
                        }
                    }
                }

                M3ButtonGroup {
                    visible: !root.online
                    Layout.preferredHeight: 40
                    model: [{ value: "name", label: "Name", icon: "sort_by_alpha" }, { value: "newest", label: "Newest", icon: "schedule" }]
                    activeCheck: v => ServiceWallpaper.localSortBy === v
                    onSegmentClicked: v => ServiceWallpaper.localSortBy = v
                    activeColor: pal.primary
                    activeTextColor: pal.primaryText
                    inactiveColor: pal.containerHigh
                    inactiveTextColor: pal.text
                    iconSize: 16
                    textSize: 12
                }

                PalIconButton {

                    tone: pal
                    icon: "tune"
                    lit: root.railOpen
                    onClicked: root.railOpen = !root.railOpen
                }
            }

            WallpaperOnlineFilters {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                visible: root.online
                tone: pal
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                Item {
                    id: gridWrap
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    GridView {
                        id: grid
                        anchors.fill: parent
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        readonly property int cols: Math.max(3, Math.round(width / 190))
                        cellWidth: Math.floor(width / cols)
                        cellHeight: Math.round((cellWidth - 14) * 10 / 16) + 14
                        currentIndex: -1
                        keyNavigationEnabled: true
                        highlightFollowsCurrentItem: false
                        model: root.online ? onlineModel : root.items
                        cacheBuffer: cellHeight * 2
                        ScrollBar.vertical: CustomScrollBar {}

                        onCurrentIndexChanged: if (currentIndex >= 0 && currentIndex < root.itemCount
                                                    && activeFocus) root.picked = root.items[currentIndex]
                        Keys.onReturnPressed: root.apply(root.picked)
                        Keys.onEnterPressed: root.apply(root.picked)
                        Keys.onEscapePressed: search.forceActiveFocus()
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_F && !root.online && root.picked) {
                                ServiceWallpaper.toggleFavorite(root.picked)
                                event.accepted = true
                            }
                        }

                        onContentYChanged: if (root.online && contentY > contentHeight - height - cellHeight * 2)
                            ServiceWallpaper.fetchNextPage()

                        delegate: Item {
                            id: cell
                            required property int index
                            readonly property var modelData: cell.index < root.itemCount ? root.items[cell.index] : null
                            width: grid.cellWidth
                            height: grid.cellHeight

                            readonly property bool isPicked: root.online
                                ? (root.idOf(root.picked) !== "" && root.idOf(root.picked) === root.idOf(cell.modelData))
                                : root.picked === cell.modelData
                            readonly property bool isCurrent: !root.online && cell.modelData === ServiceWallpaper.currentCachePath

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 3
                                radius: 22
                                color: "transparent"
                                border.width: 3
                                border.color: pal.primary
                                opacity: cell.isPicked ? 1 : 0
                                Behavior on opacity { EffectsAnim { speed: "fast" } }
                            }

                            ClippingRectangle {
                                id: tile
                                anchors.fill: parent
                                anchors.margins: 7
                                radius: 17
                                color: pal.container

                                Image {
                                    anchors.fill: parent
                                    source: root.thumbOf(cell.modelData)
                                    sourceSize.width: 320
                                    sourceSize.height: 320
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectCrop
                                }

                                Rectangle {
                                    visible: cell.isCurrent
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 8
                                    height: 22
                                    width: inUse.implicitWidth + 16
                                    radius: 11
                                    color: Qt.rgba(0, 0, 0, 0.55)
                                    CustomText {
                                        id: inUse
                                        anchors.centerIn: parent
                                        content: "In use"
                                        size: 11
                                        weight: 500
                                        customColor: "white"
                                    }
                                }

                                MaterialIconSymbol {
                                    visible: !root.online && ServiceWallpaper.favoritedWallpapers.indexOf(cell.modelData) >= 0
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.margins: 8
                                    content: "favorite"
                                    iconSize: 16
                                    customColor: "white"
                                }

                                Rectangle {
                                    visible: root.online && ServiceWallpaper.localFor(cell.modelData) !== ""
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.margins: 8
                                    width: 26
                                    height: 26
                                    radius: 13
                                    color: Qt.rgba(0, 0, 0, 0.55)
                                    MaterialIconSymbol {
                                        anchors.centerIn: parent
                                        content: "download_done"
                                        iconSize: 16
                                        customColor: "white"
                                    }
                                }
                            }

                            Rectangle {
                                visible: cell.isPicked
                                anchors.right: tile.right
                                anchors.top: tile.top
                                anchors.margins: 8
                                width: 26
                                height: 26
                                radius: 13
                                color: pal.primary
                                MaterialIconSymbol {
                                    anchors.centerIn: parent
                                    content: "check"
                                    iconSize: 16
                                    customColor: pal.primaryText
                                }
                            }

                            MouseArea {
                                id: cellArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        const m = cellArea.mapToItem(root, mouse.x, mouse.y)
                                        ctxMenu.show(m.x, m.y, cell.modelData, root.online)
                                        return
                                    }
                                    grid.forceActiveFocus()
                                    root.pick(cell.index)
                                }
                                onDoubleClicked: root.apply(cell.modelData)
                            }
                        }
                    }

                    NumberAnimation {
                        id: wheelAnim
                        target: grid
                        property: "contentY"
                        duration: 380
                        easing.type: Easing.OutCubic
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        onWheel: wheel => {
                            wheel.accepted = false
                            const maxY = Math.max(0, grid.contentHeight - grid.height)
                            if (maxY <= 0) return
                            if (wheel.pixelDelta.y !== 0) {
                                wheelAnim.stop()
                                grid.cancelFlick()
                                grid.contentY = Math.max(0, Math.min(maxY, grid.contentY - wheel.pixelDelta.y))
                                wheel.accepted = true
                                return
                            }
                            if (wheel.angleDelta.y === 0) return
                            const base = wheelAnim.running ? wheelAnim.to : grid.contentY
                            const to = Math.max(0, Math.min(maxY, base - wheel.angleDelta.y / 120 * grid.cellHeight))
                            grid.cancelFlick()
                            wheelAnim.stop()
                            wheelAnim.from = grid.contentY
                            wheelAnim.to = to
                            wheelAnim.start()
                            wheel.accepted = true
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        visible: root.itemCount === 0
                        CustomLoader {
                            Layout.alignment: Qt.AlignHCenter
                            visible: root.online ? ServiceWallpaper.isFetchingOnline : ServiceWallpaper.isProcessing
                            size: 60
                            color: pal.primary
                        }
                        MaterialIconSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            visible: !(root.online ? ServiceWallpaper.isFetchingOnline : ServiceWallpaper.isProcessing)
                            content: root.online && ServiceWallpaper.onlineError.length > 0 ? "error"
                                : root.tab === "favorites" ? "favorite" : "image_not_supported"
                            iconSize: 32
                            customColor: pal.subtext
                        }
                        CustomText {
                            Layout.alignment: Qt.AlignHCenter
                            content: root.online ? (ServiceWallpaper.onlineError.length > 0 ? ServiceWallpaper.onlineError
                                                    : ServiceWallpaper.isFetchingOnline ? "Looking on Wallhaven…" : "Nothing found")
                                : ServiceWallpaper.isProcessing ? "Loading wallpapers…"
                                : root.tab === "favorites" ? "No favourites yet — press F on a wallpaper"
                                : ServiceWallpaper.wallpapers.length === 0 ? "No wallpapers in " + ServiceWallpaper.wallpaperDir
                                : "No wallpapers match your search"
                            size: 13
                            weight: 400
                            customColor: pal.subtext
                        }
                    }
                }

            }
        }
        ColumnLayout {
            visible: !root.railOpen
            Layout.preferredWidth: 340
            Layout.maximumWidth: 340
            Layout.fillHeight: true
            spacing: 12

            ClippingRectangle {
                id: hero
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(hero.width * 10 / 16)
                radius: 24
                color: pal.container

                Image {
                    id: heroThumb
                    anchors.fill: parent
                    visible: root.online && root.pickedLocal === ""
                    source: root.online && root.pickedLocal === "" ? root.thumbOf(root.picked) : ""
                    sourceSize.width: 320
                    sourceSize.height: 320
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                }

                Item {
                    id: heroFull
                    anchors.fill: parent
                    visible: !root.online || root.pickedLocal !== ""

                    readonly property string wanted: heroFull.visible && root.pickedFile !== "" ? "file://" + root.pickedFile : ""
                    property Image front: null

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

                    Image {
                        id: fullA
                        anchors.fill: parent
                        sourceSize.width: 1280
                        sourceSize.height: 720
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        opacity: 0
                        onStatusChanged: if (status === Image.Ready) heroFull.show(fullA)
                    }

                    Image {
                        id: fullB
                        anchors.fill: parent
                        sourceSize.width: 1280
                        sourceSize.height: 720
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        opacity: 0
                        onStatusChanged: if (status === Image.Ready) heroFull.show(fullB)
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 14
                    visible: root.picked !== null
                    height: 32
                    radius: 16
                    width: badgeRow.implicitWidth + 24
                    color: Qt.rgba(0, 0, 0, 0.55)
                    RowLayout {
                        id: badgeRow
                        anchors.centerIn: parent
                        spacing: 6
                        MaterialIconSymbol {
                            content: root.pickedIsCurrent ? "check_circle" : root.online ? "public" : "auto_awesome"
                            iconSize: 16
                            customColor: "white"
                        }
                        CustomText {
                            content: root.pickedIsCurrent ? "In use"
                                : root.online ? "Wallhaven · " + (root.idOf(root.picked) !== "" ? root.picked.resolution : "")
                                : "Previewing — nothing applied yet"
                            size: 12
                            weight: 500
                            customColor: "white"
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    visible: root.downloading
                    color: Qt.rgba(0, 0, 0, 0.5)
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        CustomLoader {
                            Layout.alignment: Qt.AlignHCenter
                            size: 64
                            color: "white"
                        }
                        CustomText {
                            Layout.alignment: Qt.AlignHCenter
                            content: Math.round(ServiceWallpaper.downloadProgress * 100) + "%"
                            size: 13
                            customColor: "white"
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: mouse => {
                        const m = mapToItem(root, mouse.x, mouse.y)
                        ctxMenu.show(m.x, m.y, root.picked, root.online)
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    CustomText {
                        Layout.fillWidth: true
                        content: root.nameOf(root.picked)
                        size: 18
                        weight: 600
                        customColor: pal.text
                    }
                    CustomText {
                        Layout.fillWidth: true
                        visible: root.metaText !== ""
                        content: root.metaText
                        size: 12
                        weight: 500
                        customColor: pal.text
                    }
                    CustomText {
                        Layout.fillWidth: true
                        content: root.online ? (root.pickedLocal !== "" ? "Already in your wallpaper folder" : "Downloads to your wallpaper folder")
                            : root.pickedIsCurrent ? "Your shell is wearing these colours"
                            : root.preview ? "Your shell will take these colours"
                            : "Reading colours…"
                        size: 12
                        weight: 400
                        customColor: pal.subtext
                    }
                }

                SeedSwatches {
                    id: heroSeeds
                    visible: !root.online && !ServiceWallpaper.gowallActive && heroSeeds.seeds.length > 1
                    path: !root.online ? root.pickedFile : ""
                    disc: 26
                    ring: pal.primary
                }

                Row {
                    spacing: 6
                    visible: !root.online && !heroSeeds.visible
                    Repeater {
                        model: [pal.primary, pal.primaryContainer, pal.secondary, pal.secondaryContainer, pal.tertiary, pal.tertiaryContainer]
                        Rectangle {
                            required property color modelData
                            width: 24
                            height: 24
                            radius: 12
                            color: modelData
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: !root.online
                spacing: 3

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    topLeftRadius: 20
                    topRightRadius: 20
                    bottomLeftRadius: 5
                    bottomRightRadius: 5
                    color: pal.containerHigh

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 10
                        spacing: 10

                        CustomText {
                            Layout.fillWidth: true
                            content: "Transition"
                            size: 13
                            weight: 500
                            customColor: pal.text
                        }

                        CustomListNew {
                            Layout.preferredWidth: 130
                            Layout.preferredHeight: 30
                            color: pal.containerHighest
                            list: Settings.transitionTypes
                            Component.onCompleted: currentVal = Settings.transitionOrDefault(SettingsConfig.theme.transitionType)
                            onCurrentValChanged: {
                                if (currentVal && currentVal !== SettingsConfig.theme.transitionType)
                                    SettingsConfig.theme = Object.assign({}, SettingsConfig.theme, { transitionType: currentVal })
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    topLeftRadius: 5
                    topRightRadius: 5
                    bottomLeftRadius: 20
                    bottomRightRadius: 20
                    color: pal.containerHigh

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 12
                        spacing: 10

                        CustomText {
                            Layout.fillWidth: true
                            content: "Workspace glide"
                            size: 13
                            weight: 500
                            customColor: pal.text
                        }

                        CustomToogle {
                            isToggleOn: SettingsConfig.general.wallpaperGlide ?? true
                            onToggled: state => {
                                SettingsConfig.general = Object.assign({}, SettingsConfig.general, { wallpaperGlide: state })
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    id: applyBtn
                    readonly property bool usable: root.picked !== null && !root.pickedIsCurrent && !root.downloading
                    implicitHeight: 48
                    implicitWidth: applyRow.implicitWidth + 40
                    radius: applyArea.pressed ? 14 : 24
                    color: applyBtn.usable ? pal.primary : pal.containerHighest
                    Behavior on radius { SpatialAnim { speed: "fast" } }
                    RowLayout {
                        id: applyRow
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialIconSymbol {
                            content: root.online && root.pickedLocal === "" ? "download" : "check"
                            iconSize: 20
                            customColor: applyBtn.usable ? pal.primaryText : pal.subtext
                        }
                        CustomText {
                            content: root.downloading ? "Downloading " + Math.round(ServiceWallpaper.downloadProgress * 100) + "%"
                                : root.pickedIsCurrent ? "In use"
                                : root.online && root.pickedLocal === "" ? "Download & apply" : "Apply wallpaper"
                            size: 14
                            weight: 600
                            customColor: applyBtn.usable ? pal.primaryText : pal.subtext
                        }
                    }
                    CustomMouseArea {
                        id: applyArea
                        radius: applyBtn.radius
                        enabled: applyBtn.usable
                        onClicked: root.apply(root.picked)
                    }
                }

                Item { Layout.fillWidth: true }

                PalIconButton {

                    tone: pal
                    visible: !root.online && root.picked !== null
                    icon: "favorite"
                    box: 48
                    lit: !root.online && root.picked !== null
                        && ServiceWallpaper.favoritedWallpapers.indexOf(root.picked) >= 0
                    onClicked: ServiceWallpaper.toggleFavorite(root.picked)
                }

                PalIconButton {

                    tone: pal
                    icon: "shuffle"
                    box: 48
                    onClicked: root.shuffle()
                }
            }
        }


        WallpaperSettingsRail {
            visible: root.railOpen
            Layout.fillHeight: true
            Layout.preferredWidth: 352
        }
    }

    WallpaperContextMenu {
        id: ctxMenu
        anchors.fill: parent
        z: 50
    }
}
