#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/u3_env.sh"


# ==== OPTIMIZACIÓN DE RED ==== #
# 1. Kernel (sysctl): baja latencia y alto rendimiento (BBR + CAKE, buffers grandes)
# 2. Tarjeta de red (ethtool): ring buffer, offloading y txqueuelen
#    -> se hace PERSISTENTE con una regla udev + un servicio systemd (si no, se pierde al reiniciar)
# 3. DNS rápido con caché local (systemd-resolved)
#
# Requiere el paquete "ethtool" (está en NETWORK_PKGS de c2_install_packages.sh).
# Nota: en CachyOS el paquete cachyos-settings ya trae ajustes de red; este
# archivo (prefijo 99-) se aplica al final y tiene prioridad sobre ellos.

# DNS-over-TLS: "opportunistic" usa TLS cuando se puede y NO rompe el DNS si la red
# bloquea el puerto 853. Con "yes" es estricto: sin TLS no hay resolución de nombres.
DNS_OVER_TLS="opportunistic"

# Tamaño máximo al que se sube el ring buffer (se usa el menor entre este valor y el máximo de la tarjeta)
RING_BUFFER_MAX=4096

SYSCTLD_DIR="/etc/sysctl.d"
TARGET_NETWORK_OPTIMIZATION="99-network-optimization.conf"
TUNE_SCRIPT="/usr/local/bin/md-network-tune"

echo "$T_RED_INICIANDO"


# ====================================================================
# 0. DETECCIÓN AUTOMÁTICA DE LA INTERFAZ DE RED ACTIVA
# ====================================================================
is_virtual() {
    case "$1" in
        lo|docker*|br-*|veth*|virbr*|tun*|tap*|wg*) return 0 ;;
        *) return 1 ;;
    esac
}

detect_interface() {
    local dev path name

    # 1. Rutas por defecto, ignorando interfaces virtuales (VPN, docker...)
    while read -r dev; do
        if [ -n "$dev" ] && ! is_virtual "$dev"; then
            echo "$dev"
            return 0
        fi
    done < <(ip route show default 2> /dev/null \
        | awk '{for (i = 1; i < NF; i++) if ($i == "dev") print $(i + 1)}')

    # 2. Si no hay ruta por defecto: primera interfaz física levantada
    for path in /sys/class/net/*; do
        name="${path##*/}"
        if ! is_virtual "$name" && [ "$(cat "$path/operstate" 2> /dev/null)" = "up" ]; then
            echo "$name"
            return 0
        fi
    done

    return 1
}

INTERFAZ="$(detect_interface || true)"

if [ -z "$INTERFAZ" ]; then
    echo "$T_RED_SIN_INTERFAZ" >&2
    exit 1
fi

echo "$T_RED_INTERFAZ_DETECTADA $INTERFAZ"


# ====================================================================
# 1. OPTIMIZACIÓN DEL KERNEL (SYSCTL) - BAJA LATENCIA & ALTO RENDIMIENTO
# ====================================================================
echo "$T_RED_APLICANDO_SYSCTL"

# Módulos necesarios para BBR y CAKE (se cargan ahora y en cada arranque)
sudo tee /etc/modules-load.d/network-optimization.conf > /dev/null <<'EOF'
tcp_bbr
sch_cake
EOF
sudo modprobe tcp_bbr 2> /dev/null || true
sudo modprobe sch_cake 2> /dev/null || true

sudo tee "$SYSCTLD_DIR/$TARGET_NETWORK_OPTIMIZATION" > /dev/null <<'EOF'
# Gestión de colas avanzada con CAKE (Combate el Bufferbloat de forma agresiva)
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr

# Buffers TCP maximizados para tuberías masivas de datos (Hasta 64MB para descargas Docker/NPM masivas)
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Incrementar el límite de procesamiento y colas del sistema bajo estrés
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_max_syn_backlog = 8192

# Optimización extrema de reutilización de sockets (Evita agotar puertos en miles de peticiones API concurrentes)
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10

# Deshabilitar Slow Start tras inactividad (Evita que TCP baje el ritmo entre descarga y descarga)
net.ipv4.tcp_slow_start_after_idle = 0

# TCP Fast Open (Acelera los handshakes en conexiones repetidas de gestores de paquetes)
net.ipv4.tcp_fastopen = 3

# Keepalives agresivos para matar sockets muertos y liberar recursos de inmediato
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 3

# --- SEGURIDAD Y ESTABILIDAD ---
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
EOF

