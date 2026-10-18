#!/usr/bin/env bash
# ==============================================================================
# Historial de notificaciones (Quickshell, md_menu)
#   Elige una entrada para copiar su contenido (resumen + cuerpo) al portapapeles.
#
# Uso:
#   notifications_menu.sh [history]   Abre el historial (por defecto)
#   notifications_menu.sh dnd         Activa / desactiva "No molestar"
#   notifications_menu.sh dismiss     Cierra las notificaciones visibles
#   notifications_menu.sh clear       Borra el historial
#
# El demonio (quickshell/notifd.qml) guarda el historial en:
#   ~/.local/state/MinimalistDots/notifications.jsonl
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
MENU="$SCRIPT_DIR/md_menu"
QML="$HOME/.local/bin/MinimalistDots/quickshell/notifd.qml"
HIST="${XDG_STATE_HOME:-$HOME/.local/state}/MinimalistDots/notifications.jsonl"

# "Historial" es una app ignorada por el demonio: estos avisos no ensucian el historial
say() { notify-send -a "Historial" -t 2500 "$1" "${2:-}" 2> /dev/null || true; }

notifd() { qs -p "$QML" ipc call notifd "$@" 2> /dev/null; }

need() {
    command -v "$1" > /dev/null 2>&1 || { say "Falta $1" "Instálalo para usar el historial."; exit 1; }
}

# Lee el historial ignorando líneas dañadas
load='[inputs | try fromjson catch empty]'

history() {
    need jq
    need wl-copy

    local state dnd_label list choice idx text
    state="$(notifd status || true)"
    if [ "$state" = "dnd" ]; then dnd_label="🔔 Desactivar No molestar"; else dnd_label="🔕 Activar No molestar"; fi

    list="$(
        if [ -s "$HIST" ]; then
            jq -Rn "$load"' | to_entries | reverse | .[] |
                "#\(.key + 1)  \(.value.time | localtime | strftime("%d/%m %H:%M"))  [\(.value.app)] \(.value.summary)"
                + (if (.value.body // "") != "" then " — \(.value.body | gsub("[\n\t]"; " "))" else "" end)' \
                -r "$HIST" | cut -c1-220
        fi
    )"

    choice="$({ echo "$dnd_label"; echo "🗑️ Borrar historial"; [ -n "$list" ] && echo "$list"; } \
        | "$MENU" notifications --raw --prompt "Notificaciones — Enter copia" || true)"
    [ -z "$choice" ] && exit 0

    case "$choice" in
        *"No molestar"*) dnd; exit 0 ;;
        *"Borrar historial"*) clear_history; exit 0 ;;
    esac

    idx="$(grep -oP '^#\K[0-9]+' <<< "$choice" || true)"
    [ -z "$idx" ] && exit 0

    text="$(jq -Rn "$load"' | .['"$((idx - 1))"'] | .summary + (if (.body // "") != "" then "\n" + .body else "" end)' \
        -j "$HIST")"
    if [ -n "$text" ]; then
        printf '%s' "$text" | wl-copy
        say "Copiado al portapapeles" "$(head -c 80 <<< "$text" | tr '\n' ' ')"
    fi
}

dnd() {
    local r
    r="$(notifd toggleDnd)" || { say "Demonio de notificaciones apagado" "Reinicia la sesión o ejecuta: qs -p $QML"; exit 1; }
    # Las críticas siempre se muestran: así se ve el aviso incluso al activar
    if [ "$r" = "on" ]; then
        notify-send -a "Historial" -u critical -t 2500 "No molestar activado" "Se guardan en el historial sin mostrarse." 2> /dev/null || true
    else
        say "No molestar desactivado"
    fi
}

clear_history() {
    : > "$HIST" 2> /dev/null || true
    say "Historial borrado"
}

case "${1:-history}" in
    history)  history ;;
    dnd)      dnd ;;
    dismiss)  notifd clearPopups > /dev/null ;;
    clear)    clear_history ;;
    *)
        echo "Uso: $(basename "$0") {history|dnd|dismiss|clear}" >&2
        exit 1
        ;;
esac
