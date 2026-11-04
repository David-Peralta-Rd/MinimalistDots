#!/usr/bin/env bash
# src/setup/lang/load_lang.sh
#
# Selecciona (o reutiliza) el idioma de la instalación y carga sus
# traducciones (variables T_*) desde src/setup/lang/options/.
#
# Convención: lgN_Nombre_del_idioma_locale.cfg
#   - N ordena numéricamente; los empates se resuelven por nombre completo.
#   - El locale puede ser de idioma (es) o idioma-región (es-CO).
#   - Para añadir un idioma basta con copiar un .cfg y traducirlo.

LANG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPTIONS_DIR="$LANG_DIR/options"
CONFIG_TMP="/tmp/.current_lang"
LANG_PAGE_SIZE=7

MD_LANG_FILES=()
MD_LANG_NAMES=()
MD_LANG_KEYS=()
MD_FILTER_FILES=()
MD_FILTER_NAMES=()
MD_FILTER_KEYS=()

# Descubre solo archivos que cumplen la convención y los ordena por N y nombre.
discover_languages() {
    local path base entry
    local -a unsorted=() sorted=()

    shopt -s nullglob
    for path in "$OPTIONS_DIR"/*.cfg; do
        base="${path##*/}"
        if [[ "$base" =~ ^lg([1-9][0-9]*)_([A-Za-z]+(?:_[A-Za-z]+)*)_([A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})?)\.cfg$ ]]; then
            unsorted+=("${BASH_REMATCH[1]}"$'\t'"$base")
        fi
    done
    shopt -u nullglob

    if [ "${#unsorted[@]}" -eq 0 ]; then
        return 1
    fi

    mapfile -t sorted < <(printf '%s\n' "${unsorted[@]}" | LC_ALL=C sort -t $'\t' -k1,1n -k2,2)
    for entry in "${sorted[@]}"; do
        base="${entry#*$'\t'}"
        [[ "$base" =~ ^lg([1-9][0-9]*)_([A-Za-z]+(?:_[A-Za-z]+)*)_([A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})?)\.cfg$ ]] || continue
        MD_LANG_FILES+=("$base")
        MD_LANG_NAMES+=("${BASH_REMATCH[2]//_/ }")
        MD_LANG_KEYS+=("${BASH_REMATCH[3],,}")
    done
}

# Valida contra basenames descubiertos: nunca se acepta una ruta arbitraria.
find_language() {
    local wanted="${1:-}" i
    for i in "${!MD_LANG_FILES[@]}"; do
        if [ "$wanted" = "${MD_LANG_FILES[$i]}" ]; then
            return 0
        fi
    done
    return 1
}

# Mantiene el comportamiento anterior: una opción inválida selecciona inglés.
select_default_language() {
    local i
    for i in "${!MD_LANG_KEYS[@]}"; do
        if [ "${MD_LANG_KEYS[$i]}" = "en" ]; then
            SELECTED_LANG="${MD_LANG_FILES[$i]}"
            return 0
        fi
    done
    # Si alguien elimina inglés, usa el primer idioma descubierto en vez de fallar.
    SELECTED_LANG="${MD_LANG_FILES[0]}"
}

build_language_filter() {
    local query="${1,,}" i name key
    MD_FILTER_FILES=()
    MD_FILTER_NAMES=()
    MD_FILTER_KEYS=()

    for i in "${!MD_LANG_FILES[@]}"; do
        name="${MD_LANG_NAMES[$i],,}"
        key="${MD_LANG_KEYS[$i]}"
        if [[ -z "$query" || "$name" == *"$query"* || "$key" == *"$query"* ]]; then
            MD_FILTER_FILES+=("${MD_LANG_FILES[$i]}")
            MD_FILTER_NAMES+=("${MD_LANG_NAMES[$i]}")
            MD_FILTER_KEYS+=("$key")
        fi
    done
}

