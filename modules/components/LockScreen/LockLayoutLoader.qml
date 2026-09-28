pragma ComponentBehavior: Bound

import QtQuick

Loader {
    id: root

    property string variant: "veil"
    property var context: null
    property bool preview: false
    property bool exiting: false
    property bool greeter: false
    property var cfg: root.greeter ? LockSession.greeterCfg : LockSession.lockCfg

    readonly property Item authField: root.item ? root.item.authField : null

    sourceComponent: {
        switch (LockCatalog.normalize(root.variant)) {
        case "bloom":    return cBloom
        case "orbit":    return cOrbit
        case "darkroom": return cDarkroom
        case "deck":     return cDeck
        case "tessera":  return cTessera
        case "tear":     return cTear
        default:         return cVeil
        }
    }

    Component { id: cVeil;     LockLayoutVeil     { context: root.context; preview: root.preview; exiting: root.exiting; greeter: root.greeter; cfg: root.cfg } }
    Component { id: cBloom;    LockLayoutBloom    { context: root.context; preview: root.preview; exiting: root.exiting; greeter: root.greeter; cfg: root.cfg } }
    Component { id: cOrbit;    LockLayoutOrbit    { context: root.context; preview: root.preview; exiting: root.exiting; greeter: root.greeter; cfg: root.cfg } }
    Component { id: cDarkroom; LockLayoutDarkroom { context: root.context; preview: root.preview; exiting: root.exiting; greeter: root.greeter; cfg: root.cfg } }
    Component { id: cDeck;     LockLayoutDeck     { context: root.context; preview: root.preview; exiting: root.exiting; greeter: root.greeter; cfg: root.cfg } }
    Component { id: cTessera;  LockLayoutTessera  { context: root.context; preview: root.preview; exiting: root.exiting; greeter: root.greeter; cfg: root.cfg } }
    Component { id: cTear;     LockLayoutTear     { context: root.context; preview: root.preview; exiting: root.exiting; greeter: root.greeter; cfg: root.cfg } }
}
