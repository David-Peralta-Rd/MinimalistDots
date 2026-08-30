#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Si el subscript se ejecuta solo (sin pasar por setup.sh), carga el idioma guardado
if [ -z "${TXT_WELCOME:-}" ]; then
    source "$SRC_DIR/load_lang.sh"
fi



# ================================== #
# ==== ACTUALIZAMOS EL SISTEMA. ==== #
# ================================== #
sudo pacman -Syyu --noconfirm



# =========================================== #
# ==== DESISTALAR PROGRAMAS INNECESARIOS ==== #
# =========================================== #
echo "${TXT_DELETE_PKGS:-Uninstall packages / Desistalamos paquetes }"

DELETE_PKGS=(
    yay
    foot
    fish
    kitty
    firefox
    yay-bin
)

DELETE_ALL_PKGS=(
    "${DELETE_PKGS[@]}"
)

# Desinstalamos los paquetes de forma segura con coincidencia exacta
for pkg in "${DELETE_ALL_PKGS[@]}"; do
    paru -Qq "$pkg" &>/dev/null && paru -Rncs --noconfirm "$pkg"
done





# ================================================== #
# ==== LISTANDO PAQUETES QUE SE VAN A INSTALAR. ==== #
# ================================================== #
CORE_PKGS=(
    jq
    curl
    sddm
    wofi
    unzip
    swaync
    ffmpeg
    qt6-svg
    flatpak
    cliphist
    hypridle
    hyprlock
    hyprland
    hyprpaper
    wf-recorder
    rofi-wayland
    qt6-declarative
    xdg-desktop-portal-hyprland
)

APPS_PKGS=(
    zsh
    ark
    unrar
    alacritty
    brave-bin
    libreoffice-fresh
)

PROGRAMMING_PKGS=(
    uv
    docker
    docker-compose
    visual-studio-code-bin
)

CURSOR_PKGS=(
    bibata-cursor-theme-bin
    rose-pine-hyprcursor
)

ZSH_PKGS=(
    git
    zsh-completions
    zsh-autosuggestions
    zsh-syntax-highlighting
)

SCREENSHOT_PKGS=(
    grim
    slurp
    wl-clipboard
    libnotify
    tesseract
    tesseract-data-eng
    tesseract-data-spa
    zbar
    swappy
    grimblast-git
)

THUNAR_PKGS=(
    imv
    mpv
    libgsf
    thunar
    tumbler
    file-roller
    poppler-glib
    thunar-volman
    raw-thumbnailer
    ffmpegthumbnailer
    papirus-icon-theme
    thunar-archive-plugin
)


# Para agregar una categoría nueva: declárala arriba y agrégala aquí.
ALL_PKGS=(
    "${ZSH_PKGS[@]}"
    "${CORE_PKGS[@]}"
    "${APPS_PKGS[@]}"
    "${CURSOR_PKGS[@]}"
    "${THUNAR_PKGS[@]}"
    "${SCREENSHOT_PKGS[@]}"
    "${PROGRAMMING_PKGS[@]}"
)

# INSTALAMOS LOS PAQUETES
echo "${TXT_INSTALL_PACKAGES:-Installing Packages / Instalando paquetes}"
paru -Sy --needed --noconfirm "${ALL_PKGS[@]}"
