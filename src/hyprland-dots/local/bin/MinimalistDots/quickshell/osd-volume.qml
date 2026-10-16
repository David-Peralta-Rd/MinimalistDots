import QtQuick
import Quickshell
import Quickshell.Wayland

// OSD de volumen: muestra $MD_OSD_TEXT ~1.2 s y se cierra solo.
ShellRoot {
    Theme { id: theme }

    Timer {
        running: true
        interval: 1200
        onTriggered: Qt.quit()
    }

    PanelWindow {
        anchors.top: true
        margins.top: 15
        implicitWidth: Math.max(100, label.implicitWidth + 28)   // se ajusta solo al texto
        implicitHeight: 36
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "md-osd"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: theme.bg90
            radius: 8
            border.width: 1
            border.color: theme.borderInactive

            Text {
                id: label
                anchors.centerIn: parent
                text: Quickshell.env("MD_OSD_TEXT") || ""
                color: theme.text
                font.family: theme.font
                font.pixelSize: 14
                font.bold: true
            }
        }
    }
}
