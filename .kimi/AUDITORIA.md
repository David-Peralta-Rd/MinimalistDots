# 🔍 Auditoría de MinimalistDots (Fase 0 resuelta)

> Documento de referencia para Kimi. Todo lo que sigue fue verificado leyendo el código
> (revisión estática). No se ejecutó nada que modifique el sistema.

---

## 1. Inventario real de archivos

### 1.1 El instalador (`src/setup/`)

```
install.sh                              # entry: borra /tmp/.current_lang, carga load_lang, llama steps.sh
src/setup/scripts/steps.sh              # orquestador: c0→c4 + recarga final de Hyprland
src/setup/scripts/utils/
  u1_title.sh                           # print_title (solo estética de títulos)
  u2_palette.sh                         # paleta única (C_* con #, RAW_* sin #)
  u3_env.sh                             # rutas MD_* + carga idioma + paleta (idempotente)
src/setup/scripts/components/
  c0_sudo_session.sh                    # sudoers timestamp_timeout=-1
  c1_new_folders.sh                     # crea 6 carpetas
  c2_install_packages.sh                # pacman -Syu + paru + 15 listas de paquetes
  c3_backup_and_install.sh              # backup dinámico + despliegue de config/ + piezas hypr
  c4_install_services_and_scripts.sh    # sync services/scripts + ejecuta c4_backup_scripts/*
  c3_backup_hypr/                       # bk1..bk5 (generan con heredoc)
    bk1_hyprland_lua.sh                 # -> ~/.config/hypr/hyprland.lua
    bk2_hypridle.sh                     # -> ~/.config/hypr/hypridle.conf
    bk3_hyprlock.sh                     # -> ~/.config/hypr/hyprlock.conf  ⚠ colores Catppuccin
    bk4_hyprpaper.sh                    # -> ~/.config/hypr/hyprpaper.conf
    bk5_colors_lua.sh                   # -> ~/.config/hypr/hyprland/colors.lua
  c4_backup_scripts/                    # bk1..bk8 (se ejecutan en orden numérico; un fallo no detiene)
    bk1_zsh.sh                          # alias + plugins + edita ~/.zshrc
    bk2_process_manager.sh              # genera scripts/process_manager.sh (heredoc)
    bk3_quickshell.sh                   # copia 6 .qml + genera Theme.qml + 7 menu-*.qml + 5 wrappers
    bk4_sddm_theme.sh                   # descarga Catppuccin Mocha/Blue  ⚠ no usa la paleta
    bk5_docker.sh
    bk6_github.sh
    bk7_99_network_optimization.sh      # 99- es la prioridad sysctl; bk7 se ejecuta antes de bk8
    bk8_ai.sh                           # plantillas + models.env/api_models.conf (una vez) + opencode
src/setup/lang/
  load_lang.sh                          # ⚠ menú y case ESCRITOS A MANO (ítem 3)
  options/                              # 5 archivos, ~88 líneas c/u, misma estructura T_*
    lg1_es.cfg  lg2_en.cfg  lg3_fr.cfg  lg4_de.cfg  lg5_pt.cfg
```

### 1.2 Lo que se instala (`src/hyprland-dots/`)

```
config/
  dolphinrc
  foot/foot.ini                         # colores = paleta (verificado)
  hypr/hyprland/
    general.lua  animations.lua  env.lua  monitors.lua
    windowrules.lua  keybinds.lua  vars.lua
    lib/    init.lua  keybinder.lua  rules.lua  services.lua
    services/init.lua                   # lista de require(...) = "archivo maestro" de servicios
local/bin/MinimalistDots/
  services/                             # 11 .lua: 10 servicios + helper load_direction
    polkit.lua footclient.lua dbus_env.lua clipboard.lua export_keybinds.lua
    notifications.lua create_custom_config.lua hypridle.lua wallpaper.lua
    desktop_clock.lua load_direction.lua
  quickshell/                           # 6 .qml (lógica real)
    MdMenu.qml launcher.qml clock.qml osd-volume.qml notifd.qml pomodoro.qml
  scripts/                              # 8 .sh (textos en español a fuego)
    volume.sh select_wallpaper.sh screenshot.sh screenrecord.sh
    pomodoro.sh notifications_menu.sh llm_menu.sh ai.sh
  ai/                                   # plantillas + examples (no es i18n)
    config/models.env.example  config/api_models.conf.example
    templates/project/{AGENTS.md,CLAUDE.md,SPEC.md,tasks.md,README.md,.gitignore,docs/adr/0001-template.md}
```

