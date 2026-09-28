pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property var entries: []
    readonly property int keep: 6

    readonly property string title: ServiceMusic.activePlayer ? (ServiceMusic.activeTrack?.title ?? "") : ""
    readonly property string artist: ServiceMusic.activeTrack?.artist ?? ""
    readonly property string artUrl: ServiceMusic.activeTrack?.artUrl ?? ""
    readonly property string key: root.title + "|" + root.artist

    property var _current: null

    function _commit() {
        if (root._current && root._current.title !== "" && root._current.title !== "Unknown Title") {
            const prev = root._current
            const list = [prev].concat(root.entries.filter(e => e.title + "|" + e.artist !== prev.title + "|" + prev.artist))
            root.entries = list.slice(0, root.keep)
        }
        root._current = root.title !== "" ? { title: root.title, artist: root.artist, artUrl: root.artUrl, at: Date.now() } : null
    }

    onKeyChanged: root._commit()
    onArtUrlChanged: if (root._current && root._current.title === root.title) root._current.artUrl = root.artUrl
    Component.onCompleted: root._commit()

    function ago(ms) {
        const m = Math.max(0, Math.round((Date.now() - ms) / 60000))
        if (m < 1)
            return "just now"
        if (m < 60)
            return m + " min ago"
        return Math.floor(m / 60) + " h ago"
    }
}
