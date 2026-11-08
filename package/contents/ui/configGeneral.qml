import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_city: cityField.text
    property alias cfg_showSeconds: secondsBox.checked
    property alias cfg_clockFormat: clockBox.currentIndex
    property alias cfg_dateFormat: dateBox.currentIndex
    property alias cfg_size: sizeBox.value
    property alias cfg_showTrackToast: toastBox.checked

    Kirigami.FormLayout {
        QQC2.TextField {
            id: cityField
            Kirigami.FormData.label: i18n("Weather city:")
            placeholderText: i18n("e.g. Berlin")
        }
        QQC2.Label {
            text: i18n("Without a city, the pill shows “Set city” instead of the temperature.")
            opacity: 0.7
            font: Kirigami.Theme.smallFont
        }
        QQC2.SpinBox {
            id: sizeBox
            Kirigami.FormData.label: i18n("Size:")
            from: 16
            to: 72
            stepSize: 2
            textFromValue: (value, locale) => i18n("%1 px", value)
            valueFromText: (text, locale) => parseInt(text) || 32
        }
        QQC2.Label {
            text: i18n("Tip: hold Ctrl and scroll over the pill to resize it live.")
            opacity: 0.7
            font: Kirigami.Theme.smallFont
        }
        QQC2.CheckBox {
            id: secondsBox
            Kirigami.FormData.label: i18n("Clock:")
            text: i18n("Show seconds")
        }
        QQC2.ComboBox {
            id: clockBox
            Kirigami.FormData.label: i18n("Time format:")
            model: [i18n("System default"), i18n("12-hour"), i18n("24-hour")]
        }
        QQC2.ComboBox {
            id: dateBox
            Kirigami.FormData.label: i18n("Date format:")
            readonly property var sample: new Date()
            model: [
                Qt.locale().toString(sample, "ddd, MMM d"),
                Qt.locale().toString(sample, "ddd, d MMM"),
                Qt.locale().toString(sample, "dd/MM/yyyy"),
                Qt.locale().toString(sample, "MM/dd/yyyy"),
                Qt.locale().toString(sample, "yyyy-MM-dd"),
                Qt.locale().toString(sample, "d MMMM yyyy"),
                i18n("System short date") + " (" + Qt.locale().toString(sample, Locale.ShortFormat) + ")"
            ]
        }
        QQC2.CheckBox {
            id: toastBox
            Kirigami.FormData.label: i18n("Music:")
            text: i18n("Briefly show each new track in the pill")
        }
    }
}
