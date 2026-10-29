---------------------
---- MY PROGRAMS ----
---------------------

local HOME = os.getenv("HOME")
local MINIMALISTDOTS = HOME .. "/.local/bin/MinimalistDots"

return {
-- ======================== --
-- ==== Fast Execution ==== --
-- ======================== --
    terminal        = "footclient",
    terminal_float  = "footclient --app-id=programing-terminal",
    terminal_float_opencode  = "footclient --app-id=programing-terminal-opencode",
    fileManager     = "dolphin",
    menu            = MINIMALISTDOTS .. "/scripts/md_launcher",
    browser         = "brave",
    mainMod         = "SUPER",
    editor          = "code",
    hyprlock        = "loginctl lock-session",

-- =========================== --
-- ==== Complex Execution ==== --
-- =========================== --
    cliphist = "sel=$(cliphist list | " .. MINIMALISTDOTS .. "/scripts/md_menu clipboard --raw) && printf '%s' \"$sel\" | cliphist decode | wl-copy",

-- ========================== --
-- ==== Keybinds Scripts ==== --
-- ========================== --
    volume_up           = MINIMALISTDOTS .. "/scripts/volume.sh up",
    volume_down         = MINIMALISTDOTS .. "/scripts/volume.sh down",
    volume_mute         = MINIMALISTDOTS .. "/scripts/volume.sh mute",
    screenshot          = MINIMALISTDOTS .. "/scripts/screenshot.sh",
    select_wallpaper    = MINIMALISTDOTS .. "/scripts/select_wallpaper.sh",
    show_binds          = MINIMALISTDOTS .. "/scripts/show_binds",
    screenrecord        = MINIMALISTDOTS .. "/scripts/screenrecord.sh",
    process_manager     = MINIMALISTDOTS .. "/scripts/process_manager.sh",
    pomodoro            = MINIMALISTDOTS .. "/scripts/pomodoro.sh toggle",
    llm_menu            = MINIMALISTDOTS .. "/scripts/llm_menu.sh toggle",
    notifications       = MINIMALISTDOTS .. "/scripts/notifications_menu.sh history",
    notifications_dnd   = MINIMALISTDOTS .. "/scripts/notifications_menu.sh dnd",
    notifications_close = MINIMALISTDOTS .. "/scripts/notifications_menu.sh dismiss",
}
