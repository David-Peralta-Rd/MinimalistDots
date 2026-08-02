local Service = require("hyprland.lib.services")
local colors  = require("hyprland.colors")

local SCRIPTS_DIR = os.getenv("HOME") .. "/.config/hypr/scripts"
local BIN_DIR     = os.getenv("HOME") .. "/.local/bin"

-- Extraemos los strings en formato HEX limpios desde tu módulo de colores
local bg       = colors.background.hex
local surface  = colors.surface.hex
local text     = colors.text.hex
-- Usamos fallbacks razonables basados en tu paleta para las variables que pide el CSS
local surface2 = "#252538"
local overlay  = colors.border_inactive.hex
local subtext  = "#a6adc8"
local mod_col  = colors.border_active.hex

-- ==========================================
-- 1. PLANTILLA DEL ARCHIVO HTML
-- ==========================================
-- NOTA: En los bloques [[ ]] de Lua, los caracteres de escape como \s o \d
-- dentro de expresiones de JS/CSS causan fallos si se interpretan de forma literal.
-- Cambié los templates de JS de `${i.key}` a " .. " para evitar roturas de parsing en Lua.
local HTML_TEMPLATE = [[
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Keybinds — MinimalistDots</title>
<style>
@import url('https://googleapis.com');

:root {
    --bg: %s;
    --surface: %s;
    --surface-2: %s;
    --overlay: %s;
    --text: %s;
    --subtext: %s;
    --mod: %s;
    --mod-dim: rgba(137, 180, 250, 0.15);
    --shift-dim: rgba(249, 226, 175, 0.15);
    --alt-dim: rgba(250, 179, 135, 0.15);
    --media-dim: rgba(245, 194, 231, 0.15);
}

* { box-sizing: border-box; }

body {
    margin: 0;
    background: var(--bg);
    color: var(--text);
    font-family: 'Inter', sans-serif;
    padding: 32px 20px 64px;
}

.wrap { max-width: 880px; margin: 0 auto; }
header { margin-bottom: 24px; }
.eyebrow {
    font-family: 'JetBrains Mono', monospace;
    font-size: 12px;
    letter-spacing: 0.08em;
    color: var(--mod);
    text-transform: uppercase;
    margin: 0 0 6px;
}
h1 { font-size: 26px; font-weight: 600; margin: 0 0 6px; letter-spacing: -0.01em; }

.toolbar { display: flex; margin: 16px 0 24px; }
.search-box { flex: 1; position: relative; }
.search-box input {
    width: 100%;
    font-family: 'Inter', sans-serif;
    font-size: 13px;
    color: var(--text);
    background: var(--surface);
    border: 1px solid var(--overlay);
    border-radius: 8px;
    padding: 10px 12px 10px 36px;
    outline: none;
}
.search-box input:focus { border-color: var(--mod); }
.search-box input::placeholder { color: var(--subtext); }
.search-box svg {
    position: absolute;
    left: 12px;
    top: 50%;
    transform: translateY(-50%);
    width: 14px;
    height: 14px;
    stroke: var(--subtext);
}

section.group {
    margin-bottom: 26px;
    background: var(--surface);
    border-radius: 12px;
    border: 1px solid var(--overlay);
    overflow: hidden;
}
.group-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 12px 16px;
    border-left: 3px solid var(--mod);
    background: var(--surface-2);
}
.group-title { font-family: 'JetBrains Mono', monospace; font-size: 13px; font-weight: 500; }
.group-count { font-size: 11px; color: var(--subtext); font-family: 'JetBrains Mono', monospace; }
.rows { padding: 4px 8px; }
.row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    padding: 10px 8px;
    border-radius: 8px;
}
.row:hover { background: var(--surface-2); }
.row + .row { border-top: 1px solid rgba(88,91,112,0.35); }

