import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick.Layouts
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents


PanelWindow{
    id: widgetScreen
    anchors.left: true
    anchors.right: true
    anchors.top: true
    anchors.bottom: true

    // Normally parked behind windows. Arrange mode has to come forward and take
    // the keyboard, otherwise the widgets are unreachable and Esc never arrives.
    WlrLayershell.namespace: "quickshell:backgroundWidgets"
    readonly property bool arranging: GlobalStates.widgetEditMode && !GlobalStates.fileDialogOpen
    WlrLayershell.layer: widgetScreen.arranging ? WlrLayer.Top : WlrLayer.Bottom

    // Three states rather than two. A layer surface with None can be clicked but
    // never receives key events, so text fields were untypable; leaving it on
    // OnDemand permanently meant the surface kept the keyboard and no other
    // window could be typed into. So: ask for the keyboard only while a widget
    // text field actually holds focus, and drop straight back to None after.
    WlrLayershell.keyboardFocus: widgetScreen.arranging       ? WlrKeyboardFocus.Exclusive
                               : GlobalStates.widgetTextFocus ? WlrKeyboardFocus.OnDemand
                                                              : WlrKeyboardFocus.None

    HoverHandler {
        onPointChanged: {
            GlobalStates.desktopCursorX = point.position.x
            GlobalStates.desktopCursorY = point.position.y
        }
        onHoveredChanged: GlobalStates.desktopCursorActive = hovered
    }

    // Parking spot for focus. Clicking empty desktop moves QML focus here, which
    // makes the text field report activeFocus false and releases the keyboard.
    Item { id: focusSink }

    // Sits under everything: a click that a widget already consumed never
    // reaches it, so only clicks on bare desktop drop the field's focus.
    MouseArea {
        anchors.fill: parent
        z: -2
        enabled: GlobalStates.widgetTextFocus && !GlobalStates.widgetEditMode
        onPressed: mouse => {
            focusSink.forceActiveFocus()
            mouse.accepted = false
        }
    }
    color: "transparent"

    Item {
        width: 0
        height: 0
        clip: true

        Image {
            id: backdropRaw
            width: widgetScreen.width
            height: widgetScreen.height
            source: WallpaperTheme.wallpaper !== "" ? "file://" + WallpaperTheme.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 1280
            sourceSize.height: 720
            asynchronous: true
            cache: false
        }

        ShaderEffectSource {
            id: backdropSharp
            width: widgetScreen.width
            height: widgetScreen.height
            textureSize: Qt.size(1280, 720)
            sourceItem: backdropRaw
            hideSource: true
            live: true
        }

        MultiEffect {
            id: backdropBlur
            source: backdropSharp
            width: widgetScreen.width
            height: widgetScreen.height
            blurEnabled: true
            blur: 1.0
            blurMax: 48
            saturation: -0.1
        }
    }

    Component.onCompleted: {
        GlobalStates.widgetBackdrop = backdropBlur
        GlobalStates.widgetBackdropSharp = backdropSharp
    }
    Component.onDestruction: {
        GlobalStates.widgetBackdrop = null
        GlobalStates.widgetBackdropSharp = null
    }

    onWidthChanged: GlobalStates.widgetScreenSize = Qt.vector2d(width, height)
    onHeightChanged: GlobalStates.widgetScreenSize = Qt.vector2d(width, height)

    // ── Arrange mode: grid + scrim, behind the widgets ────────────────
    readonly property real reveal: GlobalStates.widgetEditReveal
    readonly property real scrimT: Math.max(0, Math.min(1, widgetScreen.reveal * 2.5))

    Rectangle {
        anchors.fill: parent
        z: -1
        visible: widgetScreen.reveal > 0.001
        color: Qt.alpha(Colors.surface, 0.45 * widgetScreen.scrimT)

        MouseArea {
            anchors.fill: parent
            enabled: GlobalStates.widgetEditMode
            onClicked: GlobalStates.widgetSettingsKey = ""
        }

        // The pass of light itself: one band travelling left to right, its x driven
        // by the same reveal the cells read, so the lighting always matches the edge.
        Rectangle {
            id: sweepBand
            readonly property real band: M3Motion.reveal.band
            width: parent.width * sweepBand.band
            height: parent.height
            x: -sweepBand.width + widgetScreen.reveal * (parent.width + sweepBand.width)
            visible: widgetScreen.reveal > 0.001 && widgetScreen.reveal < 0.999
            opacity: Math.min(1, Math.min(widgetScreen.reveal, 1 - widgetScreen.reveal) * 8)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0;  color: "transparent" }
                GradientStop { position: 0.55; color: Qt.alpha(Colors.primary, 0.20) }
                GradientStop { position: 1.0;  color: "transparent" }
            }
        }

        Canvas {
            id: gridCanvas
            anchors.fill: parent

            property color inkColor: Colors.surfaceText
            property color liveColor: Colors.primary
            property real reveal: widgetScreen.reveal
            property var geometry: [WidgetSizes.originX, WidgetSizes.originY,
                                    WidgetSizes.gridCols, WidgetSizes.gridRows]
            onInkColorChanged: requestPaint()
            onRevealChanged: requestPaint()
            onGeometryChanged: requestPaint()
            onVisibleChanged: if (visible) requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()

                const p = WidgetSizes.pitch
                const c = WidgetSizes.cell
                const band = M3Motion.reveal.band
                const edge = gridCanvas.reveal * (1 + band)
                ctx.lineWidth = 1

                for (let i = 0; i < WidgetSizes.gridCols; i++) {
                    const x = WidgetSizes.originX + i * p
                    // how far the pass of light has moved past this column
                    const nx = (x + c / 2) / Math.max(1, gridCanvas.width)
                    const t = Math.max(0, Math.min(1, (edge - nx) / band))
                    if (t <= 0.001)
                        continue

                    // lit at the leading edge, settling to resting ink behind it
                    const settle = Math.max(0, Math.min(1, (t - 0.45) / 0.55))
                    const lit = Qt.rgba(liveColor.r + (inkColor.r - liveColor.r) * settle,
                                        liveColor.g + (inkColor.g - liveColor.g) * settle,
                                        liveColor.b + (inkColor.b - liveColor.b) * settle,
                                        1)
                    const inset = (1 - (0.94 + 0.06 * t)) * c / 2

                    ctx.fillStyle = Qt.alpha(inkColor, 0.06 * t)
                    ctx.strokeStyle = Qt.alpha(lit, 0.22 + 0.5 * (1 - settle) * t)

                    for (let j = 0; j < WidgetSizes.gridRows; j++) {
                        const y = WidgetSizes.originY + j * p
                        ctx.beginPath()
                        ctx.roundedRect(x + 0.5 + inset, y + 0.5 + inset,
                                        c - 1 - inset * 2, c - 1 - inset * 2, 16, 16)
                        ctx.fill()
                        ctx.stroke()
                    }
                }
            }
        }
    }

    // Esc leaves arrange mode
    Item {
        anchors.fill: parent
        focus: GlobalStates.widgetEditMode
        Keys.onEscapePressed: {
            if (GlobalStates.widgetSettingsKey !== "") GlobalStates.widgetSettingsKey = ""
            else GlobalStates.widgetEditMode = false
        }
    }

    // ── Arrange mode hint bar ─────────────────────────────────────────
    Rectangle {
        z: 200
        // trails the sweep: the hint only matters once the grid has read as a mode
        readonly property real t: Math.max(0, Math.min(1, (widgetScreen.reveal - 0.45) / 0.35))
        visible: widgetScreen.reveal > 0.001
        opacity: t
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 24 - 12 * (1 - t)
        implicitWidth: hintRow.implicitWidth + 34
        implicitHeight: 42
        radius: 21
        color: Colors.surfaceContainerHigh

        RowLayout {
            id: hintRow
            anchors.centerIn: parent
            spacing: 12

            MaterialIconSymbol { content: "drag_pan"; iconSize: 17; customColor: Colors.primary }
            CustomText { content: "Drag to move · drag the corner to resize"; size: 13 }

            Rectangle {
                implicitWidth: 1; implicitHeight: 18
                color: Colors.outlineVariant; opacity: 0.5
            }

            CustomText {
                content: "Tidy"
                size: 13
                customColor: Colors.primary
                weight: 700
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WidgetLayout.tidy()
                }
            }

            Rectangle {
                implicitWidth: 1; implicitHeight: 18
                color: Colors.outlineVariant; opacity: 0.5
            }

            CustomText {
                content: "Done"
                size: 13
                customColor: Colors.primary
                weight: 700
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: GlobalStates.widgetEditMode = false
                }
            }
        }
    }

    Loader {
        active: SettingsConfig.widgets.showCircularMusicPlayer ?? true
        visible: active
        sourceComponent: CircularMusicPlayer {}
    }

    Loader {
        active: SettingsConfig.widgets.showClock ?? false
        visible: active
        sourceComponent: {
            switch (SettingsConfig.widgets.digitalClockStyle ?? "veil") {
            case "bloom":
            case "shapes":    return clockBloom
            case "orbit":     return clockOrbit
            case "script":    return clockScript
            case "stack":
            case "stacked":   return clockStack
            case "condensed": return clockCondensed
            default:          return clockVeil
            }
        }
    }

    Component { id: clockVeil;      ClockVeil      {} }
    Component { id: clockBloom;     ClockBloom     {} }
    Component { id: clockOrbit;     ClockOrbit     {} }
    Component { id: clockScript;    ClockScript    {} }
    Component { id: clockStack;     ClockStack     {} }
    Component { id: clockCondensed; ClockCondensed {} }

    Loader {
        active: SettingsConfig.widgets.showDateWidget ?? false
        visible: active
        sourceComponent: {
            var style = SettingsConfig.widgets.dateWidgetStyle ?? "default"
            if (style === "calendar") return dateCalendar
            if (style === "pill")     return datePill
            if (style === "split")    return dateSplit
            if (style === "bold")     return dateBold
            if (style === "ghost")    return dateGhost
            if (style === "accent")   return dateAccent
            if (style === "inline")   return dateInline
            if (style === "shape")    return dateShape
            return dateDefault
        }
    }

    Component { id: dateShape; DateWidgetShape {} }

    Component { id: dateDefault;  DateWidget         {} }
    Component { id: dateCalendar; DateWidgetCalendar {} }
    Component { id: datePill;     DateWidgetPill     {} }
    Component { id: dateSplit;    DateWidgetSplit     {} }
    Component { id: dateBold;     DateWidgetBold     {} }
    Component { id: dateGhost;    DateWidgetGhost    {} }
    Component { id: dateAccent;   DateWidgetAccent   {} }
    Component { id: dateInline;   DateWidgetInline   {} }

    Loader {
        active: SettingsConfig.widgets.showAnalogClock ?? false
        visible: active
        sourceComponent: {
            var style = SettingsConfig.widgets.analogClockStyle ?? "classic"
            if (style === "minimal") return analogMinimal
            if (style === "shape")   return analogShape
            return analogClassic
        }
    }

    Component { id: analogClassic; AnalogClockClassic {} }
    Component { id: analogMinimal; AnalogClockMinimal {} }
    Component { id: analogShape;   AnalogClockShape   {} }

    Loader {
        active: SettingsConfig.widgets.showWeatherSlanted ?? false
        visible: active
        sourceComponent: WeatherWidgetSlanted {}
    }

    Loader {
        active: SettingsConfig.widgets.showWeatherForecast ?? false
        visible: active
        sourceComponent: WeatherWidgetForecast {}
    }

    Loader {
        active: SettingsConfig.widgets.showWeatherDetails ?? false
        visible: active
        sourceComponent: WeatherWidgetDetails {}
    }

    Loader {
        active: SettingsConfig.widgets.showWeatherHourly ?? false
        visible: active
        sourceComponent: WeatherHourlyWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showWeatherWind ?? false
        visible: active
        sourceComponent: WeatherWindWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showWeatherBarometer ?? false
        visible: active
        sourceComponent: WeatherBarometerWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showVpn ?? false
        visible: active
        sourceComponent: VpnWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showClaudeCode ?? false
        visible: active
        sourceComponent: ClaudeCodeWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showSunArc ?? false
        visible: active
        sourceComponent: SunArcWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showPomodoro ?? false
        visible: active
        sourceComponent: PomodoroWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showSystemMonitor ?? false
        visible: active
        sourceComponent: {
            var style = SettingsConfig.widgets.systemMonitorStyle ?? "default"
            if (style === "compact") return sysCompact
            if (style === "pulse")   return sysPulse
            return sysDefault
        }
    }

    Component { id: sysDefault; SystemMonitorWidget  {} }
    Component { id: sysCompact; SystemMonitorCompact {} }
    Component { id: sysPulse;   SystemMonitorPulse   {} }

    Loader {
        active: SettingsConfig.widgets.showBattery ?? false
        visible: active
        sourceComponent: {
            var style = SettingsConfig.widgets.batteryStyle ?? "default"
            if (style === "minimal") return battMinimal
            if (style === "ring")    return battRing
            if (style === "shape")   return battShape
            return battDefault
        }
    }

    Component { id: battShape; BatteryWidgetShape {} }

    Component { id: battDefault; BatteryWidget        {} }
    Component { id: battMinimal; BatteryWidgetMinimal {} }
    Component { id: battRing;    BatteryWidgetRing    {} }

    Loader {
        active: SettingsConfig.widgets.showProfileCard ?? false
        visible: active
        sourceComponent: (SettingsConfig.widgets.profileCardStyle ?? "card") === "tile"
            ? profileTile : profileCardComp
    }

    Component { id: profileCardComp; ProfileCard {} }
    Component { id: profileTile;     ProfileTile {} }

    Loader {
        active: SettingsConfig.widgets.showJpDay ?? false
        visible: active
        sourceComponent: JpDayWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showJpClock ?? false
        visible: active
        sourceComponent: JpClockWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showJpHaiku ?? false
        visible: active
        sourceComponent: JpHaikuWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showJpWeather ?? false
        visible: active
        sourceComponent: JpWeatherWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showJpKanji ?? false
        visible: active
        sourceComponent: JpKanjiWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showJpSeal ?? false
        visible: active
        sourceComponent: JpSealWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showMoonPhase ?? false
        visible: active
        sourceComponent: MoonPhaseWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showStickyNote ?? false
        visible: active
        sourceComponent: StickyNoteWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showHeadlines ?? false
        visible: active
        sourceComponent: HeadlinesWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showTaskList ?? false
        visible: active
        sourceComponent: TaskListWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showNetworkGraph ?? false
        visible: active
        sourceComponent: NetworkGraphWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showMusicStrip ?? false
        visible: active
        sourceComponent: MusicStripWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showCassette ?? false
        visible: active
        sourceComponent: CassetteWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showVinyl ?? false
        visible: active
        sourceComponent: VinylWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showWeatherShape ?? false
        visible: active
        sourceComponent: WeatherShapeWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showStatStack ?? false
        visible: active
        sourceComponent: StatStackWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showWorldClock ?? false
        visible: active
        sourceComponent: WorldClockWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showAlbumShape ?? false
        visible: active
        sourceComponent: AlbumShapeWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showPhotoFrame ?? false
        visible: active
        sourceComponent: PhotoFrameWidget {}
    }

    WidgetSettingsCard {
        z: 150
    }

    Connections {
        target: GlobalStates
        function onWidgetEditModeChanged() {
            if (!GlobalStates.widgetEditMode) GlobalStates.widgetSettingsKey = ""
        }
    }

}
