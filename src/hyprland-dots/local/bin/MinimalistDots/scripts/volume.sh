#!/usr/bin/env bash

# Cierra el OSD anterior si se presiona la tecla varias veces seguidas
pkill -x wofi 2>/dev/null || true

# Cambiar volumen
case "${1:-}" in
    up)   wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
    down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
esac

# Obtener nivel actual e icono
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o "MUTED" || true)
VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')

if [ -n "$MUTED" ]; then
    ICON="󰝟"
    TEXT="$ICON  Silenciado"
else
    if [ "$VOL" -ge 70 ]; then
        ICON="󰕾"
    elif [ "$VOL" -ge 30 ]; then
        ICON="󰖀"
    else
        ICON="󰕿"
    fi

    # Genera indicador por puntos (10 niveles: • para lleno, ◦ para vacío)
    DOTS_TOTAL=10
    FILLED=$(( (VOL + 5) / 10 ))  # Redondea al múltiplo de 10 más cercano
    (( FILLED > DOTS_TOTAL )) && FILLED=$DOTS_TOTAL
    EMPTY=$(( DOTS_TOTAL - FILLED ))

    DOTS=""
    for (( i=0; i<FILLED; i++ )); do DOTS+="•"; done
    for (( i=0; i<EMPTY; i++ )); do DOTS+="◦"; done

    TEXT="$ICON  $VOL%  $DOTS"
fi

# Ruta de configuración
CONFIG_DIR="$HOME/.local/bin/MinimalistDots/wofi"

# Lanzar OSD minimalista en segundo plano
echo "$TEXT" | wofi --define=hide_search=true -c "$CONFIG_DIR/configs/config-volume" -s "$CONFIG_DIR/themes/style-volume.css" &

PID=$!
(sleep 1.2 && kill "$PID" 2>/dev/null) &
