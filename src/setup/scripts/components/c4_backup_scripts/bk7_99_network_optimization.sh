#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/u3_env.sh"


# ==== OPTIMIZACIÓN DE RED ==== #
# 1. Kernel (sysctl): BBR + fq, buffers razonables, MTU probing
# 2. Tarjeta de red (ethtool/iw/tc): ring buffer, offloading, Wi-Fi sin ahorro de energía
#    -> PERSISTENTE con una regla udev + un servicio systemd
# 3. DNS rápido con caché local (systemd-resolved)
# 4. Descargas paralelas en pacman (el kernel NO paraleliza descargas; eso lo hace cada app)
#
# Requiere "ethtool" (y opcionalmente "iw" para Wi-Fi).
# Nota: este archivo (prefijo 99-) se aplica al final y tiene prioridad sobre cachyos-settings.

# DNS-over-TLS: "opportunistic" usa TLS cuando se puede y NO rompe el DNS si la red
# bloquea el puerto 853. Con "yes" es estricto. Si notas DNS lento, prueba "no".
DNS_OVER_TLS="opportunistic"

# Ring buffer: tope máximo. Más grande NO siempre es mejor (añade latencia).
RING_BUFFER_MAX=2048

# Opcional: límite de CAKE en bajada/subida de TU conexión, ej. "90Mbit".
# CAKE solo combate el bufferbloat si le das un ancho de banda ~5-10% menor al real.
# Déjalo vacío ("") para usar fq (recomendado con BBR) sin limitar nada.
CAKE_BANDWIDTH=""

# Descargas paralelas de pacman (0 = no tocar pacman.conf)
PACMAN_PARALLEL=10

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
# 1. OPTIMIZACIÓN DEL KERNEL (SYSCTL)
# ====================================================================
echo "$T_RED_APLICANDO_SYSCTL"

# Módulos necesarios para BBR y CAKE (se cargan ahora y en cada arranque)
sudo tee /etc/modules-load.d/network-optimization.conf > /dev/null <<'EOF'
tcp_bbr
sch_fq
sch_cake
EOF
sudo modprobe tcp_bbr 2> /dev/null || true
sudo modprobe sch_fq 2> /dev/null || true
sudo modprobe sch_cake 2> /dev/null || true

sudo tee "$SYSCTLD_DIR/$TARGET_NETWORK_OPTIMIZATION" > /dev/null <<'EOF'
# fq = cola recomendada para BBR (pacing por flujo, escala bien en NICs multicola).
# Solo se aplica a interfaces al levantarse (reinicio o reconexión).
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# Buffers TCP: 32 MB bastan para ~1 Gbps con 250 ms de latencia.
# Más grande solo gasta RAM y puede aumentar latencia.
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.ipv4.tcp_rmem = 4096 131072 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432

# Colas del sistema bajo carga
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_max_syn_backlog = 8192

# Muchas conexiones concurrentes (descargas paralelas, APIs, npm, docker)
net.ipv4.ip_local_port_range = 10240 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15

# No volver a empezar lento tras una pausa entre descargas
net.ipv4.tcp_slow_start_after_idle = 0

# No reutilizar métricas cacheadas de conexiones viejas (evita arrastrar malas rachas)
net.ipv4.tcp_no_metrics_save = 1

# Detecta MTU problemático (PPPoE, túneles, algunos ISP) y evita cuelgues/lentitud
net.ipv4.tcp_mtu_probing = 1

# Menos datos "sin enviar" en el buffer del socket: baja la latencia sin perder velocidad
net.ipv4.tcp_notsent_lowat = 131072

# TCP Fast Open (handshakes más rápidos en conexiones repetidas)
net.ipv4.tcp_fastopen = 3

# Keepalives moderados (más agresivos que el default, sin romper NAT/Wi-Fi)
net.ipv4.tcp_keepalive_time = 120
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5

# --- SEGURIDAD Y ESTABILIDAD ---
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 3
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
EOF