# Se aplica solo este archivo (no todo el sistema); si un parámetro no existe en tu kernel, se avisa y se sigue
if ! sudo sysctl -p "$SYSCTLD_DIR/$TARGET_NETWORK_OPTIMIZATION" > /dev/null; then
    echo "$T_RED_SYSCTL_AVISO" >&2
fi


# ====================================================================
# 2. OPTIMIZACIÓN DE HARDWARE (TARJETA DE RED)
# ====================================================================
echo "$T_RED_OPTIMIZANDO_NIC $INTERFAZ"

if ! command -v ethtool &> /dev/null; then
    echo "$T_RED_SIN_ETHTOOL" >&2
else
    # Script que aplica los ajustes a UNA interfaz. Lo usan esta instalación (ahora)
    # y el servicio systemd (en cada arranque o al conectar la tarjeta).
    # RING_BUFFER_MAX se escribe aquí; el resto de variables se evalúan al ejecutarlo.
    sudo tee "$TUNE_SCRIPT" > /dev/null <<EOF
#!/usr/bin/env bash
# Generado por MinimalistDots (bk7_99_network_optimization.sh)
IFACE="\${1:?uso: md-network-tune <interfaz>}"
command -v ethtool > /dev/null || exit 0

# Ring buffer: sube al menor entre el máximo de la tarjeta y $RING_BUFFER_MAX
read -r RX_MAX TX_MAX < <(ethtool -g "\$IFACE" 2> /dev/null | awk '
    /Pre-set maximums/ {s = 1; next}
    /Current hardware settings/ {s = 0}
    s && /^RX:/ {rx = \$2}
    s && /^TX:/ {tx = \$2}
    END {print rx + 0, tx + 0}')

cap() { if [ "\$1" -gt $RING_BUFFER_MAX ]; then echo $RING_BUFFER_MAX; else echo "\$1"; fi; }

if [ "\${RX_MAX:-0}" -gt 0 ] && [ "\${TX_MAX:-0}" -gt 0 ]; then
    ethtool -G "\$IFACE" rx "\$(cap "\$RX_MAX")" tx "\$(cap "\$TX_MAX")" 2> /dev/null || true
fi

# Offloading: delega el procesamiento de red a la tarjeta en lugar de la CPU
ethtool -K "\$IFACE" rx on tx on tso on gso on gro on gro_hw off &> /dev/null || true

# Cola de transmisión física de la interfaz
ip link set dev "\$IFACE" txqueuelen 10000 || true
EOF
    sudo chmod 755 "$TUNE_SCRIPT"

    # Aplicar ahora a la interfaz activa
    sudo "$TUNE_SCRIPT" "$INTERFAZ"

    # --- Persistencia: regla udev + servicio systemd por interfaz ---
    echo "$T_RED_PERSISTENCIA"

    sudo tee /etc/systemd/system/md-network-tune@.service > /dev/null <<'EOF'
[Unit]
Description=MinimalistDots: optimizacion de red para %i
After=sys-subsystem-net-devices-%i.device

[Service]
Type=oneshot
ExecStart=/usr/local/bin/md-network-tune %i
EOF

    sudo tee /etc/udev/rules.d/99-md-network-tune.rules > /dev/null <<'EOF'
ACTION=="add", SUBSYSTEM=="net", KERNEL=="en*|eth*|wl*", TAG+="systemd", ENV{SYSTEMD_WANTS}+="md-network-tune@%k.service"
EOF

    sudo systemctl daemon-reload
    sudo udevadm control --reload
fi


# ====================================================================
# 3. DNS DE ULTRABAJA LATENCIA CON CACHÉ LOCAL (SYSTEMD-RESOLVED)
# ====================================================================
echo "$T_RED_CONFIGURANDO_DNS"

sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/dns_latency.conf > /dev/null <<EOF
[Resolve]
DNS=1.1.1.1 9.9.9.9 8.8.8.8
FallbackDNS=1.0.0.1 149.112.112.112
DNSSEC=allow-downgrade
DNSOverTLS=$DNS_OVER_TLS
Cache=yes
EOF

# Vincular el resolv.conf del sistema al stub de systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

sudo systemctl enable --now systemd-resolved
sudo systemctl restart systemd-resolved

# Si se usa NetworkManager, que delegue el DNS en systemd-resolved
# (así no vuelve a sobrescribir /etc/resolv.conf)
if systemctl is-active --quiet NetworkManager; then
    sudo mkdir -p /etc/NetworkManager/conf.d
    sudo tee /etc/NetworkManager/conf.d/dns-resolved.conf > /dev/null <<'EOF'
[main]
dns=systemd-resolved
EOF
    sudo systemctl reload NetworkManager || true
fi

echo "$T_RED_LISTO"
