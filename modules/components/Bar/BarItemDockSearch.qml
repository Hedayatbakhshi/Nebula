import QtQuick
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root

    property Item host: null
    property string itemId: ""
    readonly property bool shown: true

    readonly property real icon: root.host && root.host.iconSize ? root.host.iconSize : 32
    readonly property real pillH: root.icon + 12
    readonly property real pillW: BarLayout.opt(root.itemId, "width") ?? 200
    readonly property bool editing: !!root.host && !!root.host.editing

    implicitWidth: root.pillW
    implicitHeight: root.icon + 22

    function handOff(text) {
        GlobalStates.launcherSeed = text
        GlobalStates.appLauncherOpen = true
        field.text = ""
        root.release()
    }

    function claim() {
        if (root.editing) return
        GlobalStates.dockSearchActive = true
        field.forceActiveFocus()
    }

    function release() {
        GlobalStates.dockSearchActive = false
        field.focus = false
    }

    onEditingChanged: if (root.editing) root.release()
    Component.onDestruction: root.release()

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: root.pillW
        height: root.pillH
        radius: root.pillH / 2
        color: field.activeFocus ? Colors.surfaceContainerHighest
             : pillMa.containsMouse ? Colors.surfaceContainerHigh
                                    : Colors.surfaceContainer
        Behavior on color { EffectsColorAnim { speed: "fast" } }

        MaterialIconSymbol {
            id: glass
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            content: "search"
            iconSize: 18
            customColor: field.activeFocus ? Colors.primary : Colors.outline
        }

        TextInput {
            id: field
            anchors {
                left: glass.right; leftMargin: 8
                right: parent.right; rightMargin: 14
                verticalCenter: parent.verticalCenter
            }
            height: parent.height - 12
            verticalAlignment: TextInput.AlignVCenter
            font.pixelSize: 13
            font.family: SettingsConfig.general.defaultFont ?? "Rubik"
            color: Colors.surfaceText
            selectionColor: Colors.primary
            selectedTextColor: Colors.primaryText
            clip: true
            enabled: !root.editing

            onTextChanged: if (text !== "") root.handOff(text)

            Keys.onEscapePressed: root.release()

            CustomText {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                content: "Search apps"
                size: 13
                weight: 400
                customColor: Colors.outline
                visible: field.text === ""
            }
        }

        MouseArea {
            id: pillMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.editing ? Qt.ArrowCursor : Qt.IBeamCursor
            acceptedButtons: Qt.LeftButton
            onClicked: root.claim()
        }
    }
}
