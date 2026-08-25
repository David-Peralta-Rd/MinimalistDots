#!/usr/bin/env bash
# =========================================================
# setup-antigravity.sh
# Restaura settings.json + extensiones de Antigravity IDE
# tras una instalacion limpia.
# =========================================================
set -e

echo "==> Buscando el comando de Antigravity IDE en el PATH..."
if command -v antigravity-ide >/dev/null 2>&1; then
    BIN="antigravity-ide"
elif command -v agy >/dev/null 2>&1; then
    BIN="agy"
elif command -v antigravity >/dev/null 2>&1; then
    BIN="antigravity"
else
    echo "ERROR: no encontre 'antigravity-ide', 'agy' ni 'antigravity' en el PATH."
    echo "Abre Antigravity IDE y corre: Ctrl+Shift+P > \"Shell Command: Install command in PATH\""
    exit 1
fi
echo "==> Usando comando: $BIN"

# =========================================================
# 1. Detectar carpeta de configuracion de usuario (User dir)
# =========================================================
echo "==> Buscando carpeta de configuracion de usuario..."

CANDIDATES=(
    "$HOME/.config/Antigravity IDE/User"
    "$HOME/.config/antigravity-ide/User"
    "$HOME/.config/Antigravity/User"
    "$HOME/Library/Application Support/Antigravity IDE/User"
    "$APPDATA/Antigravity IDE/User"
)

CONFIG_DIR=""
for dir in "${CANDIDATES[@]}"; do
    if [ -d "$dir" ]; then
        CONFIG_DIR="$dir"
        break
    fi
done

if [ -z "$CONFIG_DIR" ]; then
    CONFIG_DIR="$HOME/.config/Antigravity IDE/User"
    echo "AVISO: no encontre una carpeta existente, voy a crear: $CONFIG_DIR"
    echo "       Si tu instalacion usa otra ruta, edita CONFIG_DIR en este script."
fi

mkdir -p "$CONFIG_DIR"
echo "==> Carpeta de configuracion: $CONFIG_DIR"

# =========================================================
# 2. Escribir settings.json (con backup si ya existia uno)
# =========================================================
if [ -f "$CONFIG_DIR/settings.json" ]; then
    cp "$CONFIG_DIR/settings.json" "$CONFIG_DIR/settings.json.bak.$(date +%s)"
    echo "==> Se hizo backup del settings.json anterior"
fi