# Se aplica solo este archivo; si un parámetro no existe en tu kernel, se avisa y se sigue
if ! sudo sysctl -p "$SYSCTLD_DIR/$TARGET_NETWORK_OPTIMIZATION" > /dev/null; then
    echo "$T_RED_SYSCTL_AVISO" >&2
fi


# ====================================================================
# 2. OPTIMIZACIÓN DE HARDWARE (TARJETA DE RED)
# ====================================================================
echo "$T_RED_OPTIMIZANDO_NIC $INTERFAZ"

if ! command -v ethtool &> /dev/null; then
    echo "$T_RED_SIN_ETHTOOL" >&2
fi

# Script que aplica los ajustes a UNA interfaz. Lo usan esta instalación (ahora)
# y el servicio systemd (en cada arranque o al conectar la tarjeta).
# RING_BUFFER_MAX y CAKE_BANDWIDTH se escriben aquí; el resto se evalúa al ejecutarlo.
sudo tee "$TUNE_SCRIPT" > /dev/null <<EOF
#!/usr/bin/env bash
# Generado por MinimalistDots (bk7_99_network_optimization.sh)
IFACE="\${1:?uso: md-network-tune <interfaz>}"

# Wi-Fi: desactivar el ahorro de energía (causa picos de latencia y lentitud)
case "\$IFACE" in
    wl*) command -v iw > /dev/null && iw dev "\$IFACE" set power_save off &> /dev/null || true ;;
esac

# CAKE con límite de ancho de banda (solo si se configuró CAKE_BANDWIDTH)
if [ -n "$CAKE_BANDWIDTH" ]; then
    tc qdisc replace dev "\$IFACE" root cake bandwidth $CAKE_BANDWIDTH 2> /dev/null || true
fi

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
ethtool -K "\$IFACE" rx on tx on tso on gso on gro on &> /dev/null || true
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


# ====================================================================
# 3. DNS CON CACHÉ LOCAL (SYSTEMD-RESOLVED)
# ====================================================================
echo "$T_RED_CONFIGURANDO_DNS"

sudo mkdir -p /etc/systemd/resolved.conf.d
# Domains=~. fuerza a usar estos DNS para todo (si no, el DNS lento del router/ISP
# sigue teniendo prioridad). Los dominios de VPN/red local siguen funcionando.
# Se usan solo Cloudflare + Google: Quad9 filtra dominios y daba resultados inconsistentes al mezclarlo.
sudo tee /etc/systemd/resolved.conf.d/dns_latency.conf > /dev/null <<EOF
[Resolve]
DNS=1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4
FallbackDNS=9.9.9.9 149.112.112.112
Domains=~.
DNSSEC=allow-downgrade
DNSOverTLS=$DNS_OVER_TLS
Cache=yes
EOF

# Vincular el resolv.conf del sistema al stub de systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

sudo systemctl enable --now systemd-resolved
sudo systemctl restart systemd-resolved

# Si se usa NetworkManager, que delegue el DNS en systemd-resolved
if systemctl is-active --quiet NetworkManager; then
    sudo mkdir -p /etc/NetworkManager/conf.d
    sudo tee /etc/NetworkManager/conf.d/dns-resolved.conf > /dev/null <<'EOF'
[main]
dns=systemd-resolved
EOF
    sudo systemctl reload NetworkManager || true
fi


# ====================================================================
# 4. DESCARGAS PARALELAS EN PACMAN
# ====================================================================
if [ "$PACMAN_PARALLEL" -gt 0 ] && [ -f /etc/pacman.conf ]; then
    if grep -qE '^[[:space:]]*#?[[:space:]]*ParallelDownloads' /etc/pacman.conf; then
        sudo sed -i -E "s|^[[:space:]]*#?[[:space:]]*ParallelDownloads.*|ParallelDownloads = $PACMAN_PARALLEL|" /etc/pacman.conf
    else
        sudo sed -i "/^\[options\]/a ParallelDownloads = $PACMAN_PARALLEL" /etc/pacman.conf
    fi
fi

echo "$T_RED_LISTO"
