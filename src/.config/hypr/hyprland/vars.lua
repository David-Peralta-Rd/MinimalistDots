---------------------
---- MY PROGRAMS ----
---------------------

local HOME = os.getenv("HOME")

return {
-- ======================== --
-- ==== Fast Execution ==== --
-- ======================== --
    terminal        = "footclient",
    fileManager     = "dolphin",
    menu            = "wofi",
    browser         = "brave",
    mainMod         = "SUPER",
    editor          = "code",
    hyprlock        = "loginctl lock-session",

-- =========================== --
-- ==== Complex Execution ==== --
-- =========================== --
    cliphist = "cliphist list | wofi -c " .. HOME .. "/.config/wofi/configs/config-clipboard -s " .. HOME .. "/.config/wofi/themes/style-clipboard.css --dmenu | cliphist decode | wl-copy",

-- ========================== --
-- ==== Keybinds Scripts ==== --
-- ========================== --
    volume_up           = HOME .. "/.local/bin/MinimalistDots/scripts/volume.sh up",
    volume_down         = HOME .. "/.local/bin/MinimalistDots/scripts/volume.sh down",
    volume_mute         = HOME .. "/.local/bin/MinimalistDots/scripts/volume.sh mute",
    screenshot          = HOME .. "/.local/bin/MinimalistDots/scripts/screenshot.sh",
    select_wallpaper    = HOME .. "/.local/bin/MinimalistDots/scripts/select_wallpaper.sh",
    show_binds          = HOME .. "/.local/bin/MinimalistDots/scripts/show_binds",
    screenrecord        = HOME .. "/.local/bin/MinimalistDots/scripts/screenrecord.sh",
    process_manager     = HOME .. "/.local/bin/MinimalistDots/scripts/process_manager.sh"
}
