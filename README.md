# MinimalistDots

Dotfiles minimalistas para **Hyprland** sobre **Arch Linux** (o derivadas), con instalación automatizada, paleta de colores unificada y configuración modular escrita en Lua.

El objetivo es levantar un escritorio Wayland limpio y coherente —Hyprland, Wofi, SwayNC, Foot, Dolphin, Zsh— con un solo comando, y en el idioma que prefieras.

## Características

- **Instalador de un solo comando** (`install.sh`) que orquesta todo el proceso paso a paso a través de `src/scripts/steps.sh`.
- **Selector de idioma** al inicio de la instalación: **Español, English, Français, Deutsch** (con archivo de traducciones adicional en portugués listo para activarse). La elección se recuerda durante toda la instalación en `/tmp/.current_lang`.
- **Backup automático y dinámico**: antes de instalar, el script detecta *todas* las carpetas dentro de `src/.config/` (hypr, foot, dolphin, etc.), hace una copia de tu configuración actual con timestamp en `~/.config/backups_dots/<app>-backups/`, y luego despliega la nueva. Pide una única confirmación antes de tocar nada.
- **Configuración de Hyprland en Lua**, modular y organizada en `general`, `animations`, `env`, `monitors`, `windowrules` y `keybinds`, con overrides personalizados en `~/.config/hypr/custom/` que **nunca se pierden** al reinstalar (se cargan automáticamente después de la config base).
- **Paleta de colores unificada** ("gris frío y colores muted") definida en un único archivo (`src/scripts/utils/palette.sh`) y propagada en tiempo de instalación a Hyprland/hyprlock, Wofi, Rofi (gestor de procesos) y Foot.
- **Servicios de Hyprland en Lua** (`~/.local/bin/MinimalistDots/services/`): Polkit, entorno D-Bus, `footclient`, portapapeles (`cliphist`), notificaciones (SwayNC), `hypridle`, fondo de pantalla persistente, tema de Wofi, exportación de atajos y generación de configs personalizados — todos activables/desactivables comentando una línea en `services/init.lua`.
- **Scripts de usuario** (`~/.local/bin/MinimalistDots/scripts/`) para capturas de pantalla, grabación de pantalla, selector de fondo de pantalla, control de volumen, gestor de procesos (Rofi) y visor de atajos de teclado (Wofi).
- **Zsh listo para usar**: autosugerencias, autocompletado, resaltado de sintaxis y un set de alias (sistema, pacman/paru, git, docker) configurados automáticamente sobre el paquete oficial de Arch (sin clonar repos manualmente).
- **Tema de SDDM** (Catppuccin Mocha/Blue) descargado e instalado automáticamente desde el último release de GitHub.
- **Recarga en caliente**: si Hyprland ya está corriendo, el instalador ejecuta `hyprctl reload` al final y valida que no haya errores de configuración antes de terminar.

## Requisitos

- **Arch Linux** o derivada, con `pacman` (el instalador instala `paru` por ti si no lo tienes).
- Acceso a `sudo`.
- Conexión a internet (se actualizan e instalan paquetes, y se descarga el tema de SDDM desde GitHub).

> ⚠️ El instalador **reemplaza por completo** cualquier configuración existente en `~/.config/hypr`, `~/.config/foot` y `~/.config/dolphinrc` (con backup previo automático), y modifica `~/.zshrc`. Revisa `src/scripts/components/install_packages.sh` para ver la lista completa de paquetes antes de ejecutar.

## Instalación

```bash
git clone https://github.com/David-Peralta-Rd/MinimalistDots.git
cd MinimalistDots
bash install.sh
```

Durante la ejecución se te pedirá:
1. Elegir el idioma de la instalación.
2. Confirmar el reemplazo de las configuraciones detectadas (se hace backup automático de cada una).

El instalador ejecuta, en orden, los componentes definidos en `src/scripts/components/`:

