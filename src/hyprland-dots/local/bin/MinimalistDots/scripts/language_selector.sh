#!/usr/bin/env bash
# Selector de idioma del entorno: terminal o menú Quickshell.
# La elección cambia pending_lang; active_lang solo cambia al iniciar sesión.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_lang.sh"

MD_MENU="$SCRIPT_DIR/md_menu"

md_lang_write_locale() {
    local target="$1" locale="$2" tmp
    mkdir -p "$MD_LANG_STATE_DIR"
    tmp="$target.tmp.$$"
    printf '%s\n' "$locale" > "$tmp"
    mv -f "$tmp" "$target"
}

# Genera las instantáneas desde las variables ya resueltas por _lang.sh.
md_lang_write_snapshots() {
    local tmp_json="$MD_LANG_STATE_DIR/.strings.json.tmp.$$"
    local tmp_lua="$MD_LANG_STATE_DIR/.strings.lua.tmp.$$"
    local variable value equals

    mkdir -p "$MD_LANG_STATE_DIR"
    (
        set -e
        trap 'rm -f "$tmp_json" "$tmp_lua"' EXIT

        jq -n 'env | to_entries | map(select(.key | startswith("MD_TXT_"))) | sort_by(.key) | from_entries' > "$tmp_json"

        printf 'return {\n' > "$tmp_lua"
        while IFS= read -r variable; do
            value="${!variable}"
            equals=""
            while [[ "$value" == *"]${equals}]"* ]]; do
                equals="${equals}="
            done
            printf '["%s"] = [%s[%s]%s],\n' "$variable" "$equals" "$value" "$equals" >> "$tmp_lua"
        done < <(compgen -v MD_TXT_ | LC_ALL=C sort)
        printf '}\n' >> "$tmp_lua"

        mv -f "$tmp_json" "$MD_LANG_STATE_DIR/strings.json"
        mv -f "$tmp_lua" "$MD_LANG_STATE_DIR/strings.lua"
        trap - EXIT
    )
}

# Promueve la elección pendiente una única vez por inicio de sesión.
md_lang_activate() {
    local requested=""
    if [ -f "$MD_LANG_PENDING_FILE" ]; then
        IFS= read -r requested < "$MD_LANG_PENDING_FILE" || true
    elif [ -f "$MD_LANG_ACTIVE_FILE" ]; then
        IFS= read -r requested < "$MD_LANG_ACTIVE_FILE" || true
    fi
    [ -n "$requested" ] || requested="es"

    md_lang_load "$requested"
    md_lang_write_snapshots
    md_lang_write_locale "$MD_LANG_ACTIVE_FILE" "$MD_LANG_ACTIVE"

    if [ "$MD_LANG_FALLBACK" -eq 1 ]; then
        notify-send -a "MinimalistDots" "$MD_TXT_IDIOMA_TITULO" "$MD_TXT_IDIOMA_INVALIDO" 2>/dev/null || true
    fi
}

# Siembra el instalador: no pisa un idioma activo ya existente.
md_lang_seed() {
    local requested="${1:-es}" selected current=""

    md_lang_load "$requested"
    selected="$MD_LANG_ACTIVE"
    md_lang_write_locale "$MD_LANG_PENDING_FILE" "$selected"

    if [ -f "$MD_LANG_ACTIVE_FILE" ]; then
        IFS= read -r current < "$MD_LANG_ACTIVE_FILE" || true
    fi
    if md_lang_find_file "$current"; then
        md_lang_load "$current"
    else
        md_lang_load "$selected"
        md_lang_write_locale "$MD_LANG_ACTIVE_FILE" "$MD_LANG_ACTIVE"
    fi
    md_lang_write_snapshots
}

md_lang_choose_pending() {
    local locale="$1" name="$2" active_message pending_message
    md_lang_write_locale "$MD_LANG_PENDING_FILE" "$locale"
    active_message="$(md_lang_format MD_TXT_IDIOMA_ACTIVO "idioma=$MD_LANG_ACTIVE_NAME")"
    pending_message="$(md_lang_format MD_TXT_IDIOMA_PENDIENTE "idioma=$name")"

    if [ "$MD_SELECTOR_MODE" = "terminal" ]; then
        printf '%s\n%s\n' "$active_message" "$pending_message"
    else
        notify-send -a "MinimalistDots" "$MD_TXT_IDIOMA_TITULO" "$active_message
$pending_message" 2>/dev/null || true
    fi
}

