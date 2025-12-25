#!/bin/bash

echo "=== Optimizando Red para InputLeap ==="

# Configurar WiFi para menor latencia
echo "Configurando WiFi para gaming/baja latencia..."
sudo iw dev wlp2s0 set power_save off 2>/dev/null || echo "No se pudo desactivar power save"

# Optimizar TCP para baja latencia
echo "Aplicando optimizaciones TCP..."
sudo sysctl -w net.ipv4.tcp_low_latency=1 2>/dev/null || true
sudo sysctl -w net.core.netdev_max_backlog=5000 2>/dev/null || true
sudo sysctl -w net.ipv4.tcp_fastopen=3 2>/dev/null || true
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null || true
sudo sysctl -w net.core.default_qdisc=fq 2>/dev/null || true

# Optimizar buffers específicamente para InputLeap
echo "Optimizando buffers de red..."
sudo sysctl -w net.core.rmem_default=262144 2>/dev/null || true
sudo sysctl -w net.core.wmem_default=262144 2>/dev/null || true
sudo sysctl -w net.core.rmem_max=16777216 2>/dev/null || true
sudo sysctl -w net.core.wmem_max=16777216 2>/dev/null || true

# Prioridad de red para InputLeap
echo "Configurando QoS para InputLeap..."
sudo tc qdisc add dev wlp2s0 root handle 1: prio 2>/dev/null || true
sudo tc filter add dev wlp2s0 parent 1: protocol ip prio 1 u32 match ip dport 24800 0xffff flowid 1:1 2>/dev/null || true

echo "Optimizaciones aplicadas. Reinicia InputLeap para ver mejoras."