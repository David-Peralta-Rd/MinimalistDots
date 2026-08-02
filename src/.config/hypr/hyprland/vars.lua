---------------------
---- MY PROGRAMS ----
---------------------

return {
    terminal    = "footclient",
    fileManager = "footclient -e yazi",
    menu        = "wofi",
    browser     = "brave",
    mainMod     = "SUPER",
    editor      = "code",
    cliphist    = "cliphist list | wofi --dmenu | cliphist decode | wl-copy",
    screenshot  = HOME .. "/.local/bin/minimaldots/screenshot.sh",
    select_wallpaper = HOME .. "/.config/hypr/hyprland/scripts/select_wallpaper.sh",
    show_binds  = HOME .. "/.local/bin/minimaldots/show_binds",
    hyprlock    = "loginctl lock-session",
}
