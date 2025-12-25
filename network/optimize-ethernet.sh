#!/bin/bash
# Script para optimizar la configuración de Ethernet al máximo

echo "Optimizando configuración de Ethernet..."

# Aumentar buffers de red
sudo sysctl -w net.core.netdev_max_backlog=10000
sudo sysctl -w net.core.rmem_max=67108864
sudo sysctl -w net.core.wmem_max=67108864
sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 67108864"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 67108864"

# Optimizaciones TCP adicionales
sudo sysctl -w net.ipv4.tcp_fastopen=3
sudo sysctl -w net.ipv4.tcp_mtu_probing=1
sudo sysctl -w net.core.default_qdisc=fq

# Aumentar ring buffers de las interfaces ethernet
sudo ethtool -G enp172s0 rx 4096 tx 4096 2>/dev/null || echo "Ring buffers ya al máximo en enp172s0"
sudo ethtool -G enp173s0 rx 4096 tx 4096 2>/dev/null || echo "Ring buffers ya al máximo en enp173s0"

# Habilitar rx-gro-list si está disponible
sudo ethtool -K enp172s0 rx-gro-list on 2>/dev/null
sudo ethtool -K enp173s0 rx-gro-list on 2>/dev/null

echo "Optimización completada. Configuración actual:"
echo "- Control de congestión: $(cat /proc/sys/net/ipv4/tcp_congestion_control)"
echo "- Backlog: $(sysctl -n net.core.netdev_max_backlog)"
echo "- Velocidad: $(ethtool enp172s0 2>/dev/null | grep Speed)"
