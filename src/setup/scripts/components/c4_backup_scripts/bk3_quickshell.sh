#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../../utils/u3_env.sh"

# ==== QUICKSHELL INSTALACION ==== #
# Reemplaza por completo a wofi y eww. Todo vive en $MD_QUICKSHELL:
#
#   Archivos QML reales (en el proyecto: hyprland-dots/local/bin/MinimalistDots/quickshell/)
#     MdMenu.qml       menú genérico (dmenu con búsqueda fuzzy, o lanzador de apps)
#                      + borrado opcional: botón 🗑 por fila, Shift+Delete / Ctrl+D,
#                        "Borrar todo" y Ctrl+Shift+Delete (si el menú define deleteCmd / wipeCmd)
#     launcher.qml     lanzador de aplicaciones (SUPER+A)
#     osd-volume.qml   OSD de volumen
#     clock.qml        reloj de escritorio
#     pomodoro.qml     widget + temporizador del Pomodoro
#     notifd.qml       servidor de notificaciones + historial (reemplaza a SwayNC)
#
#   Generados aquí (dependen de la paleta de u2_palette.sh)
#     Theme.qml        colores
#     menu-<nombre>.qml  una instancia de MdMenu por menú (tamaño, acento, prompt, extras)
#                      OJO: se generan aquí, así que cualquier menu-*.qml que esté en la
#                      carpeta del proyecto se sobrescribe. Los cambios van en este script.
#
# Y en $MD_SCRIPTS_DIR los wrappers:
#   md_menu <nombre> [--prompt X] [--raw]   equivale a  wofi --dmenu  (lista por stdin)
#   md_menu --close                         cierra cualquier menú abierto (para los toggles)
#   md_launcher                             abre / cierra el lanzador de apps
#   md_volume_osd "<texto>"                 muestra el OSD de volumen
#   show_binds                              visor de atajos
#   md_cliphist_list                        historial de cliphist con miniaturas de imágenes
#
# Formato de las líneas que recibe md_menu:
#   "etiqueta"                 línea normal
#   "etiqueta<TAB>/ruta/img"   línea con miniatura (solo se imprime la etiqueta)
#   con --raw la línea entera es la etiqueta (cliphist)
#
# Menú clipboard (cliphist):
#   deleteCmd = "cliphist delete"   recibe por stdin la línea completa de la entrada
#   wipeCmd   = borra la carpeta de caché de cliphist; la db se recrea sola en la
#               próxima copia (cliphist store la crea si no existe)
#
# Requiere: quickshell (comando `qs`) y jq.

MD_QS_DIR="$MD_QUICKSHELL"
QML_SRC="$MD_DOTS_BIN/quickshell"

mkdir -p "$MD_QS_DIR" "$MD_SCRIPTS_DIR"

# Carpeta de versiones anteriores de este instalador
rm -rf "$MD_QS_DIR/menus"

