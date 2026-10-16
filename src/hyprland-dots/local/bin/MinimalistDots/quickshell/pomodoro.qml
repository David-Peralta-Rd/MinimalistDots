import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Widget del Pomodoro (reemplaza al widget de eww + el daemon de bash).
// El temporizador vive aquí; scripts/pomodoro.sh solo pregunta los tiempos y manda
// órdenes por IPC:  qs -p pomodoro.qml ipc call pomodoro {pause|restart|stop}
// Entrada (env): MD_POMO_FOCUS, MD_POMO_BREAK (minutos), MD_POMO_SESSIONS,
//                MD_POMO_UNIT (segundos por "minuto", solo para probar rápido)
ShellRoot {
    id: root

    Theme { id: theme }

    function num(name, def) {
        const n = parseInt(Quickshell.env(name));
        return n > 0 ? n : def;
    }

    readonly property int unit: num("MD_POMO_UNIT", 60)
    readonly property int focusLen: num("MD_POMO_FOCUS", 25) * unit
    readonly property int breakLen: num("MD_POMO_BREAK", 5) * unit
    readonly property int total: num("MD_POMO_SESSIONS", 4)

    property int session: 1
    property string phase: "focus"      // focus | break
    property bool paused: false
    property int remaining: focusLen
    property double endTs: 0            // ms desde epoch en que termina la fase

    readonly property int phaseLen: phase === "focus" ? focusLen : breakLen
    readonly property string cls: paused ? "paused" : phase
    readonly property real pct: phaseLen > 0 ? remaining * 100 / phaseLen : 0
    readonly property string clockText: pad(Math.floor(remaining / 60)) + ":" + pad(remaining % 60)

    function pad(n) { return n < 10 ? "0" + n : "" + n; }

    function notify(title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Pomodoro", title, body || ""]);
    }

    function secondsLeft() {
        return Math.max(0, Math.round((endTs - Date.now()) / 1000));
    }

    function startPhase() {
        remaining = phaseLen;
        endTs = Date.now() + remaining * 1000;
    }

    function advance() {
        if (phase === "focus") {
            if (session >= total) {
                notify("Pomodoro completado 🎉", "Terminaste las " + total + " sesiones.");
                Qt.quit();
                return;
            }
            phase = "break";
            notify("Descanso", "Sesión " + session + " de " + total + " terminada.");
        } else {
            session += 1;
            phase = "focus";
            notify("Sesión " + session + " de " + total, "A concentrarse.");
        }
        startPhase();
    }

    function tick() {
        remaining = secondsLeft();
        if (remaining <= 0) advance();
    }

    function togglePause() {
        if (!paused) {
            remaining = secondsLeft();
            paused = true;
        } else {
            endTs = Date.now() + remaining * 1000;
            paused = false;
        }
    }

    function restartPhase() {
        paused = false;
        startPhase();
    }

    function run(action) {
        if (action === "pause") togglePause();
        else if (action === "restart") restartPhase();
        else Qt.quit();
    }

    Component.onCompleted: {
        startPhase();
        notify("Pomodoro iniciado", "Sesión 1 de " + total);
    }

    Timer {
        interval: 1000
        repeat: true
        running: !root.paused
        onTriggered: root.tick()
    }

    IpcHandler {
        target: "pomodoro"
        function pause(): void { root.togglePause(); }
        function restart(): void { root.restartPhase(); }
        function stop(): void { Qt.quit(); }
    }

    PanelWindow {
        // abajo al centro; margin = gaps_out de Hyprland para alinear con las ventanas
        anchors.bottom: true
        margins.bottom: 6
        implicitWidth: Math.max(80, content.implicitWidth + 16)
        implicitHeight: content.implicitHeight + 10
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "md-pomodoro"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: theme.bg92
            border.width: 1
            border.color: theme.borderInactive
            radius: 7
            // semitransparente hasta que pasas el mouse
            opacity: hover.hovered ? 1.0 : 0.35
            Behavior on opacity { NumberAnimation { duration: 200 } }

            HoverHandler { id: hover }

            // clic izq: pausa | clic der: reiniciar fase | clic medio: detener
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) root.run("restart");
                    else if (mouse.button === Qt.MiddleButton) root.run("stop");
                    else root.run("pause");
                }
            }

            Row {
                id: content
                anchors.centerIn: parent
                spacing: 6

                Column {
                    spacing: 3
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: timeText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.clockText
                        color: root.paused ? theme.subtext : theme.text
                        font.family: theme.font
                        font.pixelSize: 16
                        font.weight: Font.ExtraBold
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.session + "/" + root.total
                        color: theme.subtext
                        font.family: theme.font
                        font.pixelSize: 9
                    }
                    // barra fina: se vacía a medida que pasa el tiempo
                    Rectangle {
                        width: timeText.implicitWidth
                        height: 3
                        radius: 2
                        color: theme.surface
                        Rectangle {
                            width: parent.width * root.pct / 100
                            height: parent.height
                            radius: 2
                            color: root.cls === "paused" ? theme.gray
                                 : root.cls === "break" ? theme.accentGreen
                                 : theme.accentRed
                        }
                    }
                }

                // botones: pausa/reanudar, reiniciar fase, detener
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                        model: [
                            { l: root.paused ? "▶" : "❚❚", a: "pause" },
                            { l: "↻", a: "restart" },
                            { l: "✕", a: "stop" }
                        ]
                        delegate: Rectangle {
                            id: btn
                            required property var modelData
                            width: lbl.implicitWidth + 8
                            height: lbl.implicitHeight + 2
                            radius: 3
                            color: ma.containsMouse ? theme.selection : "transparent"
                            Text {
                                id: lbl
                                anchors.centerIn: parent
                                text: btn.modelData.l
                                color: ma.containsMouse ? theme.text : theme.subtext
                                font.family: theme.font
                                font.pixelSize: 9
                            }
                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.run(btn.modelData.a)
                            }
                        }
                    }
                }
            }
        }
    }
}
