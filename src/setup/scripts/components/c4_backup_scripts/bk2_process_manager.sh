#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/u3_env.sh"

# ==== Process_manager.sh ==== #
INSTALL_DIR="$MD_SCRIPTS_DIR"
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
    background-color: __C_BG__;
    text-color: __C_TEXT__;
    border-color: __C_ACCENT_BLUE__;
}

window {
    location: center;
    anchor: center;
    width: 600px;
    height: 480px;
    border: 2px;
    border-radius: 12px;
    padding: 16px;
    background-color: __C_BG__;
}

mainbox {
    children: [ inputbar, listview ];
    spacing: 12px;
}

inputbar {
    children: [ prompt, entry ];
    background-color: __C_SURFACE__;
    border-radius: 8px;
    padding: 8px 12px;
}

prompt {
    text-color: __C_ACCENT_BLUE__;
    margin: 0px 8px 0px 0px;
}

entry {
    placeholder: "Search";
    placeholder-color: __C_SUBTEXT__;
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
    background-color: __C_ACCENT_RED__;
    text-color: __C_TEXT__;
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
📱 Aplicaciones Día a Día (GUI)
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
            notify-send -a "Process Manager" -i "dialog-information" "Process Finished" "Process closed with PID: $pid"
        else
            notify-send -a "Process Manager" -i "dialog-error" "Error" "The process could not be closed $pid"
        fi
    fi
fi
EOF

chmod +x "$TARGET_FILE"

# Inyectar la paleta real de colores en el script instalado
# (se mantiene el heredoc principal citado 'EOF' para no romper las
# variables de runtime como $pid o $selected).
sed -i \
    -e "s/__C_BG__/${C_BG}/g" \
    -e "s/__C_TEXT__/${C_TEXT}/g" \
    -e "s/__C_ACCENT_BLUE__/${C_ACCENT_BLUE}/g" \
    -e "s/__C_SURFACE__/${C_SURFACE}/g" \
    -e "s/__C_SUBTEXT__/${C_SUBTEXT}/g" \
    -e "s/__C_ACCENT_RED__/${C_ACCENT_RED}/g" \
    "$TARGET_FILE"

echo "$T_GESTOR_DE_PROCESOS_INSTALADOS $TARGET_FILE"
