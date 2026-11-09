import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.mpris as Mpris
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: compactRepresentation
    activationTogglesExpanded: false

    // The island is its own tooltip; an empty tooltip keeps Plasma's from covering it.
    toolTipMainText: ""
    toolTipSubText: ""

    // UI language: "" follows the system, otherwise "en", "ru", "es", "de" or "el".
    // Dates, month and weekday names follow it too (times keep the system/12h/24h setting).
    readonly property string language: Plasmoid.configuration.language
    readonly property var uiLocale: language === "" ? Qt.locale() : Qt.locale(language)

    // Pill height in px (settings, or Ctrl+scroll on the pill). Everything else scales with it.
    readonly property int pillSize: Plasmoid.configuration.size
    readonly property real uiScale: pillSize / 32

    // The card under the pill: whether it is open and which view it shows
    // ("player", "weather" or "calendar").
    property bool cardOpen: false
    property string cardMode: "player"

    function openCard(mode) {
        cardMode = mode;
        cardOpen = true;
    }

    // --- Clock -----------------------------------------------------------
    property date now: new Date()
    readonly property bool showSeconds: Plasmoid.configuration.showSeconds
    // Clock format: 0 = follow system locale, 1 = 12-hour, 2 = 24-hour.
    readonly property int clockMode: Plasmoid.configuration.clockFormat
    readonly property string shortTimeFormat: clockMode === 1 ? "h:mm AP"
        : clockMode === 2 ? "HH:mm" : Qt.locale().timeFormat(Locale.ShortFormat)
    readonly property bool twelveHour: /a/i.test(shortTimeFormat)
    readonly property string timeText: {
        let fmt = shortTimeFormat;
        if (showSeconds && fmt.indexOf("ss") < 0) {
            fmt = fmt.replace("mm", "mm:ss");
        }
        return uiLocale.toString(now, fmt);
    }
    // Date format shown on the right of the pill (see the settings for the choices).
    readonly property var dateFormats: [
        "ddd, MMM d", "ddd, d MMM", "dd/MM/yyyy", "MM/dd/yyyy", "yyyy-MM-dd", "d MMMM yyyy"
    ]
    readonly property string dateText: {
        const i = Plasmoid.configuration.dateFormat;
        if (i === 6) {
            return uiLocale.toString(now, Locale.ShortFormat);
        }
        return uiLocale.toString(now, dateFormats[i] || dateFormats[0]);
    }

    Timer {
        // Fire just after each second boundary so the display never lags.
        interval: 1000 - (new Date().getMilliseconds()) + 5
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.now = new Date();
            interval = 1000 - root.now.getMilliseconds() + 5;
        }
    }

    // --- World clocks ----------------------------------------------------
    // Any number of IANA zone ids from the settings, e.g. "America/New_York".
    readonly property var timeZones: Plasmoid.configuration.timeZones
    P5Support.DataSource {
        id: timeSource
        engine: "time"
        connectedSources: root.timeZones
        interval: 60000
        intervalAlignment: P5Support.Types.AlignToMinute
    }
    // [{ city, delta }] where delta = zone offset − local offset, in seconds.
    // Only reassigned when something actually changes, so the list in the calendar card keeps
    // its scroll position; each row computes its own time from `now` and `delta`.
    property var worldClocks: []
    function rebuildWorldClocks() {
        const localOffset = -new Date().getTimezoneOffset() * 60;
        const out = [];
        for (const tz of timeZones) {
            const d = timeSource.data[tz];
            if (!d || d["Offset"] === undefined) {
                continue;
            }
            out.push({
                city: (d["Timezone City"] || tz.split("/").pop()).replace(/_/g, " "),
                delta: d["Offset"] - localOffset
            });
        }
        if (JSON.stringify(out) !== JSON.stringify(worldClocks)) {
            worldClocks = out;
        }
    }
    onTimeZonesChanged: rebuildWorldClocks()
    Connections {
        target: timeSource
        function onNewData() { root.rebuildWorldClocks() }
    }

    // --- Weather ---------------------------------------------------------
    Weather {
        id: weather
        city: Plasmoid.configuration.city
        language: root.language
    }
    readonly property alias weather: weather

    // --- Media -----------------------------------------------------------
    // Row 0 of the model is Plasma's multiplexer: it follows whichever player is active.
    Mpris.Mpris2Model {
        id: mpris
    }
    readonly property var player: mpris.currentPlayer

    compactRepresentation: Island { app: root }
    fullRepresentation: Item {}

    // A global shortcut or the keyboard can still "activate" the applet; treat it as a click.
    onExpandedChanged: {
        if (expanded) {
            expanded = false;
            if (cardOpen) {
                cardOpen = false;
            } else {
                openCard("player");
            }
        }
    }
}
