#!/usr/bin/env bash
# ==============================================================================
# IA para desarrollo — servidores locales, diagnóstico, medición y proyectos nuevos
#
# Es la capa "agentes" encima de llm_menu.sh (que sigue siendo el único que
# arranca llama.cpp). Los alias de Zsh (ai-up, ai-down, ai-code, ai-new...)
# apuntan aquí.
#
# Uso:
#   ai.sh up [chat|fim|all]   Enciende los modelos de ~/.config/ai/models.env (def.: chat)
#   ai.sh down                Apaga todo y libera la RAM
#   ai.sh status              Qué está corriendo
#   ai.sh doctor              Revisa herramientas, modelos, puertos y memoria (no cambia nada)
#   ai.sh bench [chat|fim]    llama-bench con tus hilos (tokens/s reales); guarda el resultado
#   ai.sh code [args]         Enciende el chat si hace falta y abre OpenCode contra tu modelo local
#   ai.sh config              (Re)genera ~/.config/opencode/opencode.json desde models.env
#   ai.sh new <nombre> [--public] [--local] [-d "descripción"]
#                             Proyecto nuevo (AGENTS.md, SPEC.md, tasks.md...), primer commit y repo
#                             en GitHub con gh (privado por defecto; --local = sin GitHub)
#
# Notas:
#   - Chat y autocompletado a la vez se reparten la CPU: usa "fim" solo mientras codeas.
#   - La API compatible con OpenAI queda en http://127.0.0.1:<puerto>/v1 (agentes, Continue).
# ==============================================================================
set -uo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
HERE="$(dirname "$SELF")"                                   # .../MinimalistDots/scripts
LLM_MENU="$HERE/llm_menu.sh"
AI_HOME="${MD_AI_DIR:-$(dirname "$HERE")/ai}"               # .../MinimalistDots/ai
AI_ENV="${AI_ENV:-${XDG_CONFIG_HOME:-$HOME/.config}/ai/models.env}"
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/llm-servers"

die() { echo "ai.sh: $*" >&2; exit 1; }

# Carga models.env (si existe) con los mismos valores por defecto que llm_menu.sh
load_env() {
    if [ -f "$AI_ENV" ]; then
        # shellcheck disable=SC1090
        source "$AI_ENV"
    fi
    CHAT_PORT="${CHAT_PORT:-8080}"; FIM_PORT="${FIM_PORT:-8081}"
    THREADS="${THREADS:-6}"; FIM_THREADS="${FIM_THREADS:-2}"
}


# ==============================================================================
# DOCTOR (solo lee; no cambia nada)
# ==============================================================================
cmd_doctor() {
    local fail=0
    ok()   { printf '  [ok]      %s\n' "$1"; }
    miss() { printf '  [MISSING] %s\n' "$1"; fail=1; }
    warn() { printf '  [warn]    %s\n' "$1"; }

    echo "Herramientas"
    local c
    for c in git docker jq curl uv qs llama-server; do
        command -v "$c" > /dev/null 2>&1 && ok "$c" || miss "$c"
    done
    docker compose version > /dev/null 2>&1 && ok "docker compose" || miss "docker compose (paquete docker-compose)"
    docker info > /dev/null 2>&1 && ok "docker sin sudo" || warn "docker no responde sin sudo (¿cerraste sesión tras instalar?)"
    command -v llama-bench > /dev/null 2>&1 && ok "llama-bench" || warn "llama-bench no está (lo trae el paquete llama-cpp según la versión)"
    command -v aria2c > /dev/null 2>&1 && ok "aria2c (descargas rápidas de modelos)" || warn "aria2c no instalado: los modelos se bajan con 1 conexión"
    command -v gh > /dev/null 2>&1 && ok "gh" || miss "gh (paquete github-cli)"
    gh auth status --hostname github.com > /dev/null 2>&1 && ok "gh con sesión en GitHub (ai-new puede crear repos)" \
        || warn "gh sin sesión: ai-new dejará los proyectos solo locales (gh auth login)"
    command -v opencode > /dev/null 2>&1 && ok "opencode" || warn "opencode no instalado (sudo pacman -S opencode)"
    grep -qs '"llamacpp"' "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json" \
        && ok "opencode apunta a tu llama-server (proveedor llamacpp)" \
        || warn "opencode sin proveedor llamacpp (ejecuta: ai-config)"
    command -v claude > /dev/null 2>&1 && ok "claude (Claude Code)" || warn "claude no instalado (opcional)"

    echo "Configuración"
    if [ -f "$AI_ENV" ]; then
        ok "$AI_ENV"
        load_env
        [ -f "${CHAT_MODEL:-}" ] && ok "modelo de chat: $CHAT_MODEL" \
            || miss "modelo de chat no encontrado: ${CHAT_MODEL:-sin definir} (descárgalo con SUPER+ALT+SHIFT+L o edita $AI_ENV)"
        [ -f "${FIM_MODEL:-}" ] && ok "modelo de autocompletado: $FIM_MODEL" \
            || miss "modelo de autocompletado no encontrado: ${FIM_MODEL:-sin definir}"
    else
        miss "$AI_ENV (ejecuta el instalador o copia ai/config/models.env.example)"
    fi
    [ -d "$AI_HOME/templates/project" ] && ok "plantillas en $AI_HOME/templates" || miss "plantillas en $AI_HOME/templates"

    echo "Servidores"
    load_env
    local pair name port
    for pair in "chat:$CHAT_PORT" "fim:$FIM_PORT"; do
        name="${pair%%:*}"; port="${pair##*:}"
        if curl -fsS -m 2 "http://127.0.0.1:${port}/health" > /dev/null 2>&1; then
            ok "$name responde en :$port"
        else
            warn "$name no responde en :$port (enciéndelo con: ai-up $name)"
        fi
    done

    echo "Memoria y CPU"
    free -h 2> /dev/null | awk 'NR<=2'
    echo "  hilos de CPU: $(nproc 2> /dev/null || echo '?')  (THREADS=$THREADS en models.env; pruébalo con ai-bench)"

    echo
    if [ "$fail" -eq 0 ]; then echo "Listo."; else echo "Arregla los MISSING de arriba."; fi
    return "$fail"
}


