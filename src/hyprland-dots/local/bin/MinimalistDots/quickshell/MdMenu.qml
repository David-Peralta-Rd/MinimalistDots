import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Menú genérico de MinimalistDots. Dos modos:
//   dmenu    (por defecto): lee $MD_MENU_ITEMS, escribe la elección en $MD_MENU_OUT
//   appsMode (launcher)   : lista las apps instaladas (.desktop) y las lanza
// Teclas: Enter elige | Esc cierra | ↑/↓, Ctrl+j/k, Ctrl+n/p navegan
//         Shift+Delete o Ctrl+d borra la entrada seleccionada (si deleteCmd está definido)
//         Ctrl+Shift+Delete borra todo (pide confirmar pulsando dos veces)
ShellRoot {
    id: root

    property string prompt: ""
    property int menuWidth: 600
    property int menuHeight: 400
    property int menuRadius: 10
    property color accent: "#89b4fa"

    property bool appsMode: false
    property bool atTop: false          // true: pegado arriba (launcher) en vez de centrado
    property int topMargin: 20
    property var terminalCmd: ["footclient"]   // para apps con Terminal=true

    // Borrado (opcional). Si están vacíos, el menú se comporta como antes.
    //   deleteCmd: comando de shell que recibe la línea completa por stdin (ej. "cliphist delete")
    //   wipeCmd  : comando de shell que borra todo (ej. "cliphist wipe")
    property string deleteCmd: ""
    property string wipeCmd: ""
    readonly property bool canDelete: !appsMode && deleteCmd !== ""
    readonly property bool canWipe: !appsMode && wipeCmd !== ""
    property bool confirmWipe: false

    // MD_MENU_RAW=1: la línea completa es la etiqueta (sin separar miniatura por TAB).
    // Necesario para cliphist, cuyas líneas son "id<TAB>contenido".
    readonly property bool rawMode: Quickshell.env("MD_MENU_RAW") === "1"
    readonly property string shownPrompt: Quickshell.env("MD_MENU_PROMPT") || prompt

    property var allItems: []      // [{ label, icon, extra, entry }]
    property var shown: []
    property string query: ""
    property bool hasIcons: false

    Theme { id: theme }

    // ---------- búsqueda ----------
    function fuzzy(q, s) {
        let i = 0;
        for (let c = 0; c < s.length && i < q.length; c++) {
            if (s[c] === q[i]) i++;
        }
        return i === q.length;
    }

    // 0 = empieza igual, 1 = empieza una palabra, 2 = contiene, 3 = fuzzy, -1 = no coincide
    function score(q, s) {
        s = s.toLowerCase();
        if (s.startsWith(q)) return 0;
        if (s.includes(" " + q)) return 1;
        if (s.includes(q)) return 2;
        return fuzzy(q, s) ? 3 : -1;
    }

    function refilter() {
        const q = query.toLowerCase();
        if (q === "") {
            shown = allItems;
        } else if (appsMode) {
            // en el launcher las mejores coincidencias van primero
            const hits = [];
            allItems.forEach((it, i) => {
                let s = score(q, it.label);
                if (s < 0 && it.extra) {
                    s = score(q, it.extra);
                    if (s >= 0) s += 4;
                }
                if (s >= 0) hits.push({ it: it, s: s, i: i });
            });
            hits.sort((a, b) => (a.s - b.s) || (a.i - b.i));
            shown = hits.map(h => h.it);
        } else {
            // en dmenu se respeta el orden original
            shown = allItems.filter(it => score(q, it.label) >= 0);
        }
        list.currentIndex = 0;
    }

    // ---------- dmenu ----------
    function choose(text) {
        out.command = ["sh", "-c", 'printf "%s" "$1" > "$MD_MENU_OUT"', "sh", text];
        out.running = true;
    }

    FileView {
        id: itemsFile
        path: root.appsMode ? "" : (Quickshell.env("MD_MENU_ITEMS") || "")
        blockLoading: true
    }

    Process {
        id: out
        onExited: Qt.quit()
    }

    function loadFile() {
        const lines = itemsFile.text().split("\n");
        if (lines.length > 0 && lines[lines.length - 1] === "") lines.pop();
        allItems = lines.map(l => {
            if (rawMode) {
                // Modo raw: la línea completa es la etiqueta. Opcionalmente puede
                // llevar una miniatura tras un separador \x1f ("línea\x1f/ruta/img")
                const k = l.indexOf("\x1f");
                if (k < 0) return { label: l, icon: "", extra: "", entry: null };
                return { label: l.slice(0, k), icon: l.slice(k + 1), extra: "", entry: null };
            }
            const p = l.split("\t");
            return { label: p[0], icon: p.length > 1 ? p[1] : "", extra: "", entry: null };
        });
        hasIcons = allItems.some(it => it.icon !== "");
        refilter();
    }

    // ---------- borrado ----------
    // Borra una entrada: manda su línea completa a deleteCmd por stdin,
    // la quita de la lista y deja el menú abierto en la misma posición.
    function removeItem(item) {
        if (!canDelete || !item) return;
        // Los errores se guardan en /tmp/md_menu.log y avisan con notify-send
        const script = 'printf "%s\\n" "$1" | { ' + deleteCmd + '; } 2>>/tmp/md_menu.log'
            + ' || notify-send -a "Menú" "Error al borrar" "Revisa /tmp/md_menu.log"';
        Quickshell.execDetached(["sh", "-c", script, "sh", item.label]);
        const idx = list.currentIndex;
        // Se compara por etiqueta (la línea de cliphist incluye su id, es única):
        // con el click, modelData llega como copia y la comparación por identidad falla
        const label = item.label;
        allItems = allItems.filter(it => it.label !== label);
        refilter();
        list.currentIndex = Math.max(0, Math.min(idx, shown.length - 1));
    }

    // Borra todo. Primera pulsación: pide confirmación (3 s). Segunda: ejecuta.
    function wipeAll() {
        if (!canWipe) return;
        if (!confirmWipe) {
            confirmWipe = true;
            wipeTimer.restart();
            return;
        }
        wipeTimer.stop();
        confirmWipe = false;
        Quickshell.execDetached(["sh", "-c", wipeCmd]);
        allItems = [];
        refilter();
    }

    Timer {
        id: wipeTimer
        interval: 3000
        onTriggered: root.confirmWipe = false
    }

    // ---------- launcher ----------
    // DesktopEntries se escanea en segundo plano: por eso es un binding reactivo
    readonly property var appEntries: appsMode ? DesktopEntries.applications.values : []
    onAppEntriesChanged: if (appsMode) loadApps()

    function loadApps() {
        const apps = appEntries
            .filter(e => !e.noDisplay)
            .map(e => ({ label: e.name, icon: e.icon, extra: e.genericName || "", entry: e }));
        apps.sort((a, b) => a.label.localeCompare(b.label));
        allItems = apps;
        hasIcons = true;
        refilter();
    }

    function launch(e) {
        if (e.runInTerminal) Quickshell.execDetached(terminalCmd.concat(e.command));
        else e.execute();
        Qt.quit();
    }

    function activate(item) {
        if (appsMode) launch(item.entry);
        else choose(item.label);
    }

    function iconSource(icon) {
        if (icon === "") return "";
        if (appsMode) {
            if (icon.startsWith("/")) return "file://" + icon;
            return Quickshell.iconPath(icon, "application-x-executable");
        }
        return "file://" + icon;
    }

    Component.onCompleted: {
        if (!appsMode) loadFile();
    }

    PanelWindow {
        anchors.top: root.atTop
        margins.top: root.topMargin
        implicitWidth: root.menuWidth
        implicitHeight: root.menuHeight
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "md-menu"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: theme.bg90
            radius: root.menuRadius
            border.width: 2
            border.color: root.accent

            // ---- barra de búsqueda ----
            Rectangle {
                id: inputBox
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
                anchors.bottomMargin: 4
                height: 34
                radius: 6
                color: theme.surface70
                border.width: 1
                border.color: theme.borderInactive

                Text {
                    id: promptLabel
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    width: Math.min(implicitWidth, inputBox.width * 0.6)
                    elide: Text.ElideRight
                    text: root.shownPrompt
                    visible: text !== ""
                    color: root.accent
                    font.family: theme.font
                    font.pixelSize: 14
                    font.bold: true
                }

                // ---- botón "borrar todo" ----
                Rectangle {
                    id: wipeBtn
                    visible: root.canWipe
                    anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                    width: wipeText.implicitWidth + 16
                    height: 26
                    radius: 5
                    color: root.confirmWipe ? "#f7768e" : (wipeArea.containsMouse ? theme.surface90 : "transparent")

                    Text {
                        id: wipeText
                        anchors.centerIn: parent
                        text: root.confirmWipe ? "¿Seguro? Click otra vez" : "🧹 Borrar todo"
                        color: root.confirmWipe ? "#1a1b26" : theme.text
                        font.family: theme.font
                        font.pixelSize: 12
                        font.bold: root.confirmWipe
                    }

                    MouseArea {
                        id: wipeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.wipeAll()
                    }
                }

                TextInput {
                    id: input
                    anchors {
                        left: promptLabel.visible ? promptLabel.right : parent.left
                        leftMargin: 10
                        right: wipeBtn.visible ? wipeBtn.left : parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    color: theme.text
                    font.family: theme.font
                    font.pixelSize: 14
                    focus: true
                    clip: true
                    selectionColor: root.accent
                    Component.onCompleted: forceActiveFocus()

                    onTextChanged: { root.query = text; root.refilter(); }

                    Keys.onPressed: event => {
                        const ctrl = event.modifiers & Qt.ControlModifier;
                        const shift = event.modifiers & Qt.ShiftModifier;
                        if (event.key === Qt.Key_Escape) {
                            Qt.quit();
                        } else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                            list.incrementCurrentIndex();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                            list.decrementCurrentIndex();
                            event.accepted = true;
                        } else if (root.canWipe && ctrl && shift && event.key === Qt.Key_Delete) {
                            root.wipeAll();
                            event.accepted = true;
                        } else if (root.canDelete && ((shift && event.key === Qt.Key_Delete) || (ctrl && event.key === Qt.Key_D))) {
                            if (root.shown.length > 0) root.removeItem(root.shown[list.currentIndex]);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (root.shown.length > 0) root.activate(root.shown[list.currentIndex]);
                            else if (!root.appsMode && !root.rawMode) root.choose(root.query);   // dmenu: valor propio
                            event.accepted = true;
                        }
                    }
                }
            }

            // ---- lista ----
            ListView {
                id: list
                anchors {
                    top: inputBox.bottom; bottom: parent.bottom
                    left: parent.left; right: parent.right
                    margins: 10
                }
                anchors.topMargin: 4
                clip: true
                model: root.shown
                currentIndex: 0
                boundsBehavior: Flickable.StopAtBounds
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    // las filas con miniatura son más altas; las de solo texto, compactas
                    height: root.appsMode ? 36 : (row.modelData.icon !== "" ? 56 : 28)
                    radius: 4
                    color: row.ListView.isCurrentItem ? theme.surface90 : "transparent"

                    Image {
                        id: thumb
                        visible: root.hasIcons && row.modelData.icon !== ""
                        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                        width: root.appsMode ? 24 : 80
                        height: root.appsMode ? 24 : 44
                        fillMode: root.appsMode ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: width * 2
                        sourceSize.height: height * 2
                        source: row.modelData.icon !== "" ? root.iconSource(row.modelData.icon) : ""
                    }

                    Text {
                        anchors {
                            top: parent.top; bottom: parent.bottom
                            right: parent.right; rightMargin: root.canDelete ? 38 : 6
                        }
                        anchors.left: thumb.visible ? thumb.right : parent.left
                        anchors.leftMargin: thumb.visible ? 10 : 6
                        verticalAlignment: Text.AlignVCenter
                        text: row.modelData.label
                        elide: Text.ElideRight
                        color: row.ListView.isCurrentItem ? root.accent : theme.text
                        font.family: theme.font
                        font.pixelSize: 13
                        font.bold: row.ListView.isCurrentItem
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: list.currentIndex = row.index
                        onClicked: root.activate(row.modelData)
                    }

                    // ---- botón borrar esta entrada (declarado después: queda encima) ----
                    Rectangle {
                        id: delBtn
                        visible: root.canDelete && (row.ListView.isCurrentItem || delArea.containsMouse)
                        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                        width: 26
                        height: 22
                        radius: 4
                        color: delArea.containsMouse ? "#f7768e" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "🗑"
                            font.pixelSize: 13
                            color: theme.text
                        }

                        MouseArea {
                            id: delArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.removeItem(row.modelData)
                        }
                    }
                }
            }
        }
    }
}
