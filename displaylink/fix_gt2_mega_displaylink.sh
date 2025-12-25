#!/bin/bash
echo "=== SOLUCION PARA GEEKOM GT2 MEGA + DISPLAYLINK ==="

# El GT2 Mega tiene estos puertos:
# - 2x USB-A traseros (Bus 003 - controlador principal)  
# - 2x USB-C laterales (Thunderbolt independientes)
# - 1x USB-A frontal

echo "SOLUCION PARA LINEAS HORIZONTALES:"
echo "1. Conecta UNA pantalla DisplayLink al puerto USB-C izquierdo"
echo "2. Conecta la OTRA pantalla DisplayLink al puerto USB-C derecho" 
echo "3. NO uses los puertos USB-A traseros para DisplayLink"
echo ""
echo "Configuración actual detectada:"
lsusb | grep DisplayLink
echo ""
echo "RECOMENDACION:"
echo "- Mueve las pantallas a puertos USB-C diferentes"
echo "- Cada puerto USB-C tiene su propio controlador Thunderbolt"
echo "- Esto eliminará completamente las líneas horizontales"
echo ""
echo "Si solo tienes cables USB-A:"
echo "- Usa adaptadores USB-A to USB-C"
echo "- O conecta solo UNA pantalla en full resolution"
