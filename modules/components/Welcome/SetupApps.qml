import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.settings
import qs.modules.services

Item {
    id: root

    visible: false

    readonly property string cli: Quickshell.shellDir + "/bin/nebula"

    property var apps: []
    property bool scanning: false
    property bool scanned: false
    property bool applying: false
    property bool applied: false
    property var results: ({})

    readonly property var savedIds: {
        const v = SettingsConfig.theme.themeApps
        if (v === undefined || v === null)
            return null
        const out = []
        for (let i = 0; i < v.length; i++)
            out.push(String(v[i]))
        return out
    }

    readonly property var installedApps: root.apps.filter(a => a.installed)
    readonly property var missingApps: root.apps.filter(a => !a.installed)
    readonly property var pickedIds: root.savedIds !== null ? root.savedIds : root.installedApps.map(a => a.id)
    readonly property var pickedApps: root.installedApps.filter(a => root.pickedIds.indexOf(a.id) !== -1)
    readonly property int replaceCount: root.pickedApps.filter(a => a.replacesFile).length

    readonly property var resultList: {
        const out = []
        for (const a of root.apps) {
            const r = root.results[a.id]
            if (r)
                out.push(Object.assign({ name: a.name }, r))
        }
        return out
    }
    readonly property int okCount: root.resultList.filter(r => r.status === "ok").length
    readonly property var failed: root.resultList.filter(r => r.status === "error")

    function isPicked(id) {
        return root.pickedIds.indexOf(id) !== -1
    }

    function setPicked(id, on) {
        const list = root.pickedIds.filter(x => x !== id)
        if (on)
            list.push(id)
        root._save(list)
    }

    function pickAll() {
        root._save(root.installedApps.map(a => a.id))
    }

    function pickNone() {
        root._save([])
    }

    function _save(list) {
        SettingsConfig.theme = Object.assign({}, SettingsConfig.theme, { themeApps: list })
    }

    function scan() {
        if (detector.running)
            return
        root.scanning = true
        detector.running = true
    }

    function apply() {
        if (applier.running)
            return
        const ids = root.pickedIds.slice()
        root._save(ids)
        root.results = ({})
        root.applied = false
        root.applying = true
        const cmd = [root.cli, "scheme", "apply", "--apps", ids.join(","),
                     "--mode", SettingsConfig.theme.matugenTheme ?? "dark"]
        if (ServiceWallpaper.gowallActive && ServiceWallpaper.gowallIcons)
            cmd.push("--keep-icon-theme")
        applier.command = cmd
        applier.running = true
    }

    Process {
        id: detector
        command: [root.cli, "apps", "detect"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.apps = JSON.parse(text)
                } catch (e) {
                    console.warn("[SetupApps] detect output unreadable:", e)
                }
                root.scanning = false
                root.scanned = true
            }
        }
        onExited: code => {
            if (code !== 0) {
                root.scanning = false
                root.scanned = true
            }
        }
    }

    Process {
        id: applier
        stdout: SplitParser {
            onRead: data => {
                if (!data.startsWith("[theme-app] ") || data === "[theme-app] done")
                    return
                try {
                    const r = JSON.parse(data.slice(12))
                    const next = Object.assign({}, root.results)
                    next[r.id] = r
                    root.results = next
                } catch (e) {
                    console.warn("[SetupApps] bad result line:", data)
                }
            }
        }
        onExited: {
            root.applying = false
            root.applied = true
            root.scan()
        }
    }
}
