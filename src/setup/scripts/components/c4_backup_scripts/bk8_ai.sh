#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/u3_env.sh"

# ==== IA PARA DESARROLLO (agentes sobre los modelos locales) ==== #
# Capa encima de llm_menu.sh: el menú sigue siendo el único que arranca llama.cpp.
# Esta pieza solo deja listo lo que NO se copia con los scripts:
#
#   ~/.local/bin/MinimalistDots/ai/templates/   plantillas de proyecto (AGENTS.md, CLAUDE.md,
#                                               SPEC.md, tasks.md, ADR) y el prompt del agente
#                                               de logística. Se reemplazan en cada instalación.
#   ~/.config/ai/models.env                     rutas de modelos, puertos, hilos y contexto.
#                                               Se crea UNA vez y nunca se sobrescribe.
#
# El script principal es scripts/ai.sh (lo copia c4 con los demás .sh) y sus alias
# de Zsh (ai-up, ai-down, ai-doctor, ai-bench, ai-new) los escribe bk1_zsh.sh.
#
# Además instala OpenCode (agente de terminal; binario propio, sin Node) y le genera
# ~/.config/opencode/opencode.json apuntando a tu llama-server (ai.sh config). Se instala
# aquí y no en c2 porque si el paquete no existe en tus repos, un fallo aislado no debe
# romper la instalación de todos los demás paquetes.
#
# No instala llama.cpp (ya está en LLM_PKGS) ni descarga modelos (lo hace el menú
# SUPER+ALT+SHIFT+L).

if [ ! -d "$MD_AI_SRC/templates" ] || [ ! -f "$MD_AI_SRC/config/models.env.example" ]; then
    echo "$T_CONFIGURACION_NO_ENCONTRADA $MD_AI_SRC" >&2
    exit 1
fi

mkdir -p "$MD_AI_DIR" "$MD_AI_CONF"

# Plantillas: siempre las del proyecto (copia las que quieras editar a tus proyectos)
rm -rf "$MD_AI_DIR/templates"
cp -a "$MD_AI_SRC/templates" "$MD_AI_DIR/templates"
cp -f "$MD_AI_SRC/config/models.env.example" "$MD_AI_DIR/models.env.example"
echo "$T_AI_INSTALADO '${MD_AI_DIR#"$HOME"/}'"

# models.env: configuración del usuario, jamás se pisa
if [ ! -f "$MD_AI_CONF/models.env" ]; then
    cp "$MD_AI_SRC/config/models.env.example" "$MD_AI_CONF/models.env"
    echo "$T_AI_MODELS_CREADO $MD_AI_CONF/models.env"
else
    echo "$T_AI_MODELS_EXISTE"
fi

chmod +x "$MD_SCRIPTS_DIR/ai.sh" 2> /dev/null || true

# OpenCode: repos oficiales (extra) y, si no está, el AUR. Un fallo aquí no detiene nada.
if ! command -v opencode > /dev/null 2>&1; then
    paru -S --needed --noconfirm opencode 2> /dev/null \
        || paru -S --needed --noconfirm opencode-bin \
        || echo "$T_AI_OPENCODE_FALLO" >&2
fi

# Config de OpenCode desde models.env (si ya existe, solo se actualiza el proveedor llamacpp)
"$MD_SCRIPTS_DIR/ai.sh" config || echo "$T_AI_OPENCODE_CONFIG_FALLO" >&2

echo "$T_AI_SIGUIENTE"
