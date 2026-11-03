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
    bk7_99_network_optimization.sh      # prefijo 99- para ordenar al final
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
  services/                             # 11 .lua (uno por servicio)
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
    templates/project/{AGENTS.md,CLAUDE.md,SPEC.md,tasks.md,README.md,docs/adr/0001-template.md}
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

### ¿Falta un "archivo maestro por apartado"? — En su mayoría ya existe

| Apartado | Maestro actual | Estado |
|----------|----------------|--------|
| Instalador (rutas/idioma/paleta) | `utils/u3_env.sh` | ✅ ya lo es |
| Pasos de instalación | `steps.sh` | ✅ ya lo es |
| Servicios Hyprland | `services/init.lua` | ✅ ya lo es |
| Config Hyprland | `hyprland.lua` (generado) | ✅ ya lo es |
| Paleta | `u2_palette.sh` | ✅ ya lo es |
| Scripts de usuario | ❌ ninguno | Falta: el ítem 2 lo introduce de forma natural (un loader de idioma compartido = el "maestro" de textos) |
| Menús Quickshell | `bk3_quickshell.sh` (`write_menu_qml`) | ✅ ya centralizado, aunque "mezcla" generación de QML + wrappers (ver problema P3) |

---

## 4. Problemas encontrados, ordenados por impacto

### P1 — Identidad visual dividida entre dos paletas (ítem 5) · impacto ALTO
El proyecto dice tener "paleta única" (`u2_palette.sh`, gris frío + muted), pero conviven **tres
fuentes de color**:
- **Hyprland + Quickshell + Foot**: paleta correcta (`#1e222a`, verde `#7ec7a2`, azul `#7aa2f7`…).
- **`hyprlock.conf`** (`bk3_hyprlock.sh`): colores Catppuccin Mocha `rgba(1e1e2ecc)`, `cdd6f4`,
  `89b4fa`, `f38ba8`, `313244`, `585b70`. No coinciden.
- **SDDM** (`bk4_sddm_theme.sh`): tema Catppuccin Mocha/Blue. No coincide.
- **Dentro de `MdMenu.qml`**: color de acento por defecto `#89b4fa` (azul Catppuccin) y colores
  del botón "borrar todo" `#f7768e` / `#1a1b26` (paleta TokyoNight). Hardcodeados, no usan `Theme`.
- Esto es exactamente el "minimalismo dividido" que describe el BACKLOG ítem 5.

**Dirección ya decidida por David (ver `.kimi/IDENTIDAD_VISUAL.md`)**: minimalismo macOS sin los
tres puntos — base **gris + negro** neutra, acentos muted suavizados, bordes hairline `1px`
`rgba(255,255,255,0.08)`, radios unificados (14/12/10/8), sombras suaves solo en QML, y un **slot de
logo cacheado vacío por ahora** en `~/.cache/MinimalistDots/brand/logo.svg` (consumido vía
`Theme.logo`). El ítem 5 debe: (1) unificar todo en `Theme.qml`+`MdMenu.qml`, (2) eliminar los
hardcodes de color, (3) neutralizar `u2_palette.sh` hacia gris+negro, (4) regenerar `hyprlock.conf`
desde la paleta y (5) alinear/reemplazar el tema SDDM (Catppuccin) con la marca.

### P2 — El entorno instalado no tiene sistema de idioma (ítems 2 y 4) · impacto ALTO
Cero soporte i18n fuera del instalador. Ver `INVENTARIO_TEXTOS.md` para la lista completa
(`scripts/*.sh`, `quickshell/*.qml`, `bk2_process_manager.sh`, `bk3_quickshell.sh`).

