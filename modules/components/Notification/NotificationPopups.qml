import QtQuick
import Quickshell
import qs.modules.utils
import qs.modules.settings
import qs.modules.services

Item {
    id: popups

    property Item topSurface: null
    property Item bottomSurface: null

    readonly property string style: {
        const s = SettingsConfig.general?.notifPopupStyle ?? "corner"
        return ["bar", "dock", "icon"].indexOf(s) >= 0 ? s : "corner"
    }
    readonly property bool enabled_: popups.style !== "corner" && popups.visible
    readonly property var live: popups.enabled_ ? [...ServiceNotification.popups].reverse() : []
    readonly property var front: popups.live.length > 0 ? popups.live[0] : null
    readonly property bool active: popups.front !== null
    property var shown: null
    property bool hovered: false
    readonly property rect hit: loader.item && loader.item.hit ? loader.item.hit : Qt.rect(0, 0, 0, 0)

    onFrontChanged: if (popups.front) popups.shown = popups.front

    function ease(on) {
        return on ? M3Motion.spatialCurve("default") : [0.3, 0.0, 0.8, 0.15, 1, 1]
    }

    function appKeyFor(n) {
        if (!n) return ""
        GlobalStates.dockIconsVersion
        const map = GlobalStates.dockIconItems
        const keys = Object.keys(map)
        const cands = []
        const de = (n.notification?.desktopEntry ?? "").toLowerCase()
        if (de !== "") cands.push(de)
        const an = (n.appName ?? "").toLowerCase()
        if (an !== "") {
            cands.push(an)
            cands.push(an.replace(/\s+/g, "-"))
            const hit = DesktopEntries.heuristicLookup(n.appName)
            if (hit && hit.id) cands.push(String(hit.id).toLowerCase())
        }
        for (const c of cands) {
            for (const k of keys) {
                if (k === c || k.endsWith("." + c) || c.endsWith("." + k) || k.replace(/\.desktop$/, "") === c)
                    return k
            }
        }
        return ""
    }

    Binding {
        target: ServiceNotification
        property: "popupsPaused"
        value: popups.hovered && popups.active
        when: popups.style !== "corner"
    }

    Binding {
        target: GlobalStates
        property: "dockPeek"
        value: popups.active && (popups.style === "icon" || popups.style === "dock")
    }

    Loader {
        id: loader
        anchors.fill: parent
        active: popups.style !== "corner"
        sourceComponent: popups.style === "bar" ? barComp : popups.style === "dock" ? dockComp : iconComp
    }

    Component { id: barComp; NotifBarTab { host: popups } }
    Component { id: dockComp; NotifDockToast { host: popups } }
    Component { id: iconComp; NotifIconBubble { host: popups } }
}
