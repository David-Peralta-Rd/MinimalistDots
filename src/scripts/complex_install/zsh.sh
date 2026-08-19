#!/usr/bin/env bash
set -euo pipefail

ARCHIVO_LANG="${1:-en.cfg}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LANG_DIR="$PROJECT_ROOT/src/lang"

[ -f "$LANG_DIR/$ARCHIVO_LANG" ] && source "$LANG_DIR/$ARCHIVO_LANG"

echo "==> Instalando componentes y complementos para Zsh..."
paru -S --needed --noconfirm git zsh-autosuggestions zsh-syntax-highlighting zsh-completions

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

# Código AI
alias autocomplete_on='sudo systemctl start ollama'
alias autocomplete_off='sudo systemctl stop ollama'
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
