pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Services.Mpris
import qs.modules.settings

Singleton{
    id: root

    property MprisPlayer trackedPlayer: null
    property MprisPlayer activePlayer: trackedPlayer ?? Mpris.players.values[0] ?? null
    signal trackChanged(reverse: bool)

    property bool __reverse: false
    property var activeTrack
    property string _lastArtUrl: ""

    property var _hdCache: ({})
    readonly property int _hdMinSide: 300
    readonly property string _rawArt: root.activePlayer?.trackArtUrl ?? ""

    function _hdKey(title, artist) {
        return String(title).toLowerCase() + "|" + String(artist).toLowerCase()
    }

    function _hdFor(title, artist) {
        const hit = root._hdCache[root._hdKey(title, artist)]
        return typeof hit === "string" ? hit : ""
    }

    function _cleanTitle(t) {
        return String(t)
            .replace(/\s*[\(\[][^\)\]]*(remaster|version|official|video|audio|lyric|live|edit|mono|stereo|feat)[^\)\]]*[\)\]]/gi, "")
            .replace(/\s+-\s+.*(remaster|version|edit|live|mono|stereo).*$/i, "")
            .trim()
    }

    function _considerHd() {
        const p = root.activePlayer
        if (!p || !p.trackTitle || p.trackTitle === "")
            return
        const key = root._hdKey(p.trackTitle, p.trackArtist ?? "")
        if (root._hdCache[key] !== undefined || artLookup.running || artFetch.running || ytLookup.running)
            return
        if (root._rawArt !== "") {
            if (artProbe.status === Image.Loading || artProbe.status === Image.Null)
                return
            if (artProbe.status === Image.Ready && Math.min(artProbe.implicitWidth, artProbe.implicitHeight) >= root._hdMinSide)
                return
        }
        artLookup.forKey = key
        artLookup.forArtist = String(p.trackArtist ?? "").toLowerCase()
        artLookup.forAlbum = String(p.trackAlbum ?? "").toLowerCase()
        artLookup.forQuery = ((p.trackArtist ?? "") + " " + p.trackTitle).trim()
        artLookup.command = ["curl", "-sf", "-m", "8", "-G", "https://itunes.apple.com/search",
                             "--data-urlencode", "term=" + ((p.trackArtist ?? "") + " " + root._cleanTitle(p.trackTitle)).trim(),
                             "--data-urlencode", "entity=song", "--data-urlencode", "limit=8"]
        artLookup.running = true
    }

    function _applyHd(key, url) {
        const cache = Object.assign({}, root._hdCache)
        cache[key] = url
        root._hdCache = cache
        const p = root.activePlayer
        if (url !== "" && p && root._hdKey(p.trackTitle ?? "", p.trackArtist ?? "") === key && root.activeTrack)
            root.activeTrack = Object.assign({}, root.activeTrack, { artUrl: url })
    }

    Image {
        id: artProbe
        visible: false
        asynchronous: true
        source: root._rawArt
        onStatusChanged: root._considerHd()
    }

    Timer {
        id: hdKick
        interval: 400
        onTriggered: root._considerHd()
    }

    on_RawArtChanged: hdKick.restart()

    Process {
        id: artLookup
        property string forKey: ""
        property string forArtist: ""
        property string forAlbum: ""
        property string forQuery: ""
        stdout: StdioCollector { id: artOut }
        onExited: {
            let url = ""
            try {
                const results = JSON.parse(artOut.text).results ?? []
                const a = artLookup.forArtist
                const byArtist = results.filter(r => {
                    const n = String(r.artistName ?? "").toLowerCase()
                    return a === "" || n.includes(a) || a.includes(n)
                })
                const pick = byArtist.find(r => String(r.collectionName ?? "").toLowerCase() === artLookup.forAlbum) ?? byArtist[0]
                if (pick && pick.artworkUrl100)
                    url = String(pick.artworkUrl100).replace(/\/\d+x\d+bb\./, "/600x600bb.")
            } catch (e) {
                url = ""
            }
            if (url === "") {
                ytLookup.forKey = artLookup.forKey
                ytLookup.command = ["sh", "-c", "command -v yt-dlp >/dev/null && timeout 25 yt-dlp --no-warnings --skip-download --no-playlist --print thumbnail \"ytsearch1:$1\"",
                                    "sh", artLookup.forQuery]
                ytLookup.running = true
                return
            }
            root._fetchArt(artLookup.forKey, url, "")
        }
    }

    function _fetchArt(key, url, fallback) {
        const file = root._artDir + "/" + Qt.md5(key) + ".jpg"
        artFetch.forKey = key
        artFetch.file = file
        artFetch.command = ["sh", "-c", "mkdir -p \"$1\"; [ -s \"$2\" ] || { { curl -sf -m 10 -o \"$2.part\" \"$3\" || { [ -n \"$4\" ] && curl -sf -m 10 -o \"$2.part\" \"$4\"; }; } && mv \"$2.part\" \"$2\"; }; [ -s \"$2\" ]",
                            "sh", root._artDir, file, url, fallback]
        artFetch.running = true
    }

    Process {
        id: ytLookup
        property string forKey: ""
        stdout: StdioCollector { id: ytOut }
        onExited: {
            const line = ytOut.text.trim().split("\n").pop() ?? ""
            const m = line.match(/\/vi(?:_webp)?\/([A-Za-z0-9_-]{11})\//)
            if (!m) {
                root._applyHd(ytLookup.forKey, "")
                hdKick.restart()
                return
            }
            root._fetchArt(ytLookup.forKey, "https://i.ytimg.com/vi/" + m[1] + "/maxresdefault.jpg",
                           "https://i.ytimg.com/vi/" + m[1] + "/hqdefault.jpg")
        }
    }

    readonly property string _artDir: Quickshell.env("HOME") + "/.cache/quickshell/art"

    Process {
        id: artFetch
        property string forKey: ""
        property string file: ""
        onExited: code => {
            root._applyHd(artFetch.forKey, code === 0 ? "file://" + artFetch.file : "")
            hdKick.restart()
        }
    }

    readonly property string _cli: Quickshell.shellDir + "/bin/nebula"

    Process {
        id: musicColorGen
        onExited: (exitCode) => {
            if (exitCode !== 0)
                console.warn("[ServiceMusic] music_colors.sh exited with code:", exitCode)
        }
    }

    function generateMusicColors(artUrl) {
        if (!artUrl || artUrl === _lastArtUrl) return
        _lastArtUrl = artUrl
        musicColorGen.command = [
            _cli,
            "music-colors",
            artUrl,
            SettingsConfig.theme.matugenScheme,
            SettingsConfig.theme.matugenTheme.toLowerCase()
        ]
        musicColorGen.running = true
    }

    property real trackLength: 0

    function _metadataLength(player) {
        const raw = Number(player?.metadata?.["mpris:length"])
        return (isFinite(raw) && raw > 0) ? raw / 1000000 : 0
    }

    function refreshLength() {
        const p = root.activePlayer
        if (!p) {
            root.trackLength = 0
            return
        }
        const fromMeta = root._metadataLength(p)
        if (fromMeta > 0) {
            root.trackLength = fromMeta
            return
        }
        if (p.lengthSupported && p.length > 0)
            root.trackLength = p.length
    }

    Timer {
        running: ServiceMusic.activePlayer?.isPlaying ?? false
        interval: 1000
        repeat: true
        onTriggered: {
            if (ServiceMusic.activePlayer) {
                ServiceMusic.activePlayer.positionChanged()
                ServiceMusic.refreshLength()
            }
        }
    }

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: {
                if (root.trackedPlayer == null || modelData.isPlaying) {
                    root.trackedPlayer = modelData
                }
            }

            Component.onDestruction: {
                if (root.trackedPlayer == null || !root.trackedPlayer.isPlaying) {
                    for (const player of Mpris.players.values) {
                        if (player.playbackState.isPlaying) {
                            root.trackedPlayer = player
                            break
                        }
                    }

                    if (trackedPlayer == null && Mpris.players.values.length != 0) {
                        trackedPlayer = Mpris.players.values[0]
                    }
                }
            }

            function onPlaybackStateChanged() {
                if (root.trackedPlayer !== modelData) root.trackedPlayer = modelData
            }
        }
    }

    Connections {
        target: activePlayer

        function onPostTrackChanged() {
            root.updateTrack()
        }

        function onMetadataChanged() {
            root.refreshLength()
        }

        function onTrackArtUrlChanged() {
            if (root.activePlayer.uniqueId == root.activeTrack.uniqueId && root.activePlayer.trackArtUrl != root.activeTrack.rawArtUrl) {
                const r = root.__reverse
                root.updateTrack()
                root.__reverse = r
            }
        }
    }

    function formatTime(seconds) {
        if (!seconds || seconds <= 0) return "0:00"
        const mins = Math.floor(seconds / 60)
        const secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    onActivePlayerChanged: this.updateTrack()

    function updateTrack() {
        hdKick.restart()
        this.trackLength = 0
        this.refreshLength()
        this.activeTrack = {
            uniqueId: this.activePlayer?.uniqueId ?? 0,
            artUrl: root._hdFor(this.activePlayer?.trackTitle ?? "", this.activePlayer?.trackArtist ?? "") || (this.activePlayer?.trackArtUrl ?? ""),
            rawArtUrl: this.activePlayer?.trackArtUrl ?? "",
            title: this.activePlayer?.trackTitle || "Unknown Title",
            artist: this.activePlayer?.trackArtist || "Unknown Artist",
            album: this.activePlayer?.trackAlbum || "Unknown Album",
            desktopEntry: this.activePlayer?.desktopEntry,
            identity: this.activePlayer?.identity
        }

        this.trackChanged(__reverse)
        this.__reverse = false

        // if (this.activeTrack.artUrl)
        //     this.generateMusicColors(this.activeTrack.artUrl)
    }

    property bool isPlaying: this.activePlayer && this.activePlayer.isPlaying
    property bool canTogglePlaying: this.activePlayer?.canTogglePlaying ?? false
    function togglePlaying() {
        if (this.canTogglePlaying) this.activePlayer.togglePlaying()
    }

    property bool canGoPrevious: this.activePlayer?.canGoPrevious ?? false
    function previous() {
        if (this.canGoPrevious) {
            this.__reverse = true
            this.activePlayer.previous()
        }
    }

    property bool canGoNext: this.activePlayer?.canGoNext ?? false
    function next() {
        if (this.canGoNext) {
            this.__reverse = false
            this.activePlayer.next()
        }
    }

    property bool canChangeVolume: this.activePlayer && this.activePlayer.volumeSupported && this.activePlayer.canControl

    property bool loopSupported: this.activePlayer && this.activePlayer.loopSupported && this.activePlayer.canControl
    property var loopState: this.activePlayer?.loopState ?? MprisLoopState.None
    function setLoopState(loopState) {
        if (this.loopSupported) {
            this.activePlayer.loopState = loopState
        }
    }

    property bool shuffleSupported: this.activePlayer && this.activePlayer.shuffleSupported && this.activePlayer.canControl
    property bool hasShuffle: this.activePlayer?.shuffle ?? false
    function setShuffle(shuffle) {
        if (this.shuffleSupported) {
            this.activePlayer.shuffle = shuffle
        }
    }

    function setActivePlayer(player) {
        const targetPlayer = player ?? Mpris.players[0]

        if (targetPlayer && this.activePlayer) {
            this.__reverse = Mpris.players.indexOf(targetPlayer) < Mpris.players.indexOf(this.activePlayer)
        } else {
            this.__reverse = false
        }

        this.trackedPlayer = targetPlayer
    }

    function pauseAll() {
        for (const player of Mpris.players.values) {
            if (player.canPause) player.pause()
        }
    }
}
