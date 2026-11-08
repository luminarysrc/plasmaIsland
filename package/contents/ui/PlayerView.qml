import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

// Now playing: art, title/artist, a seekable progress bar and transport controls.
// Scroll over it to change the player's volume (Plasma shows its volume OSD).
Item {
    id: view

    property var player: null      // an MPRIS PlayerContainer, or null
    property real u: 1             // size multiplier
    property bool active: false    // true while this view is on screen
    signal raiseRequested()

    readonly property bool hasTrack: !!player && (player.track || "") !== ""
    readonly property bool playing: !!player && player.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property bool canSeek: !!player && player.canSeek && player.length > 0

    implicitWidth: Math.round(360 * u)
    implicitHeight: Math.round(152 * u)

    // MPRIS only pushes the position on seeks, so poll it while visible and playing.
    Timer {
        interval: 1000
        repeat: true
        running: view.active && view.playing && !seekArea.pressed
        onTriggered: view.player.updatePosition()
    }

    function formatTime(us) {
        if (!us || us < 0) {
            return "0:00";
        }
        const s = Math.floor(us / 1e6);
        const m = Math.floor(s / 60);
        const h = Math.floor(m / 60);
        const ss = String(s % 60).padStart(2, "0");
        return h > 0 ? h + ":" + String(m % 60).padStart(2, "0") + ":" + ss : m + ":" + ss;
    }

    WheelHandler {
        enabled: !!view.player && view.player.canControl
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const steps = event.angleDelta.y / 120;
            if (steps !== 0) {
                view.player.changeVolume(steps * 0.05, true);
            }
        }
    }

    // --- Nothing playing ---------------------------------------------------
    ColumnLayout {
        anchors.centerIn: parent
        visible: !view.hasTrack
        spacing: 8 * view.u
        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 28 * view.u
            implicitHeight: 28 * view.u
            source: "media-playback-stopped-symbolic"
            isMask: true
            color: "#8a8a8a"
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Nothing playing")
            color: "#8a8a8a"
            font.pixelSize: Math.round(14 * view.u)
            font.weight: Font.Medium
        }
    }

    // --- Now playing -------------------------------------------------------
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14 * view.u
        spacing: 6 * view.u
        visible: view.hasTrack

        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * view.u

            Item {
                implicitWidth: 56 * view.u
                implicitHeight: 56 * view.u

                Rectangle {
                    anchors.fill: parent
                    radius: 12 * view.u
                    color: "#26262c"
                    visible: art.status !== Image.Ready
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 26 * view.u
                        height: 26 * view.u
                        source: "media-album-cover"
                        isMask: true
                        color: "#9a9a9a"
                    }
                }
                Kirigami.ShadowedImage {
                    id: art
                    anchors.fill: parent
                    radius: 12 * view.u
                    source: view.player ? view.player.artUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: Math.round(112 * view.u)
                    sourceSize.height: Math.round(112 * view.u)
                    asynchronous: true
                    visible: status === Image.Ready
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !!view.player && view.player.canRaise
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        view.player.Raise();
                        view.raiseRequested();
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2 * view.u
                Text {
                    Layout.fillWidth: true
                    text: view.player ? view.player.track : ""
                    color: "white"
                    font.pixelSize: Math.round(15 * view.u)
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: view.player ? (view.player.artist || view.player.identity || "") : ""
                    color: "#9a9a9a"
                    font.pixelSize: Math.round(13 * view.u)
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }
        }

        // Progress: elapsed, bar (click or drag to seek), total.
        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * view.u
            visible: !!view.player && view.player.length > 0

            // While dragging, show where the drop will land instead of the live position.
            readonly property real fraction: seekArea.pressed
                ? seekArea.dragFraction
                : (view.player && view.player.length > 0
                   ? Math.min(1, Math.max(0, view.player.position / view.player.length)) : 0)

            Text {
                text: view.formatTime(parent.fraction * (view.player ? view.player.length : 0))
                color: "#8a8a8a"
                font.pixelSize: Math.max(8, Math.round(10 * view.u))
                font.features: { "tnum": 1 }
            }
            Item {
                id: track
                Layout.fillWidth: true
                implicitHeight: 14 * view.u   // taller than the bar, so it's easy to hit

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: (seekArea.containsMouse || seekArea.pressed ? 6 : 4) * view.u
                    radius: height / 2
                    color: "#333338"
                    Behavior on height { NumberAnimation { duration: 120 } }

                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        color: "white"
                        width: parent.width * track.parent.fraction
                    }
                }

                MouseArea {
                    id: seekArea
                    anchors.fill: parent
                    enabled: view.canSeek
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    property real dragFraction: 0
                    function fractionAt(x) {
                        return Math.min(1, Math.max(0, x / width));
                    }
                    onPressed: mouse => dragFraction = fractionAt(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed) {
                            dragFraction = fractionAt(mouse.x);
                        }
                    }
                    onReleased: mouse => {
                        dragFraction = fractionAt(mouse.x);
                        view.player.position = Math.round(dragFraction * view.player.length);
                    }
                }
            }
            Text {
                text: view.formatTime(view.player ? view.player.length : 0)
                color: "#8a8a8a"
                font.pixelSize: Math.max(8, Math.round(10 * view.u))
                font.features: { "tnum": 1 }
            }
        }

        // Controls.
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 34 * view.u

            ControlButton {
                iconName: "media-skip-backward-symbolic"
                size: Math.round(22 * view.u)
                enabled: !!view.player && view.player.canGoPrevious
                onClicked: view.player.Previous()
            }
            ControlButton {
                iconName: view.playing ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                size: Math.round(28 * view.u)
                enabled: !!view.player && (view.playing ? view.player.canPause : view.player.canPlay)
                onClicked: view.player.PlayPause()
            }
            ControlButton {
                iconName: "media-skip-forward-symbolic"
                size: Math.round(22 * view.u)
                enabled: !!view.player && view.player.canGoNext
                onClicked: view.player.Next()
            }
        }
    }

    component ControlButton: Item {
        id: btn
        property string iconName
        property int size: 22
        signal clicked()
        implicitWidth: size + Math.round(size * 0.45)
        implicitHeight: size + Math.round(size * 0.45)
        opacity: enabled ? 1 : 0.35

        Kirigami.Icon {
            anchors.centerIn: parent
            width: btn.size
            height: btn.size
            source: btn.iconName
            isMask: true
            color: "white"
            scale: area.pressed ? 0.82 : (area.containsMouse ? 1.08 : 1)
            Behavior on scale { NumberAnimation { duration: 120 } }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
