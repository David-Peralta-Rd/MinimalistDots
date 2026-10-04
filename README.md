# MinimalistDots

Dotfiles minimalistas para **Hyprland** sobre **Arch Linux** (o derivadas), con instalación automatizada, paleta de colores unificada y configuración modular escrita en Lua.

El objetivo es levantar un escritorio Wayland limpio y coherente —Hyprland, Wofi, SwayNC, Foot, Dolphin, Zsh— con un solo comando, y en el idioma que prefieras.

## Características

- **Instalador de un solo comando** (`install.sh`) que orquesta todo el proceso paso a paso a través de `src/setup/scripts/steps.sh`.
- **Selector de idioma** al inicio de la instalación: **Español, English, Français, Deutsch, Português**. La elección se recuerda durante toda la instalación en `/tmp/.current_lang`.
- **Backup automático y dinámico**: antes de instalar, el script detecta *todo* lo que haya en `src/hyprland-dots/config/` (carpetas como hypr o foot, y archivos sueltos como `dolphinrc`), hace una copia de tu configuración actual con timestamp en `~/.config/backups_dots/<app>-backups/`, y luego despliega la nueva. Pide una única confirmación antes de tocar nada.
- **Configuración de Hyprland en Lua**, modular y organizada en `general`, `animations`, `env`, `monitors`, `windowrules` y `keybinds`, con overrides personalizados en `~/.config/hypr/custom/` que **nunca se pierden** al reinstalar (el instalador los restaura desde el backup y se cargan automáticamente después de la config base).
- **Paleta de colores unificada** ("gris frío y colores muted") definida en un único archivo (`src/setup/scripts/utils/u2_palette.sh`) y propagada en tiempo de instalación a Hyprland (`colors.lua`), Wofi y Rofi (gestor de procesos). Los valores de Foot coinciden con la paleta y están fijos en `foot.ini`.
- **Servicios de Hyprland en Lua** (`~/.local/bin/MinimalistDots/services/`): Polkit, entorno D-Bus, `footclient`, portapapeles (`cliphist`), notificaciones (SwayNC), `hypridle`, fondo de pantalla persistente, tema de Wofi, exportación de atajos y generación de configs personalizados — todos activables/desactivables comentando una línea en `services/init.lua`.
- **Scripts de usuario** (`~/.local/bin/MinimalistDots/scripts/`) para capturas de pantalla, grabación de pantalla, selector de fondo de pantalla, control de volumen, gestor de procesos (Rofi) y visor de atajos de teclado (Wofi).
- **Zsh listo para usar**: autosugerencias, autocompletado, resaltado de sintaxis y un set de alias (sistema, pacman/paru, git, docker) configurados automáticamente sobre el paquete oficial de Arch (sin clonar repos manualmente).
- **Tema de SDDM** (Catppuccin Mocha/Blue) descargado e instalado automáticamente desde el último release de GitHub.
- **Recarga en caliente**: si Hyprland ya está corriendo, el instalador ejecuta `hyprctl reload` al final y valida que no haya errores de configuración antes de terminar.

## Requisitos

- **Arch Linux** o derivada, con `pacman` (el instalador instala `paru` por ti si no lo tienes).
- Acceso a `sudo`.
- Conexión a internet (se actualizan e instalan paquetes, y se descarga el tema de SDDM desde GitHub).

> ⚠️ El instalador **reemplaza por completo** cualquier configuración existente en `~/.config/hypr`, `~/.config/foot` y `~/.config/dolphinrc` (con backup previo automático), y modifica `~/.zshrc`. Revisa `src/setup/scripts/components/c2_install_packages.sh` para ver la lista completa de paquetes antes de ejecutar.

## Instalación

```bash
git clone https://github.com/David-Peralta-Rd/MinimalistDots.git
cd MinimalistDots
bash install.sh
```

Durante la ejecución se te pedirá:
1. Elegir el idioma de la instalación.
2. Confirmar el reemplazo de las configuraciones detectadas (se hace backup automático de cada una).

El instalador ejecuta, en orden, los componentes definidos en `src/setup/scripts/components/`:

| Paso | Componente | Descripción |
|------|------------|-------------|
| 0 | `c0_sudo_session.sh` | Configura sudo para que no vuelva a pedir la clave durante la instalación (se hace primero para cubrir la instalación de paquetes) |
| 1 | `c1_new_folders.sh` | Crea las carpetas necesarias en `$HOME` (`.config/hypr/hyprland`, `.local/bin/MinimalistDots/{scripts,services,wofi}`, etc.) |
| 2 | `c2_install_packages.sh` | Actualiza el sistema, instala `paru` (repos de CachyOS o compilado del AUR en Arch) y todos los paquetes agrupados por categoría |
| 3 | `c3_backup_and_install.sh` | Detecta lo que hay en `src/hyprland-dots/config/`, hace backup de su equivalente en `~/.config/` y lo reemplaza. Para Hyprland ejecuta además las piezas de `c3_backup_hypr/` (`hyprland.lua`, `hypridle.conf`, `hyprlock.conf`, `hyprpaper.conf`, `colors.lua`) y restaura `custom/` |
| 4 | `c4_install_services_and_scripts.sh` | Instala los servicios y scripts de Lua/Bash y ejecuta las piezas de `c4_backup_scripts/`: Zsh, gestor de procesos, menús de Wofi, tema de SDDM, Docker sin sudo y Git/GitHub (login por navegador + firma GPG; pregunta antes de empezar y se omite sin terminal interactiva). Si una pieza falla, las demás continúan y se informa al final |

