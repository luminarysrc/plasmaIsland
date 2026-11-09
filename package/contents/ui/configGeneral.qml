import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    // "" follows the system language; otherwise one of languageCodes below.
    property string cfg_language
    property alias cfg_city: cityField.text
    property alias cfg_showSeconds: secondsBox.checked
    property int cfg_clockFormat
    property int cfg_dateFormat
    property alias cfg_size: sizeBox.value
    property alias cfg_showTrackToast: toastBox.checked

    readonly property var languageCodes: ["", "en", "ru", "es", "de", "el"]
    readonly property var loc: cfg_language === "" ? Qt.locale() : Qt.locale(cfg_language)

    // The page itself switches language as soon as one is chosen.
    Translator { id: t; language: page.cfg_language }

    // The combo boxes use ListModels whose labels are updated in place: replacing a plain
    // array model would reset their current index and clobber the saved choice.
    ListModel {
        id: languageModel
        ListElement { label: "" }
        ListElement { label: "English" }
        ListElement { label: "Русский" }
        ListElement { label: "Español" }
        ListElement { label: "Deutsch" }
        ListElement { label: "Ελληνικά" }
    }
    ListModel {
        id: clockModel
        ListElement { label: "System default" }
        ListElement { label: "12-hour" }
        ListElement { label: "24-hour" }
    }
    ListModel {
        id: dateModel
        ListElement { label: "" }
        ListElement { label: "" }
        ListElement { label: "" }
        ListElement { label: "" }
        ListElement { label: "" }
        ListElement { label: "" }
        ListElement { label: "" }
    }

    // A ComboBox keeps showing the old text of its current item when that item's label changes;
    // clearing and re-binding the index makes it read the new one.
    function refreshBox(box, valueFn) {
        box.currentIndex = -1;
        box.currentIndex = Qt.binding(valueFn);
    }

    function retranslate() {
        const now = new Date();
        languageModel.setProperty(0, "label", t.tr("System default"));
        clockModel.setProperty(0, "label", t.tr("System default"));
        clockModel.setProperty(1, "label", t.tr("12-hour"));
        clockModel.setProperty(2, "label", t.tr("24-hour"));
        const fmts = ["ddd, MMM d", "ddd, d MMM", "dd/MM/yyyy", "MM/dd/yyyy", "yyyy-MM-dd", "d MMMM yyyy"];
        for (let i = 0; i < fmts.length; i++) {
            dateModel.setProperty(i, "label", loc.toString(now, fmts[i]));
        }
        dateModel.setProperty(6, "label", t.tr("System short date") + " (" + loc.toString(now, Locale.ShortFormat) + ")");
        refreshBox(languageBox, () => Math.max(0, page.languageCodes.indexOf(page.cfg_language)));
        refreshBox(clockBox, () => page.cfg_clockFormat);
        refreshBox(dateBox, () => page.cfg_dateFormat);
    }
    Component.onCompleted: retranslate()
    // Deferred: this handler can run before `t` and `loc` have picked up the new language.
    onCfg_languageChanged: Qt.callLater(retranslate)

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: languageBox
            Kirigami.FormData.label: t.tr("Language:")
            model: languageModel
            textRole: "label"
            currentIndex: Math.max(0, page.languageCodes.indexOf(page.cfg_language))
            onActivated: index => page.cfg_language = page.languageCodes[index]
        }

        QQC2.TextField {
            id: cityField
            Kirigami.FormData.label: t.tr("Weather city:")
            placeholderText: t.tr("e.g. Berlin")
        }
        QQC2.Label {
            text: t.tr("Without a city, the pill shows “Set city” instead of the temperature.")
            opacity: 0.7
            font: Kirigami.Theme.smallFont
        }
        QQC2.SpinBox {
            id: sizeBox
            Kirigami.FormData.label: t.tr("Size:")
            from: 16
            to: 72
            stepSize: 2
            textFromValue: (value, locale) => t.tr("%1 px", value)
            valueFromText: (text, locale) => parseInt(text) || 32
        }
        QQC2.Label {
            text: t.tr("Tip: hold Ctrl and scroll over the pill to resize it live.")
            opacity: 0.7
            font: Kirigami.Theme.smallFont
        }
        QQC2.CheckBox {
            id: secondsBox
            Kirigami.FormData.label: t.tr("Clock:")
            text: t.tr("Show seconds")
        }
        QQC2.ComboBox {
            id: clockBox
            Kirigami.FormData.label: t.tr("Time format:")
            model: clockModel
            textRole: "label"
            currentIndex: page.cfg_clockFormat
            onActivated: index => page.cfg_clockFormat = index
        }
        QQC2.ComboBox {
            id: dateBox
            Kirigami.FormData.label: t.tr("Date format:")
            model: dateModel
            textRole: "label"
            currentIndex: page.cfg_dateFormat
            onActivated: index => page.cfg_dateFormat = index
        }
        QQC2.CheckBox {
            id: toastBox
            Kirigami.FormData.label: t.tr("Music:")
            text: t.tr("Briefly show each new track in the pill")
        }
    }
}
