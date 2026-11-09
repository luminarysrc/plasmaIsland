import QtQuick
import "Translations.js" as T

// Translates the widget's own strings. With no language chosen it defers to Plasma's i18n
// (the system language); otherwise it uses the bundled dictionary, so the choice applies to
// this widget only. Use as: Translator { id: t; language: ... }, then t.tr("Text") / t.trc("ctx", "Text").
QtObject {
    property string language: ""

    function tr(s, ...args) {
        return language === "" ? i18n(s, ...args) : T.tr(language, "", s, args);
    }
    function trc(ctx, s, ...args) {
        return language === "" ? i18nc(ctx, s, ...args) : T.tr(language, ctx, s, args);
    }
}
