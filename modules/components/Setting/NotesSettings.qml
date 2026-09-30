import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 5

    readonly property string side: SettingsConfig.general.notesSide ?? "L"
    readonly property bool stacked: (SettingsConfig.general.notesLayout ?? "stack") === "stack"
    readonly property string anchorAt: SettingsConfig.general.notesAnchor ?? "top"
    readonly property int offset: SettingsConfig.general.notesOffset ?? 200
    readonly property int gap: SettingsConfig.general.notesGap ?? 12
    readonly property int cardWidth: SettingsConfig.general.notesCardWidth ?? 340

    readonly property int widthChoice: [300, 340, 400][root.nearest([300, 340, 400], root.cardWidth)]
    readonly property var offsets: [60, 120, 200, 300, 420]
    readonly property var gaps: [0, 6, 12, 20, 32]
    readonly property color ink: "#2e2410"

    function set(key, value) {
        const o = {}
        o[key] = value
        SettingsConfig.general = Object.assign({}, SettingsConfig.general, o)
    }

    function nearest(list, v) {
        let best = 0
        for (let i = 1; i < list.length; i++)
            if (Math.abs(list[i] - v) < Math.abs(list[best] - v))
                best = i
        return best
    }

    function openNote(id) {
        GlobalStates.settingsOpen = false
        ServiceNotes.openId = id
    }

    component SectionLabel: CustomText {
        Layout.topMargin: 20
        size: 13
        customColor: Colors.primary
    }

    component Row2: RowLayout {
        id: r2
        property string title: ""
        property string sub: ""
        default property alias control: slot.data
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            CustomText { content: r2.title; size: 14 }
            CustomText { Layout.fillWidth: true; content: r2.sub; size: 12; customColor: Colors.outline; wrapMode: Text.WordWrap; elide: Text.ElideNone }
        }
        Item {
            id: slot
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }

    Flickable {
        id: flick
        ScrollBar.vertical: CustomScrollBar {}
        anchors.fill: parent
        contentHeight: column.implicitHeight
        contentWidth: width
        clip: true

        ColumnLayout {
            id: column
            anchors { top: parent.top; left: parent.left; right: parent.right }
            anchors { leftMargin: 5; rightMargin: 5; topMargin: 5 }
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: newRow.implicitWidth + 28
                    implicitHeight: 36
                    radius: 18
                    color: Colors.primary
                    RowLayout {
                        id: newRow
                        anchors.centerIn: parent
                        spacing: 6
                        MaterialIconSymbol { content: "add"; iconSize: 17; customColor: Colors.primaryText }
                        CustomText { content: "New note"; size: 13; weight: 700; customColor: Colors.primaryText }
                    }
                    RippleEffect {
                        anchors.fill: parent
                        radius: 18
                        onClicked: root.openNote(ServiceNotes.add())
                    }
                }
            }

            CustomText {
                Layout.topMargin: 6
                Layout.fillWidth: true
                content: "Notes live as small tabs on the screen edge. Hover a tab to peek, click to open, drag it along the edge to reorder or across the screen to switch sides."
                size: 12
                customColor: Colors.outline
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 14
                Layout.preferredHeight: 206
                radius: 20
                color: Colors.surfaceContainer

                Rectangle {
                    id: mini
                    readonly property real k: mini.height / 1080
                    readonly property var notes: ServiceNotes.notes.length
                        ? ServiceNotes.notes.slice().sort((a, b) => a.y - b.y)
                        : [{ c: "butter", y: 0.3 }, { c: "sage", y: 0.45 }, { c: "blush", y: 0.6 }]
                    readonly property real chipH: 46 * mini.k
                    readonly property real stackH: mini.notes.length * mini.chipH + Math.max(0, mini.notes.length - 1) * root.gap * mini.k
                    readonly property real stackTop: {
                        const want = root.anchorAt === "bottom" ? mini.height - root.offset * mini.k - mini.stackH
                            : root.anchorAt === "middle" ? (mini.height - mini.stackH) / 2
                            : root.offset * mini.k
                        return Math.max(52 * mini.k, Math.min(mini.height - 12 * mini.k - mini.stackH, want))
                    }
                    anchors.centerIn: parent
                    height: parent.height - 32
                    width: height * 16 / 9
                    radius: 12
                    color: Colors.surfaceContainerLowest
                    border.width: 1
                    border.color: Colors.outlineVariant
                    clip: true

                    Rectangle {
                        x: 10
                        y: 6
                        width: parent.width - 20
                        height: 8
                        radius: 4
                        color: Colors.surfaceContainerHigh
                    }

                    Repeater {
                        model: mini.notes
                        Rectangle {
                            id: mc
                            required property var modelData
                            required property int index
                            readonly property real cy: root.stacked
                                ? mini.stackTop + mc.index * (mini.chipH + root.gap * mini.k) + mini.chipH / 2
                                : mc.modelData.y * mini.height
                            width: 6
                            height: mini.chipH
                            x: root.side === "R" ? mini.width - width : 0
                            y: mc.cy - height / 2
                            color: ServiceNotes.colors[mc.modelData.c] ?? ServiceNotes.colors.butter
                            topLeftRadius: root.side === "R" ? 3 : 0
                            bottomLeftRadius: root.side === "R" ? 3 : 0
                            topRightRadius: root.side === "R" ? 0 : 3
                            bottomRightRadius: root.side === "R" ? 0 : 3
                            Behavior on y { SpatialAnim {} }
                            Behavior on x { SpatialAnim {} }
                        }
                    }

                    Rectangle {
                        readonly property var first: mini.notes[0]
                        width: root.cardWidth * mini.k
                        height: 240 * mini.k
                        radius: 6
                        x: root.side === "R" ? mini.width - width - 32 * mini.k : 32 * mini.k
                        y: Math.max(52 * mini.k, (root.stacked ? mini.stackTop : first.y * mini.height) - 10 * mini.k)
                        color: ServiceNotes.colors[first.c] ?? ServiceNotes.colors.butter
                        opacity: 0.9
                        Behavior on x { SpatialAnim {} }
                        Behavior on y { SpatialAnim {} }
                        Behavior on width { SpatialAnim {} }
                        Column {
                            x: 8
                            y: 8
                            spacing: 4
                            Rectangle { width: 40; height: 5; radius: 2.5; color: Qt.alpha(root.ink, 0.55) }
                            Rectangle { width: 56; height: 3; radius: 1.5; color: Qt.alpha(root.ink, 0.3) }
                            Rectangle { width: 48; height: 3; radius: 1.5; color: Qt.alpha(root.ink, 0.3) }
                        }
                    }
                }
            }

            SectionLabel { content: "Placement" }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20; bottomRadius: 5
                    Row2 {
                        title: "Screen edge"
                        sub: "Which side the tabs sit on. Changing it moves every note."
                        M3ButtonGroup {
                            model: [
                                { value: "L", label: "Left", icon: "align_horizontal_left" },
                                { value: "R", label: "Right", icon: "align_horizontal_right" }
                            ]
                            activeCheck: v => v === root.side
                            onSegmentClicked: v => {
                                root.set("notesSide", v)
                                ServiceNotes.moveAll(v)
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: root.stacked ? 5 : 20
                    Row2 {
                        title: "Arrangement"
                        sub: root.stacked ? "Tabs line up with an even gap; dragging reorders them."
                                          : "Each tab stays exactly where you drop it."
                        M3ButtonGroup {
                            model: [
                                { value: "stack", label: "Stacked", icon: "view_agenda" },
                                { value: "free", label: "Free", icon: "open_with" }
                            ]
                            activeCheck: v => v === (root.stacked ? "stack" : "free")
                            onSegmentClicked: v => root.set("notesLayout", v)
                        }
                    }
                }

                CustomCard {
                    visible: root.stacked
                    autoRadius: false; topRadius: 5; bottomRadius: 5
                    Row2 {
                        title: "Position"
                        sub: "Where the stack starts along the edge"
                        M3ButtonGroup {
                            model: [
                                { value: "top", label: "Top", icon: "vertical_align_top" },
                                { value: "middle", label: "Middle", icon: "vertical_align_center" },
                                { value: "bottom", label: "Bottom", icon: "vertical_align_bottom" }
                            ]
                            activeCheck: v => v === root.anchorAt
                            onSegmentClicked: v => root.set("notesAnchor", v)
                        }
                    }
                }

                CustomCard {
                    visible: root.stacked && root.anchorAt !== "middle"
                    autoRadius: false; topRadius: 5; bottomRadius: 5
                    Row2 {
                        title: root.anchorAt === "bottom" ? "Distance from bottom" : "Distance from top"
                        sub: "How far the first tab sits from that end of the screen"
                        M3Slider {
                            width: 220
                            height: 30
                            stepCount: root.offsets.length
                            stepLabels: root.offsets.map(v => v + " px")
                            currentStep: root.nearest(root.offsets, root.offset)
                            onStepChanged: step => root.set("notesOffset", root.offsets[step])
                        }
                    }
                }

                CustomCard {
                    visible: root.stacked
                    autoRadius: false; topRadius: 5; bottomRadius: 20
                    Row2 {
                        title: "Gap between notes"
                        sub: "Space between neighbouring tabs"
                        M3Slider {
                            width: 220
                            height: 30
                            stepCount: root.gaps.length
                            stepLabels: root.gaps.map(v => v === 0 ? "none" : v + " px")
                            currentStep: root.nearest(root.gaps, root.gap)
                            onStepChanged: step => root.set("notesGap", root.gaps[step])
                        }
                    }
                }
            }

            SectionLabel { content: "Look" }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 20
                Row2 {
                    title: "Card width"
                    sub: "Size of an open note"
                    M3ButtonGroup {
                        model: [
                            { value: 300, label: "Compact" },
                            { value: 340, label: "Regular" },
                            { value: 400, label: "Wide" }
                        ]
                        activeCheck: v => v === root.widthChoice
                        onSegmentClicked: v => root.set("notesCardWidth", v)
                    }
                }
            }

            SectionLabel { content: "Your notes" }

            CustomCard {
                visible: ServiceNotes.notes.length === 0
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 20
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                    spacing: 6
                    MaterialIconSymbol { Layout.alignment: Qt.AlignHCenter; content: "sticky_note_2"; iconSize: 30; customColor: Colors.outline }
                    CustomText { Layout.alignment: Qt.AlignHCenter; content: "No notes yet"; size: 14 }
                    CustomText { Layout.alignment: Qt.AlignHCenter; content: "Press SUPER+N or use New note to pin one to the edge"; size: 12; customColor: Colors.outline }
                }
            }

            ColumnLayout {
                visible: ServiceNotes.notes.length > 0
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 3

                Repeater {
                    model: ServiceNotes.notes.slice().sort((a, b) => a.y - b.y)

                    CustomCard {
                        id: nr
                        required property var modelData
                        required property int index
                        readonly property int done: nr.modelData.todo.filter(t => t[1]).length
                        autoRadius: false
                        topRadius: nr.index === 0 ? 20 : 5
                        bottomRadius: nr.index === ServiceNotes.notes.length - 1 ? 20 : 5

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Rectangle {
                                implicitWidth: 34
                                implicitHeight: 34
                                radius: 10
                                color: ServiceNotes.colors[nr.modelData.c] ?? ServiceNotes.colors.butter
                                MaterialIconSymbol {
                                    anchors.centerIn: parent
                                    content: nr.modelData.todo.length ? "checklist" : "notes"
                                    iconSize: 18
                                    customColor: root.ink
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                CustomText { Layout.fillWidth: true; content: nr.modelData.title; size: 14 }
                                CustomText {
                                    Layout.fillWidth: true
                                    content: (nr.modelData.side === "R" ? "Right edge" : "Left edge") + " · " + ServiceNotes.ago(nr.modelData.at)
                                             + (nr.modelData.todo.length ? " · " + nr.done + " of " + nr.modelData.todo.length + " done" : "")
                                    size: 12
                                    customColor: Colors.outline
                                }
                            }

                            M3IconButton {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                icon: "open_in_new"
                                iconSize: 18
                                onClicked: root.openNote(nr.modelData.id)
                            }
                            M3IconButton {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                icon: "delete"
                                iconSize: 18
                                onClicked: ServiceNotes.remove(nr.modelData.id)
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }

    ScrollFade {
        anchors.fill: parent
        flickable: flick
    }
}
