#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Si el subscript se ejecuta solo (sin pasar por setup.sh), carga el idioma guardado
if [ -z "${TXT_WELCOME:-}" ]; then
    LANG_LOADER="$SRC_DIR/../../lang/load_lang.sh"
    if [ -f "$LANG_LOADER" ]; then
        source "$LANG_LOADER"
    else
        echo "Aviso: No se pudo encontrar el archivo de idioma en $LANG_LOADER"
    fi
fi

echo "==> Limpiando instalaciones anteriores de zsh (si existen)..."
# Borramos directorios y archivos previos para evitar conflictos de clonación o duplicados
rm -rf "$HOME/.local/share/zsh/plugins/zsh-autocomplete"
rm -f "$HOME/.aliaszsh"
rm -f "$HOME/.zshrc.d/plugins.zsh"

PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
ZSHRC_D="$HOME/.zshrc.d"
mkdir -p "$PLUGIN_DIR" "$ZSHRC_D"

echo "==> Instalando/Clonando zsh-autocomplete..."
git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git "$PLUGIN_DIR/zsh-autocomplete"

echo "==> Buscando rutas de paquetes del sistema..."
# Aseguramos que paru no rompa el script si busca archivos y no los halla de inmediato
AUTOSUGGESTIONS_FILE=$(paru -Ql zsh-autosuggestions 2>/dev/null | awk '/autosuggestions\.zsh$/ {print $2; exit}' || echo "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh")
SYNTAX_FILE=$(paru -Ql zsh-syntax-highlighting 2>/dev/null | awk '/zsh-syntax-highlighting\.zsh$/ {print $2; exit}' || echo "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh")

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
[[ -f "$AUTOSUGGESTIONS_FILE" ]] && source "$AUTOSUGGESTIONS_FILE"
[[ -f "$SYNTAX_FILE" ]] && source "$SYNTAX_FILE"
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

echo "==> Configuración de Zsh completada con éxito."
