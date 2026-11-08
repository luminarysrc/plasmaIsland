import QtQuick

// The black card that springs out below the pill. It shows one of three views:
// "player" (now playing), "weather" (details) or "calendar" (month + world clocks).
// The window follows the current view's size; only the black shape inside animates.
Item {
    id: card

    required property var app      // the PlasmoidItem (player, weather, now, worldClocks, ...)
    property string mode: "player"
    property bool shown: false     // true while the dialog is open
    signal closeRequested()
    signal configureRequested()

    readonly property real u: app.uiScale
    readonly property int topGap: Math.round(6 * u)   // transparent strip between the panel and the card

    readonly property Item current: mode === "weather" ? weatherView
                                  : mode === "calendar" ? calendarView : playerView

    width: current.implicitWidth
    height: topGap + current.implicitHeight

    function popIn() {
        if (app.player) {
            app.player.updatePosition();
        }
        popAnim.restart();
    }

    Rectangle {
        id: shape
        y: card.topGap
        width: parent.width
        height: parent.height - card.topGap
        radius: 24 * card.u
        color: "black"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.16)   // same thin outline as the pill
        transformOrigin: Item.Top

        ParallelAnimation {
            id: popAnim
            NumberAnimation { target: shape; property: "scale"; from: 0.55; to: 1; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
            NumberAnimation { target: shape; property: "opacity"; from: 0; to: 1; duration: 160 }
        }

        PlayerView {
            id: playerView
            anchors.fill: parent
            visible: card.mode === "player"
            active: card.shown && visible
            player: card.app.player
            u: card.u
            onRaiseRequested: card.closeRequested()
        }

        WeatherView {
            id: weatherView
            anchors.fill: parent
            visible: card.mode === "weather"
            weather: card.app.weather
            twelveHour: card.app.twelveHour
            u: card.u
        }

        CalendarView {
            id: calendarView
            anchors.fill: parent
            visible: card.mode === "calendar"
            active: card.shown && visible
            now: card.app.now
            zones: card.app.worldClocks
            timeFormat: card.app.shortTimeFormat
            u: card.u
            onConfigureRequested: card.configureRequested()
        }
    }
}
