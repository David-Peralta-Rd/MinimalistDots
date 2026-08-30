---------------------
---- MY PROGRAMS ----
---------------------

local HOME = os.getenv("HOME")

return {
    -- Fast Execution
    terminal        = "alacritty",
    fileManager     = "thunar",
    menu            = "wofi",
    browser         = "brave",
    mainMod         = "SUPER",
    editor          = "code",

    -- Complex Execution
    cliphist        = "cliphist list | wofi -c " .. HOME .. "/.config/wofi/configs/config-clipboard -s " .. HOME .. "/.config/wofi/themes/style-clipboard.css --dmenu | cliphist decode | wl-copy",
    screenshot      = HOME .. "/.local/bin/minimalist_dots/scripts/screenshot.sh",
    select_wallpaper = HOME .. "/.local/bin/minimalist_dots/scripts/select_wallpaper.sh",
    show_binds      = HOME .. "/.local/bin/minimalist_dots/scripts/show_binds",
    hyprlock        = "loginctl lock-session",
    screenrecord    = HOME .. "/.local/bin/minimalist_dots/screenrecord.sh",
    process_manager = HOME .. "/.local/bin/minimalist_dots/process_manager.sh"
}
