#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/u3_env.sh"

# c3 pasa HYPR_DIR; si el script se ejecuta solo, usa ~/.config/hypr
HYPR_DIR="${HYPR_DIR:-$MD_HYPR_DIR}"
TARGET="$HYPR_DIR/hyprpaper.conf"
mkdir -p "$(dirname "$TARGET")"

cat > "$TARGET" <<'EOF'
splash = false
EOF
