#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/u3_env.sh"

BACKUP_SCRIPTS="$SCRIPT_DIR/c4_backup_scripts"

mkdir -p "$MD_SERVICES_DIR" "$MD_SCRIPTS_DIR"


# sync_files <msg-lista> <msg-borrar> <msg-copiar> <destino> <origen> <extension>
# Reemplaza los archivos *.<extension> del destino por los del proyecto.
# Si el origen está vacío no borra nada.
sync_files() {
    local msg_list="$1" msg_delete="$2" msg_copy="$3" dest="$4" src="$5" ext="$6"

    shopt -s nullglob
    local old=("$dest"/*."$ext") new=("$src"/*."$ext")
    shopt -u nullglob

    if [ ${#new[@]} -eq 0 ]; then
        echo "$T_CONFIGURACION_NO_ENCONTRADA $src" >&2
        return 1
    fi

    echo "$msg_list"
    if [ ${#old[@]} -gt 0 ]; then
        printf '    %s\n' "${old[@]##*/}"
    fi

    echo "$msg_delete"
    rm -f "${old[@]}"

    echo "$msg_copy"
    cp -f "${new[@]}" "$dest/"
}


# =============================================================================== #
# ==== INSTALANDO SERVICIOS DENTRO DE "~/.local/bin/MinimalistDots/services" ==== #
# =============================================================================== #
sync_files "$T_LISTANDO_SERVICIOS_ANTIGUOS" "$T_BORRANDO_SERVICIOS_ANTIGUOS" "$T_COPIANDO_SERVICIOS_NUEVOS" \
           "$MD_SERVICES_DIR" "$MD_DOTS_BIN/services" lua


# =============================================================================== #
# ==== INSTALANDO SCRIPTS DENTRO DE "~/.local/bin/MinimalistDots/scripts" ======= #
# =============================================================================== #
sync_files "$T_LISTANDO_SCRIPTS_ANTIGUOS" "$T_BORRANDO_SCRIPTS_ANTIGUOS" "$T_COPIANDO_SCRIPTS_NUEVOS" \
           "$MD_SCRIPTS_DIR" "$MD_DOTS_BIN/scripts" sh
chmod +x "$MD_SCRIPTS_DIR"/*.sh


# ============================================ #
# ==== INSTALANDO PIEZAS (c4_backup_scripts) ==== #
# ============================================ #
# Cada pieza es independiente: zsh, gestor de procesos, wofi, tema de SDDM...
# Para agregar otra, basta con crear un bkN_*.sh nuevo en c4_backup_scripts/.
# Si una falla se continúa con las demás y se informa al final.
FAILED=()
for step in "$BACKUP_SCRIPTS"/bk*.sh; do
    name="$(basename "$step")"
    if ! bash "$step"; then
        echo "$T_PASO_FALLIDO $name" >&2
        FAILED+=("$name")
    fi
done

if [ ${#FAILED[@]} -gt 0 ]; then
    exit 1
fi
