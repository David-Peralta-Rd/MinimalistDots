# MinimalistDots

Dotfiles de Hyprland (0.55+, config nativa en **Lua**) con un instalador modular
en Bash. Esta rama (`main`) es la reconstrucción limpia de `v1.0`: misma base
que ya funcionaba, arquitectura de scripts ordenada y **una sola fuente de
verdad para los colores**.

## Cómo instalar

```bash
./setup.sh
```

El instalador te pregunta el idioma y ejecuta, en orden:

1. `src/scripts/backup_and_clean.sh` — respalda tu configuración actual.
2. `src/scripts/colors.sh` — genera la paleta global (`src/colors/palette.sh`).
3. `src/scripts/install_configs.sh` — configs "estáticas" (foot, etc.), ya
   coloreadas con la paleta.
4. `src/scripts/install_hypr.sh` — instala paquetes de Hyprland y corre
   **todos** los `src/scripts/installs_hypr/*.sh` (orden alfabético; no importa,
   son generadores de texto puro, nada se ejecuta entre sí).
5. `src/scripts/install_complex.sh` — apps y utilidades adicionales
   (`src/scripts/complex_install/*.sh`): dolphin, zsh, screenshot, etc.

## Cómo cambiar la paleta de colores

Edita **un solo archivo**: `src/scripts/colors.sh` (los valores `C_*` / `RAW_*`
dentro del heredoc). Vuelve a correr `./setup.sh` (o solo
`src/scripts/colors.sh` seguido de `install_hypr.sh` e `install_configs.sh` si
no quieres reinstalar paquetes).

Ese único cambio se propaga automáticamente a:

- `hyprland/colors.lua` → bordes de ventana (`general.lua`), y en tiempo de
  arranque de Hyprland a **waybar**, **wofi** (lanzador) y **swaync**
  (notificaciones), vía los servicios en `hyprland/services/*.lua`.
- `hyprlock.conf` (pantalla de bloqueo).
- `foot.ini` (terminal).
- Los menús extra de Wofi: portapapeles y visor de atajos
  (`~/.config/wofi/themes/`).
- `dolphin` (imv/mpv) y el gestor de procesos (rofi).

**Nunca edites a mano** `hyprland/colors.lua` ni ningún archivo dentro de
`~/.config/wofi/themes/`: se regeneran en cada instalación/arranque y se
perderían tus cambios. Para overrides permanentes usa
`~/.config/hypr/custom_minimalist/` (ver abajo).

## Arquitectura de `~/.config/hypr/`

```
hyprland.lua              <- punto de entrada, solo requires
hypridle.conf / hyprlock.conf / hyprpaper.conf
hyprland/
  colors.lua               (generado, fuente única de color para Lua)
  general.lua               gaps, bordes, input
  animations.lua            curvas y animaciones
  env.lua                    variables de entorno
  monitors.lua               monitores
  windowrules.lua            reglas de ventana
  vars.lua                   apps por defecto (terminal, launcher, etc.)
  keybinds.lua                atajos, con categorías (ver abajo)
  lib/
    init.lua                 helpers globales (HOME, require_if_exists)
    keybinder.lua             DSL para registrar atajos + categorías + export JSON
    rules.lua                 DSL para reglas de ventana
    services.lua               registro de servicios (hl.on hooks)
  services/
    init.lua                  requiere todos los servicios activos
    waybar.lua, wofi_theme.lua, notifications.lua, ...
    export_keybinds.lua        vuelca keybinds.lua a ~/.cache/hypr/keybinds.json
  scripts/
    select_wallpaper.sh
```

**Regla de responsabilidad única** que evita que "algo se rompa sin saber
por qué": cada archivo generado tiene **un solo** script que lo escribe.
Antes había casos (wofi base, visor de atajos) donde dos generadores distintos
escribían el mismo archivo y el último en ejecutarse ganaba silenciosamente.
Eso ya no pasa.

## Categorías de atajos (`lib/keybinder.lua`)

```lua
local Keybinder = require("hyprland.lib.keybinder")
local kb = Keybinder.new("SUPER")

kb:category("Aplicaciones")
kb:exec("RETURN", "Abrir terminal", "footclient")

kb:category("Sistema")
kb:dispatch("Q", "Cerrar ventana", "killactive")
```

Cada atajo queda con su `category`. `services/export_keybinds.lua` los
vuelca a `~/.cache/hypr/keybinds.json` en cada arranque, y
`~/.local/bin/minimaldots/show_binds` (Wofi + `jq`) los agrupa por
categoría al mostrarlos.

## Personalización sin tocar el core

`hyprland.lua` intenta cargar, después de cada módulo base, un archivo
opcional en `~/.config/hypr/custom_minimalist/` (`env.lua`, `monitors.lua`,
`windowrules.lua`, `general.lua`, `keybinds.lua`). Si existe, se carga; si no,
se ignora. Ahí van tus overrides personales — nunca en los archivos generados.

## Notas de la reconstrucción (main vs v1.0)

Restaurado / agregado respecto al estado en que estaba `main`:

- `animations.lua`, `general.lua`, `env.lua`, `monitors.lua`,
  `windowrules.lua` — no se generaban.
- `hyprland/scripts/select_wallpaper.sh` — no se instalaba.
- Paleta unificada: antes `colors.lua` (Lua) y `palette.sh` (Bash) eran dos
  paletas hardcodeadas independientes; ahora `colors.lua` se genera a partir
  de `palette.sh`.
- Bug de rgba en Wofi (`echo "rgba($r, $g, b, $alpha)"`, con una `b` literal)
  corregido.
- Rutas de paleta que apuntaban al script generador en vez de al archivo
  generado, corregidas.
- Servicio duplicado de visor de atajos (Lua + Bash pisándose) — unificado
  en una sola implementación.
- `dolphin.sh` y el gestor de procesos ahora usan la paleta global en vez de
  colores Catppuccin hardcodeados sueltos.
