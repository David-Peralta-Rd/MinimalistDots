#!/bin/bash

# ==========================================
# Función para imprimir títulos estilizados
# ==========================================
print_title() {
    local title="$1"
    local length=${#title}
    local border=$(printf '=%.0s' $(seq 1 $((length + 4))))

    echo ""
    echo "====$border===="
    echo "====  $title  ===="
    echo "====$border===="
    echo ""
}
