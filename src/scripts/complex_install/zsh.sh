#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Si el subscript se ejecuta solo (sin pasar por setup.sh), carga el idioma guardado
if [ -z "${TXT_WELCOME:-}" ]; then
    source "$SRC_DIR/load_lang.sh"
fi


PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
ZSHRC_D="$HOME/.zshrc.d"
mkdir -p "$PLUGIN_DIR" "$ZSHRC_D"

if [ ! -d "$PLUGIN_DIR/zsh-autocomplete" ]; then
    git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git "$PLUGIN_DIR/zsh-autocomplete"
fi

AUTOSUGGESTIONS_FILE=$(paru -Ql zsh-autosuggestions | awk '/autosuggestions\.zsh$/ {print $2; exit}')
SYNTAX_FILE=$(paru -Ql zsh-syntax-highlighting | awk '/zsh-syntax-highlighting\.zsh$/ {print $2; exit}')

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
EOF

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

if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "source ~/.zshrc.d/plugins.zsh" "$HOME/.zshrc"; then
        echo "[[ -f ~/.zshrc.d/plugins.zsh ]] && source ~/.zshrc.d/plugins.zsh" >> "$HOME/.zshrc"
    fi
else
    echo "[[ -f ~/.zshrc.d/plugins.zsh ]] && source ~/.zshrc.d/plugins.zsh" > "$HOME/.zshrc"
fi

echo "==> Configuración de Zsh completada."