# ---------- QML del proyecto ----------
shopt -s nullglob
qml_files=("$QML_SRC"/*.qml)
shopt -u nullglob
if [ ${#qml_files[@]} -eq 0 ]; then
    echo "$T_CONFIGURACION_NO_ENCONTRADA $QML_SRC" >&2
    exit 1
fi
cp -f "${qml_files[@]}" "$MD_QS_DIR/"

# ---------- utilidades de color ----------
hex_norm() { echo "#${1#\#}"; }

# "#aarrggbb" (en QML el alfa va primero)
hex_to_argb() {
    local hex="${1#\#}" alpha="$2" a
    a="$(awk -v a="$alpha" 'BEGIN{printf "%02x", a*255+0.5}')"
    echo "#${a}${hex}"
}

# ==========================================================
# Theme.qml (colores generados desde las variables C_* de u2_palette.sh)
# ==========================================================
cat > "$MD_QS_DIR/Theme.qml" <<EOT
import QtQuick

QtObject {
    readonly property color bg: "$(hex_norm "$C_BG")"
    readonly property color bg90: "$(hex_to_argb "$C_BG" 0.90)"
    readonly property color bg92: "$(hex_to_argb "$C_BG" 0.92)"
    readonly property color surface: "$(hex_norm "$C_SURFACE")"
    readonly property color surface70: "$(hex_to_argb "$C_SURFACE" 0.70)"
    readonly property color surface90: "$(hex_to_argb "$C_SURFACE" 0.90)"
    readonly property color selection: "$(hex_norm "$C_SELECTION")"
    readonly property color borderInactive: "$(hex_norm "$C_BORDER_INACTIVE")"
    readonly property color borderActive: "$(hex_norm "$C_BORDER_ACTIVE")"
    readonly property color text: "$(hex_norm "$C_TEXT")"
    readonly property color subtext: "$(hex_norm "$C_SUBTEXT")"
    readonly property color gray: "$(hex_norm "$C_GRAY")"
    readonly property color accentBlue: "$(hex_norm "$C_ACCENT_BLUE")"
    readonly property color accentGreen: "$(hex_norm "$C_ACCENT_GREEN")"
    readonly property color accentRed: "$(hex_norm "$C_ACCENT_RED")"
    readonly property color accentYellow: "$(hex_norm "$C_ACCENT_YELLOW")"
    readonly property color accentMagenta: "$(hex_norm "$C_ACCENT_MAGENTA")"
    readonly property color accentCyan: "$(hex_norm "$C_ACCENT_CYAN")"
    readonly property string font: "JetBrainsMono Nerd Font"
}
EOT

# ==========================================================
# Instancias de MdMenu: una por menú
# write_menu_qml <nombre> <prompt> <ancho> <alto> <color-acento> <radio-borde> [líneas-QML-extra]
#
# Las líneas extra se pasan en una variable con comillas simples para que bash
# no expanda nada ($HOME, ${XDG_CACHE_HOME}, etc.): el shell las evalúa al
# ejecutarse el comando, no al instalar.
# ==========================================================
write_menu_qml() {
    local name="$1" prompt="$2" width="$3" height="$4" accent="$5" radius="$6" extra="${7:-}"
    cat > "$MD_QS_DIR/menu-$name.qml" <<EOT
import QtQuick

// Menú "$name" (instancia de MdMenu.qml)
MdMenu {
    prompt: "$prompt"
    menuWidth: $width
    menuHeight: $height
    menuRadius: $radius
    accent: "$(hex_norm "$accent")"
$extra
}
EOT
}

# Extras del menú clipboard: borrado individual y borrado total
clipboard_extra=''
read -r -d '' clipboard_extra <<'EOX' || true

    // Borrado desde el propio menú
    deleteCmd: "cliphist delete"
    wipeCmd: 'rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/cliphist"'
EOX

write_menu_qml "clipboard"  "📋 Portapapeles"      700 420 "$C_ACCENT_BLUE"    10 "$clipboard_extra"   # cliphist
write_menu_qml "binds"      "⌨️  Atajos de Teclado" 650 480 "$C_ACCENT_GREEN"   12   # keybinds.json
write_menu_qml "pomodoro"   "🍅 Pomodoro"          300 340 "$C_ACCENT_RED"     10   # el script pone el título
write_menu_qml "llm"        "🤖 IA local"          780 420 "$C_ACCENT_MAGENTA" 10   # nombres de modelo largos
write_menu_qml "wallpaper"  "🖼  Fondo de pantalla" 560 520 "$C_ACCENT_BLUE"    12   # con miniaturas
write_menu_qml "notifications" "🔔 Notificaciones" 760 520 "$C_ACCENT_YELLOW" 12   # historial (notifications_menu.sh)
write_menu_qml "process"    "⚙️  Gestor"            640 480 "$C_ACCENT_RED"     12   # process_manager.sh

# ==========================================================
# WRAPPERS EJECUTABLES
# ==========================================================

# --- md_menu: reemplazo directo de `wofi --dmenu` ---
cat > "$MD_SCRIPTS_DIR/md_menu" <<'EOT'
#!/usr/bin/env bash
# Uso:  <lista por stdin> | md_menu <nombre> [--prompt "Texto"] [--raw]
#       md_menu --close            cierra cualquier menú abierto
# Imprime la línea elegida. Código de salida 1 si se cancela (Esc).
set -euo pipefail

QS_DIR="__MD_QS_DIR__"

if [[ "${1:-}" == "--close" ]]; then
    pkill -f "qs .*$QS_DIR/menu-" 2>/dev/null || true
    exit 0
fi

name="${1:?uso: md_menu <nombre> [--prompt texto] [--raw]}"
shift
prompt=""
raw=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--prompt) prompt="${2:-}"; shift 2 ;;
        --raw) raw=1; shift ;;
        *) shift ;;
    esac
done

if ! command -v qs &>/dev/null; then
    notify-send -a "Menú" -i "dialog-error" "Error" "quickshell (qs) no está instalado." 2>/dev/null || true
    exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/items"

MD_MENU_ITEMS="$tmp/items" MD_MENU_OUT="$tmp/out" MD_MENU_PROMPT="$prompt" MD_MENU_RAW="$raw" \
    qs -p "$QS_DIR/menu-$name.qml" >/dev/null 2>&1 || true

[[ -s "$tmp/out" ]] || exit 1
cat "$tmp/out"
echo
EOT

# --- md_launcher: lanzador de apps (toggle: si ya está abierto lo cierra) ---
cat > "$MD_SCRIPTS_DIR/md_launcher" <<'EOT'
#!/usr/bin/env bash
QS_DIR="__MD_QS_DIR__"

if pkill -f "qs .*$QS_DIR/launcher.qml" 2>/dev/null; then
    exit 0
fi
if ! command -v qs &>/dev/null; then
    notify-send -a "Lanzador" -i "dialog-error" "Error" "quickshell (qs) no está instalado." 2>/dev/null || true
    exit 1
fi
exec setsid -f qs -p "$QS_DIR/launcher.qml" >/dev/null 2>&1
EOT

# --- md_volume_osd "<texto>": lanzar tras cambiar el volumen ---
cat > "$MD_SCRIPTS_DIR/md_volume_osd" <<'EOT'
#!/usr/bin/env bash
# Muestra el OSD con el texto dado; si ya hay uno abierto lo reemplaza.
QS_DIR="__MD_QS_DIR__"
pkill -f "$QS_DIR/osd-volume.qml" 2>/dev/null || true
MD_OSD_TEXT="${1:-}" setsid -f qs -p "$QS_DIR/osd-volume.qml" >/dev/null 2>&1
EOT

# --- show_binds: agrupa por categoría con jq y abre el menú ---
cat > "$MD_SCRIPTS_DIR/show_binds" <<'EOT'
#!/usr/bin/env bash
set -euo pipefail

JSON_FILE="$HOME/.cache/hypr/keybinds.json"
MENU="$(dirname "$(readlink -f "$0")")/md_menu"

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

echo "$formatted_list" | "$MENU" binds >/dev/null || true
EOT

# --- md_cliphist_list: historial de cliphist con miniaturas para md_menu --raw ---
# Las líneas de imagen salen como "línea<US>/ruta/miniatura" (US = \x1f); el resto, tal cual.
# Las miniaturas (160px) se generan una sola vez por id y viven en
# <cache de cliphist>/thumbs, así que "Borrar todo" también las elimina.
# Solo las MD_CLIP_THUMBS imágenes más recientes (30 por defecto) tienen miniatura.
# Usa magick/convert (ImageMagick) o ffmpeg; si no hay ninguno, lista sin miniaturas.
cat > "$MD_SCRIPTS_DIR/md_cliphist_list" <<'EOT'
#!/usr/bin/env bash
set -uo pipefail

MAX="${MD_CLIP_THUMBS:-30}"
DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbs"
SEP=$'\x1f'
re=$'^([0-9]+)\t\\[\\[ binary data .* (png|jpe?g|bmp|gif|webp|tiff?) [0-9]+x[0-9]+ \\]\\]$'

TOOL=""
if command -v magick &>/dev/null; then TOOL="magick"
elif command -v convert &>/dev/null; then TOOL="convert"
elif command -v ffmpeg &>/dev/null; then TOOL="ffmpeg"
fi

# mkthumb <línea de cliphist> <miniatura destino>
mkthumb() {
    local tmp="$2.tmp.png"
    case "$TOOL" in
        magick)  printf '%s\n' "$1" | cliphist decode | magick -[0] -thumbnail "160x160>" -strip "png:$tmp" 2>/dev/null ;;
        convert) printf '%s\n' "$1" | cliphist decode | convert -[0] -thumbnail "160x160>" -strip "png:$tmp" 2>/dev/null ;;
        ffmpeg)  printf '%s\n' "$1" | cliphist decode | ffmpeg -loglevel error -y -i pipe:0 -frames:v 1 -vf "scale=160:-2" "$tmp" 2>/dev/null ;;
    esac
    if [[ -s "$tmp" ]]; then mv -f "$tmp" "$2"; else rm -f "$tmp"; return 1; fi
}

cliphist list | {
    declare -A seen=()
    n=0
    while IFS= read -r line; do
        if (( n < MAX )) && [[ -n "$TOOL" && "$line" =~ $re ]]; then
            id="${BASH_REMATCH[1]}"
            th="$DIR/$id.png"
            if [[ ! -s "$th" ]]; then
                mkdir -p "$DIR"
                mkthumb "$line" "$th" || th=""
            fi
            if [[ -n "$th" && -s "$th" ]]; then
                seen[$id]=1
                n=$((n + 1))
                printf '%s%s%s\n' "$line" "$SEP" "$th"
                continue
            fi
        fi
        printf '%s\n' "$line"
    done

    # Limpieza: miniaturas de entradas que ya no están (o sobrantes)
    if [[ -d "$DIR" ]]; then
        shopt -s nullglob
        for f in "$DIR"/*; do
            b="${f##*/}"; b="${b%%.*}"
            [[ -n "${seen[$b]:-}" && "$f" == *.png && "$f" != *.tmp.png ]] || rm -f "$f"
        done
    fi
}
EOT

sed -i "s|__MD_QS_DIR__|${MD_QS_DIR}|g" \
    "$MD_SCRIPTS_DIR/md_menu" "$MD_SCRIPTS_DIR/md_launcher" "$MD_SCRIPTS_DIR/md_volume_osd"
chmod +x "$MD_SCRIPTS_DIR/md_menu" "$MD_SCRIPTS_DIR/md_launcher" \
         "$MD_SCRIPTS_DIR/md_volume_osd" "$MD_SCRIPTS_DIR/show_binds" \
         "$MD_SCRIPTS_DIR/md_cliphist_list"
