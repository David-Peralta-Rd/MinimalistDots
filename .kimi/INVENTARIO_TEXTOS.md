# 🗂️ Inventario de textos a fuego (candidatos a i18n — ítem 2)

> Lista verificada leyendo el código. Agrupa por archivo con línea. Los textos del **instalador**
> ya están en `T_*` (no se listan aquí salvo excepciones). Lo que sigue es lo que NO tiene i18n:
> los scripts/QML del **entorno instalado** + textos sueltos del instalador.

Leyenda de tipo:
- `notify` = título/cuerpo de `notify-send` o `notify()`
- `menu` = prompt/opción de `md_menu`
- `qml` = texto visible dentro del widget QML
- `cli` = salida de terminal / uso
- `keybind` = descripción de atajo

---

## `scripts/*.sh` (entorno instalado)

### `volume.sh`
| Línea | Texto | Tipo |
|-------|-------|------|
| 22 | `LABEL="Mute"` | qml (OSD) |

### `select_wallpaper.sh`
| Línea | Texto | Tipo |
|-------|-------|------|
| 15 | `--prompt "Fondo de pantalla"` | menu |

### `screenshot.sh`
| Línea | Texto | Tipo |
|-------|-------|------|
| 20–34 | `USAGE()` (Uso, Opciones, Flags…) | cli |
| 75,77 | `notify-send -a "Screenshot"` | notify |
| 84 | `"No hay herramienta de edición instalada (swappy/satty)."` | notify |
| 107,184 | `"Captura guardada"` / `"Guardada en $save_dir…"` | notify |
| 112 | `"Error"` / `"No se pudo abrir la herramienta de edición"` | notify |
| 116 | `"Error"` / `"Fallo al tomar la captura de pantalla"` | notify |
| 127 | `"OCR"` / `"Procesando texto de la imagen..."` | notify |
| 134 | `"OCR Exitoso"` / `"Texto copiado al portapapeles:\n$text"` | notify |
| 136,140 | `"OCR Error"` / `"No se pudo detectar texto…"` / `"Fallo al tomar…"` | notify |
| 152 | `"Escaner QR"` / `"Procesando código QR..."` | notify |
| 159 | `"QR Detectado"` / `"Contenido copiado al portapapeles:\n$qr_result"` | notify |
| 162,165 | `"QR Error"` / `"No se encontró ningún código QR"` / `"Fallo al tomar…"` | notify |

### `screenrecord.sh`
| Línea | Texto | Tipo |
|-------|-------|------|
| 17–30 | `USAGE()` | cli |
| 40,42 | `notify-send -a "Screen Recorder"` | notify |
| 55 | `"Grabación Detenida"` / `"Procesando y guardando el video..."` | notify |
| 86 | `"Error de Grabación"` / `"No se encontró gpu-screen-recorder instalado."` | notify |
| 92 | `"Screen Recorder"` / `"No había ninguna grabación en curso."` | notify |
| 120 | `"Grabación Cancelada"` / `"No se seleccionó ninguna área."` | notify |
| 129 | `"Grabación Iniciada"` / `"Presiona el atajo de nuevo para detener."` | notify |
| 135 | `"Grabación Guardada"` / `"Guardada en: $save_path"` | notify |

### `pomodoro.sh`
| Línea | Texto | Tipo |
|-------|-------|------|
| 44 | `notify-send -a "Pomodoro"` | notify |
| 180 | `"Pomodoro"` / `"Ya está activo."` | notify |
| 188 | `ask "Concentración (min)"` + opciones `25 min`… | menu |
| 189 | `ask "Descanso (min)"` + opciones `5 min`… | menu |
| 190 | `ask "Sesiones"` + opciones `4 sesiones`… | menu |
| 209 | `"Pomodoro (prueba)"` / `"6 s de concentración…"` | notify |
| 224 | `"Pomodoro detenido"` | notify |
| 239 | `Uso: … {toggle\|start\|stop\|pause\|restart\|sound\|test}` | cli |

