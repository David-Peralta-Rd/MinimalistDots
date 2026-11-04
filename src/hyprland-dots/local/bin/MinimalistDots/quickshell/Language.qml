import QtQuick
import Quickshell
import Quickshell.Io

// Lector único de la instantánea activa. No vigila cambios en tiempo real.
Item {
    id: root
    width: 0
    height: 0
    visible: false

    property var strings: ({})
    readonly property string stringsPath:
        (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache"))
        + "/MinimalistDots/language/strings.json"
    readonly property string locale: text("MD_TXT_CODIGO_IDIOMA", "es")

    function readStrings() {
        const raw = stringsFile.text()
        if (!raw) {
            strings = ({})
            return
        }
        try {
            strings = JSON.parse(raw)
        } catch (error) {
            strings = ({})
        }
    }

    function text(key, fallback) {
        const value = strings[key]
        return value === undefined || value === null || value === "" ? (fallback || "") : String(value)
    }

    function format(key, replacements, fallback) {
        let result = text(key, fallback)
        const values = replacements || ({})
        Object.keys(values).forEach(name => {
            result = result.split("{" + name + "}").join(String(values[name]))
        })
        return result
    }

    FileView {
        id: stringsFile
        path: root.stringsPath
        blockLoading: true
    }

    Component.onCompleted: readStrings()
}
