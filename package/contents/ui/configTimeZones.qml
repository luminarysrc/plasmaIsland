import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.private.digitalclock as DigitalClock

// World clocks shown in the calendar card. Any number of zones; order is kept.
KCM.ScrollViewKCM {
    id: page

    // Always assign a new array: in-place changes don't enable the Apply button.
    property var cfg_timeZones: []

    function has(id) {
        return cfg_timeZones.indexOf(id) >= 0;
    }
    function toggle(id) {
        cfg_timeZones = has(id) ? cfg_timeZones.filter(z => z !== id) : cfg_timeZones.concat([id]);
    }
    function move(index, delta) {
        const list = cfg_timeZones.slice();
        const to = index + delta;
        if (to < 0 || to >= list.length) {
            return;
        }
        const item = list.splice(index, 1)[0];
        list.splice(to, 0, item);
        cfg_timeZones = list;
    }

    DigitalClock.TimeZoneModel {
        id: zoneModel
        selectedTimeZones: page.cfg_timeZones
    }

    header: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            Layout.fillWidth: true
            text: page.cfg_timeZones.length === 0
                  ? i18n("No time zones yet. Search below and click one to add it.")
                  : i18n("Shown in the calendar card, in this order:")
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: page.cfg_timeZones
            RowLayout {
                required property string modelData
                required property int index
                Layout.fillWidth: true
                QQC2.Label {
                    Layout.fillWidth: true
                    text: modelData.split("/").pop().replace(/_/g, " ") + "  ·  " + modelData
                    elide: Text.ElideRight
                }
                QQC2.ToolButton {
                    icon.name: "go-up"
                    enabled: index > 0
                    onClicked: page.move(index, -1)
                    QQC2.ToolTip.text: i18n("Move up")
                    QQC2.ToolTip.visible: hovered
                }
                QQC2.ToolButton {
                    icon.name: "go-down"
                    enabled: index < page.cfg_timeZones.length - 1
                    onClicked: page.move(index, 1)
                    QQC2.ToolTip.text: i18n("Move down")
                    QQC2.ToolTip.visible: hovered
                }
                QQC2.ToolButton {
                    icon.name: "list-remove"
                    onClicked: page.toggle(modelData)
                    QQC2.ToolTip.text: i18n("Remove")
                    QQC2.ToolTip.visible: hovered
                }
            }
        }

        Kirigami.SearchField {
            id: search
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            placeholderText: i18n("Search a city…")
        }
    }

    view: ListView {
        clip: true
        model: KItemModels.KSortFilterProxyModel {
            sourceModel: zoneModel
            filterRoleName: "city"
            filterString: search.text
            filterCaseSensitivity: Qt.CaseInsensitive
        }
        delegate: QQC2.ItemDelegate {
            required property string timeZoneId
            required property string city
            required property string region
            required property string comment
            required property bool isLocalTimeZone

            width: ListView.view.width
            visible: !isLocalTimeZone
            height: visible ? implicitHeight : 0
            highlighted: page.has(timeZoneId)
            text: city + "  ·  " + region + (comment ? "  ·  " + comment : "")
            icon.name: page.has(timeZoneId) ? "checkmark" : "list-add"
            onClicked: page.toggle(timeZoneId)
        }
    }
}
