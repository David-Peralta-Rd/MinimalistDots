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
#   ai.sh code [args]         PREGUNTA qué modelo usar (los .gguf ya descargados, por categoría,
#                             o una API de ~/.config/ai/api_models.conf), enciende el local si
#                             hace falta, deja el elegido en opencode.json y abre OpenCode.
#   ai.sh config              (Re)genera el proveedor local en ~/.config/opencode/opencode.json
#                             (sin modelo por defecto)
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
# CONFIG (OpenCode: proveedor local "llamacpp" y proveedores de API)
# ==============================================================================
OC_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json"
API_CONF="${AI_API_CONF:-${XDG_CONFIG_HOME:-$HOME/.config}/ai/api_models.conf}"

# Alias que usa llama-server para un .gguf (idéntico al de llm_menu.sh: friendly_name)
model_alias() { local n; n="$(basename "$1" .gguf)"; echo "${n##*-GGUF_}"; }

# oc_edit <filtro jq> [args de jq...]  → aplica el filtro a opencode.json sin tocar el resto.
oc_edit() {
    local filter="$1" tmp; shift
    command -v jq > /dev/null 2>&1 || die "falta jq para editar $OC_CFG."
    [ -f "$OC_CFG" ] || cmd_config > /dev/null || die "no se pudo crear $OC_CFG"
    jq empty "$OC_CFG" > /dev/null 2>&1 || die "$OC_CFG no es JSON puro (¿lleva comentarios?); no lo toco."
    tmp="$(mktemp)"
    if jq "$@" "$filter" "$OC_CFG" > "$tmp"; then
        mv "$tmp" "$OC_CFG"
    else
        rm -f "$tmp"; die "jq falló; $OC_CFG quedó intacto."
    fi
}

# Proveedor local: solo el modelo elegido. Con select=1 (ai-code) lo deja como "model" de
# OpenCode, porque esta versión no tiene -m; sin select (ai-config) quita el "model" que
# apunte al llama.cpp local, para que no quede un modelo gigante fijo por defecto.
oc_set_local() {
    local id="$1" sel="${2:-0}"
    oc_edit '
        .["$schema"] //= "https://opencode.ai/config.json"
        | if $sel == 1 then .model = ("llamacpp/" + $id)
          elif ((.model // "") | startswith("llamacpp/")) then del(.model) else . end
        | .provider.llamacpp = {
            npm: "@ai-sdk/openai-compatible", name: "llama.cpp (local)",
            options: {baseURL: $url},
            models: {($id): {name: $id, limit: {context: $ctx, output: 4096}}}
          }' --arg id "$id" --argjson sel "$sel" --arg url "http://127.0.0.1:${CHAT_PORT}/v1" --argjson ctx "${CHAT_CTX:-16384}"
}

# Fija el modelo de OpenCode ("proveedor/modelo") en opencode.json.
oc_set_model() { oc_edit '.["$schema"] //= "https://opencode.ai/config.json" | .model = $m' --arg m "$1"; }

# OpenCode ahora corre como servicio en segundo plano y puede conservar la config vieja:
# se le pide que la recargue (si no hay servicio o falla, no pasa nada).
oc_reload() { timeout 10 opencode reload > /dev/null 2>&1 || true; }

# Proveedor de API con endpoint propio (compatible con OpenAI). La clave NO se guarda en el
# archivo: opencode la lee de la variable de entorno ({env:VAR}).
oc_set_api() {
    local prov="$1" mid="$2" url="$3" envvar="$4"
    oc_edit '
        .["$schema"] //= "https://opencode.ai/config.json"
        | .provider[$p] = ((.provider[$p] // {}) * {
            npm: "@ai-sdk/openai-compatible", name: $p,
            options: ({baseURL: $url} + (if $env != "" then {apiKey: ("{env:" + $env + "}")} else {} end)),
            models: {($m): {name: $m}}
          })' --arg p "$prov" --arg m "$mid" --arg url "$url" --arg env "$envvar"
}

cmd_config() {
    load_env
    [ -n "${CHAT_MODEL:-}" ] || die "define CHAT_MODEL en $AI_ENV"
    local id; id="$(model_alias "$CHAT_MODEL")"
    mkdir -p "$(dirname "$OC_CFG")"
    if [ ! -f "$OC_CFG" ]; then
        # Sin "model" por defecto: ai-code pregunta qué modelo usar cada vez.
        cat > "$OC_CFG" << EOT
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "llamacpp": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "llama.cpp (local)",
      "options": { "baseURL": "http://127.0.0.1:${CHAT_PORT}/v1" },
      "models": {
        "$id": {
          "name": "$id",
          "limit": { "context": ${CHAT_CTX:-16384}, "output": 4096 }
        }
      }
    }
  }
}
EOT
        echo "creado $OC_CFG"
        return 0
    fi
    command -v jq > /dev/null 2>&1 || die "$OC_CFG ya existe y falta jq para actualizarlo."
    oc_set_local "$id"
    echo "actualizado el proveedor 'llamacpp' en $OC_CFG (sin modelo por defecto)"
}


