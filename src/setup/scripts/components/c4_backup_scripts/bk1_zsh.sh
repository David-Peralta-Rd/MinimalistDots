#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/u3_env.sh"

# ==== ZSH INSTALACION ==== #
# ============================================================
# ZSH - CachyOS / Arch Linux
#
# Incluye:
#   - zsh-autocomplete
#   - zsh-autosuggestions
#   - zsh-syntax-highlighting
#   - zsh-completions
#
# Autosuggestions:
#   - history
#   - completion
#
# ============================================================

# ============================================================
# Variables
# ============================================================

PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
ZSHRC_D="$HOME/.zshrc.d"


# ============================================================
# 1. Crear directorios
# ============================================================

mkdir -p "$PLUGIN_DIR"
mkdir -p "$ZSHRC_D"


# ============================================================
# 2. zsh-autocomplete
# ============================================================

# Si ya existe una instalación manual antigua,
# la eliminamos para evitar conflictos.

if [[ -d "$PLUGIN_DIR/zsh-autocomplete" ]]; then
    rm -rf "$PLUGIN_DIR/zsh-autocomplete"
fi

# IMPORTANTE:
# Usamos el paquete oficial de Arch/CachyOS en lugar de
# clonar directamente main desde GitHub.
#
# Esto evita que una actualización inesperada del repositorio
# rompa la configuración.

AUTOCOMPLETE_FILE=""

# Buscar automáticamente dónde instaló el paquete
AUTOCOMPLETE_FILE=$(pacman -Ql zsh-autocomplete 2>/dev/null \
    | awk '$2 ~ /zsh-autocomplete\.plugin\.zsh$/ && !f {print $2; f=1}' || true)

if [[ -z "$AUTOCOMPLETE_FILE" ]]; then
    echo
    echo "ERROR: No se encontró zsh-autocomplete."
    echo
    exit 1
fi

echo "    zsh-autocomplete:"
echo "    $AUTOCOMPLETE_FILE"


# ============================================================
# 3. Localizar autosuggestions
# ============================================================

AUTOSUGGESTIONS_FILE=$(pacman -Ql zsh-autosuggestions 2>/dev/null \
    | awk '$2 ~ /zsh-autosuggestions\.zsh$/ && !f {print $2; f=1}' || true)

if [[ -z "$AUTOSUGGESTIONS_FILE" ]]; then
    echo
    echo "ERROR: No se encontró zsh-autosuggestions."
    echo
    exit 1
fi

echo "    zsh-autosuggestions:"
echo "    $AUTOSUGGESTIONS_FILE"


# ============================================================
# 4. Localizar syntax highlighting
# ============================================================

SYNTAX_FILE=$(pacman -Ql zsh-syntax-highlighting 2>/dev/null \
    | awk '$2 ~ /zsh-syntax-highlighting\.zsh$/ && !f {print $2; f=1}' || true)

if [[ -z "$SYNTAX_FILE" ]]; then
    echo
    echo "ERROR: No se encontró zsh-syntax-highlighting."
    echo
    exit 1
fi

echo "    zsh-syntax-highlighting:"
echo "    $SYNTAX_FILE"


# ============================================================
# 5. Aliases
# ============================================================

cat > "$HOME/.aliaszsh" <<'EOF'

# ============================================================
# SISTEMA
# ============================================================

alias t="touch"
alias mk="mkdir -p"


# ============================================================
# PACMAN / PARU
# ============================================================

# Instalar
alias in="paru -S --needed --noconfirm"

# Desinstalar
alias un="paru -Rns --noconfirm"

# Actualizar sistema
alias up="paru -Syu --noconfirm"

# Eliminar paquetes huérfanos
alias po='sudo pacman -Rns $(pacman -Qdtq)'


# ============================================================
# GIT
# ============================================================

alias gs="git status"
alias ga="git add"
alias gm="git commit -m"
alias gpl="git pull"
alias gps="git push"


# ============================================================
# DOCKER
# ============================================================

alias dk="docker"
alias dk-up="docker compose up -d"
alias dk-dev="docker compose -f docker-compose.dev.yml up -d"
alias dk-dev-dw="docker compose -f docker-compose.dev.yml down"
alias dk-dw="docker compose down"
alias dk-lg="docker logs -f"
alias dk-pl="docker pull"
alias dk-clean="docker system prune -a -f"
alias dk-run="docker compose run --entrypoint bash"

