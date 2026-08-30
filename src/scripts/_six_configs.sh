#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Si el subscript se ejecuta solo (sin pasar por setup.sh), carga el idioma guardado
if [ -z "${TXT_WELCOME:-}" ]; then
    source "$SRC_DIR/load_lang.sh"
fi


# CONFIGURAMOS DOCKER
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker

sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
