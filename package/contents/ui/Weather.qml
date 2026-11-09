import QtQuick

// Weather from Open-Meteo (https://open-meteo.com), which needs no API key.
// The city name is geocoded once; conditions are refreshed every 15 minutes in one request
// (current conditions + the next hours + today's high/low).
Item {
    id: weather

    property string city: ""
    property string language: ""     // the geocoder names the place in it ("" = its default)
    readonly property bool hasCity: city.trim() !== ""
    readonly property bool imperial: Qt.locale().measurementSystem === Locale.ImperialUSSystem

    // NaN until the first successful fetch, or when no city is set.
    property real temperature: NaN
    property real feelsLike: NaN
    property real high: NaN
    property real low: NaN
    property int humidity: -1
    property real windSpeed: NaN
    readonly property string windUnit: imperial ? "mph" : "km/h"
    property int code: -1
    property string iconName: "weather-none-available"
    property string placeName: ""     // as the geocoder spells it, e.g. "Berlin, Germany"
    // [{ time: Date (city-local wall clock), temperature, iconName }]
    property var hourly: []

    readonly property bool available: !isNaN(temperature)
    // True after a failed lookup or fetch (no network, unknown city), until the next success.
    property bool failed: false
    readonly property string text: available ? deg(temperature) : "—"

    function deg(t) {
        return isNaN(t) ? "—" : Math.round(t) + "°";
    }

    property real latitude: NaN
    property real longitude: NaN

    onCityChanged: {
        latitude = NaN;
        longitude = NaN;
        placeName = "";
        temperature = NaN;
        hourly = [];
        failed = false;
        iconName = "weather-none-available";
        soon.restart();
    }
    onImperialChanged: soon.restart()
    onLanguageChanged: {
        latitude = NaN;   // look the place up again to get its name in the new language
        longitude = NaN;
        soon.restart();
    }
    Component.onCompleted: soon.restart()

    // Collapses the startup/config-change triggers above into a single request.
    Timer {
        id: soon
        interval: 300
        onTriggered: weather.refresh()
    }

    Timer {
        interval: 15 * 60 * 1000
        running: weather.hasCity
        repeat: true
        onTriggered: weather.refresh()
    }

    // Retry sooner after a failure (no network at login, for example).
    Timer {
        id: retry
        interval: 60 * 1000
        onTriggered: weather.refresh()
    }

    function getJson(url, onDone) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) {
                return;
            }
            let data = null;
            if (xhr.status === 200) {
                try {
                    data = JSON.parse(xhr.responseText);
                } catch (e) {
                    data = null;
                }
            }
            onDone(data);
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function refresh() {
        const name = city.trim();
        if (name === "") {
            return;
        }
        if (isNaN(latitude)) {
            const requested = name;
            getJson("https://geocoding-api.open-meteo.com/v1/search?count=1&format=json"
                    + (language !== "" ? "&language=" + language : "") + "&name="
                    + encodeURIComponent(name), data => {
                if (requested !== weather.city.trim()) {
                    return; // the city changed while we were waiting
                }
                const hit = data && data.results && data.results[0];
                if (!hit) {
                    weather.failed = true;
                    retry.restart();
                    return;
                }
                weather.latitude = hit.latitude;
                weather.longitude = hit.longitude;
                weather.placeName = hit.country ? hit.name + ", " + hit.country : hit.name;
                weather.fetchForecast();
            });
        } else {
            fetchForecast();
        }
    }

    function fetchForecast() {
        const url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + latitude + "&longitude=" + longitude
            + "&current=temperature_2m,apparent_temperature,weather_code,is_day,relative_humidity_2m,wind_speed_10m"
            + "&hourly=temperature_2m,weather_code,is_day&forecast_hours=7"
            + "&daily=temperature_2m_max,temperature_2m_min&forecast_days=1"
            + "&timezone=auto"
            + (imperial ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "");
        getJson(url, data => {
            const cur = data && data.current;
            if (!cur || typeof cur.temperature_2m !== "number") {
                weather.failed = true;
                retry.restart();
                return;
            }
            weather.failed = false;
            weather.temperature = cur.temperature_2m;
            weather.feelsLike = typeof cur.apparent_temperature === "number" ? cur.apparent_temperature : NaN;
            weather.humidity = typeof cur.relative_humidity_2m === "number" ? cur.relative_humidity_2m : -1;
            weather.windSpeed = typeof cur.wind_speed_10m === "number" ? cur.wind_speed_10m : NaN;
            weather.code = cur.weather_code;
            weather.iconName = iconFor(cur.weather_code, cur.is_day === 1);

            const d = data.daily;
            weather.high = d && d.temperature_2m_max ? d.temperature_2m_max[0] : NaN;
            weather.low = d && d.temperature_2m_min ? d.temperature_2m_min[0] : NaN;

            const h = data.hourly;
            const hours = [];
            if (h && h.time) {
                // Skip the current hour (it's shown as "now" above); keep the next six.
                for (let i = 1; i < h.time.length && hours.length < 6; i++) {
                    hours.push({
                        time: parseLocal(h.time[i]),
                        temperature: h.temperature_2m[i],
                        iconName: iconFor(h.weather_code[i], h.is_day[i] === 1)
                    });
                }
            }
            weather.hourly = hours;
        });
    }

    // "2026-11-02T22:00" in the city's own time → a Date with the same wall-clock fields.
    function parseLocal(s) {
        const m = /^(\d+)-(\d+)-(\d+)T(\d+):(\d+)/.exec(s);
        return m ? new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5]) : new Date(NaN);
    }

    // WMO weather interpretation codes, as documented by Open-Meteo,
    // mapped to Breeze icon names.
    function iconFor(code, day) {
        switch (code) {
        case 0: return day ? "weather-clear" : "weather-clear-night";
        case 1: return day ? "weather-few-clouds" : "weather-few-clouds-night";
        case 2: return day ? "weather-clouds" : "weather-clouds-night";
        case 3: return "weather-overcast";
        case 45: case 48: return "weather-fog";
        case 51: case 53: case 55: return "weather-showers-scattered";
        case 56: case 57: case 66: case 67: return "weather-freezing-rain";
        case 61: case 63: case 65: case 80: case 81: case 82: return "weather-showers";
        case 71: case 73: case 75: case 77: return "weather-snow";
        case 85: case 86: return "weather-snow-scattered";
        case 95: case 96: case 99: return "weather-storm";
        default: return "weather-none-available";
        }
    }
}
