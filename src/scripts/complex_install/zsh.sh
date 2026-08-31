#!/usr/bin/env bash
# =========================================================
# CachyOS / End4 - Zsh Plugins
# =========================================================
# Mantiene intacta la configuración de CachyOS.
# Instala plugins adicionales y aliases.
# =========================================================
#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


# Si el subscript se ejecuta solo (sin pasar por setup.sh), carga el idioma guardado
if [ -z "${TXT_WELCOME:-}" ]; then
    # Subimos un nivel con ".." para salir de "scripts/" y entrar a "src/"
    LANG_LOADER="$SRC_DIR/../../lang/load_lang.sh"
    if [ -f "$LANG_LOADER" ]; then
        source "$LANG_LOADER"
    else
        echo "Aviso: No se pudo encontrar el archivo de idioma en $LANG_LOADER"
    fi
fi


PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
ZSHRC_D="$HOME/.zshrc.d"
mkdir -p "$PLUGIN_DIR"
mkdir -p "$ZSHRC_D"

echo "==> Instalando zsh-autocomplete"
if [ ! -d "$PLUGIN_DIR/zsh-autocomplete" ]; then
    git clone --depth=1 \
        https://github.com/marlonrichert/zsh-autocomplete.git \
        "$PLUGIN_DIR/zsh-autocomplete"
fi

echo "==> Detectando plugins instalados"
AUTOSUGGESTIONS_FILE=$(paru -Ql zsh-autosuggestions | awk '/autosuggestions\.zsh$/ {print $2; exit}')
SYNTAX_FILE=$(paru -Ql zsh-syntax-highlighting | awk '/zsh-syntax-highlighting\.zsh$/ {print $2; exit}')

if [ -z "${AUTOSUGGESTIONS_FILE:-}" ]; then
    echo "Error: zsh-autosuggestions no encontrado"
    exit 1
fi
if [ -z "${SYNTAX_FILE:-}" ]; then
    echo "Error: zsh-syntax-highlighting no encontrado"
    exit 1
fi

echo "==> Creando aliases"
cat > "$HOME/.aliaszsh" << 'EOF'
# Sistema
alias t="touch"
alias mk="mkdir -p"
alias in="paru -S --needed --noconfirm"
alias un="paru -Rns --noconfirm"
alias up="paru -Syu --noconfirm"
alias po='sudo pacman -Rns $(pacman -Qdtq)'
# Git
alias gs="git status"
alias ga="git add"
alias gm="git commit -m"
alias gpl="git pull"
alias gps="git push"
# Docker
alias dk-up="docker compose up -d"
alias dk-dw="docker compose down"
alias dk-lg="docker logs -f"
alias dk-pl="docker pull"
alias dk-clean="docker system prune -f"
# Codigo
alias autocomplete_on='sudo systemctl start ollama'
alias autocomplete_off='sudo systemctl stop ollama'
EOF

echo "==> Creando ~/.zshrc.d/plugins.zsh"
cat > "$ZSHRC_D/plugins.zsh" << EOF
# Plugins
source "$AUTOSUGGESTIONS_FILE"
source "$SYNTAX_FILE"
fpath+=(/usr/share/zsh/site-functions)
if [[ -f "$PLUGIN_DIR/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ]]; then
    source "$PLUGIN_DIR/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
fi
# Aliases
[[ -f ~/.aliaszsh ]] && source ~/.aliaszsh
EOF

echo "==> Registrando plugins.zsh"
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "source ~/.zshrc.d/plugins.zsh" "$HOME/.zshrc"; then
        cat >> "$HOME/.zshrc" << 'EOF'
# Dotfiles
[[ -f ~/.zshrc.d/plugins.zsh ]] && source ~/.zshrc.d/plugins.zsh
EOF
    fi
else
    cat > "$HOME/.zshrc" << 'EOF'
# Dotfiles
[[ -f ~/.zshrc.d/plugins.zsh ]] && source ~/.zshrc.d/plugins.zsh
EOF
fi

echo
echo "========================================"
echo "Instalación completada"
echo "========================================"
echo
echo "Plugins: ~/.zshrc.d/plugins.zsh"
echo "Aliases: ~/.aliaszsh"
echo
echo "Recarga con:"
echo "source ~/.zshrc"
