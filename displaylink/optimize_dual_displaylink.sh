#!/bin/bash
echo "=== OPTIMIZACION PARA 2 DISPLAYLINK ==="

# Reducir resolución de una pantalla para liberar ancho de banda
echo "1. Reduciendo resolución de segunda pantalla temporalmente..."
xrandr --output DVI-I-1 --mode 1440x1080 --rate 59.99 2>/dev/null || \
xrandr --output DVI-I-1 --mode 1280x1024 --rate 59.89

sleep 2

# Optimizar configuración de ambas pantallas
echo "2. Reconfigurar ambas pantallas con menor carga..."
xrandr --output DP-2 --mode 1920x1080 --rate 60
xrandr --output DVI-I-1 --mode 1440x1080 --rate 59.99

echo "=== OPTIMIZACION APLICADA ==="
echo "SOLUCION: Una pantalla a resolución reducida para evitar saturar USB"
echo "Si las líneas persisten:"
echo "1. Desconecta UNA pantalla DisplayLink"  
echo "2. Usa solo una pantalla en full resolution"
echo "3. O conecta una pantalla al USB-C y otra al Thunderbolt"
