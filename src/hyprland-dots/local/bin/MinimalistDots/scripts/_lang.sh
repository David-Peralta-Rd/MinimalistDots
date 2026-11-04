#!/usr/bin/env bash
# Loader compartido de textos del entorno instalado.
# Los catálogos son datos shell; español es la base y el respaldo por clave.

MD_LANG_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MD_LANG_OPTIONS_DIR="$MD_LANG_SCRIPT_DIR/../language_options"
MD_LANG_STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/MinimalistDots/language"
MD_LANG_ACTIVE_FILE="$MD_LANG_STATE_DIR/active_lang"
MD_LANG_PENDING_FILE="$MD_LANG_STATE_DIR/pending_lang"

MD_LANG_FILES=()
MD_LANG_NAMES=()
MD_LANG_LOCALES=()
MD_LANG_ACTIVE=""
MD_LANG_ACTIVE_NAME=""
MD_LANG_FALLBACK=0

md_lang_discover() {
    local path base entry
    local -a unsorted=() sorted=()

    MD_LANG_FILES=()
    MD_LANG_NAMES=()
    MD_LANG_LOCALES=()

    shopt -s nullglob
    for path in "$MD_LANG_OPTIONS_DIR"/*.cfg; do
        base="${path##*/}"
        if [[ "$base" =~ ^lg([1-9][0-9]*)_([A-Za-z]+(?:_[A-Za-z]+)*)_([A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})?)\.cfg$ ]]; then
            unsorted+=("${BASH_REMATCH[1]}"$'\t'"$base")
        fi
    done
    shopt -u nullglob

    [ "${#unsorted[@]}" -gt 0 ] || return 1
    mapfile -t sorted < <(printf '%s\n' "${unsorted[@]}" | LC_ALL=C sort -t $'\t' -k1,1n -k2,2)
    for entry in "${sorted[@]}"; do
        base="${entry#*$'\t'}"
        [[ "$base" =~ ^lg([1-9][0-9]*)_([A-Za-z]+(?:_[A-Za-z]+)*)_([A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})?)\.cfg$ ]] || continue
        MD_LANG_FILES+=("$base")
        MD_LANG_NAMES+=("${BASH_REMATCH[2]//_/ }")
        MD_LANG_LOCALES+=("${BASH_REMATCH[3],,}")
    done
}

# Resuelve un locale solo contra archivos descubiertos; nunca acepta una ruta.
md_lang_find_file() {
    local wanted="${1,,}" i
    MD_LANG_FOUND_FILE=""
    MD_LANG_FOUND_NAME=""
    MD_LANG_FOUND_LOCALE=""

    for i in "${!MD_LANG_FILES[@]}"; do
        if [ "$wanted" = "${MD_LANG_LOCALES[$i]}" ]; then
            MD_LANG_FOUND_FILE="${MD_LANG_FILES[$i]}"
            MD_LANG_FOUND_NAME="${MD_LANG_NAMES[$i]}"
            MD_LANG_FOUND_LOCALE="${MD_LANG_LOCALES[$i]}"
            return 0
        fi
    done
    return 1
}

md_lang_clear_texts() {
    local variable
    while IFS= read -r variable; do
        unset "$variable"
    done < <(compgen -v MD_TXT_)
}

# md_lang_load [locale]: carga español y después el idioma solicitado.
md_lang_load() {
    local requested="${1:-}" base_file base_locale selected_file selected_locale selected_name

    if [ "${#MD_LANG_FILES[@]}" -eq 0 ] && ! md_lang_discover; then
        echo "MinimalistDots: no se encontraron catálogos de idioma." >&2
        return 1
    fi
    if ! md_lang_find_file "es"; then
        echo "MinimalistDots: falta el catálogo base en español." >&2
        return 1
    fi
    base_file="$MD_LANG_FOUND_FILE"
    base_locale="$MD_LANG_FOUND_LOCALE"

    if [ -z "$requested" ] && [ -f "$MD_LANG_ACTIVE_FILE" ]; then
        IFS= read -r requested < "$MD_LANG_ACTIVE_FILE" || true
    fi
    [ -n "$requested" ] || requested="es"

    MD_LANG_FALLBACK=0
    if md_lang_find_file "$requested"; then
        selected_file="$MD_LANG_FOUND_FILE"
        selected_locale="$MD_LANG_FOUND_LOCALE"
        selected_name="$MD_LANG_FOUND_NAME"
    else
        selected_file="$base_file"
        selected_locale="$base_locale"
        selected_name="Espanol"
        MD_LANG_FALLBACK=1
    fi

    md_lang_clear_texts
    set -a
    source "$MD_LANG_OPTIONS_DIR/$base_file"
    if [ "$selected_file" != "$base_file" ]; then
        source "$MD_LANG_OPTIONS_DIR/$selected_file"
    fi
    set +a

    MD_LANG_ACTIVE="$selected_locale"
    MD_LANG_ACTIVE_NAME="$selected_name"
}

# md_lang_format VARIABLE [clave=valor ...]
md_lang_format() {
    local variable="$1" template replacement key value
    shift
    [[ -v $variable ]] || return 1
    template="${!variable}"
    for replacement in "$@"; do
        key="${replacement%%=*}"
        value="${replacement#*=}"
        template="${template//"{$key}"/$value}"
    done
    printf '%s' "$template"
}

md_lang_load
