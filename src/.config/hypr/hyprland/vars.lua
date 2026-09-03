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

    volume_up = [[bash -c "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ && VOL=\$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int(\$2 * 100)}') && notify-send -e -u low -h string:x-canonical-private-synchronous:volume 'Volumen' \"\${VOL}%\""]],

    volume_down = [[bash -c "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && VOL=\$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int(\$2 * 100)}') && notify-send -e -u low -h string:x-canonical-private-synchronous:volume 'Volumen' \"\${VOL}%\""]],

-- ========================== --
-- ==== Keybinds Scripts ==== --
-- ========================== --
    screenshot      = HOME .. "/.local/bin/MinimalistDots/scripts/screenshot.sh",
    select_wallpaper = HOME .. "/.local/bin/MinimalistDots/scripts/select_wallpaper.sh",
    show_binds      = HOME .. "/.local/bin/MinimalistDots/scripts/show_binds",
    screenrecord    = HOME .. "/.local/bin/MinimalistDots/scripts/screenrecord.sh",
    process_manager = HOME .. "/.local/bin/MinimalistDots/scripts/process_manager.sh"
}
