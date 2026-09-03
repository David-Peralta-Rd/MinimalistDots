#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANG_DIR="$(cd "$SCRIPT_DIR/../../lang" && pwd)"
MINIMALISTDOTS="$(cd "$HOME/.local/bin/MinimalistDots" && pwd)"
SRC_HYPRLAND_SERVICES="$(cd "$SCRIPT_DIR/../../../src/.local/bin/MinimalistDots/services" && pwd)"
SRC_HYPRLAND_SCRIPTS="$(cd "$SCRIPT_DIR/../../../src/.local/bin/MinimalistDots/scripts" && pwd)"

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
cp $SRC_HYPRLAND_SCRIPTS/*.sh $MINIMALISTDOTS/scripts


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
# 2. Crear directorios
# ============================================================

mkdir -p "$PLUGIN_DIR"
mkdir -p "$ZSHRC_D"


# ============================================================
# 3. zsh-autocomplete
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
    | awk '/zsh-autocomplete\.plugin\.zsh$/ {print $2; exit}')

if [[ -z "$AUTOCOMPLETE_FILE" ]]; then
    echo
    echo "ERROR: No se encontró zsh-autocomplete."
    echo
    exit 1
fi

echo "    zsh-autocomplete:"
echo "    $AUTOCOMPLETE_FILE"


# ============================================================
# 4. Localizar autosuggestions
# ============================================================

AUTOSUGGESTIONS_FILE=$(pacman -Ql zsh-autosuggestions 2>/dev/null \
    | awk '/zsh-autosuggestions\.zsh$/ {print $2; exit}')

if [[ -z "$AUTOSUGGESTIONS_FILE" ]]; then
    echo
    echo "ERROR: No se encontró zsh-autosuggestions."
    echo
    exit 1
fi

echo "    zsh-autosuggestions:"
echo "    $AUTOSUGGESTIONS_FILE"


# ============================================================
# 5. Localizar syntax highlighting
# ============================================================

SYNTAX_FILE=$(pacman -Ql zsh-syntax-highlighting 2>/dev/null \
    | awk '/zsh-syntax-highlighting\.zsh$/ {print $2; exit}')

if [[ -z "$SYNTAX_FILE" ]]; then
    echo
    echo "ERROR: No se encontró zsh-syntax-highlighting."
    echo
    exit 1
fi

echo "    zsh-syntax-highlighting:"
echo "    $SYNTAX_FILE"


# ============================================================
# 6. Aliases
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

alias dk-up="docker compose up -d"
alias dk-dw="docker compose down"
alias dk-lg="docker logs -f"
alias dk-pl="docker pull"
alias dk-clean="docker system prune -f"

EOF


# ============================================================
# 7. Configuración de plugins
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
# 8. Configurar ~/.zshrc
# ============================================================

touch "$HOME/.zshrc"


# Eliminar líneas antiguas de nuestro instalador
sed -i \
    '\|\.zshrc\.d/plugins\.zsh|d' \
    "$HOME/.zshrc"


# Eliminar compinit añadido manualmente por este instalador,
# si existiera.

sed -i \
    '/^[[:space:]]*autoload -Uz compinit/d' \
    "$HOME/.zshrc"

sed -i \
    '/^[[:space:]]*compinit/d' \
    "$HOME/.zshrc"


# Añadir nuestra configuración

cat >> "$HOME/.zshrc" <<'EOF'


# ============================================================
# CONFIGURACIÓN PERSONAL DE ZSH
# ============================================================

[[ -f "$HOME/.zshrc.d/plugins.zsh" ]] && \
    source "$HOME/.zshrc.d/plugins.zsh"

EOF


# ============================================================
# 9. Comprobaciones
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
# 10. Final
# ============================================================

echo "============================================================"
echo "       $T_ZSH_INSTALADO"
echo "============================================================"


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
📱 Aplicaciones Día a Día (GUI)
⚙️ Procesos del Sistema / Fondo
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


# ==== WOFI INSTALACION ==== #
# Genera los dos menús "extra" de Wofi que NO tienen equivalente en un
# servicio Lua (a diferencia del wofi de aplicaciones, que ya regenera
# hyprland/services/wofi_theme.lua en cada arranque de Hyprland):
#   1. El selector del portapapeles (cliphist)
#   2. El visor de atajos de teclado (keybinds.json -> wofi)

WOFI_DIR="$HOME/.config/wofi"
WOFI_THEMES="$WOFI_DIR/themes"
WOFI_CONFIGS="$WOFI_DIR/configs"
BIN_DIR="$HOME/.local/bin/MinimalistDots/scripts"
mkdir -p "$WOFI_THEMES" "$WOFI_CONFIGS" "$BIN_DIR"

# Convertidor HEX -> CSS rgba(r, g, b, alpha)
hex_to_rgba() {
    local hex="${1#\#}"
    local alpha="$2"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "rgba($r, $g, $b, $alpha)"
}

BG_90_RGBA=$(hex_to_rgba "$C_BG" 0.90)
SURFACE_70_RGBA=$(hex_to_rgba "$C_SURFACE" 0.70)
SURFACE_90_RGBA=$(hex_to_rgba "$C_SURFACE" 0.90)

# ==========================================================
# 1. PORTAPAPELES (cliphist)
# ==========================================================
cat << EOF > "$WOFI_CONFIGS/config-clipboard"
# Configuración específica para Gestor de Portapapeles (cliphist)
show=dmenu
allow_images=false
width=700
height=420
lines=12
location=center
hide_scroll=true
matching=fuzzy
prompt=📋 Portapapeles
EOF

cat << EOF > "$WOFI_THEMES/style-clipboard.css"
/* Estilo dedicado para Portapapeles */
window {
    margin: 0px;
    background-color: ${BG_90_RGBA};
    border: 2px solid ${C_ACCENT_BLUE}; /* Acento azul para diferenciar del lanzador */
    border-radius: 10px;
    font-family: 'JetBrainsMono Nerd Font', 'monospace';
    font-size: 13px;
}
#input {
    margin: 10px 10px 4px 10px;
    border: 1px solid ${C_BORDER_INACTIVE};
    border-radius: 6px;
    background-color: ${SURFACE_70_RGBA};
    color: ${C_TEXT};
    padding: 6px 10px;
}
#inner-box { margin: 4px 10px 10px 10px; border: none; background-color: transparent; }
#entry { padding: 4px 6px; background-color: transparent; border-radius: 4px; border: none; }
#entry:selected { background-color: ${SURFACE_90_RGBA}; transition: background-color 0.1s ease-in-out; }
#text { color: ${C_TEXT}; background-color: transparent; }
#text:selected { color: ${C_ACCENT_BLUE}; font-weight: bold; }
#outer-box { margin: 0px; border: none; background-color: transparent; }
#scroll { margin: 0px; border: none; background-color: transparent; }
EOF