md_lang_terminal_selector() {
    local query="" page=0 pages count start end i choice name key
    local -a filtered_files=() filtered_names=() filtered_locales=()

    while true; do
        filtered_files=()
        filtered_names=()
        filtered_locales=()
        for i in "${!MD_LANG_FILES[@]}"; do
            name="${MD_LANG_NAMES[$i],,}"
            key="${MD_LANG_LOCALES[$i]}"
            if [[ -z "$query" || "$name" == *"$query"* || "$key" == *"$query"* ]]; then
                filtered_files+=("${MD_LANG_FILES[$i]}")
                filtered_names+=("${MD_LANG_NAMES[$i]}")
                filtered_locales+=("$key")
            fi
        done
        count="${#filtered_files[@]}"

        if [ "$count" -eq 0 ]; then
            printf '%s\n' "$MD_TXT_IDIOMA_SIN_RESULTADOS"
            if ! read -rp "/ " OPCION_IDIOMA; then return 1; fi
            case "$OPCION_IDIOMA" in
                /*) query="${OPCION_IDIOMA#/}"; page=0 ;;
                *) return 1 ;;
            esac
            continue
        fi

        pages=$(( (count + 6) / 7 ))
        if [ "$page" -ge "$pages" ]; then page=$((pages - 1)); fi
        start=$((page * 7))
        end=$((start + 7))
        if [ "$end" -gt "$count" ]; then end="$count"; fi

        printf '\n%s\n' "$MD_TXT_IDIOMA_SELECCIONA"
        for ((i = start; i < end; i++)); do
            printf '%d) %s (%s)\n' "$((i + 1))" "${filtered_names[$i]}" "${filtered_locales[$i]^^}"
        done
        if [ "$pages" -gt 1 ]; then
            md_lang_format MD_TXT_IDIOMA_PAGINA "actual=$((page + 1))" "total=$pages"
            printf '\n'
        fi
        printf '%s\n' "$MD_TXT_IDIOMA_AYUDA_TERMINAL"
        if ! read -rp "$MD_TXT_IDIOMA_OPCION: " OPCION_IDIOMA; then return 1; fi

        case "$OPCION_IDIOMA" in
            /*) query="${OPCION_IDIOMA#/}"; page=0 ;;
            n|N) if [ "$page" -lt $((pages - 1)) ]; then page=$((page + 1)); fi ;;
            p|P) if [ "$page" -gt 0 ]; then page=$((page - 1)); fi ;;
            *)
                if [[ "$OPCION_IDIOMA" =~ ^[0-9]+$ ]]; then
                    choice=$((10#$OPCION_IDIOMA))
                    if [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
                        md_lang_choose_pending "${filtered_locales[$((choice - 1))]}" "${filtered_names[$((choice - 1))]}"
                        return 0
                    fi
                fi
                ;;
        esac
    done
}

md_lang_menu_selector() {
    local i choice
    local -a labels=()
    for i in "${!MD_LANG_FILES[@]}"; do
        labels+=("${MD_LANG_NAMES[$i]} (${MD_LANG_LOCALES[$i]^^})")
    done

    choice="$(printf '%s\n' "${labels[@]}" | "$MD_MENU" language --prompt "$MD_TXT_IDIOMA_SELECCIONA" || true)"
    [ -n "$choice" ] || return 0
    for i in "${!labels[@]}"; do
        if [ "$choice" = "${labels[$i]}" ]; then
            md_lang_choose_pending "${MD_LANG_LOCALES[$i]}" "${MD_LANG_NAMES[$i]}"
            return 0
        fi
    done
    return 1
}

MD_SELECTOR_MODE="${1:-}"
case "$MD_SELECTOR_MODE" in
    --activate)
        md_lang_activate
        ;;
    --seed)
        [ "$#" -eq 2 ] || { printf '%s\n' "$MD_TXT_IDIOMA_USO" >&2; exit 2; }
        md_lang_seed "$2"
        ;;
    terminal|menu)
        "md_lang_${MD_SELECTOR_MODE}_selector"
        ;;
    "")
        if [ -t 0 ] && [ -t 1 ]; then
            MD_SELECTOR_MODE="terminal"
            md_lang_terminal_selector
        else
            MD_SELECTOR_MODE="menu"
            md_lang_menu_selector
        fi
        ;;
    *)
        printf '%s\n' "$MD_TXT_IDIOMA_USO" >&2
        exit 2
        ;;
esac