.combo { display: flex; align-items: center; gap: 4px; font-family: 'JetBrains Mono', monospace; }
.plus { color: var(--subtext); font-size: 12px; }
.chip { font-size: 11px; font-weight: 700; padding: 4px 8px; border-radius: 6px; line-height: 1; }
.chip-mod { background: var(--mod-dim); color: var(--mod); }
.chip-shift { background: var(--shift-dim); color: #f9e2af; }
.chip-alt { background: var(--alt-dim); color: #fab387; }
.chip-key { background: var(--overlay); color: var(--text); }
.chip-media { background: var(--media-dim); color: #f5c2e7; }
.desc { font-size: 13px; color: var(--subtext); text-align: right; }

@media (max-width: 560px) {
    .row { flex-direction: column; align-items: flex-start; gap: 6px; }
    .desc { text-align: left; }
}
</style>
</head>
<body>
<div class="wrap">
    <header>
        <p class="eyebrow">MinimalistDots · Hyprland</p>
        <h1>Mapa de atajos</h1>
    </header>

    <div class="toolbar">
        <div class="search-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            <input type="text" id="search" placeholder="Buscar por tecla, categoría o descripción...">
        </div>
    </div>
    <div id="sections"></div>
</div>

<script>
let kbdData = [];

function cargarJsonDirecto(datos) {
    kbdData = datos;
    renderData(kbdData);
}

function renderData(data) {
    const container = document.getElementById('sections');
    container.innerHTML = '';
    if (data.length === 0) {
        container.innerHTML = '<div style="text-align:center; padding:40px; color:var(--subtext);">No se encontraron atajos.</div>';
        return;
    }
    const groups = {};
    data.forEach(item => {
        const groupName = item.category || item.mod || "Otros";
        if (!groups[groupName]) groups[groupName] = [];
        groups[groupName].push(item);
    });
    for (const [groupTitle, items] of Object.entries(groups)) {
        const section = document.createElement('section');
        section.className = 'group';

        let rowsHtml = items.map(i => {
            return '<div class="row">' +
                        '<div class="combo">' + renderChips(i.mod, i.key) + '</div>' +
                        '<div class="desc">' + i.description + '</div>' +
                   '</div>';
        }).join('');

        section.innerHTML =
            '<div class="group-head">' +
                '<div class="group-title">' + groupTitle + '</div>' +
                '<div class="group-count">' + items.length + ' binds</div>' +
            '</div>' +
            '<div class="rows">' + rowsHtml + '</div>';

        container.appendChild(section);
    }
}

function renderChips(mod, key) {
    let html = '';
    if (mod) {
        const mods = mod.split('+').map(m => m.trim().toUpperCase());
        mods.forEach((m, idx) => {
            let cls = 'chip-key';
            if (m.includes('SUPER') || m.includes('WIN')) cls = 'chip-mod';
            else if (m.includes('SHIFT')) cls = 'chip-shift';
            else if (m.includes('ALT')) cls = 'chip-alt';
            else if (m.includes('CTRL')) cls = 'chip-media';
            html += '<span class="chip ' + cls + '">' + m + '</span>';
            if (idx < mods.length - 1) html += '<span class="plus">+</span>';
        });
        if (key) html += '<span class="plus">+</span>';
    }
    if (key) html += '<span class="chip chip-key">' + key.toUpperCase() + '</span>';
    return html;
}

document.getElementById('search').addEventListener('input', (e) => {
    const term = e.target.value.toLowerCase();
    const filtered = kbdData.filter(i =>
        (i.description && i.description.toLowerCase().includes(term)) ||
        (i.key && i.key.toLowerCase().includes(term)) ||
        (i.mod && i.mod.toLowerCase().includes(term)) ||
        (i.category && i.category.toLowerCase().includes(term))
    );
    renderData(filtered);
});

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        window.close();
    }
});
</script>
</body>
</html>
]]

-- ==========================================
-- 2. PLANTILLA DEL SCRIPT DE PYTHON COMPLETADA
-- ==========================================
local PYTHON_TEMPLATE = [[#!/usr/bin/env python3
import os
import sys
import json
import gi

sys.argv = ["hyprland-keybinds"]

gi.require_version('Gtk', '3.0')
gi.require_version('WebKit2', '4.0')
from gi.repository import Gtk, WebKit2

class KeybindsWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Hyprland Keybinds")
        self.set_default_size(850, 600)

        html_path = os.path.expanduser("~/.config/hypr/scripts/keybinds.html")
        json_path = os.path.expanduser("~/.config/hypr/scripts/keybinds.json")

        if not os.path.exists(html_path):
            sys.exit(1)

        self.json_data = "[]"
        if os.path.exists(json_path):
            try:
                with open(json_path, 'r', encoding='utf-8') as f:
                    self.json_data = json.dumps(json.load(f))
            except Exception:
                pass

        self.webview = WebKit2.WebView()
        self.webview.connect("load-changed", self.on_load_changed)

        self.webview.load_uri("file://" + html_path)

        self.add(self.webview)
        self.connect("destroy", Gtk.main_quit)
        self.show_all()

    def on_load_changed(self, webview, event):
        if event == WebKit2.LoadEvent.FINISHED:
            js_code = f"cargarJsonDirecto({self.json_data});"
            self.webview.run_javascript(js_code, None, None, None)

if __name__ == "__main__":
    win = KeybindsWindow()
    Gtk.main()
]]

-- ==========================================
-- 3. REGISTRO DEL SERVICIO PROPIO
-- ==========================================
Service.define("keybinds-generator", function()
    -- Crear directorios
    os.execute("mkdir -p " .. SCRIPTS_DIR)

    -- Inyectar las variables extraídas de tu 'hyprland.colors' al string
    local html_content = string.format(HTML_TEMPLATE, bg, surface, surface2, overlay, text, subtext, mod_col)

    local f_html = io.open(SCRIPTS_DIR .. "/keybinds.html", "w")
    if f_html then
        f_html:write(html_content)
        f_html:close()
    end