# ==========================================================
# 2. VISOR DE ATAJOS DE TECLADO (lee ~/.cache/hypr/keybinds.json,
#    escrito por hyprland/lib/keybinder.lua -> export_json())
# ==========================================================
cat << EOF > "$WOFI_CONFIGS/config-binds"
# Configuración específica para el menú de Atajos de Teclado
show=dmenu
allow_images=false
width=650
height=480
lines=14
location=center
hide_scroll=true
matching=fuzzy
prompt=⌨️  Atajos de Teclado
EOF

cat << EOF > "$WOFI_THEMES/style-binds.css"
/* Estilo dedicado para el visualizador de atajos de teclado */
window {
    margin: 0px;
    background-color: ${BG_90_RGBA};
    border: 2px solid ${C_ACCENT_GREEN};
    border-radius: 12px;
    font-family: 'JetBrainsMono Nerd Font', 'monospace';
    font-size: 13px;
}
#input {
    margin: 10px 10px 4px 10px;
    border: 1px solid ${C_BORDER_INACTIVE};
    border-radius: 6px;
    background-color: ${SURFACE_70_RGBA};
    color: ${C_TEXT};
    padding: 6px 10px;
}
#inner-box { margin: 4px 10px 10px 10px; border: none; background-color: transparent; }
#entry { padding: 4px 6px; background-color: transparent; border-radius: 4px; border: none; }
#entry:selected { background-color: ${SURFACE_90_RGBA}; transition: background-color 0.1s ease-in-out; }
#text { color: ${C_TEXT}; background-color: transparent; }
#text:selected { color: ${C_ACCENT_GREEN}; font-weight: bold; }
#outer-box { margin: 0px; border: none; background-color: transparent; }
#scroll { margin: 0px; border: none; background-color: transparent; }
EOF

# ==========================================================
# 3. OSD DE VOLUMEN (Wofi HUD)
# ==========================================================
cat << EOF > "$WOFI_CONFIGS/config-volume"
# Configuración específica para HUD de Volumen
show=dmenu
allow_images=false
width=320
height=60
lines=1
location=top
yoffset=30
hide_scroll=true
no_actions=true
prompt=🔊 Volumen
EOF

cat << EOF > "$WOFI_THEMES/style-volume.css"
/* Estilo dedicado para el OSD de Volumen */
window {
    margin: 0px;
    background-color: ${BG_90_RGBA};
    border: 2px solid ${C_ACCENT_PURPLE:-#c678dd};
    border-radius: 10px;
    font-family: 'JetBrainsMono Nerd Font', 'monospace';
    font-size: 14px;
}
#input {
    display: none; /* Oculta la barra de búsqueda para que parezca solo un HUD */
}
#inner-box { margin: 10px; border: none; background-color: transparent; }
#entry { padding: 4px; background-color: transparent; border: none; }
#text { color: ${C_TEXT}; background-color: transparent; font-weight: bold; }
#outer-box { margin: 0px; border: none; background-color: transparent; }
EOF

# El binario "show_binds" agrupa por categoría usando jq y lanza Wofi
# con el estilo generado arriba. Consume el JSON que exporta el
# Keybinder de Lua (categorías incluidas).
cat << 'EOF' > "$BIN_DIR/show_binds"
#!/usr/bin/env bash
set -euo pipefail

JSON_FILE="$HOME/.cache/hypr/keybinds.json"
WOFI_CONFIG="$HOME/.config/wofi/configs/config-binds"
WOFI_STYLE="$HOME/.config/wofi/themes/style-binds.css"

if ! command -v jq &>/dev/null; then
    notify-send -a "Atajos" -i "dialog-error" "Error" "jq no está instalado."
    exit 1
fi

if [[ ! -f "$JSON_FILE" ]]; then
    notify-send -a "Atajos" -i "dialog-warning" "Atajos no encontrados" "No se detectó $JSON_FILE"
    exit 1
fi

formatted_list=$(jq -r '
    group_by(.category) | .[] |
    "󰌌  [" + .[0].category + "]",
    (.[] | "   " + (if .mod == "" then "" else .mod + " + " end) + .key + "  󰁔  " + .description),
    ""
' "$JSON_FILE")

echo "$formatted_list" | wofi -c "$WOFI_CONFIG" -s "$WOFI_STYLE" --dmenu | true
EOF

chmod +x "$BIN_DIR/show_binds"


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
