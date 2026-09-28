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
    focus: true

    property string tab: ServiceWallpaper.favoritedWallpapers.length > 0 ? "favorites" : "all"
    property int cur: 0
    property real wheelAccum: 0

    readonly property bool online: ServiceWallpaper.onlineMode
    readonly property var items: root.online ? ServiceWallpaper.onlineWallpapers
        : root.tab === "favorites" ? ServiceWallpaper.favoritedWallpapers
        : ServiceWallpaper.filteredWallpapers
    readonly property int itemCount: root.items ? root.items.length : 0
    readonly property var heroItem: root.cur >= 0 && root.cur < root.itemCount ? root.items[root.cur] : null
    readonly property var preview: !root.online && root.heroItem ? ServiceWallpaper.previewFor(root.heroItem) : null

    readonly property real gap: 12
    readonly property real peekW: 64
    readonly property var sideW: {
        const w = stage.width
        return [Math.round(w * 0.21), Math.round(w * 0.14), Math.round(w * 0.09), 48]
    }
    readonly property real heroW: Math.max(200, stage.width - root.peekW - root.sideW.reduce((a, b) => a + b, 0) - 5 * root.gap)

    function slotX(d) {
        if (d < -1) return -root.gap - 40
        if (d === -1) return 0
        let x = root.peekW + root.gap
        if (d === 0) return x
        x += root.heroW + root.gap
        for (let k = 1; k < d && k <= 4; k++) x += root.sideW[k - 1] + root.gap
        return d > 4 ? stage.width + root.gap : x
    }

    function slotW(d) {
        if (d < -1 || d > 4) return 40
        if (d === -1) return root.peekW
        if (d === 0) return root.heroW
        return root.sideW[d - 1]
    }

    function idOf(it) {
        return it && typeof it === "object" && it.id !== undefined ? it.id : ""
    }

    function nameOf(it) {
        if (!it) return ""
        if (root.online) return root.idOf(it) !== "" ? "wallhaven-" + it.id : ""
        const f = ServiceWallpaper.getOriginalPath(it).split("/").pop()
        const dot = f.lastIndexOf(".")
        return dot > 0 ? f.slice(0, dot) : f
    }

    function go(i) {
        if (root.itemCount === 0) return
        root.cur = Math.max(0, Math.min(root.itemCount - 1, i))
        if (root.online && root.cur >= root.itemCount - 6) ServiceWallpaper.fetchNextPage()
    }

    function apply() {
        const it = root.heroItem
        if (!it) return
        if (root.online) ServiceWallpaper.downloadAndSetWallpaper(it)
        else ServiceWallpaper.setWallpaper(it)
    }

    function toggleFav() {
        if (!root.online && root.heroItem) ServiceWallpaper.toggleFavorite(root.heroItem)
    }

    function shuffle() {
        if (root.itemCount < 2) return
        let i = Math.floor(Math.random() * root.itemCount)
        if (i === root.cur) i = (i + 1) % root.itemCount
        root.go(i)
    }

    function landOnCurrent() {
        const i = root.online ? -1 : root.items.indexOf(ServiceWallpaper.currentCachePath)
        root.cur = i >= 0 ? i : 0
    }

    function setTab(t) {
        if (t === "online") {
            if (!root.online) {
                search.text = ""
                ServiceWallpaper.updateSearch("")
                ServiceWallpaper.onlineMode = true
                ServiceWallpaper.fetchWallhaven(true)
            }
            root.cur = 0
            return
        }
        if (root.online) {
            search.text = ""
            ServiceWallpaper.onlineMode = false
        }
        root.tab = t
        root.landOnCurrent()
    }

    onItemCountChanged: if (root.cur >= root.itemCount) root.cur = Math.max(0, root.itemCount - 1)

    function syncOnline() {
        if (!root.online) {
            onlineModel.clear()
            return
        }
        const n = ServiceWallpaper.onlineWallpapers.length
        if (n < onlineModel.count) onlineModel.clear()
        for (let i = onlineModel.count; i < n; i++) onlineModel.append({})
    }

    ListModel { id: onlineModel }

    Connections {
        target: ServiceWallpaper
        function onOnlineWallpapersChanged() { root.syncOnline() }
        function onOnlineModeChanged() { root.syncOnline() }
    }
    onHeroItemChanged: if (!root.online && root.heroItem) previewTimer.restart()

    Timer {
        id: previewTimer
        interval: 160
        onTriggered: ServiceWallpaper.requestPreview(root.heroItem)
    }

    Component.onCompleted: {
        root.landOnCurrent()
        root.syncOnline()
        if (!GlobalStates.barEditMode) root.forceActiveFocus()
    }

    Keys.onLeftPressed: root.go(root.cur - 1)
    Keys.onRightPressed: root.go(root.cur + 1)
    Keys.onReturnPressed: root.apply()
    Keys.onEnterPressed: root.apply()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_F) root.toggleFav()
        else if (event.key === Qt.Key_Home) root.go(0)
        else if (event.key === Qt.Key_End) root.go(root.itemCount - 1)
        else if (event.key === Qt.Key_Slash) search.forceActiveFocus()
        else return
        event.accepted = true
    }

    component SeatTab: Rectangle {
        id: st
        property string label: ""
        property bool lit: false
        signal clicked
        implicitHeight: 32
        implicitWidth: stText.implicitWidth + 32
        radius: 16
        color: st.lit ? Colors.surfaceContainerHighest : stArea.containsMouse ? Colors.surfaceContainerHigh : "transparent"
        Behavior on color { EffectsColorAnim { speed: "fast" } }
        CustomText {
            id: stText
            anchors.centerIn: parent
            content: st.label
            size: 13
            weight: st.lit ? 600 : 400
            customColor: st.lit ? Colors.surfaceText : Colors.surfaceVariantText
        }
        CustomMouseArea {
            id: stArea
            radius: st.radius
            hoverEnabled: true
            onClicked: st.clicked()
        }
    }

    component SeatKey: Rectangle {
        property string key: ""
        implicitWidth: Math.max(22, skText.implicitWidth + 12)
        implicitHeight: 22
        radius: 6
        color: "transparent"
        border.width: 1
        border.color: Colors.outlineVariant
        CustomText {
            id: skText
            anchors.centerIn: parent
            content: parent.key
            size: 11
            weight: 500
            customColor: Colors.surfaceVariantText
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                implicitHeight: 40
                implicitWidth: tabsRow.implicitWidth + 8
                radius: 20
                color: Colors.surfaceContainer
                RowLayout {
                    id: tabsRow
                    anchors.centerIn: parent
                    spacing: 4
                    SeatTab {
                        label: "Favourites"
                        lit: !root.online && root.tab === "favorites"
                        onClicked: root.setTab("favorites")
                    }
                    SeatTab {
                        label: "All " + ServiceWallpaper.wallpapers.length
                        lit: !root.online && root.tab === "all"
                        onClicked: root.setTab("all")
                    }
                    SeatTab {
                        label: "Online"
                        lit: root.online
                        onClicked: root.setTab("online")
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitHeight: 40
                implicitWidth: 280
                radius: 20
                color: Colors.surfaceContainerHigh
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 10
                    spacing: 8
                    MaterialIconSymbol {
                        content: "search"
                        iconSize: 18
                        customColor: Colors.surfaceVariantText
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        CustomText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: search.text.length === 0
                            content: root.online ? "Search Wallhaven" : "Search"
                            size: 13
                            weight: 400
                            customColor: Colors.surfaceVariantText
                        }
                        TextInput {
                            id: search
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            font.pixelSize: 13
                            font.family: SettingsConfig.general.defaultFont ?? "Rubik"
                            color: Colors.surfaceText
                            onTextChanged: if (!root.online) {
                                if (root.tab === "favorites" && text.length > 0) root.tab = "all"
                                ServiceWallpaper.updateSearch(text)
                                root.cur = 0
                            }
                            Keys.onReturnPressed: {
                                if (root.online && !ServiceWallpaper.isFetchingOnline) {
                                    ServiceWallpaper.currentSearchText = text
                                    ServiceWallpaper.fetchWallhaven(true)
                                    root.cur = 0
                                }
                                root.forceActiveFocus()
                            }
                            Keys.onEscapePressed: {
                                text = ""
                                root.forceActiveFocus()
                            }
                            Keys.onDownPressed: root.forceActiveFocus()
                        }
                    }
                }
            }

            M3IconButton {
                icon: "shuffle"
                onClicked: root.shuffle()
            }
            M3IconButton {
                icon: "chevron_left"
                enabledButton: root.cur > 0
                onClicked: root.go(root.cur - 1)
            }
            M3IconButton {
                icon: "chevron_right"
                enabledButton: root.cur < root.itemCount - 1
                onClicked: root.go(root.cur + 1)
            }
        }

        WallpaperOnlineFilters {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            chipHeight: 30
            visible: root.online
        }

        Item {
            id: stage
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Repeater {
                model: root.online ? onlineModel : root.items

                Item {
                    id: slot
                    required property int index
                    readonly property var modelData: slot.index < root.itemCount ? root.items[slot.index] : null
                    readonly property int d: slot.index - root.cur
                    readonly property bool near: slot.d >= -2 && slot.d <= 5
                    readonly property bool isHero: slot.d === 0

                    visible: slot.near
                    x: root.slotX(slot.d)
                    width: root.slotW(slot.d)
                    height: stage.height
                    Behavior on x { SpatialAnim { speed: "default" } }
                    Behavior on width { SpatialAnim { speed: "default" } }

                    Loader {
                        anchors.fill: parent
                        active: slot.near
                        sourceComponent: ClippingRectangle {
                            radius: slot.width > 100 ? 28 : 20
                            color: Colors.surfaceContainer
                            Behavior on radius { SpatialAnim { speed: "fast" } }

                            Image {
                                anchors.fill: parent
                                source: root.online ? (root.idOf(slot.modelData) !== "" ? slot.modelData.thumbUrl : "")
                                    : typeof slot.modelData === "string" ? "file://" + slot.modelData : ""
                                sourceSize.width: 320
                                sourceSize.height: 320
                                asynchronous: true
                                fillMode: Image.PreserveAspectCrop
                            }

                            Image {
                                id: full
                                anchors.fill: parent
                                source: slot.isHero && !root.online && typeof slot.modelData === "string" ? "file://" + ServiceWallpaper.getOriginalPath(slot.modelData) : ""
                                sourceSize.width: 1280
                                sourceSize.height: 720
                                asynchronous: true
                                fillMode: Image.PreserveAspectCrop
                                opacity: status === Image.Ready ? 1 : 0
                                Behavior on opacity { EffectsAnim { speed: "default" } }
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: "black"
                                opacity: slot.isHero ? 0 : slotArea.containsMouse ? 0.05 : 0.18
                                Behavior on opacity { EffectsAnim { speed: "fast" } }
                            }

                            MaterialIconSymbol {
                                visible: !root.online && slot.width > 100
                                         && ServiceWallpaper.favoritedWallpapers.indexOf(slot.modelData) >= 0
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 14
                                content: "favorite"
                                iconSize: 18
                                customColor: "white"
                            }

                            MouseArea {
                                id: slotArea
                                anchors.fill: parent
                                enabled: !slot.isHero
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.go(slot.index)
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                onClicked: mouse => {
                                    const m = mapToItem(root, mouse.x, mouse.y)
                                    ctxMenu.show(m.x, m.y, slot.modelData, root.online)
                                }
                            }

                            RowLayout {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 16
                                spacing: 10
                                opacity: slot.isHero ? 1 : 0
                                visible: opacity > 0
                                Behavior on opacity { EffectsAnim { speed: "default" } }

                                Rectangle {
                                    implicitHeight: capCol.implicitHeight + 18
                                    implicitWidth: Math.min(capCol.implicitWidth + 32, slot.width * 0.6)
                                    radius: 18
                                    color: Qt.rgba(0.04, 0.05, 0.08, 0.6)
                                    ColumnLayout {
                                        id: capCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        spacing: 1
                                        CustomText {
                                            Layout.fillWidth: true
                                            content: root.nameOf(slot.modelData)
                                            size: 15
                                            weight: 600
                                            customColor: "white"
                                        }
                                        CustomText {
                                            Layout.fillWidth: true
                                            content: root.online ? (root.idOf(slot.modelData) !== "" ? slot.modelData.resolution : "")
                                                : slot.modelData === ServiceWallpaper.currentCachePath ? "In use"
                                                : (slot.index + 1) + " of " + root.itemCount
                                            size: 11
                                            weight: 400
                                            customColor: Qt.rgba(1, 1, 1, 0.8)
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    id: applyBtn
                                    readonly property bool busy: root.online && root.idOf(slot.modelData) !== "" && ServiceWallpaper.downloadingId === root.idOf(slot.modelData)
                                    readonly property bool inUse: !root.online && slot.modelData === ServiceWallpaper.currentCachePath
                                    implicitHeight: 44
                                    implicitWidth: applyRow.implicitWidth + 36
                                    radius: applyArea.pressed ? 12 : 22
                                    color: applyBtn.inUse ? Qt.rgba(0.04, 0.05, 0.08, 0.6) : Colors.primary
                                    Behavior on radius { SpatialAnim { speed: "fast" } }
                                    RowLayout {
                                        id: applyRow
                                        anchors.centerIn: parent
                                        spacing: 8
                                        MaterialIconSymbol {
                                            content: applyBtn.inUse ? "check_circle" : root.online ? "download" : "check"
                                            iconSize: 18
                                            customColor: applyBtn.inUse ? "white" : Colors.primaryText
                                        }
                                        CustomText {
                                            content: applyBtn.busy ? Math.round(ServiceWallpaper.downloadProgress * 100) + "%"
                                                : applyBtn.inUse ? "In use" : "Apply"
                                            size: 14
                                            weight: 600
                                            customColor: applyBtn.inUse ? "white" : Colors.primaryText
                                        }
                                    }
                                    CustomMouseArea {
                                        id: applyArea
                                        radius: applyBtn.radius
                                        enabled: !applyBtn.inUse && !applyBtn.busy
                                        onClicked: root.apply()
                                    }
                                }
                            }
                        }
                    }

                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => {
                    const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : -wheel.angleDelta.x
                    if (delta === 0) {
                        wheel.accepted = false
                        return
                    }
                    if (root.wheelAccum !== 0 && (root.wheelAccum > 0) !== (delta > 0)) root.wheelAccum = 0
                    root.wheelAccum += delta / 120
                    const steps = root.wheelAccum > 0 ? Math.floor(root.wheelAccum) : Math.ceil(root.wheelAccum)
                    if (steps !== 0) {
                        root.wheelAccum -= steps
                        root.go(root.cur - steps)
                    }
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
                    color: Colors.primary
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
                    customColor: Colors.surfaceVariantText
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: root.peekW + root.gap
            spacing: 10

            Row {
                spacing: 5
                visible: root.preview !== null
                Repeater {
                    model: root.preview ? ["primary", "primaryContainer", "secondary", "secondaryContainer", "tertiary", "tertiaryContainer"] : []
                    Rectangle {
                        required property string modelData
                        width: 16
                        height: 16
                        radius: 8
                        color: root.preview[modelData]
                    }
                }
            }

            CustomText {
                content: root.online ? "" : root.preview ? "theme it would give you" : "reading colours…"
                size: 12
                weight: 400
                customColor: Colors.surfaceVariantText
            }

            Item { Layout.fillWidth: true }

            SeatKey { key: "←" }
            SeatKey { key: "→" }
            CustomText { content: "browse"; size: 12; weight: 400; customColor: Colors.surfaceVariantText }
            Item { implicitWidth: 6 }
            SeatKey { key: "↵" }
            CustomText { content: "apply"; size: 12; weight: 400; customColor: Colors.surfaceVariantText }
            Item { implicitWidth: 6; visible: !root.online }
            SeatKey { key: "F"; visible: !root.online }
            CustomText { content: "favourite"; size: 12; weight: 400; customColor: Colors.surfaceVariantText; visible: !root.online }
            Item { implicitWidth: 6 }
            SeatKey { key: "/" }
            CustomText { content: "search"; size: 12; weight: 400; customColor: Colors.surfaceVariantText }
        }
    }

    WallpaperContextMenu {
        id: ctxMenu
        anchors.fill: parent
        z: 50
    }
}
