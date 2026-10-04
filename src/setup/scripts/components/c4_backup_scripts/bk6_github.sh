#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/u3_env.sh"


# ==== GIT + GITHUB (login por navegador + firma GPG) ==== #
# Requiere: git, github-cli (gh) y gnupg.
# Flujo:
#   1. Pregunta nombre y correo y los guarda en git.
#   2. `gh auth login --web`: abre el navegador y muestra un código de un solo uso.
#   3. Configura git para usar esa sesión (credential helper), sin tokens a mano.
#   4. Crea (o reutiliza) una clave GPG, la sube a GitHub y activa la firma de commits.
# Es idempotente: se puede ejecutar varias veces.

# Navegador que usará gh para el login (se instala con brave-bin en c2).
# Si el comando no existe en el sistema, gh usa el predeterminado (xdg-open).
GH_BROWSER_CMD="brave"

# Sin terminal interactiva no se puede preguntar nada: se omite
if [ ! -t 0 ]; then
    echo "$T_GH_SIN_TERMINAL"
    exit 0
fi

read -rp "$T_GH_PREGUNTA ($T_LETRA_DE_CONFIRMACION/n): " answer
answer="${answer:-$T_LETRA_DE_CONFIRMACION}"   # Enter = confirmar
if [ "${answer,,}" != "${T_LETRA_DE_CONFIRMACION,,}" ]; then
    echo "$T_GH_OMITIDO bash $0"
    exit 0
fi

# ---------- 1. Datos ----------
current_name="$(git config --global user.name || true)"
current_email="$(git config --global user.email || true)"

read -rp "$T_GH_PEDIR_NOMBRE [$current_name]: " GIT_NAME
GIT_NAME="${GIT_NAME:-$current_name}"

# Debe ser un correo verificado en tu cuenta de GitHub (o tu correo noreply)
# para que los commits aparezcan como "Verified".
read -rp "$T_GH_PEDIR_CORREO [$current_email]: " GIT_EMAIL
GIT_EMAIL="${GIT_EMAIL:-$current_email}"

if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
    echo "$T_GH_DATOS_OBLIGATORIOS" >&2
    exit 1
fi

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main

# ---------- 2. Login en GitHub (navegador + código de un solo uso) ----------
GH_SCOPES="admin:public_key,write:gpg_key"

if command -v "$GH_BROWSER_CMD" &> /dev/null; then
    gh config set browser "$GH_BROWSER_CMD"
fi

if gh auth status --hostname github.com &> /dev/null; then
    echo "$T_GH_SESION_ACTIVA"
    # Si la sesión existente no tiene permiso para subir claves GPG, se amplía
    if ! gh auth status --hostname github.com 2>&1 | grep -q "gpg_key"; then
        gh auth refresh --hostname github.com --scopes "$GH_SCOPES"
    fi
else
    echo "$T_GH_ABRIENDO_NAVEGADOR"
    gh auth login --hostname github.com --git-protocol https --web --scopes "$GH_SCOPES"
fi

# ---------- 3. Vincular git con la sesión de gh ----------
gh auth setup-git --hostname github.com

# ---------- 4. GPG: clave, subida a GitHub y firma de commits ----------
export GPG_TTY="$(tty)"

find_key_id() {
    gpg --list-secret-keys --with-colons "$GIT_EMAIL" 2> /dev/null \
        | awk -F: '$1 == "sec" && !f {print $5; f=1}' || true
}

KEY_ID="$(find_key_id)"

if [ -z "$KEY_ID" ]; then
    echo "$T_GH_GENERANDO_GPG"
    gpg --quick-generate-key "$GIT_NAME <$GIT_EMAIL>" ed25519 sign 2y
    KEY_ID="$(find_key_id)"
fi

if [ -z "$KEY_ID" ]; then
    echo "$T_GH_GPG_ERROR" >&2
    exit 1
fi

# Subir la clave pública a GitHub (si ya estaba subida, no es un error grave)
if ! gpg --armor --export "$KEY_ID" | gh gpg-key add - --title "$(hostname) $(date +%F)"; then
    echo "$T_GH_GPG_SUBIDA_ERROR" >&2
fi

git config --global user.signingkey "$KEY_ID"
git config --global commit.gpgsign true
git config --global tag.gpgSign true

echo "$T_GH_LISTO '$GIT_NAME <$GIT_EMAIL>' (GPG $KEY_ID)."