Para agregar una pieza nueva basta con crear un `bkN_*.sh` en `c3_backup_hypr/` o `c4_backup_scripts/` (se ejecutan en orden numérico, del 1 al 9). Todas las rutas y la carga de idioma y paleta viven en `src/setup/scripts/utils/u3_env.sh`, por lo que cualquier pieza puede ejecutarse sola.

Si respondes que **no** en la confirmación del paso 3, el instalador se detiene sin tocar tus configuraciones (Enter equivale a confirmar).

Al finalizar, si detecta una sesión activa de Hyprland, recarga la configuración automáticamente (`hyprctl reload`) y te avisa si hay errores.

## Estructura del proyecto

```
MiniTest/
├── install.sh                          # Punto de entrada
├── src/
│   ├── hyprland-dots/                  # LO QUE SE INSTALA (los dotfiles)
│   │   ├── config/                     # Se copia a ~/.config
│   │   │   ├── dolphinrc
│   │   │   ├── eww/  foot/  qt6ct/
│   │   │   └── hypr/hyprland/          # Configuración de Hyprland en Lua
│   │   │       ├── general.lua  animations.lua  env.lua  monitors.lua
│   │   │       ├── vars.lua            # Programas por defecto y rutas de scripts
│   │   │       ├── windowrules.lua  keybinds.lua
│   │   │       ├── lib/                # Librerías internas (keybinder, rules, services, helpers)
│   │   │       └── services/init.lua   # Lista de servicios activos
│   │   └── local/bin/MinimalistDots/   # Se copia a ~/.local/bin/MinimalistDots
│   │       ├── services/               # Servicios en Lua (uno por archivo)
│   │       └── scripts/                # Scripts de usuario en Bash
│   └── setup/                          # EL INSTALADOR
│       ├── lang/
│       │   ├── load_lang.sh
│       │   └── options/lg1_es.cfg ... lg5_pt.cfg
│       └── scripts/
│           ├── steps.sh                # Orquesta todo el proceso
│           ├── utils/
│           │   ├── u1_title.sh         # Encabezados
│           │   ├── u2_palette.sh       # Paleta de colores única
│           │   └── u3_env.sh           # Rutas (MD_*), idioma y paleta compartidos
│           └── components/
│               ├── c0_sudo_session.sh
│               ├── c1_new_folders.sh
│               ├── c2_install_packages.sh
│               ├── c3_backup_and_install.sh
│               ├── c3_backup_hypr/     # bk1..bk5: hyprland.lua, hypridle, hyprlock, hyprpaper, colors.lua
│               ├── c4_install_services_and_scripts.sh
│               └── c4_backup_scripts/  # bk1..bk6: zsh, process_manager, wofi, sddm_theme, docker, github
├── LICENSE
└── README.md
```

## Personalización

La configuración base de Hyprland **no debe editarse directamente**: se sobrescribe en cada instalación. En su lugar, crea tus propios archivos en `~/.config/hypr/custom/` (`env.lua`, `monitors.lua`, `windowrules.lua`, `general.lua`, `keybinds.lua`, `services/init.lua`) — se cargan automáticamente después de la configuración base y son seguros de editar.

Para cambiar la paleta de colores global, edita `src/setup/scripts/utils/u2_palette.sh` y vuelve a ejecutar el instalador; Hyprland (`colors.lua`), Wofi y Rofi toman los colores desde ahí.

Para activar o desactivar un servicio de Hyprland (por ejemplo, el fondo de pantalla persistente o las notificaciones), comenta o descomenta su línea `require(...)` en `src/hyprland-dots/config/hypr/hyprland/services/init.lua`.

## Atajos de teclado principales

La tecla modificadora por defecto es `SUPER` (definida en `vars.lua`). Consulta el listado completo, agrupado por categoría, con `SUPER+SHIFT+ALT+K`.

| Atajo | Acción |
|-------|--------|
| `SUPER+T` | Abrir terminal |
| `SUPER+B` | Abrir navegador |
| `SUPER+E` | Abrir gestor de archivos |
| `SUPER+A` | Abrir menú de aplicaciones |
| `SUPER+C` | Abrir editor de código |
| `SUPER+V` | Abrir portapapeles |
| `SUPER+Q` | Cerrar ventana |
| `SUPER+L` | Bloquear sesión |
| `SUPER+G` | Gestor de procesos |
| `SUPER+SHIFT+ALT+T` | Elegir fondo de pantalla |
| `SUPER+SHIFT+P` | Captura de pantalla completa |
| `SUPER+ALT+S` | Grabar pantalla (área, con audio) |

## Idiomas

Todos los mensajes de la instalación están centralizados en `src/setup/lang/options/*.cfg` y disponibles en Español, Inglés, Francés y Alemán (incluido portugués). Añadir un idioma nuevo es tan simple como copiar un `.cfg` existente de `options/`, traducirlo y agregar la opción en `src/setup/lang/load_lang.sh`.

## Licencia

Este proyecto está bajo la licencia [MIT](LICENSE). Eres libre de usar, copiar, modificar y distribuir el código, incluso con fines comerciales, siempre que mantengas el aviso de copyright original.

## Autor

[David-Peralta-Rd](https://github.com/David-Peralta-Rd)
