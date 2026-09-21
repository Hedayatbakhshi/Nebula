pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.settings

Item {
    id: root

    property LockContext context: null
    property bool exiting: false
    property bool greeter: LockSession.greeter
    focus: true

    readonly property var _cfg: (root.greeter ? SettingsConfig.greeter : SettingsConfig.lockscreen) ?? ({})
    readonly property string variantStyle: LockCatalog.normalize(root._cfg.layout)
    readonly property Item layoutItem: layoutLoader.item

    function focusInput() {
        const f = layoutLoader.authField
        if (f && f.input)
            f.input.forceActiveFocus()
    }

    Keys.onPressed: event => root.focusInput()

    Item {
        anchors.fill: parent
        opacity: 0

        NumberAnimation on opacity {
            from: 0; to: 1; running: true
            duration: 420; easing.type: Easing.OutQuad
        }
        NumberAnimation on opacity {
            from: 1; to: 0; running: root.exiting
            duration: 520; easing.type: Easing.InQuad
        }

        LockBackdrop {
            anchors.fill: parent
            style: LockCatalog.backdropFor(root.variantStyle)
        }
    }

    LockLayoutLoader {
        id: layoutLoader
        anchors.fill: parent
        variant: root.variantStyle
        context: root.context
        exiting: root.exiting
        greeter: root.greeter
        onLoaded: Qt.callLater(root.focusInput)
    }

    Timer {
        interval: 700; running: true
        onTriggered: root.focusInput()
    }
}
