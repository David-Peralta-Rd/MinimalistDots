#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# RUTAS (MD_*), IDIOMA (T_*) Y PALETA (C_*)
source "$SCRIPT_DIR/utils/u3_env.sh"

# UTILIDAD DE TITULO
source "$MD_UTILS_DIR/u1_title.sh"


# ======================================= #
# ==== EMPEZAMOS A EJECUTAR LOS PASOS ==== #
# ======================================= #
print_title "$T_BIENVENIDO"

# PASO 0 -- SESION DE SUDO (antes de lo largo, para no pedir la clave a mitad de la instalacion)
print_title "$T_CONFIGURANDO_SUDO"
bash "$MD_COMPONENTS_DIR/c0_sudo_session.sh"

# PRIMER PASO -- CREACIONES DE CARPETAS
print_title "$T_NUEVAS_CARPETAS"
bash "$MD_COMPONENTS_DIR/c1_new_folders.sh"

# SEGUNDO PASO -- INSTALACION DE PAQUETES
print_title "$T_INSTALANDO_PAQUETES"
bash "$MD_COMPONENTS_DIR/c2_install_packages.sh"

# TERCER PASO -- BACKUP DE LAS CONFIGURACIONES DENTRO DE "~/.config"
# c3 devuelve 10 cuando el usuario cancela: en ese caso no se sigue con nada mas.
print_title "$T_COMENZANDO_BACKUP_Y_INSTALACION"
C3_STATUS=0
bash "$MD_COMPONENTS_DIR/c3_backup_and_install.sh" || C3_STATUS=$?
if [ "$C3_STATUS" -eq 10 ]; then
    exit 0
elif [ "$C3_STATUS" -ne 0 ]; then
    exit "$C3_STATUS"
fi

# CUARTO PASO -- INSTALACION DE SERVICIOS Y SCRIPTS
# Si un sub-paso falla (p. ej. sin internet para el tema de SDDM) igual se
# recarga Hyprland y se informa al final.
print_title "$T_INSTALANDO_SERVICIOS_Y_SCRIPTS"
C4_STATUS=0
bash "$MD_COMPONENTS_DIR/c4_install_services_and_scripts.sh" || C4_STATUS=$?


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

# OPCIONAL: si la sesion de sudo sin caducidad solo la quieres durante la
# instalacion, descomenta esta linea para borrarla al terminar:
# sudo rm -f "/etc/sudoers.d/sudo_timeout_${SUDO_USER:-$(whoami)}"

if [ "$C4_STATUS" -ne 0 ]; then
    echo "$T_INSTALACION_CON_ERRORES"
    exit "$C4_STATUS"
fi

echo "$T_CONFIGURACIONES_LISTAS"
