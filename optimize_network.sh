#!/bin/bash

echo "=== Optimización de Red ==="

# Aplicar optimizaciones temporales
echo "1. Aplicando optimizaciones temporales..."
sudo sysctl -w net.core.rmem_max=16777216
sudo sysctl -w net.core.wmem_max=16777216
sudo sysctl -w net.core.rmem_default=262144
sudo sysctl -w net.core.wmem_default=262144
sudo sysctl -w net.ipv4.tcp_rmem="4096 65536 16777216"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216"
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr
sudo sysctl -w net.core.netdev_max_backlog=5000

echo "2. Para hacer permanente, ejecuta:"
echo "sudo tee -a /etc/sysctl.conf << EOL"
echo "# Optimizaciones de red"
echo "net.core.rmem_max=16777216"
echo "net.core.wmem_max=16777216"
echo "net.core.rmem_default=262144"
echo "net.core.wmem_default=262144"
echo "net.ipv4.tcp_rmem=4096 65536 16777216"
echo "net.ipv4.tcp_wmem=4096 65536 16777216"
echo "net.ipv4.tcp_congestion_control=bbr"
echo "net.core.netdev_max_backlog=5000"
echo "EOL"

echo "✅ Optimizaciones aplicadas"
echo "💡 Instala speedtest-cli: sudo apt install speedtest-cli"
