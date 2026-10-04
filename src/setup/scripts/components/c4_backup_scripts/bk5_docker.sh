#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/u3_env.sh"


# ==== DOCKER SIN SUDO ==== #
# Requiere el paquete "docker" (ya está en PROGRAMMING_PKGS de c2_install_packages.sh).
# El acceso sin sudo se da con el grupo "docker": el socket /var/run/docker.sock
# pertenece a ese grupo, así que basta con agregar al usuario.
# Nota: estar en el grupo docker equivale a tener permisos de root en el equipo.

TARGET_USER="${SUDO_USER:-$(whoami)}"

# 1. Servicio activo ahora y en cada arranque
sudo systemctl enable --now docker.service

# 2. Grupo docker (normalmente ya lo crea el paquete) y usuario dentro de él
getent group docker > /dev/null || sudo groupadd docker
sudo usermod -aG docker "$TARGET_USER"

# 3. Verificación sin necesidad de reiniciar sesión
if sg docker -c "docker info" > /dev/null 2>&1; then
    echo "$T_DOCKER_FUNCIONA '$TARGET_USER'."
else
    echo "$T_DOCKER_SIN_RESPUESTA" >&2
fi

echo "$T_DOCKER_REINICIAR_SESION"
