#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LANG_FILE="${1:-es.cfg}"
PATH_TRADUCCION="$SCRIPT_DIR/lang/$LANG_FILE"

if [[ -f "$PATH_TRADUCCION" ]]; then
    source "$PATH_TRADUCCION"
fi

echo "=========================================================="
echo "${TXT_ENV_INSTALLING:-Generando variables de entorno...}"
echo "=========================================================="

HYPR_DIR="$HOME/.config/hypr/hyprland"
mkdir -p "$HYPR_DIR"

cat << 'EOF' > "$HYPR_DIR/env.lua"
--------------------------------------------------------------------------------------
-- NO MODIFIQUES ESTA CONFIGURACIÓN; SI DESEAS HACER CAMBIOS,                       --
-- VE A LA SIGUIENTE CARPETA Y REALIZA TUS CONFIGURACIONES PERSONALES:              --
-- ~/.config/hypr/custom_minimalist/env.lua                                         --
--------------------------------------------------------------------------------------
hl.env("XCURSOR_SIZE", "18")
hl.env("HYPRCURSOR_SIZE", "18")
EOF

echo "${TXT_ENV_OK:-Variables de entorno generadas correctamente.}"
echo ""
