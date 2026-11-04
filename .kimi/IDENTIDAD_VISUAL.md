# 🎨 Identidad visual de MinimalistDots — Dirección y tokens aprobados

> Dirección pedida por David y especificación aprobada en la Fase 1. Se aplicará de forma
> centralizada en `u2_palette.sh`, `Theme.qml` y `MdMenu.qml` durante el ítem 5. Las capacidades
> dependientes de versiones de Quickshell o SDDM permanecen marcadas "verificar".

---

## 1. La idea, en una frase

> **Minimalismo tipo macOS, pero no por los tres puntos: por la calma, la translucidez sutil,
> los colores suaves desaturados y los bordes finos y elegantes sobre una base gris + negro.**

Lo que sí tomamos del lenguaje visual de macOS:

- **Superficies translúcidas y en calma** (vidrio esmerilado sutil, no exagerado).
- **Colores suaves y desaturados** (acentos muted, nunca chillones).
- **Esquinas generosas y redondeadas**, uniformes.
- **Bordes finos tipo "hairline"** (1px, contraste bajísimo) que dan esa suavidad elegante.
- **Sombras suaves en capas** (solo en QML, no en Hyprland).
- **Mucho aire / espaciado generoso**.

Lo que NO tomamos de macOS:

- ❌ Los tres puntos de tráfico (rojo/amarillo/verde) de la ventana.
- ❌ La translucidez extrema o el blur pesado (cuesta GPU y contradice "menos es más").
- ❌ La tipografía SF Pro (no es libre; no se añade fuente nueva).
- ❌ Sombras duras o rebotes bruscos.

---

## 2. Paleta propuesta (gris + negro neutro, acentos suaves)

> Hoy la paleta es "gris frío" con tinte azulado (`#1e222a`). La dirección pide neutralizarla
> hacia **negro + gris sin tinte**, manteniendo los acentos muted pero un punto más suaves.
> La fuente de verdad sigue siendo `u2_palette.sh`; esto es el ajuste que el ítem 5 haría allí.

| Token | Actual (`u2_palette.sh`) | Propuesto | Nota |
|-------|--------------------------|-----------|------|
| Fondo (`bg`) | `#1e222a` (azulado) | `#121315` | negro neutro profundo |
| Superficie (`surface`) | `#282c34` | `#1b1c1f` | gris oscuro neutro |
| Superficie elevada | — (no existe) | `#232428` | hover / botones |
| Selección (`selection`) | `#3e4451` | `#2e3036` | fila activa |
| Borde inactivo | `#4b5263` | `rgba(255,255,255,0.08)` | **hairline** sobre negro |
| Borde activo | `#7ec7a2` | `#86d2a8` | verde menta (acento) |
| Texto | `#abb2bf` | `#e8e9ea` | casi blanco suave |
| Subtexto | `#5c6370` | `#8b8e94` | gris medio |
| Azul | `#7aa2f7` | `#8ab4ff` | más suave |
| Verde | `#7ec7a2` | `#86d2a8` | más suave |
| Rojo | `#e06c75` | `#e78293` | coral suave |
| Amarillo | `#d19a66` | `#d8a878` | ámbar suave |
| Magenta | `#c678dd` | `#cc8be0` | púrpura suave |
| Cian | `#56b6c2` | `#7fc4cf` | cian suave |

Regla de acentos: **un solo acento por contexto** (verde para "activo/positivo", rojo para
"crítico/destruir", azul para "enlace/informativo", etc.), nunca varios a la vez compitiendo.

---

## 3. Tipografía

- **Mantener `JetBrainsMono Nerd Font`** como única fuente (ya se instala con
  `ttf-jetbrains-mono-nerd`; añadir otra viola el Filtro de Admisión).
- Jerarquía por peso y tamaño, no por familia:
  - Títulos de menú/prompt: `bold`, `15px`.
  - Cuerpo / filas: `regular`, `13px`.
  - Metadatos / subtexto: `regular`, `10px`, `letterSpacing: 1`.
- Los **números/tiempos** (reloj, pomodoro) siguen en mono y en grande: es parte de la marca
  "precisa y silenciosa".

---

## 4. Radios, bordes, sombras, espaciado (escala unificada)

> Hoy están dispersos (radios 2/3/4/5/6/7/8/10/12/22, bordes 1/2). El ítem 5 los lleva a UNA escala.

