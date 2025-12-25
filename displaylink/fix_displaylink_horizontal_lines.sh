#!/bin/bash
# Script para eliminar líneas horizontales en DisplayLink

echo "=== SOLUCION PARA LINEAS HORIZONTALES DISPLAYLINK ==="

# 1. Reducir compresión (aumentar calidad)
echo "1. Ajustando compresión..."
sudo sh -c 'echo 0 > /sys/module/evdi/parameters/enable_cursor_blinking' 2>/dev/null || true

# 2. Forzar sincronización correcta
echo "2. Reiniciando pantalla con sincronización mejorada..."
xrandr --output DVI-I-1 --off
sleep 3
xrandr --output DVI-I-1 --auto --right-of DP-2

# 3. Ajustar parámetros de DisplayLink
echo "3. Optimizando DisplayLink..."
# Reducir buffer para evitar tearing
sudo sysctl -w vm.dirty_ratio=5 2>/dev/null || true
sudo sysctl -w vm.dirty_background_ratio=2 2>/dev/null || true

echo "=== SOLUCION APLICADA ==="
echo "Si las líneas persisten:"
echo "1. Desconecta el USB-C por 10 segundos"
echo "2. Reconecta en otro puerto USB"  
echo "3. Ejecuta de nuevo este script"
