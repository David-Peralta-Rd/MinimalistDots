#!/usr/bin/env bash
set -euo pipefail

ARCHIVO_LANG="${1:-en.cfg}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LANG_DIR="$PROJECT_ROOT/src/lang"

[ -f "$LANG_DIR/$ARCHIVO_LANG" ] && source "$LANG_DIR/$ARCHIVO_LANG"

echo "==> Instalando dependencias de Process Manager..."
paru -S --needed --noconfirm rofi-wayland jq libnotify

INSTALL_DIR="$HOME/.local/bin/minimaldots"
TARGET_FILE="$INSTALL_DIR/process_manager.sh"
mkdir -p "$INSTALL_DIR"

cat << 'EOF' > "$TARGET_FILE"
#!/usr/bin/env bash

ROFI_THEME="${XDG_RUNTIME_DIR:-/tmp}/rofi-process-manager.rasi"

cat << 'RFT' > "$ROFI_THEME"
configuration {
    show-icons: true;
    font: "JetBrainsMono Nerd Font 8";
    case-sensitive: false;
    matching: "fuzzy";
}

* {
    background-color: #1e1e2e;
    text-color: #cdd6f4;
    border-color: #89b4fa;
}

window {
    location: center;
    anchor: center;
    width: 600px;
    height: 480px;
    border: 2px;
    border-radius: 12px;
    padding: 16px;
    background-color: #1e1e2e;
}

mainbox {
    children: [ inputbar, listview ];
    spacing: 12px;
}

inputbar {
    children: [ prompt, entry ];
    background-color: #313244;
    border-radius: 8px;
    padding: 8px 12px;
}

prompt {
    text-color: #89b4fa;
    margin: 0px 8px 0px 0px;
}

entry {
    placeholder: "Buscar o seleccionar para cerrar...";
    placeholder-color: #6c7086;
}

listview {
    lines: 10;
    columns: 1;
    cycle: true;
    scrollbar: false;
}

element {
    padding: 2px 3px;
    border-radius: 3px;
    background-color: transparent;
}

element selected {
    background-color: #992600;
    text-color: #cdd6f4;
}

element-text {
    text-color: inherit;
}
RFT

get_user_apps() {
    if command -v hyprctl &>/dev/null; then
        hyprctl clients -j | jq -r '.[] | "🗑️  \(.title) [Class: \(.class)] (PID: \(.pid))"' | sort -u
    else
        ps -u "$USER" -o pid,comm --no-headers | awk '{print "🗑️  " $2 " (PID: " $1 ")"}'
    fi
}

get_system_apps() {
    ps -u "$USER" -o pid,comm,%mem,%cpu --sort=-%mem | awk 'NR>1 {print "⚙️  " $2 " | RAM: " $3 "% | CPU: " $4 "% (PID: " $1 ")"}'
}

show_category_menu() {
    cat <<EOFM | rofi -dmenu -i -theme "$ROFI_THEME" -p "Gestor" -mesg "Selecciona una categoría:"
📱 Aplicaciones del Día a Día (GUI)
⚙️ Procesos del Sistema / Fondo
EOFM
}

category=$(show_category_menu)

case "$category" in
    *"Día a Día"*)
        selected=$(get_user_apps | rofi -dmenu -i -theme "$ROFI_THEME" -p "Cerrar App" -mesg "Selecciona una app para finalizarla:")
        ;;
    *"Sistema"*)
        selected=$(get_system_apps | rofi -dmenu -i -theme "$ROFI_THEME" -p "Matar Proceso" -mesg "Selecciona un proceso para matarlo:")
        ;;
    *)
        exit 0
        ;;
esac

if [[ -n "$selected" ]]; then
    pid=$(echo "$selected" | grep -oP '\(PID:\s*\K[0-9]+(?=\))')

    if [[ -n "$pid" ]]; then
        if kill -9 "$pid" 2>/dev/null; then
            notify-send -a "Gestor de Procesos" -i "dialog-information" "Proceso Finalizado" "Se cerró el proceso con PID: $pid"
        else
            notify-send -a "Gestor de Procesos" -i "dialog-error" "Error" "No se pudo cerrar el proceso $pid"
        fi
    fi
fi
EOF

chmod +x "$TARGET_FILE"
echo "==> Gestor de procesos instalado exitosamente en $TARGET_FILE"
