#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANG_DIR="$(cd "$SCRIPT_DIR/../../lang" && pwd)"
MINIMALISTDOTS="$HOME/.local/bin/MinimalistDots"
SRC_HYPRLAND_SERVICES="$(cd "$SCRIPT_DIR/../../../src/.local/bin/MinimalistDots/services" && pwd)"

# CARGAR EL IDIOMA SI EL SCRIPT SE EJECUTA DIRECTAMENTE
if [ -z "${T_BIENVENIDO:-}" ]; then
    source "$LANG_DIR/load_lang.sh"
fi


# =============================================================================== #
# ==== INSTALANDO SERVICIOS DENTRO DE "~/.local/bin/MinimalistDots/services" ==== #
# =============================================================================== #
echo "$T_LISTANDO_SERVICIOS_ANTIGUOS"
ls "$MINIMALISTDOTS/services"
sleep 3

echo "$T_BORRANDO_SERVICIOS_ANTIGUOS"
rm -f $MINIMALISTDOTS/services/*.lua

echo "$T_COPIANDO_SERVICIOS_NUEVOS"
cp $SRC_HYPRLAND_SERVICES/*.lua $MINIMALISTDOTS/services


# =============================================================================== #
# ==== INSTALANDO SCRIPTS DENTRO DE "~/.local/bin/MinimalistDots/scripts" ==== #
# =============================================================================== #
echo "$T_LISTANDO_SCRIPTS_ANTIGUOS"
ls "$MINIMALISTDOTS/scripts"
sleep 3

echo "$T_BORRANDO_SCRIPTS_ANTIGUOS"
rm -f $MINIMALISTDOTS/scripts/*.sh

echo "$T_COPIANDO_SCRIPTS_NUEVOS"
cp $SRC_HYPRLAND_SERVICES/*.sh $MINIMALISTDOTS/scripts


# ==== ZSH INSTALACION ==== #
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

echo "$T_ZSH_INSTALADO"


# ==== Process_manager.sh ==== #
INSTALL_DIR="$HOME/.local/bin/MinimalistDots/scripts"
TARGET_FILE="$INSTALL_DIR/process_manager.sh"
mkdir -p "$INSTALL_DIR"

cat << 'EOF' > "$TARGET_FILE"
#!/usr/bin/env bash

ROFI_THEME="${XDG_RUNTIME_DIR:-/tmp}/rofi-process-manager.rasi"

cat << 'RFT' > "$ROFI_THEME"
configuration {
    show-icons: true;
    font: "JetBrainsMono Nerd Font 8";
    case-sensitive: false;
    matching: "fuzzy";
}

* {
    background-color: __C_BG__;
    text-color: __C_TEXT__;
    border-color: __C_ACCENT_BLUE__;
}

window {
    location: center;
    anchor: center;
    width: 600px;
    height: 480px;
    border: 2px;
    border-radius: 12px;
    padding: 16px;
    background-color: __C_BG__;
}

mainbox {
    children: [ inputbar, listview ];
    spacing: 12px;
}

inputbar {
    children: [ prompt, entry ];
    background-color: __C_SURFACE__;
    border-radius: 8px;
    padding: 8px 12px;
}

prompt {
    text-color: __C_ACCENT_BLUE__;
    margin: 0px 8px 0px 0px;
}

entry {
    placeholder: "Search";
    placeholder-color: __C_SUBTEXT__;
}

listview {
    lines: 10;
    columns: 1;
    cycle: true;
    scrollbar: false;
}

element {
    padding: 2px 3px;
    border-radius: 3px;
    background-color: transparent;
}

element selected {
    background-color: __C_ACCENT_RED__;
    text-color: __C_TEXT__;
}

element-text {
    text-color: inherit;
}
RFT

get_user_apps() {
    if command -v hyprctl &>/dev/null; then
        hyprctl clients -j | jq -r '.[] | "🗑️  \(.title) [Class: \(.class)] (PID: \(.pid))"' | sort -u
    else
        ps -u "$USER" -o pid,comm --no-headers | awk '{print "🗑️  " $2 " (PID: " $1 ")"}'
    fi
}

get_system_apps() {
    ps -u "$USER" -o pid,comm,%mem,%cpu --sort=-%mem | awk 'NR>1 {print "⚙️  " $2 " | RAM: " $3 "% | CPU: " $4 "% (PID: " $1 ")"}'
}

show_category_menu() {
    cat <<EOFM | rofi -dmenu -i -theme "$ROFI_THEME" -p "Gestor" -mesg "Selecciona una categoría:"
📱 Day-to-Day Applications (GUI)
⚙️ System Processes / Background
EOFM
}

category=$(show_category_menu)

case "$category" in
    *"Día a Día"*)
        selected=$(get_user_apps | rofi -dmenu -i -theme "$ROFI_THEME" -p "Cerrar App" -mesg "Selecciona una app para finalizarla:")
        ;;
    *"Sistema"*)
        selected=$(get_system_apps | rofi -dmenu -i -theme "$ROFI_THEME" -p "Matar Proceso" -mesg "Selecciona un proceso para matarlo:")
        ;;
    *)
        exit 0
        ;;
esac

if [[ -n "$selected" ]]; then
    pid=$(echo "$selected" | grep -oP '\(PID:\s*\K[0-9]+(?=\))')

    if [[ -n "$pid" ]]; then
        if kill -9 "$pid" 2>/dev/null; then
            notify-send -a "Process Manager" -i "dialog-information" "Process Finished" "Process closed with PID: $pid"
        else
            notify-send -a "Process Manager" -i "dialog-error" "Error" "The process could not be closed $pid"
        fi
    fi
fi
EOF

chmod +x "$TARGET_FILE"

# Inyectar la paleta real de colores en el script instalado
# (se mantiene el heredoc principal citado 'EOF' para no romper las
# variables de runtime como $pid o $selected).
sed -i \
    -e "s/__C_BG__/${C_BG}/g" \
    -e "s/__C_TEXT__/${C_TEXT}/g" \
    -e "s/__C_ACCENT_BLUE__/${C_ACCENT_BLUE}/g" \
    -e "s/__C_SURFACE__/${C_SURFACE}/g" \
    -e "s/__C_SUBTEXT__/${C_SUBTEXT}/g" \
    -e "s/__C_ACCENT_RED__/${C_ACCENT_RED}/g" \
    "$TARGET_FILE"

echo "$T_GESTOR_DE_PROCESOS_INSTALADOS $TARGET_FILE"


# ==== SDDM TEMA ==== #
FLAVOR="mocha"
ACCENT="blue"
THEME_NAME="catppuccin-${FLAVOR}-${ACCENT}"
ASSET_NAME="${THEME_NAME}-sddm.zip"

THEMES_DIR="/usr/share/sddm/themes"
CONF_DIR="/etc/sddm.conf.d"
CONF_FILE="$CONF_DIR/catppuccin.conf"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "$T_SDDM_TEMA_VERSION_RECIENTE"
RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/catppuccin/sddm/releases/latest)"
ASSET_URL="$(jq -r --arg name "$ASSET_NAME" '.assets[] | select(.name == $name) | .browser_download_url' <<< "$RELEASE_JSON")"

if [ -z "$ASSET_URL" ] || [ "$ASSET_URL" = "null" ]; then
    echo "Error: no se encontró el asset '$ASSET_NAME' en GitHub." >&2
    exit 1
fi

echo "$T_SDDM_DESCARGA_E_INSTALACION $THEME_NAME..."
curl -fsSL -o "$TMP_DIR/theme.zip" "$ASSET_URL"
unzip -oq "$TMP_DIR/theme.zip" -d "$TMP_DIR/extracted"

sudo mkdir -p "$THEMES_DIR" "$CONF_DIR"
sudo rm -rf "${THEMES_DIR:?}/${THEME_NAME}"
sudo cp -r "$TMP_DIR/extracted/$THEME_NAME" "$THEMES_DIR/"

sudo tee "$CONF_FILE" > /dev/null << EOF
[Theme]
Current=$THEME_NAME
EOF

sudo systemctl enable sddm
echo "$T_SDDM_TEMA_INSTALADO"
