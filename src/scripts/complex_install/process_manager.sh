#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SRC_DIR/../../.." && pwd)"

# Si el subscript se ejecuta solo (sin pasar por setup.sh), carga el idioma guardado
if [ -z "${TXT_WELCOME:-}" ]; then
    # Subimos un nivel con ".." para salir de "scripts/" y entrar a "src/"
    LANG_LOADER="$SRC_DIR/../../lang/load_lang.sh"
    if [ -f "$LANG_LOADER" ]; then
        source "$LANG_LOADER"
    else
        echo "Aviso: No se pudo encontrar el archivo de idioma en $LANG_LOADER"
    fi
fi


# Paleta global de colores (misma fuente que el resto de la instalación)
PALETTE_FILE="$PROJECT_ROOT/src/scripts/colors/palette.sh"
if [ -f "$PALETTE_FILE" ]; then
    source "$PALETTE_FILE"
else
    C_BG="#1e222a"; C_SURFACE="#282c34"; C_SELECTION="#3e4451"
    C_TEXT="#abb2bf"; C_SUBTEXT="#5c6370"; C_ACCENT_BLUE="#7aa2f7"
    C_ACCENT_RED="#e06c75"
fi


INSTALL_DIR="$HOME/.local/bin/minimalist_dots/scripts"
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
    placeholder: "Buscar o seleccionar para cerrar...";
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

echo "==> Gestor de procesos instalado exitosamente en $TARGET_FILE"
