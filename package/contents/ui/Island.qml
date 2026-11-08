import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

// The pill in the panel.
// - Resting: the time, plus a small equalizer while music plays.
// - Hover (or card open): springs wider; weather on the left, date on the right.
// - Click: the time opens the player card, the weather opens weather details,
//   the date opens the calendar with world clocks.
// - New track: briefly widens to show its title, then settles back.
Item {
    id: island

    required property var app   // the PlasmoidItem from main.qml

    readonly property bool hovered: hover.containsMouse
    readonly property bool wide: hovered || app.cardOpen
    readonly property bool playing: !!app.player && app.player.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property bool hasCity: app.weather.hasCity

    readonly property real pillHeight: app.pillSize
    readonly property real fontSize: Math.round(pillHeight * 0.46)
    readonly property real pad: Math.round(pillHeight * 0.55)
    readonly property real gap: Math.round(pillHeight * 0.45)

    // Equalizer next to the time while playing (resting state only).
    readonly property bool eqVisible: playing && !wide && !toast
    readonly property real eqWidth: Math.round(fontSize * 0.95)
    readonly property real eqGap: Math.round(fontSize * 0.5)

    // Both sides reserve the wider of the two, so the time stays dead centre.
    readonly property real sideWidth: Math.max(weatherRow.implicitWidth, dateLabel.implicitWidth)
    readonly property real restWidth: timeLabel.implicitWidth + 2 * pad + (eqVisible ? eqWidth + eqGap : 0)
    readonly property real wideWidth: timeLabel.implicitWidth + 2 * (sideWidth + gap) + 2 * pad

    // The panel slot is always as wide as the widened pill, so neighbours never shift
    // while it animates.
    Layout.minimumWidth: wideWidth
    Layout.preferredWidth: wideWidth
    Layout.maximumWidth: wideWidth
    Layout.fillHeight: true
    implicitHeight: pillHeight

    // --- New-track toast ----------------------------------------------------
    property bool toast: false
    property string lastTrackKey: ""
    property bool toastArmed: false   // not in the first seconds after login/load

    function trackKey() {
        const p = app.player;
        return p && p.track ? p.track + "\u0001" + (p.artist || "") : "";
    }
    function maybeToast() {
        const key = trackKey();
        if (key === "" || key === lastTrackKey) {
            return;
        }
        lastTrackKey = key;
        if (!toastArmed || !Plasmoid.configuration.showTrackToast || wide) {
            return;
        }
        toast = true;
        toastTimer.restart();
    }
    Timer {
        interval: 3000
        running: true
        onTriggered: {
            island.lastTrackKey = island.trackKey();
            island.toastArmed = true;
        }
    }
    Timer {
        id: toastTimer
        interval: 3500
        onTriggered: island.toast = false
    }
    Connections {
        target: island.app.player
        ignoreUnknownSignals: true
        function onTrackChanged() { island.maybeToast() }
    }
    onWideChanged: if (wide) toast = false

    // --- Click routing --------------------------------------------------------
    // Clicking the pill while the card is open first takes focus away from the card, which
    // closes it. Remember what closed and when, so that click doesn't reopen the same view.
    property double cardClosedAt: 0
    property string closedMode: ""

    function zoneAt(x) {
        if (!wide) {
            return "player";
        }
        if (x < timeLabel.x - gap / 2) {
            return "weather";
        }
        if (x > timeLabel.x + timeLabel.width + gap / 2) {
            return "calendar";
        }
        return "player";
    }
    function configure() {
        app.cardOpen = false;
        Plasmoid.internalAction("configure").trigger();
    }
    function handleClick(x) {
        const zone = zoneAt(x);
        if (zone === "weather" && !hasCity) {
            configure();
            return;
        }
        if (app.cardOpen) {
            if (app.cardMode === zone) {
                app.cardOpen = false;
            } else {
                app.cardMode = zone;
            }
            return;
        }
        if (Date.now() - cardClosedAt < 300 && closedMode === zone) {
            return;
        }
        app.openCard(zone);
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        height: island.pillHeight
        width: island.wide || island.toast ? island.wideWidth : island.restWidth
        radius: height / 2
        color: "black"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.16)   // thin outline so it shows on a dark panel
        clip: true

        Behavior on width {
            SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.3 }
        }

        Text {
            id: timeLabel
            anchors.centerIn: parent
            // Make room for the equalizer on the right while resting.
            anchors.horizontalCenterOffset: island.eqVisible ? -(island.eqWidth + island.eqGap) / 2 : 0
            Behavior on anchors.horizontalCenterOffset { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            text: island.app.timeText
            color: "white"
            font.pixelSize: island.fontSize
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }   // tabular digits: the pill doesn't wobble each second
            opacity: island.toast ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }

        Equalizer {
            anchors.left: timeLabel.right
            anchors.leftMargin: island.eqGap
            anchors.verticalCenter: parent.verticalCenter
            width: island.eqWidth
            height: Math.round(island.fontSize * 0.85)
            running: island.eqVisible
            opacity: island.eqVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }

        Row {
            id: weatherRow
            x: (timeLabel.x - width) / 2   // centred between the pill edge and the time
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(island.fontSize * 0.35)
            opacity: island.wide ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220 } }

            Kirigami.Icon {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(island.fontSize * 1.35)
                height: width
                source: island.app.weather.iconName
                visible: island.app.weather.available
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: island.hasCity ? island.app.weather.text : i18n("Set city")
                color: "#c8c8c8"
                font.pixelSize: island.fontSize
                font.weight: Font.Medium
            }
        }

        Text {
            id: dateLabel
            anchors.right: parent.right
            anchors.rightMargin: island.pad
            anchors.verticalCenter: parent.verticalCenter
            text: island.app.dateText
            color: "#c8c8c8"
            font.pixelSize: island.fontSize
            font.weight: Font.Medium
            opacity: island.wide ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220 } }
        }

        // New-track toast: small art + "Title — Artist".
        Row {
            anchors.centerIn: parent
            spacing: Math.round(island.fontSize * 0.5)
            opacity: island.toast ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 220 } }

            Kirigami.ShadowedImage {
                id: toastArt
                anchors.verticalCenter: parent.verticalCenter
                width: island.pillHeight - 8
                height: width
                radius: Math.round(width * 0.25)
                source: island.app.player ? island.app.player.artUrl : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: width * 2
                sourceSize.height: height * 2
                asynchronous: true
                visible: status === Image.Ready
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth,
                                island.wideWidth - 2 * island.pad - (toastArt.visible ? toastArt.width + parent.spacing : 0))
                elide: Text.ElideRight
                textFormat: Text.StyledText
                text: {
                    const p = island.app.player;
                    if (!p) {
                        return "";
                    }
                    const esc = s => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;");
                    return p.artist ? esc(p.track) + " <font color='#9a9a9a'>— " + esc(p.artist) + "</font>" : esc(p.track);
                }
                color: "white"
                font.pixelSize: island.fontSize
                font.weight: Font.DemiBold
            }
        }

        // Ctrl+scroll resizes the pill (saved to the widget settings).
        WheelHandler {
            acceptedModifiers: Qt.ControlModifier
            onWheel: event => {
                const step = event.angleDelta.y > 0 ? 2 : -2;
                Plasmoid.configuration.size = Math.max(16, Math.min(72, island.app.pillSize + step));
            }
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) {
                    const player = island.app.player;
                    if (player && player.canControl) {
                        player.PlayPause();
                    }
                    return;
                }
                island.handleClick(mouse.x);
            }
        }
    }

    PlasmaCore.Dialog {
        id: card
        visualParent: pill
        location: Plasmoid.location
        type: PlasmaCore.Dialog.AppletPopup
        backgroundHints: PlasmaCore.Dialog.NoBackground
        flags: Qt.WindowStaysOnTopHint
        hideOnWindowDeactivate: true
        visible: island.app.cardOpen

        onVisibleChanged: {
            if (!visible) {
                if (island.app.cardOpen) {
                    // Closed by losing focus (a click elsewhere, or on the pill).
                    island.cardClosedAt = Date.now();
                    island.closedMode = island.app.cardMode;
                }
                island.app.cardOpen = false;
            } else {
                cardContent.popIn();
            }
        }

        mainItem: Card {
            id: cardContent
            app: island.app
            mode: island.app.cardMode
            shown: card.visible
            onCloseRequested: island.app.cardOpen = false
            onConfigureRequested: island.configure()
        }
    }
}
