import QtQuick
import Quickshell
import Quickshell.Wayland

// Reloj de escritorio (reemplaza al widget desktop_clock de eww).
// Capa "bottom": queda detrás de las ventanas y no reserva espacio.
ShellRoot {
    Theme { id: theme }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    PanelWindow {
        id: win
        // izquierda, centrado en vertical y 40px más abajo (igual que el eww anterior)
        anchors { left: true; top: true }
        margins.top: Math.round(((screen ? screen.height : 1080) - implicitHeight) / 2) + 40
        implicitWidth: 280
        implicitHeight: 120
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "md-clock"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Column {
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            spacing: 4

            Text {
                anchors.right: parent.right
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: theme.text
                font.family: theme.font
                font.pixelSize: 56
                font.weight: Font.ExtraBold
            }
            Text {
                anchors.right: parent.right
                text: Qt.locale().toString(clock.date, "ddd, dd MMM").toLowerCase()
                color: theme.subtext
                font.family: theme.font
                font.pixelSize: 16
                font.weight: Font.Medium
            }
        }
    }
}
