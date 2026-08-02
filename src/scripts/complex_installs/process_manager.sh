#!/usr/bin/env bash

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}=== Instalador del Gestor Flotante de Procesos ===${NC}\n"

# 1. Instalar dependencias
install_dependencies() {
    echo -e "${YELLOW}[1/2] Verificando e instalando dependencias...${NC}"

    if command -v pacman &>/dev/null; then
        echo -e "${CYAN}Detectado Arch Linux / Pacman...${NC}"
        sudo pacman -S --needed --noconfirm rofi-wayland jq libnotify
    elif command -v dnf &>/dev/null; then
        echo -e "${CYAN}Detectado Fedora / DNF...${NC}"
        sudo dnf install -y rofi jq libnotify
    elif command -v apt &>/dev/null; then
        echo -e "${CYAN}Detectado Debian / Ubuntu / APT...${NC}"
        sudo apt update
        sudo apt install -y rofi jq libnotify-bin
    else
        echo -e "${RED}Asegúrate de instalar manualmente: rofi (o rofi-wayland), jq y libnotify.${NC}"
    fi
}

install_dependencies

# 2. Instalar el script
INSTALL_DIR="$HOME/.local/bin/minimaldots"
TARGET_FILE="$INSTALL_DIR/process_manager.sh"

mkdir -p "$INSTALL_DIR"

# (Aquí se escribe el contenido del script anterior)
cat << 'EOF' > "$TARGET_FILE"
#!/usr/bin/env bash

ROFI_THEME="${XDG_RUNTIME_DIR:-/tmp}/rofi-process-manager.rasi"

cat << 'RFT' > "$ROFI_THEME"
configuration {
    show-icons: true;
    font: "JetBrainsMono Nerd Font 11";
}

* {
    background-color: #1e1e2e;
    text-color: #cdd6f4;
    border-color: #89b4fa;
}

window {
    location: center;
    anchor: center;
    width: 600px;
    height: 480px;
    border: 2px;
    border-radius: 12px;
    padding: 16px;
    background-color: #1e1e2e;
}

mainbox {
    children: [ inputbar, listview ];
    spacing: 12px;
}

inputbar {
    children: [ prompt, entry ];
    background-color: #313244;
    border-radius: 8px;
    padding: 8px 12px;
}

prompt {
    text-color: #89b4fa;
    margin: 0px 8px 0px 0px;
}

entry {
    placeholder: "Buscar o seleccionar para cerrar...";
    placeholder-color: #6c7086;
}

listview {
    lines: 10;
    columns: 1;
    cycle: true;
    scrollbar: false;
}

element {
    padding: 8px 12px;
    border-radius: 6px;
    background-color: transparent;
}

element selected {
    background-color: #f38ba8;
    text-color: #11111b;
}

element-text {
    text-color: inherit;
}
RFT

get_user_apps() {
    if command -v hyprctl &>/dev/null; then
        hyprctl clients -j | jq -r '.[] | "🗑️  \(.title) [Class: \(.class)] (PID: \(.pid))"' | sort -u
    else
        ps -u "$USER" -o pid,comm --no-headers | awk '{print "🗑️  " $2 " (PID: " $1 ")"}'
    fi
}

get_system_apps() {
    ps -u "$USER" -o pid,comm,%mem,%cpu --sort=-%mem | awk 'NR>1 {print "⚙️  " $2 " | RAM: " $3 "% | CPU: " $4 "% (PID: " $1 ")"}'
}

show_category_menu() {
    cat <<EOFM | rofi -dmenu -theme "$ROFI_THEME" -p "Gestor" -mesg "Selecciona una categoría:"
📱 Aplicaciones del Día a Día (GUI)
⚙️ Procesos del Sistema / Fondo
EOFM
}

category=$(show_category_menu)

case "$category" in
    *"Día a Día"*)
        selected=$(get_user_apps | rofi -dmenu -theme "$ROFI_THEME" -p "Cerrar App" -mesg "Selecciona una app para finalizarla:")
        ;;
    *"Sistema"*)
        selected=$(get_system_apps | rofi -dmenu -theme "$ROFI_THEME" -p "Matar Proceso" -mesg "Selecciona un proceso para matarlo:")
        ;;
    *)
        exit 0
        ;;
esac

if [[ -n "$selected" ]]; then
    pid=$(echo "$selected" | grep -oP '\(PID:\s*\K[0-9]+(?=\))')

    if [[ -n "$pid" ]]; then
        if kill -9 "$pid" 2>/dev/null; then
            notify-send -a "Gestor de Procesos" -i "dialog-information" "Proceso Finalizado" "Se cerró el proceso con PID: $pid"
        else
            notify-send -a "Gestor de Procesos" -i "dialog-error" "Error" "No se pudo cerrar el proceso $pid"
        fi
    fi
fi
EOF

chmod +x "$TARGET_FILE"

echo -e "\n${GREEN}[2/2] ¡Instalación completada con éxito!${NC}\n"
