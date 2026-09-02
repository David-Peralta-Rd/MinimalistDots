#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANG_DIR="$(cd "$SCRIPT_DIR/../../lang" && pwd)"

# CARGAR EL IDIOMA SI EL SCRIPT SE EJECUTA DIRECTAMENTE
if [ -z "${T_BIENVENIDO:-}" ]; then
    source "$LANG_DIR/load_lang.sh"
fi


# ============================================ #
# ==== INSTALAMOS LOS PAQUETES NECESARIOS ==== #
# ============================================ #

# ACTUALIZAMOS EL SISTEMA
sudo pacman -Syu --noconfirm
sudo pacman -Sy --noconfirm paru

# ================================================== #
# ==== LISTANDO PAQUETES QUE SE VAN A INSTALAR. ==== #
# ================================================== #
ZSH_PKGS=(
    git
    zsh-completions
    zsh-autosuggestions
    zsh-syntax-highlighting
)

CORE_PKGS=(
    git
    wofi
    sddm
    swaync
    flatpak
    udisks2
    cliphist
    hypridle
    hyprland
    hyprlock
    hyprpaper
    qt5ct-kde
    qt6ct-kde
    fastfetch
    hyprpolkitagent
    xdg-desktop-portal-hyprland

)

APPS_PKGS=(
    ark
    foot
    unrar
    brave-bin
    libreoffice-fresh
)

CURSOR_PKGS=(
    rose-pine-hyprcursor
    bibata-cursor-theme-bin
)

DOLPHIN_PKGS=(
    qt5-imageformats
    ffmpegthumbs
    kde-cli-tools
    dolphin
)

SDDM_THEME_PKGS=(
    jq
    curl
    unzip
    qt6-svg
    qt6-declarative
)

SCREENSHOT_PKGS=(
    zbar
    grim
    slurp
    swappy
    libnotify
    tesseract
    wl-clipboard
    grimblast-git
    tesseract-data-eng
    tesseract-data-spa
)

PROGRAMMING_PKGS=(
    uv
    docker
    docker-compose
    visual-studio-code-bin
)

SCREENRECORD_PKGS=(
    slurp
    ffmpeg
    libnotify
    wf-recorder
)

PROCESS_MANAGER_PKGS=(
    jq
    libnotify
    rofi-wayland
)








# Para agregar una categoría nueva: declárala arriba y agrégala aquí.
ALL_PKGS=(
    "${ZSH_PKGS[@]}"
    "${CORE_PKGS[@]}"
    "${APPS_PKGS[@]}"
    "${CURSOR_PKGS[@]}"
    "${DOLPHIN_PKGS[@]}"
    "${SDDM_THEME_PKGS[@]}"
    "${SCREENSHOT_PKGS[@]}"
    "${PROGRAMMING_PKGS[@]}"
    "${SCREENRECORD_PKGS[@]}"
    "${PROCESS_MANAGER_PKGS[@]}"
)

# INSTALAMOS LOS PAQUETES
paru -Sy --needed --noconfirm "${ALL_PKGS[@]}"