# ==============================================================================
# BENCH (tokens/s reales con llama-bench)
# ==============================================================================
cmd_bench() {
    local which="${1:-chat}" model
    load_env
    case "$which" in
        chat) model="${CHAT_MODEL:-}" ;;
        fim)  model="${FIM_MODEL:-}" ;;
        *)    die "uso: ai.sh bench [chat|fim]" ;;
    esac
    command -v llama-bench > /dev/null 2>&1 || die "no encuentro llama-bench (revisa el paquete llama-cpp)."
    [ -f "$model" ] || die "modelo no encontrado: '${model:-sin definir}' (edita $AI_ENV)."

    # Con los servidores encendidos la medición sale falseada y la RAM no alcanza.
    # (se captura la salida antes de filtrar: grep -q + pipefail daría un falso "apagado")
    local running
    running="$("$LLM_MENU" status 2> /dev/null || true)"
    if grep -qE '^(chat|autocomplete)' <<< "$running"; then
        die "hay servidores encendidos; ejecuta primero: ai-down"
    fi

    mkdir -p "$LOG_DIR"
    local out="$LOG_DIR/bench-$(date +%F_%H%M).md" extra=()
    # Igual que llm_menu.sh: con la Vega compartida es mejor ni inicializar Vulkan.
    llama-bench --help 2>&1 | grep -q -- '--device' && extra+=(--device none)

    echo "Midiendo $(basename "$model") con -t $THREADS,$((THREADS * 2)) (CPU pura). Puede tardar varios minutos..."
    llama-bench -m "$model" -ngl 0 -t "$THREADS,$((THREADS * 2))" -p 512 -n 128 -o md "${extra[@]}" | tee "$out"
    echo
    echo "Guardado en $out  (pp = lectura del prompt, tg = generación; anota los tokens/s de tg)."
}


# ==============================================================================
# NEW (proyecto nuevo desde plantilla + repo en GitHub con gh)
# ==============================================================================
cmd_new() {
    local name="" visibility="--private" remote=1 desc="" tpl="$AI_HOME/templates/project"
    while [ $# -gt 0 ]; do
        case "$1" in
            --public) visibility="--public" ;;
            --local)  remote=0 ;;
            -d|--desc) [ $# -ge 2 ] || die "falta el texto de $1"; desc="$2"; shift ;;
            -*)       die "opción desconocida: $1" ;;
            *)        [ -z "$name" ] || die "sobra un argumento: $1"; name="$1" ;;
        esac
        shift
    done
    [ -n "$name" ] || die 'uso: ai.sh new <nombre> [--public] [--local] [-d "descripción"]'
    [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || die "el nombre solo puede llevar letras, números, punto, guion y guion bajo."
    [ -d "$tpl" ] || die "no encuentro la plantilla en $tpl (ejecuta el instalador de MinimalistDots)."
    [ -e "$name" ] && die "$name ya existe."
    command -v git > /dev/null 2>&1 || die "falta git."

    mkdir -p "$name"
    cp -a "$tpl"/. "$name"/
    find "$name" -name '*.md' -exec sed -i "s|__PROJECT__|$name|g" {} +
    git init -q -b main "$name"

    # Primer commit. Tu git firma con GPG (lo configura bk6_github.sh): pinentry necesita la terminal.
    local t
    if t="$(tty 2> /dev/null)"; then export GPG_TTY="$t"; fi
    git -C "$name" add -A
    if ! git -C "$name" commit -q -m "chore: estructura inicial (ai-new)"; then
        echo "ai.sh: el proyecto quedó en ./$name pero el primer commit falló (¿clave GPG o user.name/user.email?)." >&2
        echo "       Revisa: git config --global --list | grep -E 'user|gpg'  y  gpg --list-secret-keys" >&2
        return 1
    fi
    echo "creado ./$name  (rama main, primer commit hecho)"

    local url=""
    if [ "$remote" -eq 0 ]; then
        echo "modo --local: sin repo en GitHub."
    elif ! command -v gh > /dev/null 2>&1; then
        echo "aviso: gh no está instalado; el proyecto queda solo local." >&2
    elif ! gh auth status --hostname github.com > /dev/null 2>&1; then
        echo "aviso: gh no tiene sesión; el proyecto queda solo local. Entra con: gh auth login" >&2
    else
        local -a args=(repo create "$name" "$visibility" --source="./$name" --remote=origin --push)
        [ -n "$desc" ] && args+=(--description "$desc")
        if gh "${args[@]}"; then
            url="$(cd "$name" && gh repo view --json url -q .url 2> /dev/null || true)"
        else
            echo "aviso: no se pudo crear el repo en GitHub (¿ya existe '$name' en tu cuenta?); queda local." >&2
        fi
    fi

    [ -n "$url" ] && echo "repo: $url (${visibility#--})"
    echo
    echo "siguiente:"
    echo "  1) llévalo a tu Project de Claude (modo PLANEAR) y pega aquí SPEC.md y tasks.md"
    echo "  2) cd $name && ai-code        # enciende el modelo local y abre OpenCode"
}


