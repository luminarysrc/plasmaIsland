import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Weather details: now (icon, temperature, condition, place, high/low),
// feels-like / humidity / wind, and the next six hours.
Item {
    id: view

    property var weather: null     // a Weather item
    property string language: ""  // "" = system
    property var locale: Qt.locale()

    Translator { id: t; language: view.language }
    property real u: 1
    property bool twelveHour: false

    readonly property bool ready: !!weather && weather.available

    implicitWidth: Math.round(360 * u)
    implicitHeight: Math.round((ready ? 204 : 96) * u)

    readonly property color dim: "#9a9a9a"

    function conditionFor(code) {
        switch (code) {
        case 0: return t.tr("Clear");
        case 1: return t.tr("Mostly clear");
        case 2: return t.tr("Partly cloudy");
        case 3: return t.tr("Overcast");
        case 45: case 48: return t.tr("Fog");
        case 51: case 53: case 55: return t.tr("Drizzle");
        case 56: case 57: return t.tr("Freezing drizzle");
        case 61: case 63: return t.tr("Rain");
        case 65: return t.tr("Heavy rain");
        case 66: case 67: return t.tr("Freezing rain");
        case 71: case 73: return t.tr("Snow");
        case 75: return t.tr("Heavy snow");
        case 77: return t.tr("Snow grains");
        case 80: case 81: return t.tr("Showers");
        case 82: return t.tr("Heavy showers");
        case 85: case 86: return t.tr("Snow showers");
        case 95: return t.tr("Thunderstorm");
        case 96: case 99: return t.tr("Thunderstorm with hail");
        default: return "";
        }
    }

    function hourLabel(d) {
        // Hour only, in the user's 12h/24h convention.
        return view.locale.toString(d, twelveHour ? "h AP" : "HH:mm");
    }

    // --- Loading / unavailable ----------------------------------------------
    Text {
        anchors.centerIn: parent
        visible: !view.ready
        text: view.weather && view.weather.failed ? t.tr("Weather unavailable") : t.tr("Loading weather…")
        color: view.dim
        font.pixelSize: Math.round(14 * view.u)
        font.weight: Font.Medium
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16 * view.u
        spacing: 10 * view.u
        visible: view.ready

        // Now.
        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * view.u

            Kirigami.Icon {
                implicitWidth: 48 * view.u
                implicitHeight: 48 * view.u
                source: view.weather ? view.weather.iconName : ""
            }
            Text {
                text: view.weather ? view.weather.deg(view.weather.temperature) : ""
                color: "white"
                font.pixelSize: Math.round(34 * view.u)
                font.weight: Font.DemiBold
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1 * view.u
                Text {
                    Layout.fillWidth: true
                    text: view.weather ? view.conditionFor(view.weather.code) : ""
                    color: "white"
                    font.pixelSize: Math.round(14 * view.u)
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: view.weather ? view.weather.placeName : ""
                    color: view.dim
                    font.pixelSize: Math.round(12 * view.u)
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }
            Text {
                Layout.alignment: Qt.AlignTop
                text: view.weather
                      ? t.tr("H:%1  L:%2", view.weather.deg(view.weather.high), view.weather.deg(view.weather.low))
                      : ""
                color: view.dim
                font.pixelSize: Math.round(12 * view.u)
                font.weight: Font.Medium
            }
        }

        // Feels like · humidity · wind.
        Text {
            Layout.fillWidth: true
            color: view.dim
            font.pixelSize: Math.round(12 * view.u)
            font.weight: Font.Medium
            elide: Text.ElideRight
            text: {
                const w = view.weather;
                if (!w) {
                    return "";
                }
                const parts = [];
                if (!isNaN(w.feelsLike)) {
                    parts.push(t.tr("Feels like %1", w.deg(w.feelsLike)));
                }
                if (w.humidity >= 0) {
                    parts.push(t.tr("Humidity %1%", w.humidity));
                }
                if (!isNaN(w.windSpeed)) {
                    parts.push(t.tr("Wind %1 %2", Math.round(w.windSpeed), t.tr(w.windUnit)));
                }
                return parts.join(" · ");
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: "#26262c"
        }

        // Next hours.
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: view.weather ? view.weather.hourly : []
                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1   // equal columns
                    spacing: 4 * view.u
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: view.hourLabel(parent.modelData.time)
                        color: view.dim
                        font.pixelSize: Math.round(11 * view.u)
                        font.weight: Font.Medium
                    }
                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 22 * view.u
                        implicitHeight: 22 * view.u
                        source: parent.modelData.iconName
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: view.weather.deg(parent.modelData.temperature)
                        color: "white"
                        font.pixelSize: Math.round(13 * view.u)
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
