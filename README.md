<div align="center">

# MinimalistDots

**Dotfiles limpios y minimalistas para Hyprland en Arch Linux**

Sin decoraciones exageradas. Sin colores gritones. Solo lo necesario para tener un entorno funcional y agradable para programar.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnu-bash&logoColor=white)
![Hyprland](https://img.shields.io/badge/WM-Hyprland-58E1FF?logo=wayland&logoColor=white)
![Arch Linux](https://img.shields.io/badge/OS-Arch%20Linux-1793D1?logo=archlinux&logoColor=white)
![Idiomas](https://img.shields.io/badge/idioma-ES%20%2F%20EN-blue)

</div>

---

## ✨ Filosofía

Con **MinimalistDots** busco la máxima simplicidad: todo elemento tiene un propósito, nada sobra. No hay animaciones ostentosas ni paletas de colores estridentes; en su lugar, un setup directo, coherente y pensado para trabajar.

## 📦 ¿Qué incluye?

- **[Hyprland](https://hyprland.org/)** como compositor Wayland, configurado con un sistema modular escrito en **Lua** (fácil de leer, extender y mantener).
- **Waybar** como barra de estado.
- **Hyprlock** y **hypridle** para bloqueo de pantalla y suspensión automática, con un lockscreen que captura tu propio fondo de pantalla y le aplica un desenfoque adaptativo.
- **Wofi** como lanzador de aplicaciones.
- **Swaync** para notificaciones.
- **Foot** como terminal, con **Yazi** como gestor de archivos (preconfigurado con controles WASD, montaje de discos vía `udisksctl` y previews de imágenes/video con `imv`/`mpv`).
- **hyprpaper** para el fondo de pantalla.
- **SDDM** como gestor de sesión, habilitado automáticamente.
- Instalador interactivo bilingüe (Español / Inglés) que automatiza todo el proceso: bootstrap del sistema, instalación de paquetes y despliegue de configuraciones.

## 🖥️ Requisitos

- **Arch Linux** (o una derivada compatible, como CachyOS).
- Conexión a internet y una cuenta con privilegios de `sudo`.
- [`paru`](https://github.com/Morganamilo/paru) se instala automáticamente si no lo tienes.

> ⚠️ El instalador ejecuta `pacman -Syu`, modifica `/etc/paru.conf`, crea un archivo en `/etc/sudoers.d/` y **sobrescribe** tu configuración actual de `~/.config/hypr` (haciendo backup antes). Revisa los scripts en `src/scripts/` antes de correrlos si quieres saber exactamente qué hacen en tu sistema.

## 🚀 Instalación

Clona el repositorio y ejecuta el instalador:

```bash
git clone https://github.com/David-Peralta-Rd/MinimalistDots.git
cd MinimalistDots
chmod +x setup.sh
./setup.sh
```

El script te pedirá elegir idioma y luego se encargará de:

1. **Bootstrap del sistema** — actualiza pacman, instala `paru`, configura `sudoers` y ajusta opciones de `hyprpaper`.
2. **Instalación de paquetes** — instala todos los paquetes base definidos en `src/scripts/packages.sh`, además de instalaciones más complejas (Yazi, Zsh, etc.) definidas en `src/scripts/complex_installs/`.
3. **Configuraciones adicionales** — copia las configuraciones de `src/.config/` (por ejemplo Foot) a tu `~/.config`, haciendo backup de lo que ya exista.
4. **Backup e instalación de Hyprland** — respalda tu `~/.config/hypr` actual, copia la nueva configuración y valida que no existan errores con `hyprctl configerrors` antes de recargar.

Al final tendrás una sesión de Hyprland lista para usar tras reiniciar o iniciar sesión.

## 🗂️ Estructura del proyecto

```
MinimalistDots/
├── setup.sh                     # Punto de entrada del instalador
├── LICENSE
└── src/
    ├── lang/                    # Traducciones del instalador (es.cfg / en.cfg)
    ├── scripts/
    │   ├── bootstrap_system.sh  # Prepara el sistema (pacman, paru, sudoers)
    │   ├── install_packages.sh  # Instala paquetes + instalaciones complejas
    │   ├── install_configs.sh   # Copia configs "simples" (ej. foot)
    │   ├── backup_install.sh    # Backup + despliegue de la config de Hyprland
    │   ├── packages.sh          # Listas de paquetes por categoría
    │   └── complex_installs/    # Instalaciones que requieren más que "paru -S"
    │       ├── yazi.sh
    │       └── zsh.sh
    └── .config/
        ├── foot/                # Configuración de la terminal
        └── hypr/
            ├── hyprland.lua     # Config raíz de Hyprland (require de módulos)
            ├── hypridle.conf
            ├── hyprlock.conf
            └── hyprland/
                ├── vars.lua         # Programas por defecto (terminal, browser, etc.)
                ├── keybinds.lua     # Atajos de teclado
                ├── monitors.lua
                ├── windowrules.lua
                ├── general.lua
                ├── animations.lua
                ├── colors.lua
                ├── env.lua
                ├── lib/             # Helpers (keybinder, rules, services)
                ├── services/
                └── scripts/         # ej. select_wallpaper.sh
```

## 📦 Paquetes instalados

| Categoría | Paquetes |
|---|---|
| **Core** | `hyprland`, `xdg-desktop-portal-hyprland`, `hyprpolkitagent`, `sddm`, `swaync`, `hypridle`, `hyprlock`, `waybar`, `hyprpaper`, `wofi`, `git` |
| **Apps** | `foot`, `ark`, `unrar`, `libreoffice-fresh` |
| **Programación** | `visual-studio-code-bin`, `docker`, `uv` |
| **Instalaciones complejas** | `yazi` (+ plugins y previews), `zsh` |

Puedes editar `src/scripts/packages.sh` para agregar o quitar paquetes antes de instalar.

## ⌨️ Atajos de teclado por defecto

La tecla modificadora principal (`mainMod`) es **SUPER**. Se definen en `src/.config/hypr/hyprland/keybinds.lua`:

| Atajo | Acción |
|---|---|
| `SUPER + T` | Abrir terminal (`footclient`) |
| `SUPER + B` | Abrir navegador (`brave`) |
| `SUPER + E` | Abrir gestor de archivos (Yazi) |
| `SUPER + A` | Abrir menú de aplicaciones (`wofi`) |
| `SUPER + C` | Abrir editor de código (`code`) |
| `SUPER + Q` | Cerrar ventana |
| `SUPER + W` | Alternar ventana flotante |
| `SUPER + J` | Alternar dirección del split |
| `SUPER + L` | Bloquear sesión |
| `SUPER + SHIFT + T` | Elegir fondo de pantalla |
| `SUPER + SHIFT + Backspace` | Apagar PC |
| `SUPER + SHIFT + ALT + Backspace` | Reiniciar PC |
| `SUPER + ←/→/↑/↓` | Mover foco entre ventanas |
| `SUPER + 1-0` | Cambiar de espacio de trabajo |
| Rueda del mouse (botones 8/9) | Mover / redimensionar ventana |

## 🎨 Personalización

La configuración de Hyprland **no debe modificarse directamente**: el propio `hyprland.lua` te lo recuerda. En su lugar, crea tus overrides personales en:

```
~/.config/hypr/custom_minimalist/
```

Cualquier archivo `env.lua`, `monitors.lua`, `windowrules.lua`, `general.lua` o `keybinds.lua` que coloques ahí se cargará automáticamente *después* de la configuración base, sin necesidad de tocar los archivos originales. Así, futuras actualizaciones de MinimalistDots no pisan tus cambios.

## 🌐 Idiomas

El instalador está disponible en **Español** e **Inglés**. Las traducciones viven en `src/lang/es.cfg` y `src/lang/en.cfg`; puedes editarlas o añadir un nuevo idioma siguiendo el mismo formato de variables.

## 📄 Licencia

Este proyecto está bajo la licencia [MIT](LICENSE) © 2026 David Peralta.

## 🤝 Contribuciones

¿Tienes ideas para mantener este setup minimalista pero mejor? Los issues y pull requests son bienvenidos.
