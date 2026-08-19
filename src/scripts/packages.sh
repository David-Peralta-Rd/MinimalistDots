#!/usr/bin/env bash
# Este archivo se "source"-ea, no se ejecuta directo.
# Cada array es una categoría. Agrega la tuya y súmala a ALL_PKGS al final.

CORE_PKGS=(
    hyprland
    xdg-desktop-portal-hyprland
    hyprpolkitagent
    sddm
    swaync
    hypridle
    hyprlock
    waybar
    hyprpaper
    wofi
    git
    cliphist
    fastfetch
    flatpak
)

APPS_PKGS=(
    foot
    ark
    unrar
    libreoffice-fresh
    brave-bin
)

FONTS_PKGS=(
    # ttf-jetbrains-mono-nerd
)

PROGRAMMING_PKGS=(
    visual-studio-code-bin
    docker
    uv

)

# --- Junta todas las categorías en una sola variable ---
# Para agregar una categoría nueva: declárala arriba y agrégala aquí.
ALL_PKGS=(
    "${CORE_PKGS[@]}"
    "${APPS_PKGS[@]}"
    "${FONTS_PKGS[@]}"
    "${PROGRAMMING_PKGS[@]}"
)
