#!/bin/bash

echo "=== DIAGNÓSTICO DE RED ==="
echo

echo "🔌 INTERFACES DE RED:"
ip addr show | grep -E '^[0-9]|inet '
echo

echo "📡 CONEXIONES ACTIVAS:"
nmcli connection show --active
echo

echo "🛣️  TABLA DE RUTAS:"
ip route show
echo

echo "📊 MÉTRICAS DE CONEXIÓN:"
nmcli -f NAME,TYPE,DEVICE,METRIC connection show --active
echo

echo "🌐 TEST DE CONECTIVIDAD:"
if [ ! -z "$1" ]; then
    echo "Probando conectividad hacia: $1"
    ping -c 3 "$1"
else
    echo "Probando conectividad hacia gateway:"
    GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
    if [ ! -z "$GATEWAY" ]; then
        ping -c 3 "$GATEWAY"
    else
        echo "No se encontró gateway por defecto"
    fi
fi
echo

echo "🔧 PARÁMETROS DE RED OPTIMIZADOS:"
echo "net.core.rmem_max: $(sysctl -n net.core.rmem_max 2>/dev/null || echo 'no configurado')"
echo "net.core.wmem_max: $(sysctl -n net.core.wmem_max 2>/dev/null || echo 'no configurado')"
echo "net.ipv4.tcp_congestion_control: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'no configurado')"
echo

echo "💡 USO: $0 [IP_DESTINO] para probar conectividad específica"
