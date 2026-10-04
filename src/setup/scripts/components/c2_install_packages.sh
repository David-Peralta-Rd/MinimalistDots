#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/u3_env.sh"


# ============================================ #
# ==== INSTALAMOS LOS PAQUETES NECESARIOS ==== #
# ============================================ #

# ACTUALIZAMOS EL SISTEMA
sudo pacman -Syu --noconfirm

# INSTALAMOS PARU SI NO ESTA
ensure_paru() {
    if command -v paru &>/dev/null; then
        return 0
    fi

    # CachyOS (y otras derivadas) lo traen en sus repositorios
    if sudo pacman -S --needed --noconfirm paru; then
        return 0
    fi

    # Arch puro: paru solo existe en el AUR, se compila paru-bin
    echo "$T_INSTALANDO_PARU"
    sudo pacman -S --needed --noconfirm base-devel git

    local build_dir
    build_dir="$(mktemp -d)"
    git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$build_dir/paru-bin"
    (cd "$build_dir/paru-bin" && makepkg -si --noconfirm)
    rm -rf "$build_dir"
}
ensure_paru

# ================================================== #
# ==== LISTANDO PAQUETES QUE SE VAN A INSTALAR. ==== #
# ================================================== #
ZSH_PKGS=(
    zsh
    git
    zsh-completions
    zsh-autocomplete
    zsh-autosuggestions
    zsh-syntax-highlighting
)

CORE_PKGS=(
    mpv
    git
    eww
    wofi
    sddm
    qt6ct
    swaync
    flatpak
    udisks2
    cliphist
    hypridle
    hyprland
    hyprlock
    hyprpaper
    reflector
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
    github-cli
    docker-buildx
    drawio-desktop
    docker-compose
    visual-studio-code-bin
)

SCREENRECORD_PKGS=(
    slurp
    ffmpeg
    libnotify
    gpu-screen-recorder
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

# Quitamos duplicados (git, jq, slurp, libnotify...) conservando el orden
mapfile -t ALL_PKGS < <(printf '%s\n' "${ALL_PKGS[@]}" | awk '!seen[$0]++')

# INSTALAMOS LOS PAQUETES (la base ya quedó sincronizada con -Syu arriba)
paru -S --needed --noconfirm "${ALL_PKGS[@]}"