select_language_menu() {
    local query="" page=0 pages count start end i choice

    echo "Selecciona tu idioma / Choose your language / Choisissez votre langue / Wählen Sie Ihre Sprache / Escolha o idioma:"
    while true; do
        build_language_filter "$query"
        count="${#MD_FILTER_FILES[@]}"

        if [ "$count" -eq 0 ]; then
            echo "Sin resultados / No results. /texto = buscar / search; / = limpiar / clear"
            if ! read -rp "Búsqueda / Search: " OPCION_IDIOMA; then
                select_default_language
                return 0
            fi
            case "$OPCION_IDIOMA" in
                /*) query="${OPCION_IDIOMA#/}"; page=0 ;;
                *) select_default_language; return 0 ;;
            esac
            continue
        fi

        pages=$(( (count + LANG_PAGE_SIZE - 1) / LANG_PAGE_SIZE ))
        if [ "$page" -ge "$pages" ]; then page=$((pages - 1)); fi
        start=$((page * LANG_PAGE_SIZE))
        end=$((start + LANG_PAGE_SIZE))
        if [ "$end" -gt "$count" ]; then end="$count"; fi

        if [ -n "$query" ]; then printf 'Filtro / Filter: %s\n' "$query"; fi
        for ((i = start; i < end; i++)); do
            printf '%d) %s (%s)\n' "$((i + 1))" "${MD_FILTER_NAMES[$i]}" "${MD_FILTER_KEYS[$i]^^}"
        done
        if [ "$pages" -gt 1 ]; then
            printf 'Página / Page %d/%d: n = siguiente / next, p = anterior / previous\n' "$((page + 1))" "$pages"
        fi
        echo "/texto = buscar / search; / = limpiar / clear"
        if ! read -rp "Opción / Option / Option / Option / Opção: " OPCION_IDIOMA; then
            select_default_language
            return 0
        fi

        case "$OPCION_IDIOMA" in
            /*)
                query="${OPCION_IDIOMA#/}"
                page=0
                ;;
            n|N)
                if [ "$page" -lt $((pages - 1)) ]; then page=$((page + 1)); fi
                ;;
            p|P)
                if [ "$page" -gt 0 ]; then page=$((page - 1)); fi
                ;;
            *)
                if [[ "$OPCION_IDIOMA" =~ ^[0-9]+$ ]]; then
                    choice=$((10#$OPCION_IDIOMA))
                    if [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
                        SELECTED_LANG="${MD_FILTER_FILES[$((choice - 1))]}"
                        return 0
                    fi
                fi
                select_default_language
                return 0
                ;;
        esac
    done
}

if ! discover_languages; then
    echo "Error: no se encontraron idiomas válidos en $OPTIONS_DIR" >&2
    return 1 2>/dev/null || exit 1
fi

# Reutiliza una selección válida; una caché antigua o desconocida se descarta.
if [ -z "${SELECTED_LANG:-}" ] && [ -f "$CONFIG_TMP" ]; then
    SAVED_LANG="$(cat "$CONFIG_TMP")"
    if find_language "$SAVED_LANG"; then
        SELECTED_LANG="$SAVED_LANG"
    else
        rm -f "$CONFIG_TMP"
    fi
    unset SAVED_LANG
fi

# Un valor heredado inválido conserva el fallo anterior, pero sin permitir rutas.
if [ -n "${SELECTED_LANG:-}" ] && ! find_language "$SELECTED_LANG"; then
    echo "Error: No se pudo encontrar el archivo de idioma en $OPTIONS_DIR/$SELECTED_LANG" >&2
    return 1 2>/dev/null || exit 1
fi

if [ -z "${SELECTED_LANG:-}" ]; then
    select_language_menu
    printf '%s\n' "$SELECTED_LANG" > "$CONFIG_TMP"
fi

export SELECTED_LANG

PATH_TRADUCCION="$OPTIONS_DIR/$SELECTED_LANG"
if [ -f "$PATH_TRADUCCION" ]; then
    set -a
    source "$PATH_TRADUCCION"
    set +a
else
    echo "Error: No se pudo encontrar el archivo de idioma en $PATH_TRADUCCION" >&2
    return 1 2>/dev/null || exit 1
fi