EOF


# ============================================================
# 6. Configuración de plugins
# ============================================================

cat > "$ZSHRC_D/plugins.zsh" <<EOF

# ============================================================
# ZSH PLUGINS
# ============================================================


# ------------------------------------------------------------
# Variables
# ------------------------------------------------------------

PLUGIN_DIR="\$HOME/.local/share/zsh/plugins"


# ------------------------------------------------------------
# zsh-autocomplete
#
# IMPORTANTE:
# Debe cargarse temprano.
#
# NO ejecutar compinit manualmente.
# ------------------------------------------------------------

if [[ -f "$AUTOCOMPLETE_FILE" ]]; then
    source "$AUTOCOMPLETE_FILE"
fi


# ------------------------------------------------------------
# zsh-completions
#
# Proporciona completions adicionales para comandos.
# ------------------------------------------------------------

fpath+=(/usr/share/zsh/site-functions)


# ------------------------------------------------------------
# zsh-autosuggestions
#
# HISTORY:
#   Busca comandos utilizados anteriormente.
#
# COMPLETION:
#   Busca sugerencias utilizando el sistema de completion
#   de Zsh.
#
# Esto permite sugerencias en tiempo real incluso para
# comandos/opciones que no estén en el historial.
# ------------------------------------------------------------

ZSH_AUTOSUGGEST_STRATEGY=(history completion)

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

if [[ -f "$AUTOSUGGESTIONS_FILE" ]]; then
    source "$AUTOSUGGESTIONS_FILE"
fi


# ------------------------------------------------------------
# zsh-syntax-highlighting
#
# IMPORTANTE:
# Debe cargarse al final.
# ------------------------------------------------------------

if [[ -f "$SYNTAX_FILE" ]]; then
    source "$SYNTAX_FILE"
fi


# ------------------------------------------------------------
# Aliases
# ------------------------------------------------------------

[[ -f "\$HOME/.aliaszsh" ]] && source "\$HOME/.aliaszsh"

EOF


# ============================================================
# 7. Configurar ~/.zshrc
# ============================================================

touch "$HOME/.zshrc"


# Eliminar el bloque de una instalación anterior (con marcadores)
sed -i '/^# >>> MinimalistDots zsh >>>$/,/^# <<< MinimalistDots zsh <<<$/d' \
    "$HOME/.zshrc"

# Eliminar líneas de versiones antiguas del instalador (sin marcadores)
sed -i \
    -e '\|\.zshrc\.d/plugins\.zsh|d' \
    -e '/^# CONFIGURACIÓN PERSONAL DE ZSH$/d' \
    "$HOME/.zshrc"


# Eliminar compinit añadido manualmente por este instalador,
# si existiera.

sed -i \
    '/^[[:space:]]*autoload -Uz compinit/d' \
    "$HOME/.zshrc"

sed -i \
    '/^[[:space:]]*compinit/d' \
    "$HOME/.zshrc"


# Añadir nuestra configuración (bloque delimitado: se reemplaza en cada instalación)

cat >> "$HOME/.zshrc" <<'EOF'

# >>> MinimalistDots zsh >>>
[[ -f "$HOME/.zshrc.d/plugins.zsh" ]] && \
    source "$HOME/.zshrc.d/plugins.zsh"
# <<< MinimalistDots zsh <<<
EOF


# ============================================================
# 8. Comprobaciones
# ============================================================

echo "Zsh:"
zsh --version

echo
echo "zsh-autocomplete:"
if [[ -f "$AUTOCOMPLETE_FILE" ]]; then
    echo "  OK"
else
    echo "  ERROR"
fi

echo
echo "zsh-autosuggestions:"
if [[ -f "$AUTOSUGGESTIONS_FILE" ]]; then
    echo "  OK"
else
    echo "  ERROR"
fi

echo
echo "zsh-syntax-highlighting:"
if [[ -f "$SYNTAX_FILE" ]]; then
    echo "  OK"
else
    echo "  ERROR"
fi

echo
echo "zsh-completions:"
if [[ -d "/usr/share/zsh/site-functions" ]]; then
    echo "  OK"
else
    echo "  ERROR"
fi


# ============================================================
# 9. Final
# ============================================================

echo "============================================================"
echo "       $T_ZSH_INSTALADO"
echo "============================================================"