# ==============================================================================
# CODE (pregunta qué modelo usar y abre OpenCode)
# ==============================================================================
# Menú: Quickshell (md_menu) si hay sesión gráfica; si no, lista numerada en la terminal.
pick_from_stdin() {
    local title="$1" md="$HERE/md_menu"
    local -a opts=(); local l i n
    while IFS= read -r l; do opts+=("$l"); done
    if [ -x "$md" ] && [ -n "${WAYLAND_DISPLAY:-}" ] && command -v qs > /dev/null 2>&1; then
        printf '%s\n' "${opts[@]}" | "$md" llm --prompt "$title" || true
        return 0
    fi
    [ -r /dev/tty ] || return 0
    echo "== $title ==" > /dev/tty
    for i in "${!opts[@]}"; do printf '%2d) %s\n' "$((i + 1))" "${opts[$i]}" > /dev/tty; done
    printf 'Número (Enter = cancelar): ' > /dev/tty
    read -r n < /dev/tty || return 0
    [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#opts[@]}" ] && printf '%s\n' "${opts[$((n - 1))]}"
    return 0
}

chat_healthy() { curl -fsS -m 2 "http://127.0.0.1:${CHAT_PORT}/health" > /dev/null 2>&1; }

# Alias del modelo que sirve ahora mismo el llama-server del chat ("" si no hay)
running_alias() {
    local j; j="$(curl -fsS -m 3 "http://127.0.0.1:${CHAT_PORT}/v1/models" 2> /dev/null)" || return 0
    if command -v jq > /dev/null 2>&1; then jq -r '.data[0].id // empty' <<< "$j" 2> /dev/null
    else grep -o '"id" *: *"[^"]*"' <<< "$j" | head -n 1 | sed 's/.*: *"\(.*\)"/\1/'; fi
}

gb() { awk -v b="$1" 'BEGIN { printf "%.1f", b / 1073741824 }'; }

cmd_code() {
    command -v opencode > /dev/null 2>&1 || die "opencode no está instalado (sudo pacman -S opencode)."
    load_env
    CHAT_CTX="${CHAT_CTX:-16384}"

    # ---- construir las opciones ----
    local -a kinds=() labels=() datas=()
    local -A size_of=()
    local cur line cat ref name bytes warn total
    cur="$(chat_healthy && running_alias || true)"
    total="$(awk '/^MemTotal:/ { print $2 * 1024 }' /proc/meminfo)"

    if [ -n "$cur" ]; then
        kinds+=(run); labels+=("● Seguir con el que ya está encendido: $cur  (:$CHAT_PORT)"); datas+=("$cur")
    fi
    while IFS='|' read -r cat ref name bytes tag; do
        [ -n "$ref" ] || continue
        size_of["$name"]="$bytes"
        warn=""; [ "$bytes" -gt $((total * 65 / 100)) ] && warn="  ⚠ pesado para tu RAM"
        kinds+=(local); labels+=("[$cat] $name  ($(gb "$bytes") GB)${tag:-}$warn"); datas+=("$ref")
    done < <("$LLM_MENU" list-local)
    if [ -f "$API_CONF" ]; then
        local lbl mdl url envv
        while IFS='|' read -r lbl mdl url envv; do
            [[ -z "${lbl// }" || "$lbl" == \#* ]] && continue
            kinds+=(api); labels+=("☁ API · $lbl  ($mdl)"); datas+=("$mdl|${url:-}|${envv:-}")
        done < "$API_CONF"
    fi
    # Siempre al final: OpenCode sin -m, para elegir allí entre los proveedores que ya autenticaste.
    kinds+=(free); labels+=("☁ Otro proveedor…  (elegir dentro de OpenCode con /models)"); datas+=("")
    [ "${#labels[@]}" -gt 1 ] || die "no hay modelos: descarga alguno con SUPER+ALT+SHIFT+L o define APIs en $API_CONF"

    local choice
    choice="$(printf '%s\n' "${labels[@]}" | pick_from_stdin "OpenCode: ¿qué modelo usar?")"
    [ -n "$choice" ] || { echo "cancelado."; return 0; }
    local idx=-1
    for i in "${!labels[@]}"; do [ "${labels[$i]}" = "$choice" ] && { idx="$i"; break; }; done
    [ "$idx" -ge 0 ] || die "opción no reconocida."

    case "${kinds[$idx]}" in
        run)
            oc_set_local "${datas[$idx]}" 1; oc_reload
            exec opencode "$@"
            ;;
        local)
            ref="${datas[$idx]}"; name="$(model_alias "$ref")"
            if [ "$cur" != "$name" ]; then
                # ¿cabe? (si hay otro modelo encendido, su RAM se libera al cambiarlo)
                local need avail freed=0
                [ -n "$cur" ] && freed="${size_of[$cur]:-0}"
                need=$((${size_of[$name]:-0} + 3 * 1073741824))
                avail=$(($(awk '/^MemAvailable:/ { print $2 * 1024 }' /proc/meminfo) + freed))
                if [ "$need" -gt "$avail" ]; then
                    choice="$(printf '%s\n' "Continuar de todos modos" "Cancelar" \
                        | pick_from_stdin "Hacen falta ~$(gb "$need") GB y hay $(gb "$avail") GB libres")"
                    [ "$choice" = "Continuar de todos modos" ] || { echo "cancelado."; return 0; }
                    export AI_FORCE=1
                fi
                "$LLM_MENU" stop chat                 # libera el modelo anterior (no hace nada si no hay)
                "$LLM_MENU" up chat "$ref" || die "no se pudo encender $name."
            fi
            oc_set_local "$name" 1; oc_reload
            exec opencode "$@"
            ;;
        free)
            # Sin -m: OpenCode abre con su último modelo y /models (o ctrl+x m) lista los
            # proveedores conectados con "opencode auth login". Aquí no se toca ni el servidor
            # local ni opencode.json.
            [ -n "$cur" ] && echo "nota: el modelo local '$cur' sigue en RAM (ai-down lo apaga)." >&2
            echo "en OpenCode escribe /models para elegir proveedor y modelo." >&2
            [ -f "$OC_CFG" ] && oc_edit 'if ((.model // "") | startswith("llamacpp/")) then del(.model) else . end'
            oc_reload
            exec opencode "$@"
            ;;
        api)
            local mdl url envv prov mid
            IFS='|' read -r mdl url envv <<< "${datas[$idx]}"
            prov="${mdl%%/*}"; mid="${mdl#*/}"
            if [ -n "$url" ]; then
                [ -z "$envv" ] || [ -n "${!envv:-}" ] \
                    || die "falta la clave: exporta $envv en tu shell (p. ej. en ~/.zshrc) y vuelve a abrir la terminal."
                oc_set_api "$prov" "$mid" "$url" "$envv"
            elif [ -n "$envv" ] && [ -z "${!envv:-}" ]; then
                echo "aviso: $envv no está definida; si no hiciste 'opencode auth login' para $prov, fallará." >&2
            fi
            [ -n "$cur" ] && echo "nota: el modelo local '$cur' sigue en RAM (ai-down lo apaga)." >&2
            oc_set_model "$mdl"; oc_reload
            exec opencode "$@"
            ;;
    esac
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
