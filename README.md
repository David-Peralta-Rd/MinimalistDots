# MinimalistDots

Dotfiles minimalistas para **Hyprland** sobre **Arch Linux** (o derivadas), con instalación automatizada, paleta de colores unificada y configuración modular escrita en Lua.

El objetivo es levantar un escritorio Wayland limpio y coherente —Hyprland, Quickshell, SwayNC, Foot, Dolphin, Zsh— con un solo comando, y en el idioma que prefieras.

## Características

- **Instalador de un solo comando** (`install.sh`) que orquesta todo el proceso paso a paso a través de `src/setup/scripts/steps.sh`.
- **Selector de idioma** al inicio de la instalación: **Español, English, Français, Deutsch, Português**. La elección se recuerda durante toda la instalación en `/tmp/.current_lang`.
- **Backup automático y dinámico**: antes de instalar, el script detecta *todo* lo que haya en `src/hyprland-dots/config/` (carpetas como hypr o foot, y archivos sueltos como `dolphinrc`), hace una copia de tu configuración actual con timestamp en `~/.config/backups_dots/<app>-backups/`, y luego despliega la nueva. Pide una única confirmación antes de tocar nada.
- **Configuración de Hyprland en Lua**, modular y organizada en `general`, `animations`, `env`, `monitors`, `windowrules` y `keybinds`, con overrides personalizados en `~/.config/hypr/custom/` que **nunca se pierden** al reinstalar (el instalador los restaura desde el backup y se cargan automáticamente después de la config base).
- **Paleta de colores unificada** ("gris frío y colores muted") definida en un único archivo (`src/setup/scripts/utils/u2_palette.sh`) y propagada en tiempo de instalación a Hyprland (`colors.lua`) y a Quickshell (`Theme.qml`). Los valores de Foot coinciden con la paleta y están fijos en `foot.ini`.
- **Servicios de Hyprland en Lua** (`~/.local/bin/MinimalistDots/services/`): Polkit, entorno D-Bus, `footclient`, portapapeles (`cliphist`), notificaciones (Quickshell), `hypridle`, fondo de pantalla persistente, reloj de escritorio (Quickshell), exportación de atajos y generación de configs personalizados — todos activables/desactivables comentando una línea en `services/init.lua`.
- **Interfaz 100 % Quickshell** (`~/.local/bin/MinimalistDots/quickshell/`, sin wofi, eww ni rofi): lanzador de aplicaciones (`SUPER+A`, con iconos y búsqueda por relevancia), portapapeles, visor de atajos, selector de fondos con miniaturas, gestor de procesos, OSD de volumen, reloj de escritorio, Pomodoro y notificaciones con historial. Todos comparten `MdMenu.qml` y los colores de `Theme.qml`, que se genera desde la paleta.
- **Scripts de usuario** (`~/.local/bin/MinimalistDots/scripts/`) para capturas de pantalla, grabación de pantalla, selector de fondo de pantalla, control de volumen, gestor de procesos y un **Pomodoro** minimalista (`SUPER+P`): pregunta concentración, descanso y sesiones y muestra un widget compacto abajo al centro (minutos restantes, sesión y una barra fina de progreso), semitransparente hasta que pasas el mouse por encima. El temporizador vive dentro del propio widget; botones en columna a la derecha (pausa/reanudar, reiniciar fase, detener), y también funcionan el clic sobre el número (pausa), clic derecho (reiniciar) y clic medio (detener). Al terminar la concentración el widget se **agranda y se centra en la pantalla** (sin quitarte el teclado) para que no se te pase el descanso, y suena un aviso; con *Minimizar* vuelve al widget pequeño hasta la siguiente fase. Pulsa `SUPER+P` otra vez para detenerlo.

  El sonido se configura solo al inicio de `pomodoro.sh` (`SOUND_URL`, o `SOUND_FILE` con un audio tuyo, `SOUND_VOLUME`): se descarga una vez con curl a `~/.cache/MinimalistDots/pomodoro`, se convierte a mp3 si hace falta y el proceso del reproductor termina solo al acabar el audio. Pruébalo con `pomodoro.sh sound`.
