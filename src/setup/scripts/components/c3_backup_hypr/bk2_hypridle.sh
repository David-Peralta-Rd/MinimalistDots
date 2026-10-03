#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/u3_env.sh"

# c3 pasa HYPR_DIR; si el script se ejecuta solo, usa ~/.config/hypr
HYPR_DIR="${HYPR_DIR:-$MD_HYPR_DIR}"
TARGET="$HYPR_DIR/hypridle.conf"
mkdir -p "$(dirname "$TARGET")"

cat > "$TARGET" <<'EOF'
general {
    lock_cmd = pidof hyprlock || hyprlock          # Evita abrir múltiples instancias
    before_sleep_cmd = loginctl lock-session      # Bloquea la sesión antes de suspender
    after_sleep_cmd = hyprctl dispatch dpms on    # Enciende la pantalla al despertar
}

# Bloquear pantalla tras 20 minutos (1200 segundos)
listener {
    timeout = 1200
    on-timeout = loginctl lock-session
}

# Apagar pantalla a los 21 minutos (1260 segundos)
listener {
    timeout = 1260
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
EOF
