# Progreso de ejecución — MinimalistDots

Actualizado: 2026-11-04. Rama: `main`.

## Decisiones y alcance

- Fase 0 y Fase 1 aprobadas por David.
- Orden aprobado: arquitectura → idioma del instalador → idioma del entorno → identidad visual.
- No se ejecutan instalador, `sudo`, `pacman`, Quickshell ni pruebas que modifiquen el sistema.
- Verificación disponible: `bash -n`, `luac -p`, revisión estática y golden. Faltan `shellcheck`,
  `shfmt` y `qmllint`.

## Pasos cerrados

1. `b5246a9 docs: correct architecture audit and golden baseline`
   - Corrige auditoría, inventario, identidad visual y línea base.
2. `a872022 refactor: make installer language selection scalable`
   - `load_lang.sh` descubre catálogos, ordena por `N` con desempate léxico, muestra 7 por página,
     busca por nombre/locale y valida basenames.
   - Los cinco catálogos se renombraron con 100 % de contenido idéntico.
3. `feat: add runtime language infrastructure` (cambio actual)
   - Añade cinco catálogos del entorno con 13 claves `MD_TXT_*` por idioma.
   - Añade `_lang.sh`, `language_selector.sh`, `bk9_language_selector.sh` y `language.lua`.
   - Añade `Language.qml` y la generación de `menu-language.qml`.
   - Implementa `pending_lang`, `active_lang`, `strings.json` y `strings.lua` bajo
     `~/.cache/MinimalistDots/language/`.
   - `bk9` siembra el idioma del instalador, conserva un `active_lang` previo y no borra catálogos
     adicionales del usuario.
   - El servicio promueve pendiente → activo solo en `hyprland.start`; no hay watcher ni demonio.
   - Las rutas nuevas ya están reflejadas en `GOLDEN_TREE.txt`.

## Verificación del paso 3

- `bash -n`: 17 archivos Shell/catálogos correctos.
- `luac -p`: `language.lua` y `services/init.lua` correctos.
- Los cinco catálogos del entorno tienen el mismo conjunto de 13 claves.
- Los cinco catálogos del instalador tienen 72 claves `T_*` tras añadir el mensaje de `bk9`.
- Conteo fuente: 7 QML; instalación prevista: 16 QML (7 fuente + Theme + 8 instancias).
- Conteo fuente: 12 Lua en `services/`, 10 `.sh` en `scripts/`, 5 catálogos del entorno.
- `git diff --check`: correcto.
- No se ejecutó el resolvedor: su salida JSON/Lua y la lectura `FileView` quedan por comprobar en el
  entorno real. El orden `language` → `export_keybinds`/QML en `hyprland.start` también es "verificar".

## Siguiente paso

Paso 4: `refactor: localize core desktop scripts`.

Archivos: `volume.sh`, `select_wallpaper.sh`, `screenshot.sh`, `screenrecord.sh` y `pomodoro.sh`.
Añadir las claves y traducciones de esos dominios a los cinco `language_options/*.cfg`, cargar
`_lang.sh` y sustituir solo textos visibles. Conservar comandos, subcomandos, rutas, variables de
entorno y protocolos. Los catálogos posteriores pueden ser parciales porque español es el respaldo.

Después quedan: notificaciones/procesos (5), wrappers (6), LLM (7), AI (8), QML (9), atajos (10),
identidad (11), SDDM (12), contorno de notificaciones (13) y cierre documental (14).

## Pendientes fuera del alcance aprobado

- Reescritura actual de `custom/services/init.lua`.
- Restauración de `custom/` si falla una pieza de `c3`.
- Borrado de `sync_files` y residuos QML en reinstalaciones.
- Orden léxico de un futuro `bk10`.
- Localización de textos de Hyprlock (permanece bilingüe en este ciclo).