---

## 2. Mapa de dependencias (quién llama a quién)

```
install.sh
 └─ load_lang.sh          (elige/escribe /tmp/.current_lang; source del .cfg → T_*)
 └─ steps.sh
     ├─ u3_env.sh         (rutas MD_* + idioma + paleta; idempotente, lo cargan TODOS)
     │   ├─ load_lang.sh
     │   └─ u2_palette.sh
     ├─ u1_title.sh
     ├─ c0 → c1 → c2 → c3 → c4   (c3 puede devolver 10 = cancelado)
     │
     ├─ c3_backup_and_install.sh
     │    └─ por cada app en src/hyprland-dots/config/*:
     │         backup → rm → cp
     │         si app == "hypr": ejecuta c3_backup_hypr/bk*.sh  (HYPR_DIR=$DEST)
     │
     └─ c4_install_services_and_scripts.sh
          ├─ sync_files services/*.lua  → ~/.local/bin/MinimalistDots/services
          ├─ sync_files scripts/*.sh    → ~/.local/bin/MinimalistDots/scripts
          └─ por cada c4_backup_scripts/bk*.sh: bash (un fallo no detiene)
```

**Flujo de la paleta (item 5):**
```
u2_palette.sh (C_*, RAW_*)
  ├─ bk5_colors_lua.sh   → ~/.config/hypr/hyprland/colors.lua  (consume C_*/RAW_*)
  ├─ bk3_quickshell.sh   → ~/.../quickshell/Theme.qml          (consume C_*)
  └─ foot.ini            → colores fijos, coinciden manualmente (NO generados)
```

**Flujo del idioma del instalador (ítems 3):**
```
load_lang.sh
  ├─ lee /tmp/.current_lang (si existe y es válido, reutiliza)
  ├─ si no: menú hardcoded → case hardcoded → escribe /tmp/.current_lang
  └─ source options/$SELECTED_LANG  (set -a) → exporta T_*
```

**Flujo del idioma del entorno instalado (ítems 2 y 4):** ❌ NO EXISTE. Todos los scripts
(`scripts/*.sh`) y QML (`quickshell/*.qml`) llevan el español a fuego. No hay caché, ni selector,
ni `language_options/`.

---

## 3. ¿Cuántos archivos Quickshell hay de verdad? (respuesta al ítem 1)

| Origen | Archivos | Naturaleza |
|--------|----------|------------|
| Repo (`quickshell/`) | 6 `.qml` | lógica real: MdMenu (componente base), launcher, clock, osd-volume, notifd, pomodoro |
| Generado por `bk3_quickshell.sh` | 1 `Theme.qml` | colores (desde paleta) |
| Generado por `bk3_quickshell.sh` | 7 `menu-*.qml` | instancias finas de MdMenu (clipboard, binds, pomodoro, llm, wallpaper, notifications, process) |
| **Total instalado** | **14 `.qml`** | |

**Veredicto: NO son demasiados.** Los 7 `menu-*.qml` no son "código": son 7 bloques de datos
(`prompt`, `ancho`, `alto`, `acento`, `radio`) ya centralizados en una sola función
`write_menu_qml()` dentro de `bk3_quickshell.sh`. La lógica de menú vive en un único `MdMenu.qml`.
No conviene dividirlos más: sería añadir carpetas sin quitar complejidad (viola "menos es más").

**Los 6 `.qml` reales están bien separados por responsabilidad** (launcher, reloj, OSD, notifd,
pomodoro, MdMenu). No requieren subcarpetas.