### `notifications_menu.sh`
| Línea | Texto | Tipo |
|-------|-------|------|
| 23 | `say()` con `-a "Historial"` | notify |
| 28 | `"Falta $1"` / `"Instálalo para usar el historial."` | notify |
| 40 | `"🔔 Desactivar No molestar"` / `"🔕 Activar No molestar"` | menu |
| 51 | `"🗑️ Borrar historial"` | menu |
| 52 | `--prompt "Notificaciones — Enter copia"` | menu |
| 67 | `"Copiado al portapapeles"` | notify |
| 73 | `"Demonio de notificaciones apagado"` | notify |
| 76 | `"No molestar activado"` / `"Se guardan en el historial sin mostrarse."` | notify |
| 78 | `"No molestar desactivado"` | notify |
| 84 | `"Historial borrado"` | notify |
| 93 | `Uso: … {history\|dnd\|dismiss\|clear}` | cli |

### `llm_menu.sh` (el de más texto)
| Línea | Texto | Tipo |
|-------|-------|------|
| 32–37 | `CAT_CODE/CAT_THINK/CAT_GEN/CAT_LIGHT/CAT_FIM/CAT_LOCAL` | menu |
| 128 | `NONE_LABEL="— Ninguno —"` | menu |
| 137–139 | `notify()` con `-a "LLM local"` | notify |
| 309 | `back="← Volver a categorías"`, `all_label="Todos los modelos"`, `dl_label="Ya descargados"` | menu |
| 357 | opciones de contexto `16K — equilibrado`… | menu |
| 454,466 | notificaciones de descarga/espacio | notify |
| 471–474 | notificación "Descargando…" | notify |
| 497–499 | `progress_notify "Descargando…"` | notify |
| 509,515,519 | "Falló la descarga…"/"Descarga incompleta…"/"Modelo descargado" | notify |
| 554 | `"LLM local: faltan programas"` / `"Instala: …"` | notify |
| 585–626 | `doctor()` salida completa | cli |
| 644,685,721,750,752 | `"Ya está activo."` / `"No elegiste ningún modelo."` / `"LLM local iniciando…"` / `"LLM local listo"` / `"LLM local: problemas"` | notify |
| 665–666 | `"↻ Repetir: …"`, `"⚙ Elegir manualmente"` | menu |
| 696–697 | `"Continuar de todos modos"` / `"Cancelar"` | menu |
| 837,850 | `"Descarga cancelada"` / `"LLM local apagado"` | notify |
| 865 | `Uso: …` | cli |

### `ai.sh`
| Línea | Texto | Tipo |
|-------|-------|------|
| 59–108 | `cmd_doctor()` salida completa (Herramientas, Configuración, Servidores…) | cli |
| 139,142 | `"Midiendo…"` / `"Guardado en…"` | cli |
| 162–205 | `cmd_new()` mensajes (`creado ./…`, `siguiente:`, `aviso:`) | cli |
| 314–318 | `pick_from_stdin()` prompt `"Número (Enter = cancelar): "` | cli |
| 366,386–387 | `"OpenCode: ¿qué modelo usar?"` / `"Continuar de todos modos"` / `"Cancelar"` | menu |
| 397–421 | `cmd_code()` notas (`nota:`, `en OpenCode escribe /models…`) | cli |

---

## `quickshell/*.qml` (entorno instalado)

### `MdMenu.qml`
| Línea | Texto | Tipo |
|-------|-------|------|
| 130–131 | `"Error al borrar"` / `"Revisa /tmp/md_menu.log"` | qml |
| 258 | `"¿Seguro? Click otra vez"` / `"🧹 Borrar todo"` | qml |

