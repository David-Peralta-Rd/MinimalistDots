#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/u3_env.sh"

BACKUP_HYPRLAND="$SCRIPT_DIR/c3_backup_hypr"
DEST_CONFIGS_DIR="$HOME/.config"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"


# ========================================================== #
# ==== DESCUBRIMIENTO DINAMICO DE CONFIGURACIONES ========== #
# ========================================================== #
if [ ! -d "$MD_DOTS_CONFIG" ]; then
    echo "$T_CONFIGURACION_NO_ENCONTRADA $MD_DOTS_CONFIG" >&2
    exit 1
fi

# Todo lo que haya dentro de hyprland-dots/config: carpetas (hypr, foot...)
# y archivos sueltos (dolphinrc).
shopt -s nullglob
ITEMS=("$MD_DOTS_CONFIG"/*)
shopt -u nullglob

APPS=()
for item in "${ITEMS[@]}"; do
    APPS+=("$(basename "$item")")
done

if [ ${#APPS[@]} -eq 0 ]; then
    echo "$T_CONFIGURACION_NO_ENCONTRADA $MD_DOTS_CONFIG"
    exit 0
fi

# ========================================================== #
# ==== CONFIRMACIÓN ÚNICA PARA TODO EL PROCESO ============== #
# ========================================================== #
echo "=========================================================="
echo "📦 $T_CONFIGURACIONES_DE_ENCABEZADO (${#APPS[@]}: ${APPS[*]})"
echo "=========================================================="
read -rp "$T_CONFIRMACION_DE_CONFIGS ($T_LETRA_DE_CONFIRMACION/n): " confirm
confirm="${confirm:-$T_LETRA_DE_CONFIRMACION}"   # Enter = confirmar, como indica la letra en mayúscula
if [ "${confirm,,}" != "${T_LETRA_DE_CONFIRMACION,,}" ]; then
    echo "$T_CANCELADO"
    exit 10   # steps.sh interpreta 10 como "cancelado por el usuario"
fi

# ========================================================== #
# ==== BUCLE GENERAL DE BACKUP Y APLICACIÓN DE CONFIGS ===== #
# ========================================================== #
for app in "${APPS[@]}"; do
    SRC="$MD_DOTS_CONFIG/$app"
    DEST="$DEST_CONFIGS_DIR/$app"
    APP_BACKUP_ROOT="$MD_BACKUP_ROOT/$app-backups/$TIMESTAMP"

    # 1. Realizar Backup si el destino ya existe (carpeta o archivo)
    if [ -e "$DEST" ] || [ -L "$DEST" ]; then
        echo "$T_BACKUP_SI_EXISTE $app -> $APP_BACKUP_ROOT"
        mkdir -p "$APP_BACKUP_ROOT"
        if [ -d "$DEST" ]; then
            cp -a "$DEST/." "$APP_BACKUP_ROOT/"
        else
            cp -a "$DEST" "$APP_BACKUP_ROOT/"
        fi

        echo "$T_LIMPIANDO_DESTINO $DEST"
        rm -rf "$DEST"
    else
        echo "$T_PAQUETE_DETECTADO $app"
    fi

    # 2. Copiar archivos nuevos desde el proyecto
    echo "$T_COPIANDO_PAQUETE $SRC -> $DEST"
    if [ -d "$SRC" ]; then
        mkdir -p "$DEST"
        cp -a "$SRC/." "$DEST/"
    else
        cp -a "$SRC" "$DEST"
    fi

    # ====================================================== #
    # ==== LÓGICA ESPECÍFICA PARA HYPRLAND (SI APLICA) ===== #
    # ====================================================== #
    if [ "$app" = "hypr" ]; then
        echo "$T_CONFIGURANDO_ARCHIVOS_ESPECIFICOS"

        # Cada pieza generada vive en c3_backup_hypr/bkN_*.sh
        # (hyprland.lua, hypridle, hyprlock, hyprpaper, colors.lua).
        # Para agregar otra, basta con crear un bkN_*.sh nuevo en esa carpeta.
        for piece in "$BACKUP_HYPRLAND"/bk*.sh; do
            HYPR_DIR="$DEST" bash "$piece"
        done

        # Las personalizaciones del usuario sobreviven a la reinstalación
        if [ -d "$APP_BACKUP_ROOT/custom" ]; then
            cp -a "$APP_BACKUP_ROOT/custom" "$DEST/"
            echo "$T_CUSTOM_RESTAURADO $DEST/custom"
        fi
    fi
done