### ¿Conviene subcategorizar `scripts/` o `services/`? — NO

- `scripts/` (8 `.sh`) y `services/` (11 `.lua`) están planos y con nombres claros.
- Subcategorizarlos rompe rutas ya fijadas en `vars.lua` (`MINIMALISTDOTS .. "/scripts/..."`) y en
  `services/init.lua` (`require("polkit")` con `package.path` apuntando a la carpeta plana).
- Migrar rutas de usuario es justo lo que las restricciones prohíben sin plan de migración.
- La filosofía "menos es más" premia la estructura plana actual.

El bucle de piezas usa orden léxico de glob, no orden numérico general
(`c4_install_services_and_scripts.sh:62-68`). Con `bk1`…`bk9` coincide con el esperado; un futuro
`bk10` quedaría antes de `bk2`. No se cambia en este ciclo porque no afecta al nuevo `bk9`.

### ¿Falta un "archivo maestro por apartado"? — En su mayoría ya existe

| Apartado | Maestro actual | Estado |
|----------|----------------|--------|
| Instalador (rutas/idioma/paleta) | `utils/u3_env.sh` | ✅ ya lo es |
| Pasos de instalación | `steps.sh` | ✅ ya lo es |
| Servicios Hyprland | `services/init.lua` | ✅ ya lo es |
| Config Hyprland | `hyprland.lua` (generado) | ✅ ya lo es |
| Paleta | `u2_palette.sh` | ✅ ya lo es |
| Scripts de usuario | ❌ ninguno | Falta: el ítem 2 lo introduce de forma natural (un loader de idioma compartido = el "maestro" de textos) |
| Menús Quickshell | `bk3_quickshell.sh` (`write_menu_qml`) | ✅ ya centralizado, aunque mezcla generación de QML + wrappers (ver problema P4) |

---

## 4. Problemas encontrados, ordenados por impacto

### P1 — Identidad visual dividida entre varias fuentes de color (ítem 5) · impacto ALTO
El proyecto dice tener "paleta única" (`u2_palette.sh`, gris frío + muted), pero conviven varias
fuentes de color:
- **Hyprland + Quickshell + Foot**: paleta principal (`#1e222a`, verde `#7ec7a2`, azul `#7aa2f7`…).
  Foot coincide manualmente, pero no se genera desde la paleta (`foot.ini:15-42`).
- **`hyprlock.conf`** (`bk3_hyprlock.sh:12-68`): colores Catppuccin Mocha fijos.
- **SDDM** (`bk4_sddm_theme.sh:8-16`): tema Catppuccin Mocha/Blue.
- **`MdMenu.qml:19,253,259,388`**: `#89b4fa`, `#f7768e` y `#1a1b26` hardcodeados, fuera de `Theme`.

**Dirección aprobada por David** (`.kimi/IDENTIDAD_VISUAL.md`): base gris + negro neutra, acentos
muted, bordes hairline, radios unificados, sombras suaves solo en QML y slot de logo vacío en
`~/.cache/MinimalistDots/brand/`. El ítem 5 unifica paleta y tokens, actualiza Foot y Hyprlock,
alinea SDDM y elimina los hardcodes.

### P2 — El entorno instalado no tiene sistema de idioma compartido (ítems 2 y 4) · impacto ALTO
No existe selector, caché ni loader para los textos propios del entorno. El reloj ya usa
`Qt.locale()` y el lanzador recibe nombres localizados de `.desktop`, pero eso no constituye un
sistema i18n del proyecto. El inventario incluye scripts, QML, wrappers, Lua y textos generados.

Varios textos también sirven como protocolo (`notifications_menu.sh:40,51,55-57`,
`llm_menu.sh:128,309,328-345`, `ai.sh:128-131,348-353`, `bk2_process_manager.sh:30-46`). La
localización debe separar identificadores/salidas de máquina estables de las etiquetas visibles.

