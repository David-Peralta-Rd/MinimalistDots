#!/usr/bin/env bash
# src/setup/lang/load_lang.sh
#
# Selecciona (o reutiliza) el idioma de la instalación y carga sus
# traducciones (variables T_*) desde src/setup/lang/options/.
#
# Para agregar un idioma nuevo:
#   1. Copia un archivo de options/ como lgN_xx.cfg y tradúcelo.
#   2. Agrega su línea en el menú y su caso en el `case` de abajo.

LANG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPTIONS_DIR="$LANG_DIR/options"
CONFIG_TMP="/tmp/.current_lang"

# 1. Si el idioma ya está seleccionado o guardado (y sigue siendo válido), lo reutiliza
if [ -z "${SELECTED_LANG:-}" ] && [ -f "$CONFIG_TMP" ]; then
    SAVED_LANG="$(cat "$CONFIG_TMP")"
    if [ -f "$OPTIONS_DIR/$SAVED_LANG" ]; then
        SELECTED_LANG="$SAVED_LANG"
    else
        # Elección guardada por otra versión del instalador: se descarta
        rm -f "$CONFIG_TMP"
    fi
    unset SAVED_LANG
fi

if [ -z "${SELECTED_LANG:-}" ]; then
    echo "Selecciona tu idioma / Choose your language / Choisissez votre langue / Wählen Sie Ihre Sprache / Escolha o idioma:"
    echo "1) Español (ES)"
    echo "2) English (EN)"
    echo "3) Français (FR)"
    echo "4) Deutsch (DE)"
    echo "5) Português (PT)"
    read -rp "Opción / Option / Option / Option / Opção (1-5): " OPCION_IDIOMA

    case "$OPCION_IDIOMA" in
        1) SELECTED_LANG="lg1_es.cfg" ;;
        2) SELECTED_LANG="lg2_en.cfg" ;;
        3) SELECTED_LANG="lg3_fr.cfg" ;;
        4) SELECTED_LANG="lg4_de.cfg" ;;
        5) SELECTED_LANG="lg5_pt.cfg" ;;
        *) SELECTED_LANG="lg2_en.cfg" ;;
    esac

    # Guarda la elección para subscripts o ejecuciones posteriores
    echo "$SELECTED_LANG" > "$CONFIG_TMP"
fi

# Exporta para que cualquier hijo o script llamado con 'bash' lo herede
export SELECTED_LANG

# 2. Carga las traducciones
PATH_TRADUCCION="$OPTIONS_DIR/$SELECTED_LANG"

if [ -f "$PATH_TRADUCCION" ]; then
    # Al hacer set -a, todas las variables dentro de .cfg se exportan automáticamente
    set -a
    source "$PATH_TRADUCCION"
    set +a
else
    echo "Error: No se pudo encontrar el archivo de idioma en $PATH_TRADUCCION" >&2
    return 1 2>/dev/null || exit 1
fi
