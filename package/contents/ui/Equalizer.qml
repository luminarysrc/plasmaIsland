import QtQuick

// Three bouncing bars: the "something is playing" hint next to the time.
//
// Driven by one low-rate timer instead of per-bar animations. Animations tick on every
// display frame, which makes the whole panel re-render at the screen's refresh rate. Heights
// are rounded to whole pixels, so a tick that changes nothing visible causes no repaint.
Item {
    id: eq

    property bool running: false
    property color color: "#c8c8c8"
    property real elapsed: 0

    Timer {
        interval: 50
        repeat: true
        running: eq.running
        onTriggered: eq.elapsed += interval
    }

    Row {
        anchors.fill: parent
        spacing: Math.max(1, Math.round(eq.width * 0.14))

        Repeater {
            // Each bar: [low, high, half-period ms], out of step with the others.
            model: [[0.30, 1.00, 380], [0.45, 0.80, 290], [0.25, 0.95, 450]]

            Rectangle {
                required property var modelData
                anchors.bottom: parent.bottom
                width: (eq.width - 2 * parent.spacing) / 3
                radius: width / 2
                color: eq.color
                // Same motion as an InOutSine bounce between low and high.
                height: {
                    const low = modelData[0], high = modelData[1], half = modelData[2];
                    const wave = (1 - Math.cos(Math.PI * eq.elapsed / half)) / 2;
                    return Math.round(eq.height * (low + (high - low) * wave));
                }
            }
        }
    }
}