### P3 — La protección de archivos del usuario tiene excepciones · impacto ALTO
- `create_custom_config.lua:22-44,47-57` reescribe `custom/services/init.lua` en cada inicio.
- Un fallo de una pieza `c3_backup_hypr/bk*.sh` puede impedir la restauración posterior de
  `custom/` (`c3_backup_and_install.sh:85-99`).
- `sync_files` borra todos los `*.lua`/`*.sh` directos del destino, incluidos archivos añadidos por
  el usuario (`c4_install_services_and_scripts.sh:15-37`).
- `bk3_quickshell.sh:53-64` no elimina QML obsoletos al reinstalar.

Quedan fuera de los cinco ítems salvo que David apruebe una corrección aparte. `bk9` no debe
reproducir estos comportamientos: preservará idiomas adicionales y el estado activo existente.

### P4 — `bk3_quickshell.sh` mezcla 4 operaciones · impacto MEDIO
Un solo archivo: (a) copia QML, (b) genera `Theme.qml`, (c) genera 7 `menu-*.qml` y (d) genera 5
wrappers (`bk3_quickshell.sh:56-64,79-103,113-145,152-315`). Recomendación aprobada: mantenerlo;
la generación ya está centralizada y dividir no elimina complejidad por sí solo.

### P5 — `load_lang.sh` hardcodeado y con validación insuficiente (ítem 3) · impacto MEDIO
Menú + `case` escritos a mano (`load_lang.sh:27-46`). Añadir idioma exige editar dos sitios. Los 5
`.cfg` definen 71 claves `T_*` cada uno; cuatro tienen 88 líneas y el inglés 89.

La caché y `SELECTED_LANG` deben validarse contra basenames descubiertos antes de `source`
(`load_lang.sh:15-27,49-58`). Una opción inválida selecciona inglés (`:42`): se conserva ese
comportamiento para no alterar el ítem 3 fuera del alcance aprobado.

### P6 — Textos de atajos bilingües y generados en Lua · impacto MEDIO
No solo son las descripciones de `keybinds.lua:9-83`: también hay categorías y textos generados en
`lib/keybinder.lua:12-19,40-55,67-68`. Todos llegan a `keybinds.json` y `show_binds`. La propuesta
aprobada usa claves internas estables y exporta categorías/descripciones en el idioma activo.

### P7 — La descripción inicial de `notifd.qml` era imprecisa · impacto MEDIO
El ancho fijo `360` sí existe (`notifd.qml:17-21`), pero el alto por contenido ya existe (`:160-164`)
y la mayoría de secciones vacías ya colapsan (`:184-205,237-311`). La fila superior es la excepción.
El hover detiene el temporizador, pero reinicia la espera completa al salir en vez de conservar el
tiempo restante (`:154-158`). El rediseño debe partir de este comportamiento real.

### P8 — `hyprlock.conf` con textos bilingües a fuego · impacto BAJO
`bk3_hyprlock.sh:41,63` genera `Hola, $USER` y `Ingresa contraseña / Enter password...`. Quedan
bilingües en este ciclo por decisión de alcance; el ítem 5 solo unifica su presentación.

### P9 — Verificación estática limitada en este entorno · impacto en el MÉTODO
Faltan `shellcheck`, `shfmt`, `qmllint`, `node`. Solo hay `bash -n`, `luac -p`, `lua` y `qs`.
No se ejecuta el instalador ni Quickshell en el equipo. Lo que dependa de versiones concretas de
Hyprland, Quickshell o SDDM queda marcado "verificar".

---

## 5. Decisiones aprobadas por David (Fase 0 cerrada)

### (a) El idioma del instalador siembra el del entorno
La correspondencia se hace por locale estable, no por `N` ni por basename. Si no hay equivalente,
usa `es`. La siembra la ejecuta `bk9_language_selector.sh` durante `c4`, no `load_lang.sh` al
mostrar el menú; cancelar `c3` no cambia el idioma del entorno. Los catálogos `T_*` del instalador
y `MD_TXT_*` del entorno permanecen independientes.

