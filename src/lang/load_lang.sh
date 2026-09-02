#!/usr/bin/env bash
# src/lang/load_lang.sh

LANG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_TMP="/tmp/.current_lang"

# 1. Si el idioma ya está seleccionado o guardado, lo reutiliza
if [ -z "${SELECTED_LANG:-}" ]; then
    if [ -f "$CONFIG_TMP" ]; then
        SELECTED_LANG="$(cat "$CONFIG_TMP")"
    else
        echo "Selecciona tu idioma / Choose your language / Choisissez votre langue / Wählen Sie Ihre Sprache:"
        echo "1) Español (ES)"
        echo "2) English (EN)"
        echo "3) Français (FR)"
        echo "4) Deutsch (DE)"
        read -rp "Opción / Option / Option / Option (1-4): " OPCION_IDIOMA

        case "$OPCION_IDIOMA" in
            1) SELECTED_LANG="es.cfg" ;;
            2) SELECTED_LANG="en.cfg" ;;
            3) SELECTED_LANG="fr.cfg" ;;
            4) SELECTED_LANG="de.cfg" ;;
            *) SELECTED_LANG="en.cfg" ;;
        esac

        # Guarda la elección para subscripts o ejecuciones posteriores
        echo "$SELECTED_LANG" > "$CONFIG_TMP"
    fi
fi

# Exporta para que cualquier hijo o script llamado con 'bash' lo herede
export SELECTED_LANG

# 2. Carga las traducciones
PATH_TRADUCCION="$LANG_DIR/$SELECTED_LANG"

if [ -f "$PATH_TRADUCCION" ]; then
    # Al hacer set -a, todas las variables dentro de .cfg se exportan automáticamente
    set -a
    source "$PATH_TRADUCCION"
    set +a
else
    echo "Error: No se pudo encontrar el archivo de idioma en $PATH_TRADUCCION" >&2
    return 1 2>/dev/null || exit 1
fi