### `pomodoro.qml`
| Línea | Texto | Tipo |
|-------|-------|------|
| 71 | `notify("Descanso", "Sesión " + session + " de " + total + " terminada.")` | notify |
| 73 | `notify("Pomodoro completado 🎉", "Terminaste las " + total + " sesiones.")` | notify |
| 79 | `notify("Sesión " + session + " de " + total, "A concentrarse.")` | notify |
| 115 | `notify("Pomodoro iniciado", "Sesión 1 de " + total)` | notify |
| 280 | `"⏸  En pausa"` / `"☕  Hora de descansar"` | qml |
| 298–299 | `"Sesión " + … + " completada"` / `" · último descanso"` | qml |
| 307 | `"Levántate, estírate y mira a lo lejos."` | qml |
| 332–335 | botones `"▶ Reanudar"`, `"❚❚ Pausar"`, `"↻ Reiniciar"`, `"▾ Minimizar"`, `"✕ Detener"` | qml |

### `notifd.qml`
| Línea | Texto | Tipo |
|-------|-------|------|
| 22 | `ignoredApps: ["Historial"]` (app ignorada, coincide con `notifications_menu.sh`) | qml |
| 213 | `appName.toUpperCase()` (no traducible, dato) | — |
| 223 | `"✕"` (símbolo) | — |

### `clock.qml`
| Línea | Texto | Tipo |
|-------|-------|------|
| 43 | `Qt.locale().toString(...)` — **ya es locale-aware**; se puede atar al idioma elegido | qml |

---

## Instalador (textos sueltos NO cubiertos por `T_*`)

### `bk2_process_manager.sh` (genera `scripts/process_manager.sh`)
| Línea | Texto | Tipo |
|-------|-------|------|
| 30 | `"📱 Aplicaciones Día a Día (GUI)"` / `"⚙️ Procesos del Sistema / Fondo"` | menu |
| 31 | `--prompt "Gestor"` | menu |
| 35 | `--prompt "Cerrar App"` | menu |
| 37 | `--prompt "Matar Proceso"` | menu |
| 50 | `"Process Manager"` / `"Process Finished"` / `"Process closed with PID: …"` | notify |
| 52 | `"Process Manager"` / `"Error"` / `"The process could not be closed …"` | notify |

### `bk3_quickshell.sh` (prompts de menú + wrappers)
| Línea | Texto | Tipo |
|-------|-------|------|
| 139–145 | prompts: `"📋 Portapapeles"`, `"⌨️  Atajos de Teclado"`, `"🍅 Pomodoro"`, `"🤖 IA local"`, `"🖼  Fondo de pantalla"`, `"🔔 Notificaciones"`, `"⚙️  Gestor"` | menu |
| 179 | `md_menu`: `-a "Menú"` / `"Error"` / `"quickshell (qs) no está instalado."` | notify |
| 204 | `md_launcher`: `-a "Lanzador"` / `"Error"` / `"quickshell (qs)…"` | notify |
| 228 | `show_binds`: `-a "Atajos"` / `"Error"` / `"jq no está instalado."` | notify |
| 233 | `show_binds`: `-a "Atajos"` / `"Atajos no encontrados"` / `"No se detectó $JSON_FILE"` | notify |

### `bk3_hyprlock.sh` (genera `hyprlock.conf`)
| Línea | Texto | Tipo |
|-------|-------|------|
| 41 | `text = Hola, $USER` | lock |
| 63 | `placeholder_text = <i>Ingresa contraseña / Enter password...</i>` | lock |

### `keybinds.lua` (descripciones → `keybinds.json` → `show_binds`)
| Línea | Texto | Tipo |
|-------|-------|------|
| 10–73 | todas las descripciones bilingües `"Abrir navegador / Open browser"`… | keybind |

---

## Adiciones verificadas en la Fase 0

### Textos omitidos en archivos ya inventariados

