import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Month calendar (today highlighted, arrows to browse) and below it the world clocks.
Item {
    id: view

    property date now: new Date()
    property real u: 1
    property string timeFormat: Qt.locale().timeFormat(Locale.ShortFormat)
    property bool active: false
    // [{ city: string, delta: seconds ahead of local time }]
    property var zones: []

    function formatDiff(seconds) {
        if (seconds === 0) {
            return "±0";
        }
        const sign = seconds > 0 ? "+" : "−";
        const mins = Math.round(Math.abs(seconds) / 60);
        const h = Math.floor(mins / 60);
        const m = mins % 60;
        return sign + (m === 0 ? h + i18nc("hours, short", "h") : h + ":" + String(m).padStart(2, "0"));
    }
    signal configureRequested()

    // Month shown; reset to the current one each time the card opens.
    property int month: now.getMonth()
    property int year: now.getFullYear()
    onActiveChanged: {
        if (active) {
            month = now.getMonth();
            year = now.getFullYear();
        }
    }
    readonly property bool onCurrentMonth: month === now.getMonth() && year === now.getFullYear()

    function shiftMonth(delta) {
        let m = month + delta;
        let y = year;
        while (m < 0) { m += 12; y -= 1; }
        while (m > 11) { m -= 12; y += 1; }
        month = m;
        year = y;
    }

    readonly property real rowH: Math.round(30 * u)
    readonly property int visibleZoneRows: Math.min(zones.length, 6)   // scroll past six

    implicitWidth: Math.round(300 * u)
    implicitHeight: Math.round(16 * u) + header.implicitHeight + Math.round(8 * u)
                    + weekdays.implicitHeight + grid.implicitHeight
                    + Math.round(10 * u) + 1 + Math.round(6 * u)
                    + (zones.length > 0 ? visibleZoneRows * rowH : Math.round(26 * u))
                    + Math.round(12 * u)

    readonly property color dim: "#9a9a9a"

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 14 * view.u
        anchors.rightMargin: 14 * view.u
        anchors.topMargin: 16 * view.u
        anchors.bottomMargin: 12 * view.u
        spacing: 0

        Item {
            Layout.fillWidth: true
            implicitHeight: calendarCol.implicitHeight

            // Scroll over the calendar to change month.
            WheelHandler {
                target: null
                onWheel: event => {
                    if (Math.abs(event.angleDelta.y) >= 60) {
                        view.shiftMonth(event.angleDelta.y > 0 ? -1 : 1);
                    }
                }
            }

            ColumnLayout {
                id: calendarCol
                width: parent.width
                spacing: 0

                // Month title and arrows.
                RowLayout {
                    id: header
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8 * view.u
                    Text {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4 * view.u
                        text: Qt.locale().standaloneMonthName(view.month, Locale.LongFormat) + " " + view.year
                        color: "white"
                        font.pixelSize: Math.round(15 * view.u)
                        font.weight: Font.DemiBold
                        font.capitalization: Font.Capitalize
                    }
                    PillButton {
                        visible: !view.onCurrentMonth
                        label: i18n("Today")
                        onClicked: view.shiftMonth((view.now.getFullYear() - view.year) * 12 + view.now.getMonth() - view.month)
                    }
                    PillButton {
                        iconName: "go-previous-symbolic"
                        onClicked: view.shiftMonth(-1)
                    }
                    PillButton {
                        iconName: "go-next-symbolic"
                        onClicked: view.shiftMonth(1)
                    }
                }

                QQC2.DayOfWeekRow {
                    id: weekdays
                    Layout.fillWidth: true
                    locale: Qt.locale()
                    spacing: 0
                    padding: 0
                    delegate: Text {
                        required property string narrowName
                        text: narrowName
                        color: view.dim
                        font.pixelSize: Math.round(11 * view.u)
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                QQC2.MonthGrid {
                    id: grid
                    Layout.fillWidth: true
                    month: view.month
                    year: view.year
                    locale: Qt.locale()
                    spacing: 0
                    padding: 0
                    delegate: Item {
                        required property int day
                        required property int month
                        required property bool today
                        implicitHeight: Math.round(30 * view.u)
                        implicitWidth: implicitHeight

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.round(26 * view.u)
                            height: width
                            radius: width / 2
                            color: "white"
                            visible: parent.today
                        }
                        Text {
                            anchors.centerIn: parent
                            text: parent.day
                            color: parent.today ? "black"
                                 : parent.month === view.month ? "white" : "#55555c"
                            font.pixelSize: Math.round(13 * view.u)
                            font.weight: parent.today ? Font.Bold : Font.Medium
                            font.features: { "tnum": 1 }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 10 * view.u
            Layout.bottomMargin: 6 * view.u
            implicitHeight: 1
            color: "#26262c"
        }

        // World clocks (any number; scrolls after six).
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: view.visibleZoneRows * view.rowH
            visible: view.zones.length > 0
            clip: true
            interactive: view.zones.length > view.visibleZoneRows
            boundsBehavior: Flickable.StopAtBounds
            model: view.zones
            QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                policy: view.zones.length > view.visibleZoneRows ? QQC2.ScrollBar.AsNeeded : QQC2.ScrollBar.AlwaysOff
            }
            delegate: RowLayout {
                required property var modelData
                readonly property date time: new Date(view.now.getTime() + modelData.delta * 1000)
                readonly property int dayShift: time.getDate() === view.now.getDate() ? 0 : (modelData.delta > 0 ? 1 : -1)
                width: ListView.view.width
                height: view.rowH
                spacing: 8 * view.u
                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4 * view.u
                    text: parent.modelData.city
                    color: "white"
                    font.pixelSize: Math.round(13 * view.u)
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
                Text {
                    text: {
                        const row = parent;
                        const diff = view.formatDiff(row.modelData.delta);
                        const day = row.dayShift > 0 ? i18n("Tomorrow") : row.dayShift < 0 ? i18n("Yesterday") : "";
                        return day ? day + " · " + diff : diff;
                    }
                    color: view.dim
                    font.pixelSize: Math.round(11 * view.u)
                    font.weight: Font.Medium
                }
                Text {
                    Layout.rightMargin: 4 * view.u
                    text: Qt.locale().toString(parent.time, view.timeFormat)
                    color: "white"
                    font.pixelSize: Math.round(14 * view.u)
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                }
            }
        }

        // No zones yet: a hint that opens the settings.
        Text {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(26 * view.u)
            visible: view.zones.length === 0
            text: i18n("Add time zones…")
            color: view.dim
            font.pixelSize: Math.round(12 * view.u)
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: view.configureRequested()
            }
        }

        Item { Layout.fillHeight: true }
    }

    component PillButton: Rectangle {
        id: pb
        property string iconName: ""
        property string label: ""
        signal clicked()
        implicitHeight: Math.round(24 * view.u)
        implicitWidth: label !== "" ? labelText.implicitWidth + Math.round(18 * view.u) : implicitHeight
        radius: height / 2
        color: pbArea.containsMouse ? "#2c2c32" : "transparent"
        Kirigami.Icon {
            anchors.centerIn: parent
            visible: pb.iconName !== ""
            width: Math.round(16 * view.u)
            height: width
            source: pb.iconName
            isMask: true
            color: "white"
        }
        Text {
            id: labelText
            anchors.centerIn: parent
            visible: pb.label !== ""
            text: pb.label
            color: "white"
            font.pixelSize: Math.round(12 * view.u)
            font.weight: Font.DemiBold
        }
        MouseArea {
            id: pbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pb.clicked()
        }
    }
}