- **IA local con llama.cpp** (`SUPER+ALT+SHIFT+L`, `scripts/llm_menu.sh`): menú de Quickshell para elegir el modelo de chat (puerto 8080) y el de autocompletado (puerto 8081), con aviso si no caben en RAM y opción de repetir la última selección. Busca `.gguf` en `~/models`, `~/.cache/llama.cpp` y `~/.cache/huggingface/hub`, y ofrece descargar modelos recomendados (se editan en `PRESETS`). Pulsa el atajo otra vez para apagar los servidores y liberar la RAM. Log: `~/.cache/llm-servers/menu.log`.
- **IA para desarrollo** (`scripts/ai.sh`, alias `ai-up`, `ai-down`, `ai-doctor`, `ai-bench`, `ai-code`, `ai-new`...): capa de agentes encima del menú anterior. Enciende los modelos **sin menús** desde `~/.config/ai/models.env` (puertos, hilos, contexto y rutas en un solo archivo, el mismo que usan Continue y los agentes), diagnostica el equipo, mide los tokens/s reales con `llama-bench`, abre **OpenCode** ya conectado a tu modelo local y crea proyectos nuevos (plantillas + primer commit + repo en GitHub con `gh`). Sin servicios en segundo plano: todo es bajo demanda. Detalle en [IA para desarrollo](#ia-para-desarrollo-aish).
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
| 1 | `c1_new_folders.sh` | Crea las carpetas necesarias en `$HOME` (`.config/hypr/hyprland`, `.local/bin/MinimalistDots/{scripts,services,quickshell}`, etc.) |
| 2 | `c2_install_packages.sh` | Actualiza el sistema, instala `paru` (repos de CachyOS o compilado del AUR en Arch) y todos los paquetes agrupados por categoría |
| 3 | `c3_backup_and_install.sh` | Detecta lo que hay en `src/hyprland-dots/config/`, hace backup de su equivalente en `~/.config/` y lo reemplaza. Para Hyprland ejecuta además las piezas de `c3_backup_hypr/` (`hyprland.lua`, `hypridle.conf`, `hyprlock.conf`, `hyprpaper.conf`, `colors.lua`) y restaura `custom/` |
| 4 | `c4_install_services_and_scripts.sh` | Instala los servicios y scripts de Lua/Bash y ejecuta las piezas de `c4_backup_scripts/`: Zsh, gestor de procesos, menús y widgets de Quickshell, tema de SDDM, Docker sin sudo, Git/GitHub (login por navegador + firma GPG; pregunta antes de empezar y se omite sin terminal interactiva) y optimización de red (BBR + CAKE, tarjeta de red persistente y DNS con caché). Si una pieza falla, las demás continúan y se informa al final |

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
│   │   │   ├── foot/  qt6ct/
│   │   │   └── hypr/hyprland/          # Configuración de Hyprland en Lua
│   │   │       ├── general.lua  animations.lua  env.lua  monitors.lua
│   │   │       ├── vars.lua            # Programas por defecto y rutas de scripts
│   │   │       ├── windowrules.lua  keybinds.lua
│   │   │       ├── lib/                # Librerías internas (keybinder, rules, services, helpers)
│   │   │       └── services/init.lua   # Lista de servicios activos
│   │   └── local/bin/MinimalistDots/   # Se copia a ~/.local/bin/MinimalistDots
│   │       ├── services/               # Servicios en Lua (uno por archivo)
│   │       ├── quickshell/             # QML: MdMenu, launcher, clock, pomodoro, osd-volume
│   │       ├── ai/                     # Plantillas de proyecto, agente de logística y models.env de ejemplo
│   │       └── scripts/                # Scripts de usuario en Bash (llm_menu.sh, ai.sh, pomodoro.sh...)
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
│               └── c4_backup_scripts/  # bk1..bk8: zsh, process_manager, quickshell, sddm_theme, docker, github, network, ai
├── LICENSE
└── README.md
```

## Personalización

La configuración base de Hyprland **no debe editarse directamente**: se sobrescribe en cada instalación. En su lugar, crea tus propios archivos en `~/.config/hypr/custom/` (`env.lua`, `monitors.lua`, `windowrules.lua`, `general.lua`, `keybinds.lua`, `services/init.lua`) — se cargan automáticamente después de la configuración base y son seguros de editar.

Para cambiar la paleta de colores global, edita `src/setup/scripts/utils/u2_palette.sh` y vuelve a ejecutar el instalador; Hyprland (`colors.lua`) y Quickshell (`Theme.qml`) toman los colores desde ahí.

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

## Quickshell: añadir o ajustar un menú

- **Nuevo menú tipo dmenu**: añade una línea `write_menu_qml "nombre" "Título" ancho alto "$C_ACCENT_X" radio` en `bk3_quickshell.sh` y úsalo con `lista | md_menu nombre --prompt "Título"` (`--raw` si las líneas llevan TAB, como cliphist).
- **Widgets propios** (reloj, Pomodoro...): crea un `.qml` en `src/hyprland-dots/local/bin/MinimalistDots/quickshell/`; el instalador copia todos los `.qml` de esa carpeta.
- **Probar sin reinstalar**: `qs -p ~/.local/bin/MinimalistDots/quickshell/launcher.qml` (los errores salen en la terminal).

## Notificaciones (Quickshell)

`quickshell/notifd.qml` es el servidor de notificaciones (reemplaza a SwayNC): tarjetas minimalistas arriba a la derecha con borde según urgencia (rojo = crítica), barra de progreso (`notify-send -h int:value:40`), botones de acción y cierre con clic. Todas se guardan en `~/.local/state/MinimalistDots/notifications.jsonl`.

| Atajo | Acción |
| --- | --- |
| `SUPER+N` | Historial: elige una entrada y se copia (resumen + cuerpo) al portapapeles |
| `SUPER+SHIFT+N` | No molestar (se guardan en el historial sin mostrarse; las críticas sí salen) |
| `SUPER+CTRL+N` | Cierra las notificaciones visibles |

Solo puede haber un servidor de notificaciones: desinstala `swaync` (`paru -Rns swaync`) y borra `~/.config/swaync`. Ajustes (ancho, duración, máximo en pantalla) al inicio de `notifd.qml`.

## IA local (`llm_menu.sh`)

`ALT+SHIFT+L` elige modelos y levanta `llama-server`. Los modelos que no tengas se **descargan con aria2** (16 conexiones en paralelo; si no está instalado usa curl con una sola), de forma reanudable, con barra de progreso y comprobación de espacio a `~/models`. Si algo falla: `llm_menu.sh doctor` revisa llama-server, red, Hugging Face, disco y RAM; los logs están en `~/.cache/llm-servers/`.

## IA para desarrollo (`ai.sh`)

Prepara el equipo para trabajar con agentes **gratis, con la fuerza de tu propio equipo**. No añade demonios ni servicios de systemd: `llm_menu.sh` sigue siendo el único que arranca `llama-server` (mismos PID, logs y puertos), y `ai.sh` lo maneja sin menús.

```bash
ai-doctor        # revisa herramientas, modelos, puertos, gh y OpenCode (no cambia nada)
ai-up chat       # enciende el modelo de chat/agente (ai-up fim | ai-up all)
ai-status        # qué está corriendo
ai-bench         # llama-bench con tus hilos; guarda el resultado en ~/.cache/llm-servers/
ai-new mi-app    # proyecto nuevo: plantillas, primer commit y repo PRIVADO en GitHub (gh)
ai-code          # (desde la carpeta del proyecto) enciende el modelo si hace falta y abre OpenCode
ai-config        # regenera la config de OpenCode desde models.env (si cambias puertos o modelo)
ai-down          # apaga todo y libera la RAM
```

`ai-new` acepta `--public` (repo público), `--local` (sin GitHub) y `-d "descripción"`. Usa tu sesión de `gh` y tu firma GPG, tal como las deja `bk6_github.sh`; sin sesión de `gh` el proyecto queda solo local y te lo avisa.

- **`~/.config/ai/models.env`** lo crea el instalador **una sola vez** y nunca lo sobrescribe. Ahí van las rutas de tus `.gguf` (por defecto `~/models`, donde descarga el menú), los puertos (si Continue usa otros, cambia aquí y no en VS Code), hilos, contexto y capas de GPU. El menú `SUPER+ALT+SHIFT+L` también respeta puertos, hilos y GPU de ese archivo.
- **API para agentes y Continue**: `llama-server` expone una API compatible con OpenAI en `http://127.0.0.1:8080/v1` (chat; el tool calling va activado con `--jinja`) y `:8081` (autocompletado).
- **Plantillas** en `~/.local/bin/MinimalistDots/ai/templates/` (se reemplazan en cada instalación; copia y edita en tus proyectos): `project/` y `logistics-agent/CLAUDE.md`, un prompt de tech lead con los modos PLANEAR, REVISAR, APRENDER, RETOMAR y VENDER.
- **OpenCode**: `bk8_ai.sh` lo instala (`opencode` de los repos o `opencode-bin` del AUR; un fallo no detiene el instalador) y genera `~/.config/opencode/opencode.json` con un proveedor `llamacpp` apuntando a tu `llama-server`. Si ya tienes ese archivo, solo se reescribe ese proveedor. Lee el `AGENTS.md` de cada proyecto. Claude Code no se instala: es opcional y de pago.
- El instalador no descarga modelos: lo hace el menú.
- Para agregar o cambiar algo: el comportamiento está en `scripts/ai.sh`, el instalador en `c4_backup_scripts/bk8_ai.sh` y los alias en `bk1_zsh.sh`.
