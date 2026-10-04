#!/usr/bin/env bash

# OSD minimalista: solo el nivel de volumen.
# SHOW_ICON=1 -> "󰕾  70%"   |   SHOW_ICON=0 -> "70%"
SHOW_ICON=1

# Cierra el OSD anterior si se presiona la tecla varias veces seguidas
pkill -x wofi 2>/dev/null || true

# Cambiar volumen
case "$1" in
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

# Mostrar el HUD de Wofi durante 1.2 segundos en segundo plano
CONFIG_DIR="$HOME/.local/bin/MinimalistDots/wofi"
echo "$TEXT" | wofi --define=hide_search=true -c "$CONFIG_DIR/configs/config-volume" -s "$CONFIG_DIR/themes/style-volume.css" &

PID=$!
(sleep 1.2 && kill "$PID" 2>/dev/null) &