- `notifications_menu.sh:73`: cuerpo `Reinicia la sesión o ejecuta: qs -p $QML`.
- `MdMenu.qml:131` y `pomodoro.qml:48-50`: nombres de aplicación `Menú` y `Pomodoro`.
- `notifd.qml:22,38`: `Historial` es un identificador interno de aplicación, no texto visible; debe
  permanecer sincronizado con `notifications_menu.sh:23,76` aunque los avisos se traduzcan.
- `bk2_process_manager.sh:20,22,27`: etiquetas visibles `Class`, `PID`, `RAM` y `CPU`.
- `bk3_quickshell.sh:166`: uso `md_menu <nombre> [--prompt texto] [--raw]`.

### `keybinds.lua` y `lib/keybinder.lua`

Además de las descripciones explícitas de `keybinds.lua:10-73`:

- Categorías visibles en `keybinds.lua:9,21,38,47,55,67,78`.
- `(sin descripción)` y `General` en `lib/keybinder.lua:12-19`.
- `Enfocar ventana`, `Mover ventana`, `Workspaces`, `Ir al escritorio` y
  `Mover ventana al escritorio` en `lib/keybinder.lua:40-55`.
- Categoría `Multimedia` de los atajos de hardware en `lib/keybinder.lua:67-68`.

Los valores `left/right/up/down` son argumentos del dispatcher y texto visible a la vez
(`lib/keybinder.lua:40-45`): la clave interna debe separarse de su traducción.

### `llm_menu.sh`

- Notas de presets y etiquetas visibles: `:47-80,223-250,282-289`.
- Prompts `Contexto del chat`, `LLM local`, modelos y aviso de RAM: `:358,667,676-677,697`.
- Salida `status`: `:629-637`.
- Cuerpos de notificaciones de arranque, errores y apagado: `:721-752,837,850,859`.
- Salida CLI completa de `up`: `:759-827`.
- La notificación `Descargando…` está en `:474`; `:471` escribe en el log.

### `ai.sh`

- Ayuda de cabecera impresa por el `awk` final: `:3-26,426-437`.
- Formatos `[ok]`, `[MISSING]`, `[warn]`: `:53-59`.
- Errores de `bench`: `:121,123-124,131`.
- Validaciones de `new`: `:155-165`.
- Mensajes de edición/configuración de OpenCode: `:220-227,269,292,295,297`.
- Dependencias, opciones, cancelaciones y errores de `code`: `:334,346,351-352,358,362-363,367,370,388,392,413,416`.

## Nota para el ítem 2

- La mayoría son `notify-send`/`menu`/`qml`. Los catálogos usan variables `MD_TXT_*` con nombres
  descriptivos en español, compartidas por los consumidores Bash, QML y Lua.
- `llm_menu.sh` y `ai.sh` concentran gran parte del texto y se ejecutan en pasos independientes.
- Los valores internos y las etiquetas visibles deben separarse. En particular:
  - `MdMenu.qml:184-187` devuelve `item.label`.
  - `notifications_menu.sh:40,51,55-57` reconoce acciones por su etiqueta.
  - `llm_menu.sh:128,309,328-345` compara categorías y opciones.
  - `ai.sh:128-131` interpreta `llm_menu.sh status`; `status` conserva identificadores estables.
  - `ai.sh:348-353` consume `list-local`, cuyos campos de máquina no se traducen indiscriminadamente.
  - `bk2_process_manager.sh:30-46` reconoce categorías y extrae `PID`.
- `process_manager.sh` y los cinco wrappers se generan con heredocs entrecomillados
  (`bk2_process_manager.sh:13`, `bk3_quickshell.sh:152,196,211,220,253`). Las variables del entorno
  deben resolverse al ejecutar el archivo generado, no al instalarlo.
- `hyprlock.conf` también usa heredoc entrecomillado y conserva `$USER`/`$(date …)` para ejecución
  posterior (`bk3_hyprlock.sh:12,31,41,69`). Sus textos quedan bilingües en este ciclo.