# ==============================================================================
# CONFIG (OpenCode apuntando al llama-server local)
# ==============================================================================
cmd_config() {
    load_env
    [ -n "${CHAT_MODEL:-}" ] || die "define CHAT_MODEL en $AI_ENV"
    local n model_id url cfg
    n="$(basename "$CHAT_MODEL" .gguf)"
    model_id="${n##*-GGUF_}"                        # mismo nombre (--alias) que usa llm_menu.sh
    url="http://127.0.0.1:${CHAT_PORT}/v1"
    cfg="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json"
    mkdir -p "$(dirname "$cfg")"

    if [ ! -f "$cfg" ]; then
        cat > "$cfg" << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "llamacpp/$model_id",
  "provider": {
    "llamacpp": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "llama.cpp (local)",
      "options": { "baseURL": "$url" },
      "models": {
        "$model_id": {
          "name": "$model_id",
          "limit": { "context": ${CHAT_CTX:-32768}, "output": 4096 }
        }
      }
    }
  }
}
EOF
        echo "creado $cfg"
        return 0
    fi

    # Ya existe: solo se reescribe el proveedor "llamacpp"; el resto de tu configuración no se toca.
    command -v jq > /dev/null 2>&1 || die "$cfg ya existe y falta jq para actualizarlo; añade el proveedor 'llamacpp' a mano ($url)."
    jq empty "$cfg" > /dev/null 2>&1 || die "$cfg no es JSON puro (¿lleva comentarios?); no lo toco. Proveedor a añadir: llamacpp -> $url"
    local tmp; tmp="$(mktemp)"
    if jq --arg id "$model_id" --arg url "$url" --argjson ctx "${CHAT_CTX:-32768}" '
            .["$schema"] //= "https://opencode.ai/config.json"
            | .model //= ("llamacpp/" + $id)
            | .provider.llamacpp = {
                npm: "@ai-sdk/openai-compatible", name: "llama.cpp (local)",
                options: {baseURL: $url},
                models: {($id): {name: $id, limit: {context: $ctx, output: 4096}}}
              }' "$cfg" > "$tmp"; then
        mv "$tmp" "$cfg"
        echo "actualizado el proveedor 'llamacpp' en $cfg"
    else
        rm -f "$tmp"; die "jq falló; $cfg quedó intacto."
    fi
}


# ==============================================================================
# CODE (enciende el modelo si hace falta y abre OpenCode)
# ==============================================================================
cmd_code() {
    command -v opencode > /dev/null 2>&1 || die "opencode no está instalado (sudo pacman -S opencode)."
    load_env
    if ! curl -fsS -m 2 "http://127.0.0.1:${CHAT_PORT}/health" > /dev/null 2>&1; then
        "$LLM_MENU" up chat || die "no se pudo encender el modelo de chat."
    fi
    [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json" ] || cmd_config
    exec opencode "$@"
}


case "${1:-}" in
    up)     "$LLM_MENU" up "${2:-chat}" ;;
    down)   "$LLM_MENU" stop ;;
    status) "$LLM_MENU" status ;;
    doctor) cmd_doctor ;;
    bench)  cmd_bench "${2:-chat}" ;;
    new)    shift; cmd_new "$@" ;;
    config) cmd_config ;;
    code)   shift; cmd_code "$@" ;;
    *)
        # imprime el bloque de comentarios de la cabecera (entre las dos líneas de ====)
        awk '/^# =+$/ { n++; next } n == 1 { sub(/^# ?/, ""); print } n >= 2 { exit }' "$SELF" >&2
        exit 2
        ;;
esac