### P3 — `bk3_quickshell.sh` mezcla 3 responsabilidades · impacto MEDIO
Un solo archivo hace: (a) copiar QML, (b) generar `Theme.qml`, (c) generar 7 `menu-*.qml`,
(d) generar 5 wrappers de shell (`md_menu`, `md_launcher`, `md_volume_osd`, `show_binds`,
`md_cliphist_list`). El BACKLOG ítem 1 anticipa que esto puede dividirse. Recomendación: mantenerlo
salvo que el ítem 5/4 lo exija; dividir solo si se extrae la generación de menús (paso pequeño).

### P4 — `load_lang.sh` hardcodeado (ítem 3) · impacto MEDIO (esperado)
Menú + `case` escritos a mano (5 idiomas). Añadir idioma exige editar 2 sitios. Es justo lo que el
ítem 3 corrige. Los 5 `.cfg` tienen la misma estructura `T_*` (~88 líneas), así que el refactor es
solo del script, no de los datos.

### P5 — Textos de `keybinds.lua` bilingües a fuego · impacto BAJO-MEDIO
Cada descripción es "Abrir navegador / Open browser". Es una decisión deliberada, pero si el ítem 2
quiere "diálogos en el idioma elegido", estos también lo necesitan (se exponen en `show_binds`
vía `keybinds.json`). Aclarar con David si se localizan o se dejan bilingües.

### P6 — `hyprlock.conf` con textos a fuego · impacto BAJO
`text = Hola, $USER` y `placeholder_text = Ingresa contraseña / Enter password...`. Candidatos a
i18n si se quiere coherencia (requiere regenerar el `.conf` desde un loader).

### P7 — Verificación estática limitada en este entorno · impacto en el MÉTODO
Faltan `shellcheck`, `shfmt`, `qmllint`, `node`. Solo hay `bash -n`, `luac -p`, `lua` y `qs`.
Kimi debe marcar "verificar" y no afirmar sobre versiones de Quickshell/Hyprland que no pueda probar.

---

## 5. Decisiones pendientes — con recomendación (Fase 0, una sola tanda)

> Kimi debe plantearlas a David y validar estas recomendaciones, no darlas por aprobadas.

### (a) ¿El idioma del instalador siembra el del entorno, o son independientes?
**Recomendación: que lo siembre.** El instalador, al elegir idioma, escribe además el archivo de
caché del entorno (`~/.local/bin/MinimalistDots/language_options/current_lang`) con el idioma
elegido (mapeando `lgN_xx.cfg` → el archivo equivalente de `language_options/`). Si no hay
equivalente, usa `es`.
- Por qué: coherencia total (el usuario no elige dos veces) y un solo punto de verdad al instalar.
- Los dos sistemas de archivos siguen siendo independientes (el del instalador usa `T_*` en
  `/tmp`; el del entorno usa `language_options/` en el home), solo se conecta en el momento de
  instalar. Esto respeta el Filtro de Admisión (no añade proceso ni demonio).

### (b) Convención `lgN_NOMBRE-(siglas)` y significado de N
**Recomendación: quitar los paréntesis.** Propongo `lgN_Nombre_del_idioma_es-CO.cfg` (separador
`_` en vez de `(...)`). Los paréntesis obligan a entrecomillar en bash, rompen globs y ordenado, y
complican QML y el buscador. El guion del locale (`es-CO`) es seguro en nombres de archivo; solo los
paréntesis son el problema.
- **N = clave de orden de aparición, manual.** Se usa solo para ordenar la lista inicial; se muestra
  SIN el prefijo `lgN_`. Si dos archivos repiten N, desempate por nombre completo (orden léxico).
  El script NO asume que N sea único ni contiguo.
- Alternativa (si David insiste en paréntesis): mantenerlos pero documentar que toda manipulación
  debe entrecomillar. No recomendada.

### (c) "Mostrar 7 idiomas": ¿viewport o tope?
**Recomendación: es el viewport (máximo visible a la vez), NO un tope de idiomas soportados.**
Todo el ítem 3 es "escalable" (añadir idiomas sin tocar código); un tope de 7 lo contradiría.
7 = líneas visibles a la vez, con desplazamiento y buscador que filtra por siglas o nombre.

