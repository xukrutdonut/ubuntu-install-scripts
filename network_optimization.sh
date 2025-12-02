#!/bin/bash
# Script de optimización de red para máxima velocidad

echo "=== OPTIMIZACIONES DE RED ==="

# 1. Incrementar buffers de red (requiere sudo)
echo "1. Incrementando buffers de red..."
sudo sysctl -w net.core.rmem_max=16777216
sudo sysctl -w net.core.wmem_max=16777216 
sudo sysctl -w net.core.rmem_default=262144
sudo sysctl -w net.core.wmem_default=262144

# 2. Optimizar TCP
echo "2. Optimizando TCP..."
sudo sysctl -w net.ipv4.tcp_rmem="4096 65536 16777216"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216"
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr

# 3. Optimizar cola de transmisión
echo "3. Optimizando colas de red..."
sudo sysctl -w net.core.netdev_max_backlog=5000

# 4. Para hacer permanente, agregar a /etc/sysctl.conf:
echo "4. Para hacer permanente, agregar estas líneas a /etc/sysctl.conf:"
echo "net.core.rmem_max=16777216"
echo "net.core.wmem_max=16777216"
echo "net.core.rmem_default=262144" 
echo "net.core.wmem_default=262144"
echo "net.ipv4.tcp_rmem=4096 65536 16777216"
echo "net.ipv4.tcp_wmem=4096 65536 16777216"
echo "net.ipv4.tcp_congestion_control=bbr"
echo "net.core.netdev_max_backlog=5000"

echo "=== RECOMENDACIONES ADICIONALES ==="
echo "• Tu WiFi usa canal 36 (5GHz) - considera cambiar a un canal menos congestionado"
echo "• Tienes bonding activo (2Gbps) pero también WiFi - usa una sola conexión para evitar conflictos"
echo "• Señal WiFi -60dBm es moderada - acércate al router para mejor rendimiento"
echo "• Instala speedtest-cli: sudo apt install speedtest-cli"