| Elemento | Radio | Borde | Sombra |
|----------|-------|-------|--------|
| Menú / tarjeta | `14` | `1px` hairline | suave (ver abajo) |
| Ventana de widget (reloj, OSD) | `12` | `1px` hairline | suave |
| Fila de lista (hover) | `8` | — | — |
| Input / barra de búsqueda | `10` | `1px` hairline | — |
| Botón | `8` | — | — |
| Barra de progreso | `3` (altura 4–6px) | — | — |

- **Bordes**: `1px`, color `rgba(255,255,255,0.08)` (inactivo) / acento (activo). La escala
  aprobada no usa bordes de `2px`.
- **Sombras (solo QML)**: una sombra suave y en capas — `color: rgba(0,0,0,0.45)`,
  `radius ~24`, `samples` altos, offsets pequeños (y≈6–8). Hyprland sigue con `shadow.enabled=false`
  (decisión minimalista ya tomada): las sombras son solo para los elementos flotantes de Quickshell.
- **Translucidez**: fondo de menús ~`0.92` de opacidad (ya existen `bg90`/`bg92`) sobre un
  desenfoque sutil. No más translúcido que eso: legibilidad primero.
- **Espaciado**: padding de tarjeta `14px`, entre elementos `8–10px`, entre secciones `14px`.
  "Aire" constante y medido.

---

## 5. Iconografía y animaciones

- **Iconografía**: Nerd Font glyphs (ya usados: `󰕾 󰖀 󰕿 🗑 ↻ ✕ ▶ …`) + emojis en títulos de menú.
  Mantener el mismo set; no introducir un set de iconos nuevo.
- **Animaciones**: calma macOS = **fades y scale sutiles de 120–200ms**, easing `quick` (ya está
  en `animations.lua`). Sin rebotes. Las notificaciones ya tienen fade 120–150ms; unificar a ese
  tempo. El OSD 1200ms. El pomodoro usa 200–300ms.

---

## 6. Logo — slot cacheado (listo, aún sin diseño)

David quiere un logo que, cuando lo tenga, **se cargue instantáneo en todo** desde caché. Se deja
el "hueco" listo ahora; el diseño llega después.

**Dónde vive (caché, carga local instantánea):**
- `~/.cache/MinimalistDots/brand/logo.svg` (preferido: SVG, escala nítido a cualquier tamaño).
- Fallback opcional: `~/.cache/MinimalistDots/brand/logo.png` si el SVG no existe.
- **Por ahora queda VACÍO**: no hay archivo ni placeholder. El instalador deja la carpeta y el slot
  listos, pero no copia ningún logo hasta que David pase el diseño. Cuando lo tenga, reemplazar ese
  único archivo = cambia el logo en TODOS los menús/widgets, sin tocar QML y sin red (por eso
  "instantáneo").

**Cómo se consume:**
- `Theme.qml` expone `readonly property url logo: "file://" + .../logo.svg` (y `logoFallback`).
- Todos los QML referencian `Theme.logo` (nunca una ruta hardcodeada): lanzador, menús, reloj,
  notifd (marca sutil), OSD.
- Si el logo no existe aún, `Theme.logo` devuelve vacío y el UI se renderiza sin él (degradación
  limpia, cero errores).

**Dónde se usa (alcance del ítem 5):**
- Launcher (esquina), menús `MdMenu` (marca discreta), `notifd.qml` (opcional), `clock.qml`
  (opcional). `hyprlock` puede regenerarse desde el mismo loader de marca.

**Regla**: el logo es **monocromo** (texto/blanco o acento) para que siempre combine con la paleta.
No multicolor.

---

## 7. Notificaciones — contorno de consumo + tamaño adaptativo

El ítem 5 incluye rediseñar `notifd.qml` (y su `menu-notifications.qml`) para que hable el mismo
lenguaje que el resto. David pide dos cosas concretas:

### 7.1 Efecto de "consumo" (progreso en el borde)

**Problema actual**: la tarjeta tiene un borde bonito pero estático; no avisa **cuándo** va a
desaparecer ni **si** va a desaparecer.

**Nuevo comportamiento** — el borde se convierte en un **anillo de progreso** que recorre el
perímetro de la tarjeta (siguiendo las esquinas redondeadas):

