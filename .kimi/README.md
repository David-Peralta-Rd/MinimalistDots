# 🧭 Carpeta de handoff para Kimi (preparada por análisis previo)

Esta carpeta centraliza todo lo que Kimi necesita para arrancar en **Fase 0 ya resuelta**
(verificación + propuesta), sin tener que re-derivar el mapa del proyecto desde cero.

## Contenido

| Archivo | Qué es |
|---------|--------|
| `AUDITORIA.md` | Respuesta completa al ítem 1 (arquitectura): inventario de archivos, mapa de dependencias, cuántos QML hay de verdad, si sobran, recomendación de división, problemas ordenados por impacto y las 6 decisiones pendientes con recomendación. |
| `IDENTIDAD_VISUAL.md` | Dirección y tokens del ítem 5 ya capturados con David: minimalismo macOS sin los tres puntos, paleta gris+negro, bordes hairline, escala de radios, **slot de logo cacheado (vacío por ahora)** y **rediseño de notificaciones** (contorno de consumo + tamaño adaptativo). |
| `INVENTARIO_TEXTOS.md` | Catálogo de **todos** los textos escritos a fuego en español (scripts + QML + instalador) que el ítem 2 debe convertir en variables. Con archivo y línea. |
| `GOLDEN_TREE.txt` | Línea base ("golden") derivada **estáticamente** del código: qué archivos produce una instalación limpia y dónde. NO se ejecutó el instalador (prohibido). |

## Salud estática verificada (baseline)

- `bash -n` sobre **todos** los `.sh` (incluido `install.sh`): ✅ OK.
- `luac -p` sobre **todos** los `.lua`: ✅ OK.
- QML: sin `qmllint` disponible (no verificado estáticamente).

## Datos duros verificados (para que Kimi no los suponga)

- **Repositorio**: rama `main`. Único cambio sin commitear: `prompt_para_kimi.md` (sin tocar).
- **Herramientas disponibles en este entorno**:
  - Presentes: `bash`, `luac`, `lua`, `qs` (binario de Quickshell).
  - AUSENTES: `shellcheck`, `shfmt`, `qmllint`, `node`.
  - Implicación: la verificación estática se limita a `bash -n`, `luac -p` y revisión manual de QML.
    Kimi debe marcar como "verificar" lo que no pueda comprobar y no afirmar.
- **No hay contenedor ni VM**: no se puede ejecutar el instalador (además está prohibido por las
  restricciones). La línea base es estática; si Kimi necesita una "golden" real, debe pedirla o
  montarla en un entorno aislado.

## Cómo lo uso Kimi

1. Lee `AUDITORIA.md` → tiene la Fase 0 resuelta (inventario + mapa + decisiones recomendadas).
2. Lee `INVENTARIO_TEXTOS.md` → la lista exacta de textos a convertir en el ítem 2.
3. Usa `GOLDEN_TREE.txt` como referencia de "no cambiar comportamiento observable" en ítems 1 y 3.
4. Confirma con David las 6 decisiones pendientes (vienen con recomendación en `AUDITORIA.md`).

## Cómo arrancar con Kimi (para David)

1. **Abre una sesión nueva de Kimi** y pega el contenido COMPLETO de `prompt_para_kimi.md` como
   primer mensaje. No hace falta editar nada: el prompt es autocontenido y termina en
   "Empieza por la Fase 0".
2. **Dale acceso al repo** (o pégale también la carpeta `.kimi/`): Kimi debe poder leer los
   archivos `.kimi/*.md` y el código del proyecto. Si Kimi es un agente con acceso a archivos,
   basta con decirle "lee `.kimi/` primero".
3. **Qué esperar en la primera respuesta**: SOLO la Fase 0 — verificación de la auditoría, los
   problemas ordenados y las 6 decisiones pendientes con su recomendación. Kimi NO debe escribir
   código ni commits en esta primera ronda; debe esperar tu aprobación para la Fase 1.

### Nombre sugerido para la sesión

Ponle un título corto y específico que identifique el proyecto y la fase. Por ejemplo:

```
MinimalistDots · Backlog Fase 0 — auditoría y decisiones
```

Cuando apruebes la Fase 1, continúa la MISMA sesión (o renómbrala a `… Fase 1 — propuesta`) para
que Kimi conserve el contexto. Para la Fase 2 (ejecución con commits) conviene una sesión aparte
por paso, o seguir la misma con instrucciones claras de "un commit por paso".
