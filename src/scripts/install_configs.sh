#!/usr/bin/env bash
set -euo pipefail

ARCHIVO_LANG="${1:-en.cfg}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LANG_DIR="$PROJECT_ROOT/src/lang"

[ -f "$LANG_DIR/$ARCHIVO_LANG" ] && source "$LANG_DIR/$ARCHIVO_LANG"

DEST_CONFIGS_DIR="$HOME/.config"
BACKUP_ROOT="$HOME/.config/backups_dots/config-backups/$(date +%Y%m%d_%H%M%S)"

# Cargar la paleta global generada
PALETTE_FILE="$PROJECT_ROOT/src/colors/palette.sh"
if [ -f "$PALETTE_FILE" ]; then
    source "$PALETTE_FILE"
fi

write_config() {
    local app_name="$1"
    local config_dir="$DEST_CONFIGS_DIR/$app_name"
    local config_file="$2"
    local content="$3"

    echo "=========================================================="
    echo "Configurando: $app_name"
    echo "=========================================================="

    if [ -d "$config_dir" ]; then
        mkdir -p "$BACKUP_ROOT"
        cp -a "$config_dir" "$BACKUP_ROOT/$app_name"
        rm -rf "$config_dir"
    fi

    mkdir -p "$config_dir"
    echo "$content" > "$config_dir/$config_file"
}

# ------------------------------------------------------------------------------
# FOOT TERMINAL (Inyección dinámica de paleta Muted)
# ------------------------------------------------------------------------------
FOOT_CONF=$(cat <<EOF
[main]
shell=/bin/zsh
font=JetBrains Mono:size=6.8
pad=12x12

[csd]
preferred=none

[colors-dark]
background=${RAW_BG:-1e222a}
foreground=${RAW_TEXT:-abb2bf}

selection-background=${RAW_SELECTION:-3e4451}
selection-foreground=${RAW_TEXT:-abb2bf}

# Paleta base ANSI
regular0=${RAW_BG:-1e222a}
regular1=${RAW_RED:-e06c75}
regular2=${RAW_GREEN:-7ec7a2}
regular3=${RAW_YELLOW:-d19a66}
regular4=${RAW_BLUE:-7aa2f7}
regular5=${RAW_MAGENTA:-c678dd}
regular6=${RAW_CYAN:-56b6c2}
regular7=${RAW_TEXT:-abb2bf}

# Variantes brillantes
bright0=${RAW_GRAY:-5c6370}
bright1=${RAW_RED:-e06c75}
bright2=${RAW_GREEN:-7ec7a2}
bright3=${RAW_YELLOW:-d19a66}
bright4=${RAW_BLUE:-7aa2f7}
bright5=${RAW_MAGENTA:-c678dd}
bright6=${RAW_CYAN:-56b6c2}
bright7=${RAW_LIGHT_GRAY:-abb2bf}
EOF
)

write_config "foot" "foot.ini" "$FOOT_CONF"
