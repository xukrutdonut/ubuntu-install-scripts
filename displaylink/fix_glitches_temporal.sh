#!/bin/bash
# Solución temporal - Reducir carga en Bus USB 003
echo "=== SOLUCION TEMPORAL PARA GLITCHES ==="

# Reducir resolución de una pantalla para liberar ancho de banda
echo "Reduciendo resolución de DVI-I-2 temporalmente..."
xrandr --output DVI-I-2 --mode 1600x1080 --rate 59 --right-of DVI-I-1 2>/dev/null || \
xrandr --output DVI-I-2 --mode 1440x1080 --rate 59 --right-of DVI-I-1

echo "✓ Resolución reducida en pantalla secundaria"
echo "Esto debería eliminar los glitches temporalmente"
echo ""
echo "Para solución definitiva: mueve una pantalla a puerto USB-C diferente"