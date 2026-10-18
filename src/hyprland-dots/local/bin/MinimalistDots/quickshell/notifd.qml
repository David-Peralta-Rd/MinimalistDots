import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications

// Servidor de notificaciones (reemplaza a SwayNC).
//  - Muestra las notificaciones arriba a la derecha, más nuevas arriba
//  - Guarda todas en un historial (JSON por línea) que lee scripts/notifications_menu.sh
//  - "No molestar": las guarda en el historial pero no las muestra (las críticas sí)
// Control:  qs -p notifd.qml ipc call notifd {toggleDnd|status|clearPopups}
ShellRoot {
    id: root

    Theme { id: theme }

    // ---------- ajustes ----------
    readonly property int popupWidth: 360
    readonly property int maxPopups: 5
    readonly property int defaultTimeout: 6000      // ms; las críticas no expiran solas
    readonly property int historyKeep: 300          // líneas que se conservan al iniciar
    readonly property var ignoredApps: ["Historial"] // no se guardan en el historial

    readonly property string stateDir:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/MinimalistDots"
    readonly property string historyFile: stateDir + "/notifications.jsonl"

    property bool dnd: false

    // ---------- historial ----------
    function urgencyName(u) {
        if (u === NotificationUrgency.Critical) return "critical";
        if (u === NotificationUrgency.Low) return "low";
        return "normal";
    }

    function record(n) {
        if (ignoredApps.indexOf(n.appName) >= 0) return;
        const line = JSON.stringify({
            time: Math.floor(Date.now() / 1000),
            app: n.appName,
            summary: n.summary,
            body: n.body,
            urgency: urgencyName(n.urgency)
        });
        Quickshell.execDetached([
            "sh", "-c",
            'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" >> "$1"',
            "sh", historyFile, line
        ]);
    }

    Component.onCompleted: {
        // recorta el historial para que no crezca sin límite
        Quickshell.execDetached([
            "sh", "-c",
            'f="$1"; [ -f "$f" ] && tail -n "$2" "$f" > "$f.tmp" && mv "$f.tmp" "$f"',
            "sh", historyFile, String(historyKeep)
        ]);
    }

    // ---------- servidor ----------
    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            root.record(notification);

            // en "no molestar" solo se muestran las críticas; sin `tracked` se descarta
            if (root.dnd && notification.urgency !== NotificationUrgency.Critical) return;

            notification.tracked = true;
        }
    }

    IpcHandler {
        target: "notifd"
        function toggleDnd(): string {
            root.dnd = !root.dnd;
            return root.dnd ? "on" : "off";
        }
        function status(): string { return root.dnd ? "dnd" : "normal"; }
        function clearPopups(): void {
            server.trackedNotifications.values.slice().forEach(n => n.dismiss());
        }
    }

    function iconFor(n) {
        if (n.image) return n.image;
        if (n.appIcon) {
            if (n.appIcon.startsWith("/")) return "file://" + n.appIcon;
            return Quickshell.iconPath(n.appIcon, true);
        }
        return "";
    }

    // ---------- ventana ----------
    PanelWindow {
        // depende del modelo (no de la vista): evita el círculo ventana -> ListView -> ventana
        visible: server.trackedNotifications.values.length > 0
        anchors { top: true; right: true }
        margins { top: 12; right: 12 }
        implicitWidth: root.popupWidth
        implicitHeight: Math.max(1, list.contentHeight)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "md-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        ListView {
            id: list
            // altura propia, independiente de la ventana: permite crear delegados aunque la ventana mida 1px
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 800
            model: server.trackedNotifications
            spacing: 8
            interactive: false
            // el modelo va de la más vieja a la más nueva: así la nueva queda arriba
            verticalLayoutDirection: ListView.BottomToTop

            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 } }
            remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 120 } }
            displaced: Transition { NumberAnimation { property: "y"; duration: 150 } }

            delegate: Item {
                id: item
                required property var modelData      // Notification

                width: ListView.view.width
                height: card.height

                readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                readonly property real timeoutMs:
                    modelData.expireTimeout > 0 ? modelData.expireTimeout * 1000
                    : (critical ? 0 : root.defaultTimeout)
                readonly property string iconSrc: root.iconFor(modelData)
                // hint estándar "value" (0-100): notify-send -h int:value:40
                readonly property int progress:
                    (modelData.hints && modelData.hints.value !== undefined) ? Number(modelData.hints.value) : -1

                function activate() {
                    const acts = modelData.actions;
                    for (let i = 0; i < acts.length; i++) {
                        if (acts[i].identifier === "default") { acts[i].invoke(); break; }
                    }
                    modelData.dismiss();
                }

                Timer {
                    interval: item.timeoutMs
                    running: item.timeoutMs > 0 && !hover.hovered
                    onTriggered: item.modelData.expire()
                }

                Rectangle {
                    id: card
                    width: parent.width
                    height: body.implicitHeight + 24
                    radius: 12
                    color: theme.bg92
                    border.width: 1
                    border.color: item.critical ? theme.accentRed
                                : hover.hovered ? theme.accentBlue
                                : theme.borderInactive
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    HoverHandler { id: hover }

                    // clic: acción por defecto + cerrar | clic derecho/medio: cerrar
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) item.activate();
                            else item.modelData.dismiss();
                        }
                    }

                    Image {
                        id: icon
                        visible: item.iconSrc !== ""
                        anchors { left: parent.left; leftMargin: 12; top: parent.top; topMargin: 12 }
                        width: visible ? 36 : 0
                        height: 36
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        sourceSize.width: 72
                        sourceSize.height: 72
                        source: item.iconSrc
                    }

                    Column {
                        id: body
                        anchors {
                            left: icon.visible ? icon.right : parent.left
                            leftMargin: icon.visible ? 10 : 14
                            right: parent.right; rightMargin: 14
                            top: parent.top; topMargin: 12
                        }
                        spacing: 3

                        Item {
                            width: parent.width
                            height: appLabel.implicitHeight
                            Text {
                                id: appLabel
                                anchors { left: parent.left; right: closeBtn.left; rightMargin: 6 }
                                text: item.modelData.appName.toUpperCase()
                                elide: Text.ElideRight
                                color: item.critical ? theme.accentRed : theme.subtext
                                font.family: theme.font
                                font.pixelSize: 10
                                font.letterSpacing: 1
                            }
                            Text {
                                id: closeBtn
                                anchors.right: parent.right
                                text: "✕"
                                opacity: hover.hovered ? 1 : 0
                                color: closeArea.containsMouse ? theme.text : theme.subtext
                                font.family: theme.font
                                font.pixelSize: 11
                                MouseArea {
                                    id: closeArea
                                    anchors { fill: parent; margins: -6 }
                                    hoverEnabled: true
                                    onClicked: item.modelData.dismiss()
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: item.modelData.summary
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            color: theme.text
                            font.family: theme.font
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: item.modelData.body
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            color: theme.subtext
                            font.family: theme.font
                            font.pixelSize: 12
                        }

                        // barra de progreso (hint "value")
                        Rectangle {
                            visible: item.progress >= 0
                            width: parent.width
                            height: 4
                            radius: 2
                            color: theme.surface
                            Rectangle {
                                width: parent.width * Math.min(100, item.progress) / 100
                                height: parent.height
                                radius: 2
                                color: item.critical ? theme.accentRed : theme.accentBlue
                            }
                        }

                        // botones de acción (salvo "default", que es el clic en la tarjeta)
                        Row {
                            spacing: 6
                            visible: item.modelData.actions.length > 1
                                     || (item.modelData.actions.length === 1
                                         && item.modelData.actions[0].identifier !== "default")
                            Repeater {
                                model: item.modelData.actions
                                delegate: Rectangle {
                                    id: act
                                    required property var modelData
                                    visible: modelData.identifier !== "default"
                                    width: actLabel.implicitWidth + 16
                                    height: 22
                                    radius: 6
                                    color: actArea.containsMouse ? theme.selection : theme.surface
                                    Text {
                                        id: actLabel
                                        anchors.centerIn: parent
                                        text: act.modelData.text
                                        color: theme.text
                                        font.family: theme.font
                                        font.pixelSize: 11
                                    }
                                    MouseArea {
                                        id: actArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: act.modelData.invoke()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
