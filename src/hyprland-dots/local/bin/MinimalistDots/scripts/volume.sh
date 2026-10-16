#!/usr/bin/env bash

# OSD minimalista: solo el nivel de volumen (Quickshell).
# SHOW_ICON=1 -> "󰕾  70%"   |   SHOW_ICON=0 -> "70%"
SHOW_ICON=1

MD_OSD="$(dirname "$(readlink -f "$0")")/md_volume_osd"

# Cambiar volumen
case "${1:-}" in
    up)   wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
    down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
esac

# Obtener nivel actual e icono
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o "MUTED")
VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')

if [ -n "$MUTED" ]; then
    ICON="󰝟"
    LABEL="Mute"
else
    if [ "$VOL" -ge 70 ]; then ICON="󰕾"; elif [ "$VOL" -ge 30 ]; then ICON="󰖀"; else ICON="󰕿"; fi
    LABEL="$VOL%"
fi

if [ "$SHOW_ICON" = "1" ]; then
    TEXT="$ICON  $LABEL"
else
    TEXT="$LABEL"
fi

# md_volume_osd reemplaza el OSD anterior (no hace falta cerrarlo antes)
# y se cierra solo a los ~1.2 s.
"$MD_OSD" "$TEXT"
