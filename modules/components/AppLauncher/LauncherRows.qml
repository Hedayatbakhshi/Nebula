import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

ListView {
    id: list

    required property Item launcher
    property var rows: []
    property int rowHeight: 50
    property int iconSize: 28
    property bool showHints: true
    property bool showComments: false
    property bool keyHints: false
    property int indexOffset: 0
    property Item nav: null

    property int activeIndex: 0
    readonly property int columns: 1
    readonly property var navRows: {
        const out = []
        for (let i = 0; i < list.rows.length; i++)
            if (list.rows[i].app) out.push(i)
        return out
    }
    readonly property int navCount: list.navRows.length
    readonly property int localActive: (list.nav ? list.nav.activeIndex : list.activeIndex) - list.indexOffset

    function activateIndex(i) {
        const r = list.rows[list.navRows[i - list.indexOffset]]
        if (r) list.launcher.launch(r.app)
    }

    function reveal(i) {
        const r = list.navRows[i - list.indexOffset]
        if (r !== undefined) list.positionViewAtIndex(r, ListView.Contain)
    }

    function rowOf(letter) {
        for (let i = 0; i < list.rows.length; i++)
            if (list.rows[i].header === letter) return i
        return -1
    }

    onRowsChanged: Qt.callLater(() => {
        if ((list.nav ? list.nav.activeIndex : list.activeIndex) <= list.indexOffset)
            list.positionViewAtBeginning()
    })

    clip: true
    spacing: 2
    boundsBehavior: Flickable.StopAtBounds
    model: ScriptModel { values: list.rows }

    delegate: Item {
        id: row
        required property var modelData
        required property int index
        readonly property bool isHeader: !row.modelData.app
        readonly property int navIndex: row.isHeader ? -1 : list.navRows.indexOf(row.index)
        readonly property bool active: !row.isHeader && row.navIndex === list.localActive

        width: list.width
        height: row.isHeader ? 30 : list.rowHeight

        CustomText {
            visible: row.isHeader
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            content: row.modelData.header ?? ""
            size: 11
            weight: 700
            font.letterSpacing: 0.8
            customColor: row.modelData.accent ? Colors.primary : Colors.outline
        }

        Rectangle {
            visible: !row.isHeader
            anchors.fill: parent
            radius: 14
            color: row.active ? Colors.secondaryContainer
                 : area.containsMouse ? Qt.alpha(Colors.primary, 0.08) : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                LauncherIcon {
                    app: row.modelData.app ?? null
                    size: list.iconSize
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    CustomText {
                        Layout.fillWidth: true
                        content: row.modelData.app?.name ?? ""
                        size: 14
                        weight: row.active ? 600 : 500
                        elide: Text.ElideRight
                        customColor: row.active ? Colors.secondaryContainerText : Colors.surfaceText
                    }
                    CustomText {
                        Layout.fillWidth: true
                        visible: list.showComments && text !== ""
                        content: row.modelData.app?.comment || row.modelData.app?.genericName || ""
                        size: 11
                        elide: Text.ElideRight
                        customColor: row.active ? Colors.secondaryContainerText : Colors.outline
                    }
                }

                RowLayout {
                    visible: list.keyHints && row.active
                    spacing: 6
                    CustomText { content: "Open"; size: 11; customColor: Colors.secondaryContainerText }
                    LauncherKey { label: "↵"; tonal: true }
                }

                CustomText {
                    visible: list.showHints && !(list.keyHints && row.active) && (row.modelData.hint ?? "") !== ""
                    content: row.modelData.hint ?? ""
                    size: 11
                    customColor: Colors.outline
                }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onEntered: {
                    if (list.nav) list.nav.activeIndex = row.navIndex + list.indexOffset
                    else list.activeIndex = row.navIndex + list.indexOffset
                }
                onClicked: event => {
                    if (event.button === Qt.RightButton)
                        list.launcher.openMenu(area, event.x, event.y, row.modelData.app)
                    else
                        list.launcher.launch(row.modelData.app)
                }
            }
        }
    }
}