### (d) Cómo se aplica "solo al reiniciar" (caché, quién lee, cuándo)
**Recomendación:**
- **Se guarda**: `~/.local/bin/MinimalistDots/language_options/current_lang` (o
  `~/.cache/MinimalistDots/lang` si se prefiere fuera del bin). Contiene el nombre de archivo del
  idioma activo (ej. `es`).
- **Quién lee y cuándo**:
  - **Scripts bash**: al arrancar, hacen `source` de un loader único (p. ej.
    `scripts/_lang.sh`) que lee `current_lang` y hace `source` del archivo de
    `language_options/` correspondiente. Cero proceso residente.
  - **QML**: leen el idioma en el arranque del proceso `qs` (al abrir el menú/widget). Opción A:
    `qs` lee un archivo resuelto generado en el login; Opción B: `MdMenu`/widgets leen el archivo
    de `language_options/` por `Quickshell.env` o un `FileView` (ya usan `FileView` en MdMenu).
  - **`servicio.lua`** (opcional, recomendado): un servicio Hyprland one-shot enganchado a
    `hyprland.start` (igual que `export_keybinds.lua`) que (re)genera un `strings.qml` o un
    `lang.json` resuelto desde `language_options/` + `current_lang`. **No** es un proceso siempre
    activo: corre una vez por login dentro del hook ya existente. Esto cumple "no en tiempo real".
- **Qué ve el usuario si cambia sin reiniciar**: el idioma anterior (los procesos ya lanzados
  conservan el viejo) y un aviso "reinicie sesión para aplicar" (notify-send). Los procesos nuevos
  tras reiniciar leen el nuevo valor.

### (e) Variable que falta en un idioma
**Recomendación: español (`es`) como respaldo/base.** Cada archivo de `language_options/` solo
define las variables que traduce; el loader carga primero `es` y luego el idioma elegido, de modo
que toda clave ausente cae en español. Coincide con la decisión del autor (variables en español) y
evita pantallas vacías.

### (f) Los 5 `.cfg` actuales: ¿se renombran o conviven?
**Recomendación: se renombran a la convención nueva** en el ítem 3 (p. ej. `lg1_Espanol_es-ES.cfg`,
`lg2_English_en-US.cfg`, …), en el mismo cambio. No conviven dos convenciones: el `load_lang.sh`
nuevo debe leer UNA sola. El mapeo `lgN_xx.cfg` antiguo solo lo usa el instalador, que se reescribe
en el mismo paso (no rompe a usuarios ya instalados: el entorno instalado no usa esos `.cfg`).

---

## 6. Criterio del Filtro de Admisión aplicado a cada pieza nueva (borrador, a validar)

| Pieza nueva | ¿Se puede vivir sin ella? | ¿< 5 MB y ~0 CPU/RAM? | ¿Mantenimiento manual? | Veredicto preliminar |
|-------------|---------------------------|------------------------|------------------------|----------------------|
| Loader de idioma en scripts (`_lang.sh`) | No (es la base del ítem 2) | ✅ ~1 KB, corre 1 vez por invocación | No (automático) | ✅ ADMITIR |
| `language_options/` + `bk9_language_selector.sh` | No (ídem) | ✅ textos, ~KBs | Solo traducir un archivo al añadir idioma (es el objetivo) | ✅ ADMITIR |
| `servicio.lua` one-shot de idioma | Sí se puede prescindir (los QML podrían leer directo) | ✅ one-shot en `hyprland.start` | No | ⚠️ OPCIONAL (elegir el camino más simple que cumpla) |
| Cache `current_lang` | No (define qué idioma) | ✅ un archivo de bytes | No | ✅ ADMITIR |
| Tokens visuales en `Theme.qml`/`MdMenu.qml` | No (ítem 5) | ✅ reusa lo existente | No | ✅ ADMITIR |

---
