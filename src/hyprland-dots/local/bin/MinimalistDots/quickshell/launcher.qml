import QtQuick

// Lanzador de aplicaciones (SUPER+A). Reemplaza a `wofi --show drun`.
MdMenu {
    appsMode: true
    atTop: true
    topMargin: 20
    prompt: "🚀"
    menuWidth: 500
    menuHeight: 460
    menuRadius: 12
    accent: th.accentGreen

    Theme { id: th }
}