| Paso | Componente | Descripción |
|------|------------|-------------|
| 1 | `new_folders.sh` | Crea las carpetas necesarias en `$HOME` (`.config/hypr/hyprland`, `.local/bin/MinimalistDots/...`, etc.) |
| 2 | `install_packages.sh` | Actualiza el sistema, instala `paru` y todos los paquetes agrupados por categoría (Zsh, núcleo, apps, cursores, Dolphin, tema de SDDM, capturas, programación, grabación, gestor de procesos) |
| 3 | `backup_and_install.sh` | Detecta dinámicamente cada carpeta en `src/.config/`, hace backup de su equivalente en `~/.config/` y la reemplaza; además genera `hyprland.lua`, `hypridle.conf`, `hyprlock.conf`, `hyprpaper.conf` y `colors.lua` con la paleta actual |
| 4 | `install_services_and_scripts.sh` | Instala los servicios y scripts de Lua/Bash, configura Zsh y sus plugins, genera el gestor de procesos y los menús de Wofi (portapapeles, atajos, OSD de volumen), e instala el tema de SDDM |

Al finalizar, si detecta una sesión activa de Hyprland, recarga la configuración automáticamente (`hyprctl reload`) y te avisa si hay errores.

## Estructura del proyecto

```
MinimalistDots/
├── install.sh                       # Punto de entrada
├── src/
│   ├── .config/                     # Configuraciones que se copian a ~/.config
│   │   ├── dolphinrc
│   │   ├── foot/foot.ini
│   │   └── hypr/hyprland/           # Configuración de Hyprland en Lua
│   │       ├── general.lua
│   │       ├── animations.lua
│   │       ├── env.lua
│   │       ├── monitors.lua
│   │       ├── vars.lua             # Programas por defecto (terminal, navegador, editor, etc.)
│   │       ├── windowrules.lua
│   │       ├── keybinds.lua
│   │       ├── lib/                 # Librerías internas (keybinder, rules, services, helpers)
│   │       └── services/init.lua    # Lista de servicios activos
│   ├── .local/bin/MinimalistDots/
│   │   ├── services/                # Servicios en Lua (uno por archivo)
│   │   └── scripts/                 # Scripts de usuario en Bash
│   ├── scripts/
│   │   ├── steps.sh                 # Orquesta todo el proceso de instalación
│   │   ├── components/              # Un script por paso de instalación
│   │   └── utils/
│   │       ├── palette.sh           # Paleta de colores única para todo el proyecto
│   │       └── title.sh             # Utilidad para imprimir encabezados
│   └── lang/
│       ├── es.cfg / en.cfg / fr.cfg / de.cfg / pt.cfg
│       └── load_lang.sh
├── LICENSE
└── README.md
```

## Personalización

La configuración base de Hyprland **no debe editarse directamente**: se sobrescribe en cada instalación. En su lugar, crea tus propios archivos en `~/.config/hypr/custom/` (`env.lua`, `monitors.lua`, `windowrules.lua`, `general.lua`, `keybinds.lua`, `services/init.lua`) — se cargan automáticamente después de la configuración base y son seguros de editar.

Para cambiar la paleta de colores global, edita `src/scripts/utils/palette.sh` y vuelve a ejecutar el instalador; Hyprland, hyprlock, Wofi, Rofi y Foot toman los colores desde ahí.

Para activar o desactivar un servicio de Hyprland (por ejemplo, el fondo de pantalla persistente o las notificaciones), comenta o descomenta su línea `require(...)` en `src/.config/hypr/hyprland/services/init.lua`.

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

Todos los mensajes de la instalación están centralizados en `src/lang/*.cfg` y disponibles en Español, Inglés, Francés y Alemán (portugués incluido pero aún no expuesto en el menú de selección). Añadir un idioma nuevo es tan simple como copiar un `.cfg` existente, traducirlo y agregar la opción en `load_lang.sh`.

## Licencia

Este proyecto está bajo la licencia [MIT](LICENSE). Eres libre de usar, copiar, modificar y distribuir el código, incluso con fines comerciales, siempre que mantengas el aviso de copyright original.

## Autor

[David-Peralta-Rd](https://github.com/David-Peralta-Rd)