- **Notificación con tiempo de vida (`timeoutMs > 0`)**: un trazo de color recorre el borde de
  `0%` a `100%` a medida que pasan los segundos. Cuando el contorno **completa el perímetro**
  (`100%`), la notificación desaparece (con el fade actual de ~120ms).
- **Notificación que NO desaparece (`timeoutMs == 0`, p. ej. críticas)**: el borde queda
  **totalmente contorneado** — anillo completo y estático, sin barrido — como señal de "esta no se
  va sola". No hay animación: el contorno permanece.
- **Al pasar el mouse**: el contorno y el temporizador se pausan conservando el tiempo restante.
  Hoy el `Timer` se detiene, pero al salir del hover reinicia la espera completa
  (`notifd.qml:154-158`); el rediseño corrige esa diferencia.
- **Color del contorno**: acento según estado — normal `accent` (azul/verde suave), crítica
  `accentRed`. **Grosor fino (1–2px)** coherente con el borde hairline. Nada de colores nuevos:
  reutiliza `Theme`.

**Implementación (Kimi propone y marca "verificar", no lo doy por cierto)**: trazo sobre
`Shape`/`ShapePath` (QtQuick.Shapes) o `Canvas` con arcos para las esquinas, animado con una
`NumberAnimation` **atada al `timeoutMs` real** del elemento (no un timer paralelo que se
desincronice). Debe leer el radio y el color desde `Theme`.

### 7.2 Más minimalista y adaptativo al contenido

**Estado actual verificado**: ancho fijo `360` (`notifd.qml:17-21`) y padding vertical total `24`.
El alto por contenido ya existe (`:160-164`) y icono, resumen, cuerpo, progreso y acciones ya
colapsan en gran parte (`:184-205,237-311`); la fila superior de aplicación/cierre es la excepción.

**Nuevo** — tamaño adaptativo al texto:
- **Ancho**: dentro del rango `220–340` según el contenido, no fijo.
- **Alto**: conservar `implicitHeight` del contenido, reduciendo el padding vertical total a ~`20`.
- **Colapso completo**: eliminar también el hueco de la fila superior cuando no haya aplicación;
  conservar el colapso existente de icono, cuerpo, progreso y acciones.
- **Tipografía compacta**: resumen `12px`, cuerpo `11px`, app `10px`.

> El historial (`notifications_menu.sh`) **no cambia**: sigue leyendo el mismo
> `~/.local/state/MinimalistDots/notifications.jsonl`.

---

## 8. Reglas de uso (checklist que Kimi debe respetar)

1. Todo color/radio/borde sale de `Theme.qml` (o del `.cfg` de marca). **Cero hardcodes** en QML.
2. `MdMenu.qml` es el único componente que "dibuja" el estilo; los demás heredan.
3. Un solo acento activo por pantalla.
4. Transparencia máx. ~0.92 y blur sutil; nunca ilegible.
5. El logo vive SOLO en `~/.cache/MinimalistDots/brand/` y se consume vía `Theme.logo`.
6. Radios/bordes/sombras/espaciado usan la escala de la sección 4, sin excepciones por widget.
7. Las notificaciones usan el contorno de consumo (7.1) y el tamaño adaptativo (7.2); el color y el
   grosor del contorno salen de `Theme`, nunca hardcodeados.

---

## 9. Decisiones aprobadas por David (Fase 1)

- [x] Los hex exactos de la paleta (sección 2), con negro neutro `#121315`.
- [x] El radio base `14` para menús/tarjetas.
- [x] El borde hairline `1px` `rgba(255,255,255,0.08)` y borde activo de `1px`.
- [x] Sombras suaves solo en QML; Hyprland sigue sin sombras ni blur.
- [x] JetBrains Mono Nerd Font como única familia, sin añadir Inter/SF-like.
- [x] El logo queda **vacío por ahora**: se prepara `Theme.logo`, sin archivo ni placeholder.
- [x] El contorno de consumo: barrido según `timeoutMs`, anillo estático completo para las que no
      expiran y pausa conservando el tiempo restante al hacer hover.
- [x] El tamaño adaptativo: ancho `220–340`, alto por contenido, padding compacto y colapso total
      de secciones vacías.
- [x] SDDM conserva sus rutas y se alinea la presentación del tema instalado, sin añadir otro tema.
- [x] Hyprlock conserva sus textos bilingües en este ciclo; solo cambia su presentación.