### (b) Convención sin paréntesis y significado de N
Formato aprobado: `lgN_Nombre_del_idioma_es-CO.cfg`; también se admite locale de solo idioma
(`lg1_Espanol_es.cfg`). Los paréntesis se eliminan para simplificar comandos, parsing y escritura
manual, no porque rompan globs (no lo hacen).

`N` es un entero positivo y clave manual de orden; no debe ser único ni contiguo. Orden numérico por
`N` y desempate léxico por nombre completo. La numeración visible se genera sin exponer `lgN_`.

### (c) "Mostrar 7 idiomas" es el viewport
Siete entradas visibles a la vez, con desplazamiento/paginación y buscador por nombre o siglas. No
es un límite de idiomas soportados.

### (d) "Solo al reiniciar" exige separar pendiente y activo
Leer una elección mutable al arrancar cada script o `qs` aplicaría el cambio antes de reiniciar.
Por eso el diseño aprobado separa:
- `language_options/`: catálogos.
- `~/.cache/MinimalistDots/language/pending_lang`: elección que hará el selector.
- `active_lang`: idioma que consumen los scripts.
- `strings.json` y `strings.lua`: instantáneas resueltas para QML y la exportación de atajos.

El selector solo cambia el pendiente y avisa que se aplicará al reiniciar sesión. Un `language.lua`
one-shot promueve pendiente → activo al iniciar sesión y regenera las instantáneas. Scripts y QML
leen solo el activo, de modo que incluso las invocaciones nuevas conservan el idioma anterior hasta
el reinicio. QML usa `FileView`; `Quickshell.env()` solo consulta entorno, no archivos.

El servicio one-shot es necesario para esta semántica estricta; no es un demonio ni un watcher. El
orden entre activación, exportación de atajos y arranque de `qs` queda marcado "verificar".

### (e) Español como respaldo por clave
El resolvedor carga primero `es` y después el idioma activo. Una clave ausente hereda español. Si
también falta en español, es un error del catálogo base, no una cadena vacía válida. Si falta todo
el idioma activo o es inválido, se usa `es` con aviso.

### (f) Los 5 `.cfg` actuales se renombran
Se usa una sola convención en el ítem 3: `lg1_Espanol_es.cfg`, `lg2_English_en.cfg`,
`lg3_Francais_fr.cfg`, `lg4_Deutsch_de.cfg`, `lg5_Portugues_pt.cfg`. README y referencias se
actualizan en el mismo cambio. No requiere migración del entorno instalado: estos archivos son del
instalador y `/tmp/.current_lang` es temporal.

---

## 6. Criterio del Filtro de Admisión aplicado a cada pieza nueva (aprobado en Fase 1)

| Pieza nueva | ¿Se puede vivir sin ella? | ¿< 5 MB y ~0 CPU/RAM? | ¿Mantenimiento manual? | Veredicto |
|-------------|---------------------------|------------------------|------------------------|----------------------|
| Loader de idioma en scripts (`_lang.sh`) | No (es la base del ítem 2) | ✅ ~1 KB, corre 1 vez por invocación | No (automático) | ✅ ADMITIR |
| `language_options/` + `bk9_language_selector.sh` | No (ídem) | ✅ textos, ~KBs | Solo traducir un archivo al añadir idioma (es el objetivo) | ✅ ADMITIR |
| `language.lua` one-shot de idioma | No, si "solo al reiniciar" es estricto | ✅ one-shot en el inicio de sesión; sin residente | No | ✅ ADMITIR |
| Caché `pending_lang`/`active_lang` e instantáneas | No (separan elección y aplicación) | ✅ archivos pequeños regenerados una vez por sesión | No | ✅ ADMITIR |
| `Language.qml` + `menu-language.qml` | No (consumo QML y selector sin duplicar lectores) | ✅ un lector y una instancia fina; sin watcher | No | ✅ ADMITIR |
| Tokens visuales en `Theme.qml`/`MdMenu.qml` | No (ítem 5) | ✅ reutiliza lo existente | No | ✅ ADMITIR |

---
