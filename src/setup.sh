#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$SRC_DIR/scripts"

# Carga la configuración de idioma
source "$SRC_DIR/lang/load_lang.sh"

clear
echo "=========================================================="
echo "${TXT_WELCOME:-Welcome / Bienvenido}"
echo "=========================================================="
echo ""

# ======================================= #
# ==== INSTALACION DE MINIMALISTDOTS ==== #
# ======================================= #

# CREAMOS LAS CARPETAS QUE SE USARAN DURANTE LA INSTALACION
bash "$SCRIPT_DIR/_one_dirs.sh"

# DESISTALAMOS PAQUETES QUE NO VAMOS A USAR, ACTUALIZACIOMOS E INSTALAMOS LOS PAQUETES QUE USARA EL MINIMALISTDOTS
bash "$SCRIPT_DIR/_two_install_packages.sh"

# CREAMOS EL BACKUP Y INSTALAMOS LOS DOTFILES.
bash "$SCRIPT_DIR/_three_backud_install.sh"

# INSTALAMOS SERVICIOS
bash "$SCRIPT_DIR/_four_hyprland.sh"

# INSTALAMOS SCRIPTS DE USO DIARIO
bash "$SCRIPT_DIR/_five_install_scripts.sh"

# CONFIGURAMOS LOS PROGRAMAS
bash "$SCRIPT_DIR/_six_configs.sh"