echo "==> Escribiendo settings.json..."
cat > "$CONFIG_DIR/settings.json" << 'SETTINGSEOF'
{
    // =========================================================
    // === WORKBENCH - LAYOUT (soportado nativamente, fork de VS Code)
    // =========================================================
    "workbench.activityBar.location": "top",
    "workbench.sideBar.location": "right",
    "workbench.startupEditor": "none",
    "workbench.statusBar.visible": false,
    "workbench.editor.showTabs": "multiple",
    "workbench.editor.enablePreview": false,
    "workbench.editor.editorActionsLocation": "hidden",
    "workbench.navigationControl.enabled": false,
    "workbench.enableExperiments": false,
    "workbench.layoutControl.enabled": false,
    "window.commandCenter": false,
    "window.menuBarVisibility": "compact",
    "extensions.ignoreRecommendations": true,
    "telemetry.telemetryLevel": "off",

    // =========================================================
    // === EDITOR - VISUAL
    // =========================================================
    "editor.fontSize": 13,
    "editor.fontFamily": "'Cascadia Code PL', Fira Code, Courier New, monospace",
    "editor.fontLigatures": true,
    "editor.lineHeight": 1.6,
    "editor.letterSpacing": 0.5,
    "editor.codeLensFontFamily": "'Cascadia Code PL'",
    "editor.codeLensFontSize": 12,

    // Cursor
    "editor.cursorStyle": "block-outline",
    "editor.cursorWidth": 2,
    "editor.cursorBlinking": "expand",
    "editor.cursorSmoothCaretAnimation": "on",

    // Minimap
    "editor.minimap.enabled": true,
    "editor.minimap.size": "fill",
    "editor.minimap.side": "left",
    "editor.minimap.maxColumn": 90,

    // Layout limpio
    "editor.wordWrap": "on",
    "editor.folding": false,
    "editor.glyphMargin": false,
    "editor.lineNumbers": "on",
    "editor.renderLineHighlight": "none",
    "editor.overviewRulerBorder": false,
    "editor.hideCursorInOverviewRuler": true,
    "editor.scrollbar.horizontal": "hidden",
    "editor.scrollbar.vertical": "hidden",
    "editor.smoothScrolling": false,

    // Resaltado
    "editor.semanticHighlighting.enabled": true,
    "editor.selectionHighlight": true,
    // Cambiado de "multiFile" a "singleFile": resaltar coincidencias en
    // TODO el workspace en cada clic tiene un costo real de CPU. Si lo
    // necesitas de todos modos, vuelve a "multiFile".
    "editor.occurrencesHighlight": "singleFile",
    "editor.renderWhitespace": "boundary",
    "editor.wordSeparators": "`~!@#$%^&*()-=+[{]}\\|;:'\",.<>/?",

    // Brackets
    "editor.matchBrackets": "always",
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": "active",
    "editor.guides.bracketPairsHorizontal": false,
    "editor.guides.highlightActiveBracketPair": true,

    // Colores personalizados (nativo de VS Code / Antigravity)
    "workbench.colorCustomizations": {
        "editor.lineHighlightBackground": "#5a0a0a",
        "editorCursor.foreground": "#870808"
    },

    // IMPORTANTE: "workbench.iconTheme" y "workbench.colorTheme" están
    // comentados abajo a propósito. Si no tienes instaladas las extensiones
    // "Material Icon Theme" y "One Dark Pro", Antigravity mostrará avisos
    // de "tema no encontrado" en cada arranque, lo que se siente como
    // lentitud. Instala esas extensiones primero y LUEGO descomenta estas
    // dos líneas.
    // "workbench.iconTheme": "material-icon-theme",
    // "workbench.colorTheme": "One Dark Pro Mix",

    // =========================================================
    // === EDITOR - FORMATO Y GUARDADO
    // =========================================================
    // IMPORTANTE: solo funciona si tienes instalada la extensión de Python
    // (ms-python.python). Si no la tienes, cada guardado puede mostrar un
    // aviso de "formateador no encontrado". Instálala o comenta esta línea.
    // OJO: "ms-python.python" por sí solo NO formatea código — solo da
    // soporte base. Para que formatOnSave funcione de verdad en Python
    // necesitas instalar un formateador real, ej: "ms-python.black-formatter"
    // o "charliermarsh.ruff". Sin eso, cada guardado puede mostrar un aviso
    // de "no formatter found". Lo dejo puesto porque asumo que lo instalarás
    // pronto; si no, cambia esto a false por ahora.
    "editor.defaultFormatter": "ms-python.python",
    "editor.formatOnSave": true,
    "editor.formatOnPaste": true,
    "editor.formatOnType": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": "explicit"
    },

    // =========================================================
    // === EDITOR - SUGERENCIAS
    // =========================================================
    "editor.tabSize": 4,
    "editor.indentSize": "tabSize",
    "editor.insertSpaces": true,
    "editor.trimAutoWhitespace": true,
    "editor.wordBasedSuggestions": "off",
    "editor.suggestSelection": "first",
    "editor.suggest.showStatusBar": true,
    "editor.parameterHints.enabled": true,
    "editor.quickSuggestions": {
        "other": true,
        "comments": false,
        "strings": true
    },

    // =========================================================
    // === EDITOR - BÚSQUEDA Y NAVEGACIÓN
    // =========================================================
    "editor.find.seedSearchStringFromSelection": "selection",
    "editor.find.autoFindInSelection": "always",
    "editor.gotoLocation.multipleDefinitions": "goto",

    // =========================================================
    // === ARCHIVOS
    // =========================================================
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "files.encoding": "utf8",
    "files.trimFinalNewlines": true,
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "files.associations": {
        "*.py": "python"
    },
    "files.exclude": {
        "**/__pycache__": true,
        "**/.python-version": true,
        "**/pyproject.toml": true,
        "**/uv.lock": true
    },
    "search.exclude": {
        "**/.venv": true
    },
    "explorer.openEditors.visible": 1,

    // =========================================================
    // === TERMINAL
    // =========================================================
    "terminal.integrated.fontSize": 13,
    "terminal.integrated.fontFamily": "monospace",
    "terminal.integrated.defaultProfile.linux": "zsh",
    "terminal.integrated.fontLigatures.enabled": true,
    // Cambiado de "off" a "on": renderizar por GPU es más fluido que por
    // software. "off" era contraproducente para el rendimiento.
    "terminal.integrated.gpuAcceleration": "on",
    "terminal.integrated.customGlyphs": false,

    // =========================================================
    // === PYTHON - ANÁLISIS DE TIPOS (PYLANCE)
    // Es la sección clave para "definición de clases y tipos".
    // Requiere la extensión Pylance instalada en Antigravity;
    // al ser compatible con el Marketplace de VS Code, se instala igual.
    // =========================================================
    // NO tienes Pylance instalado (ms-python.vscode-pylance) — tienes
    // meta.pyrefly, que desactiva Pylance por diseño y usa su PROPIO
    // namespace de configuración: "python.pyrefly.*", no "python.analysis.*".
    // Por eso se elimina toda la sección python.analysis.* de la versión
    // anterior: no tenía ningún efecto con tu setup real y solo generaba
    // ruido/advertencias de "unknown setting" en el editor.
    //
    // Equivalente real de "strict" para Pyrefly:
    "python.pyrefly.typeCheckingMode": "strict",
    // NOTA: a diferencia de Pylance, Pyrefly hoy en día NO siempre respeta
    // esta configuración global desde settings.json en todas sus versiones
    // (hay un issue abierto al respecto). Si notas que "strict" no aplica,
    // la alternativa confiable es crear un pyrefly.toml o
    // [tool.pyrefly] dentro de pyproject.toml en la raíz de tu proyecto:
    // [tool.pyrefly]
    // python_version = "3.12"
    // (y ahí sí puedes forzar el modo strict por proyecto)

    "python.terminal.activateEnvironment": true,
    "python.terminal.launchArgs": ["-m", "ipython"],

    // =========================================================
    // === PYTHON - TESTING (PYTEST)
    // =========================================================
    "python.testing.pytestEnabled": true,
    "python.testing.pytestArgs": [
        "tests",
        "-v",
        "--tb=short"
    ],
    "python.testing.unittestEnabled": false,

    // =========================================================
    // === GIT Y DIFF
    // =========================================================
    "git.enableSmartCommit": true,
    "git.autofetch": true,
    "git.confirmSync": false,
    "scm.diffDecorations": "all",
    "scm.diffDecorationsGutterVisibility": "always",
    "diffEditor.ignoreTrimWhitespace": false,
    "diffEditor.renderSideBySide": true,

    // =========================================================
    // === DOCKER (tienes "docker.docker" instalado, no
    // "ms-azuretools.vscode-containers" — por eso se quitó el formatter
    // específico de dockerfile, que no existía en tu instalación)
    // =========================================================
    "docker.languageserver.formatter.ignoreMultilineInstructions": true,

    // =========================================================
    // === ERROR LENS (sí tienes usernamehw.errorlens instalado)
    // =========================================================
    "errorLens.enabled": true,
    "errorLens.fontSize": "12px",
    "errorLens.margin": "2px",
    "errorLens.padding": "0px",
    "errorLens.fontStyleItalic": true,
    "errorLens.messageBackgroundMode": "line",
    "errorLens.messageTemplate": "$severity $message",
    "errorLens.severityText": ["▣", "◈", "◉", "⛆"],
    "errorLens.statusBarMessageEnabled": false,
    "errorLens.statusBarIconsEnabled": false,
    "errorLens.enableOnDiffView": true
}
SETTINGSEOF

echo "==> settings.json escrito correctamente."

# =========================================================
# 3. Instalar extensiones
# =========================================================
EXTENSIONS=(
    "cweijan.dbclient-jdbc"
    "cweijan.vscode-mysql-client2"
    "docker.docker"
    "meta.pyrefly"
    "ms-python.debugpy"
    "ms-python.python"
    "ms-python.vscode-python-envs"
    "ms-toolsai.jupyter"
    "ms-toolsai.jupyter-keymap"
    "ms-toolsai.jupyter-renderers"
    "ms-toolsai.vscode-jupyter-cell-tags"
    "ms-toolsai.vscode-jupyter-slideshow"
    "njqdev.vscode-python-typehint"
    "redhat.vscode-yaml"
    "shardulm94.trailing-spaces"
    "usernamehw.errorlens"
)

echo "==> Instalando ${#EXTENSIONS[@]} extensiones..."
for ext in "${EXTENSIONS[@]}"; do
    echo "  -> Instalando: $ext"
    "$BIN" --install-extension "$ext" || echo "     AVISO: fallo instalando $ext (revisa el nombre o tu conexion)"
done

echo ""
echo "==> Listo. Reinicia Antigravity IDE para que todos los cambios tomen efecto."
