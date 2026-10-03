#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/u3_env.sh"


# ====================================================== #
# ==== CONFIGURACION DE CLAVE CON SUDOERS PARA SUDO ==== #
# ====================================================== #
# ESTO GUARDARA LA CLAVE QUE PUSISTE USANDO "SUDO"
# LO CUAL DEJARA LA CLAVE GUARDADA Y ACTIVA MIENTRAS LA SESION DE TERMINAL ESTE VIVA.
# Se ejecuta al PRINCIPIO para cubrir tambien la instalacion de paquetes (la parte mas larga).

# 1. Detectar el usuario real que ejecuta el script (incluso usando sudo)
LOGGED_IN_USER="${SUDO_USER:-$(whoami)}"

# 2. Verificar que no se esté ejecutando directamente como root real
if [ "$LOGGED_IN_USER" = "root" ]; then
    echo "$T_SUDO_NO_ROOT" >&2
    exit 1
fi

# 3. Definir la ruta del archivo temporal y el destino final
TMP_FILE="$(mktemp)"
DEST_FILE="/etc/sudoers.d/sudo_timeout_${LOGGED_IN_USER}"

# 4. Escribir la configuración usando el nombre de usuario detectado
echo "Defaults:${LOGGED_IN_USER} timestamp_timeout=-1" > "$TMP_FILE"

# 5. Validar la sintaxis con visudo antes de aplicar los cambios
if visudo -c -f "$TMP_FILE" > /dev/null 2>&1; then
    sudo mv "$TMP_FILE" "$DEST_FILE"
    sudo chmod 0440 "$DEST_FILE"
    sudo chown root:root "$DEST_FILE"
else
    rm -f "$TMP_FILE"
    echo "$T_SUDO_INVALIDO" >&2
    exit 1
fi
