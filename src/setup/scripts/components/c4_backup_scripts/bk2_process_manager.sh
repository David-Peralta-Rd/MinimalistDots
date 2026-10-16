#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/u3_env.sh"

# ==== process_manager.sh ==== #
# Usa md_menu (Quickshell), instalado por bk3_quickshell.sh (menu-process.qml).
INSTALL_DIR="$MD_SCRIPTS_DIR"
TARGET_FILE="$INSTALL_DIR/process_manager.sh"
mkdir -p "$INSTALL_DIR"

cat << 'EOF' > "$TARGET_FILE"
#!/usr/bin/env bash

MENU="$(dirname "$(readlink -f "$0")")/md_menu"

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

category=$(printf '%s\n' "📱 Aplicaciones Día a Día (GUI)" "⚙️ Procesos del Sistema / Fondo" \
    | "$MENU" process --prompt "Gestor" || true)

case "$category" in
    *"Día a Día"*)
        selected=$(get_user_apps | "$MENU" process --raw --prompt "Cerrar App" || true)
        ;;
    *"Sistema"*)
        selected=$(get_system_apps | "$MENU" process --raw --prompt "Matar Proceso" || true)
        ;;
    *)
        exit 0
        ;;
esac

if [[ -n "${selected:-}" ]]; then
    pid=$(echo "$selected" | grep -oP '\(PID:\s*\K[0-9]+(?=\))' || true)

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

echo "$T_GESTOR_DE_PROCESOS_INSTALADOS $TARGET_FILE"
