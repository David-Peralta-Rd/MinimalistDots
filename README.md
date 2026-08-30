# MinimalistDots

Dotfiles minimalistas para **Hyprland** sobre **Arch Linux**, con instalación automatizada, paleta de colores unificada y configuración modular escrita en Lua.

El objetivo del proyecto es levantar un escritorio Wayland limpio y coherente (Hyprland + Wofi + SwayNC + Alacritty + Thunar) desde cero, con un solo script y soporte de idioma Español/Inglés durante la instalación.

## Características

- **Instalador guiado** (`src/setup.sh`) que ejecuta paso a paso la creación de carpetas, instalación de paquetes, backup de tu configuración actual y despliegue de los dotfiles.
- **Selector de idioma** (Español / Inglés) al inicio de la instalación, con textos centralizados en `src/lang/es.cfg` y `src/lang/en.cfg`.
- **Backup automático** de tu `~/.config/hypr` existente antes de sobrescribirlo, guardado con timestamp en `~/.config/backups_dots/hypr-backups/`.
- **Configuración de Hyprland en Lua**, modular y organizada en `general`, `animations`, `env`, `monitors`, `windowrules` y `keybinds`, con soporte de overrides personalizados en `~/.config/hypr/custom/` que no se pierden al reinstalar.
- **Paleta de colores unificada** (tonos grises fríos y "muted") generada una sola vez y propagada automáticamente a Hyprland, Wofi, SwayNC/notificaciones, `hyprlock` y demás componentes.
- **Servicios de sistema en Lua** (`services/`) para portapapeles (`cliphist`), Polkit, D-Bus, `hypridle`, fondo de pantalla persistente, notificaciones (SwayNC) y tema de Wofi.
- **Scripts auxiliares** para capturas de pantalla, grabación de pantalla, gestor de procesos, selector de fondo de pantalla y visor de atajos de teclado.
- **Instalación de módulos adicionales** (`src/scripts/complex_install/`): tema de SDDM (Catppuccin), configuración de Zsh (autosugerencias, autocompletado, resaltado de sintaxis), Thunar y más.
- **Atajos de teclado** organizados por categorías (Aplicaciones, Sistema, Capturas, Grabación, Multimedia, Navegación) y exportables a JSON para consultarlos desde un menú de Wofi.

## Requisitos

- **Arch Linux** (o derivada) con `pacman` y [`paru`](https://github.com/Morganamilo/paru) instalados.
- Acceso a `sudo`.
- Conexión a internet (se instalan y actualizan paquetes durante el proceso).

> ⚠️ El script de instalación **desinstala** algunos paquetes considerados innecesarios (`yay`, `foot`, `fish`, `kitty`, `firefox`, `yay-bin`) y **reemplaza por completo** tu configuración actual de Hyprland en `~/.config/hypr` (con backup previo). Revisa `src/scripts/_two_install_packages.sh` antes de ejecutar si usas alguno de esos paquetes.

## Instalación

```bash
git clone git@github.com:David-Peralta-Rd/MinimalistDots.git
cd MinimalistDots/src
bash setup.sh
```

Durante la ejecución se te pedirá:
1. Elegir el idioma de la instalación (Español o Inglés).
2. Confirmar el reemplazo de tu configuración actual de Hyprland (se crea un backup automáticamente).

El instalador ejecuta, en orden:

| Paso | Script | Descripción |
|------|--------|-------------|
| 1 | `_one_dirs.sh` | Crea las carpetas necesarias en `$HOME` |
| 2 | `_two_install_packages.sh` | Actualiza el sistema, desinstala paquetes no usados e instala todos los paquetes requeridos |
| 3 | `_three_backud_install.sh` | Hace backup de `~/.config/hypr`, genera la paleta de colores y despliega la configuración base de Hyprland |
| 4 | `_four_hyprland.sh` | Instala scripts auxiliares y genera los servicios de sistema (Lua) |
| 5 | `_five_install_scripts.sh` | Ejecuta los módulos de instalación adicionales (`complex_install/`) |

## Estructura del proyecto

```
MinimalistDots/
├── src/
│   ├── setup.sh                     # Punto de entrada de la instalación
│   ├── config/
│   │   └── hypr/hyprland/           # Configuración de Hyprland en Lua
│   │       ├── general.lua
│   │       ├── animations.lua
│   │       ├── env.lua
│   │       ├── monitors.lua
│   │       ├── vars.lua             # Programas por defecto (terminal, navegador, editor, etc.)
│   │       ├── windowrules.lua
│   │       ├── lib/                 # Librerías internas (keybinder, rules, services)
│   │       └── services/            # Definición de servicios que arrancan con Hyprland
│   ├── scripts/
│   │   ├── _one_dirs.sh
│   │   ├── _two_install_packages.sh
│   │   ├── _three_backud_install.sh
│   │   ├── _four_hyprland.sh
│   │   ├── _five_install_scripts.sh
│   │   └── complex_install/         # Módulos opcionales (SDDM theme, Zsh, Thunar, capturas, etc.)
│   └── lang/
│       ├── es.cfg
│       ├── en.cfg
│       └── load_lang.sh
└── README.md
```

## Personalización

La configuración base **no debe editarse directamente**: cualquier cambio se perdería al reinstalar. En su lugar, el instalador genera automáticamente overrides vacíos en `~/.config/hypr/custom/` (`env.lua`, `monitors.lua`, `windowrules.lua`, `general.lua`, `keybinds.lua`, etc.) que se cargan después de la configuración base y sí son seguros de editar.

Para cambiar la paleta de colores, edita `src/colors/palette.sh` (generado en la primera instalación) y vuelve a ejecutar el instalador; todos los módulos (Hyprland, Wofi, SwayNC, hyprlock) toman los colores desde ahí.

## Atajos de teclado principales

La tecla modificadora por defecto es `SUPER`. Algunos atajos destacados (ver el listado completo con `SUPER+SHIFT+ALT+K`):

| Atajo | Acción |
|-------|--------|
| `SUPER+T` | Abrir terminal |
| `SUPER+B` | Abrir navegador |
| `SUPER+E` | Abrir gestor de archivos |
| `SUPER+A` | Abrir menú de aplicaciones |
| `SUPER+C` | Abrir editor de código |
| `SUPER+Q` | Cerrar ventana |
| `SUPER+L` | Bloquear sesión |
| `SUPER+SHIFT+ALT+T` | Elegir fondo de pantalla |
| `SUPER+SHIFT+P` | Captura de pantalla completa |
| `SUPER+ALT+S` | Grabar pantalla (área, con audio) |

## Idiomas

Todos los mensajes de la instalación están disponibles en Español e Inglés. La selección se guarda temporalmente en `/tmp/.current_lang` para que los subscripts ejecutados de forma independiente usen el mismo idioma.

## Licencia

Este proyecto está bajo la licencia [MIT](LICENSE). Eres libre de usar, copiar, modificar y distribuir el código, incluso con fines comerciales, siempre que mantengas el aviso de copyright original.

## Autor

[David-Peralta-Rd](https://github.com/David-Peralta-Rd)
