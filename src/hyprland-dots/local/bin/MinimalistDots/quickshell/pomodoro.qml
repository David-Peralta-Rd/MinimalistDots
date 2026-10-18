import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Widget del Pomodoro (reemplaza al widget de eww + el daemon de bash).
// En concentración: widget pequeño abajo al centro.
// En descanso: tarjeta grande en el centro de la pantalla (para que no se te pase el descanso);
//              "Minimizar" la manda al widget pequeño hasta la siguiente fase.
// Al cambiar de fase suena el aviso: lo reproduce `pomodoro.sh sound`.
// El temporizador vive aquí; scripts/pomodoro.sh solo pregunta los tiempos y manda
// órdenes por IPC:  qs -p pomodoro.qml ipc call pomodoro {pause|restart|stop}
// Entrada (env): MD_POMO_FOCUS, MD_POMO_BREAK (minutos), MD_POMO_SESSIONS,
//                MD_POMO_UNIT (segundos por "minuto", solo para probar rápido)
//                MD_POMO_SCRIPT (ruta de pomodoro.sh, la pone él mismo; reproduce el sonido)
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
    property bool collapsed: false      // descanso minimizado al widget pequeño

    readonly property string soundScript: Quickshell.env("MD_POMO_SCRIPT") || ""
    readonly property bool bigBreak: phase === "break" && !collapsed

    readonly property int phaseLen: phase === "focus" ? focusLen : breakLen
    readonly property string cls: paused ? "paused" : phase
    readonly property real pct: phaseLen > 0 ? remaining * 100 / phaseLen : 0
    readonly property string clockText: pad(Math.floor(remaining / 60)) + ":" + pad(remaining % 60)

    function pad(n) { return n < 10 ? "0" + n : "" + n; }

    function notify(title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Pomodoro", title, body || ""]);
    }

    function playSound() {
        if (soundScript !== "") Quickshell.execDetached([soundScript, "sound"]);
    }

    function secondsLeft() {
        return Math.max(0, Math.round((endTs - Date.now()) / 1000));
    }

    function startPhase() {
        remaining = phaseLen;
        endTs = Date.now() + remaining * 1000;
    }

    function advance() {
        playSound();
        if (phase === "focus") {
            if (session >= total) {
                notify("Pomodoro completado 🎉", "Terminaste las " + total + " sesiones.");
                Qt.quit();
                return;
            }
            phase = "break";
            collapsed = false;
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
        collapsed = false;
        startPhase();
    }

    function run(action) {
        if (action === "pause") togglePause();
        else if (action === "restart") restartPhase();
        else if (action === "collapse") collapsed = true;
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

    // ---------- widget pequeño (concentración, o descanso minimizado) ----------
    PanelWindow {
        visible: !root.bigBreak
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

    // ---------- descanso: tarjeta grande en el centro de la pantalla ----------
    PanelWindow {
        id: bigWin
        visible: root.bigBreak
        implicitWidth: 500
        implicitHeight: 310
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "md-pomodoro-break"
        WlrLayershell.layer: WlrLayer.Overlay                 // por encima de todo, incluso a pantalla completa
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None    // no te roba el teclado

        onVisibleChanged: if (visible) fadeIn.restart()

        Rectangle {
            id: bigCard
            anchors.fill: parent
            radius: 22
            color: theme.bg
            border.width: 2
            border.color: root.paused ? theme.gray : theme.accentGreen

            NumberAnimation { id: fadeIn; target: bigCard; property: "opacity"; from: 0; to: 1; duration: 300 }

            Column {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.paused ? "⏸  En pausa" : "☕  Hora de descansar"
                    color: root.paused ? theme.subtext : theme.accentGreen
                    font.family: theme.font
                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.clockText
                    color: theme.text
                    font.family: theme.font
                    font.pixelSize: 80
                    font.weight: Font.ExtraBold
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Sesión " + root.session + " de " + root.total + " completada"
                    color: theme.subtext
                    font.family: theme.font
                    font.pixelSize: 14
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Levántate, estírate y mira a lo lejos."
                    color: theme.subtext
                    font.family: theme.font
                    font.pixelSize: 13
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 340
                    height: 6
                    radius: 3
                    color: theme.surface
                    Rectangle {
                        width: parent.width * root.pct / 100
                        height: parent.height
                        radius: 3
                        color: root.paused ? theme.gray : theme.accentGreen
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    Repeater {
                        model: [
                            { l: root.paused ? "▶ Reanudar" : "❚❚ Pausar", a: "pause" },
                            { l: "↻ Reiniciar", a: "restart" },
                            { l: "▾ Minimizar", a: "collapse" },
                            { l: "✕ Detener", a: "stop" }
                        ]
                        delegate: Rectangle {
                            id: bigBtn
                            required property var modelData
                            width: bigLbl.implicitWidth + 20
                            height: 30
                            radius: 8
                            color: bigMa.containsMouse ? theme.selection : theme.surface
                            Text {
                                id: bigLbl
                                anchors.centerIn: parent
                                text: bigBtn.modelData.l
                                color: theme.text
                                font.family: theme.font
                                font.pixelSize: 12
                            }
                            MouseArea {
                                id: bigMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.run(bigBtn.modelData.a)
                            }
                        }
                    }
                }
            }
        }
    }
}
