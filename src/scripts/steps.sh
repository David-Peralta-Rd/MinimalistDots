#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANG_DIR="$(cd "$SCRIPT_DIR/../lang" && pwd)"
UTILS_DIR="$(cd "$SCRIPT_DIR/utils" && pwd)"

# CARGAR EL IDIOMA SI EL SCRIPT SE EJECUTA DIRECTAMENTE
if [ -z "${T_BIENVENIDO:-}" ]; then
    source "$LANG_DIR/load_lang.sh"
fi

# DEFINIMOS LA RUTA DE LA CARPETA DE SCRIPTS
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENTS_DIR="$SCRIPT_DIR/components"

# CARGAMOS UTILIDAD DE TITULO
source $UTILS_DIR/title.sh
source $UTILS_DIR/palette.sh


# ======================================= #
# ==== EMPEZAMOS A EJECUTR LOS PASOS ==== #
# ======================================= #
print_title "$T_BIENVENIDO"

# PRIMER PASO -- CREACIONES DE CARPETAS
print_title "$T_NUEVAS_CARPETAS"
bash "$COMPONENTS_DIR/new_folders.sh"

# SEGUNDO PASO -- INSTALACION DE PAQUETES
print_title "$T_INSTALANDO_PAQUETES"
bash "$COMPONENTS_DIR/install_packages.sh"

# TERCER PASO -- BACKUP DE LAS CONFIGURACIONES DENTRO DE "~/.config"
print_title "$T_COMENZANDO_BACKUP_Y_INSTALACION"
bash "$COMPONENTS_DIR/backup_and_install.sh"

# CUARTO PASO -- INSTALACION DE SERVICIOS Y SCRIPTS
print_title "$T_INSTALANDO_SERVICIOS_Y_SCRIPTS"
bash "$COMPONENTS_DIR/install_services_and_scripts.sh"

# REFRESCAMOS HYPRLAND
# ========================================================== #
# ==== RECARGA FINAL DE HYPRLAND (SI ESTÁ ACTIVO) ========== #
# ========================================================== #
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    echo "$T_RECARGA"
    hyprctl reload
    sleep 1

    ERRORS="$(hyprctl configerrors 2>/dev/null || true)"
    if [ -n "$ERRORS" ] && [ "$ERRORS" != "no errors" ]; then
        echo "=========================================================="
        echo "$T_RECARGA_ERROR"
        echo "$ERRORS"
        echo "=========================================================="
        exit 1
    fi
    echo "$T_RECARGA_EXITO"
else
    echo " $T_NO_SESION"
fi

echo "$T_CONFIGURACIONES_LISTAS"
