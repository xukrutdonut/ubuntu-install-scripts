#!/bin/bash
# Solución definitiva para glitches horizontales en DisplayLink MB16AC
# Geekom GT2 Mega - Distribución correcta de pantallas entre buses USB

echo "=== SOLUCION DEFINITIVA PARA GLITCHES DISPLAYLINK ==="
echo ""

# Verificar dispositivos DisplayLink actuales
echo "1. ESTADO ACTUAL:"
lsusb | grep -i display | nl
echo ""

# Mostrar distribución por buses
echo "2. DISTRIBUCION EN BUSES USB:"
echo "Bus 003 (saturado): $(lsusb | grep 'Bus 003.*DisplayLink' | wc -l) pantallas DisplayLink"
echo "Bus 002 (20Gbps):   $(lsusb | grep 'Bus 002.*DisplayLink' | wc -l) pantallas DisplayLink" 
echo "Bus 004 (20Gbps):   $(lsusb | grep 'Bus 004.*DisplayLink' | wc -l) pantallas DisplayLink"
echo ""

echo "3. PROBLEMA DETECTADO:"
if [ $(lsusb | grep 'Bus 003.*DisplayLink' | wc -l) -gt 1 ]; then
    echo "❌ AMBAS pantallas en Bus 003 (480Mbps) - CAUSA DE LOS GLITCHES"
    echo ""
    echo "4. SOLUCION REQUERIDA:"
    echo "📌 MOVER UNA PANTALLA A PUERTO USB DIFERENTE"
    echo ""
    echo "PUERTOS FISICOS RECOMENDADOS:"
    echo "• Puerto USB-C IZQUIERDO  → Bus 002 (20Gbps) ✅"
    echo "• Puerto USB-C DERECHO    → Bus 004 (20Gbps) ✅" 
    echo "• Puertos USB-A traseros  → Bus 003 (480Mbps) ❌ NO usar ambos"
    echo ""
    echo "PASOS PARA SOLUCIONAR:"
    echo "1️⃣  Desconecta UNA pantalla DisplayLink MB16AC"
    echo "2️⃣  Conecta esa pantalla a un puerto USB-C diferente"
    echo "3️⃣  Si no tienes cables USB-C, usa adaptador USB-A→USB-C"
    echo "4️⃣  Ejecuta este script de nuevo para verificar"
    echo ""
    echo "ALTERNATIVAS SI NO FUNCIONA:"
    echo "• Reducir resolución a 1600x1080 en una pantalla"
    echo "• Usar solo UNA pantalla DisplayLink en resolución completa"
    echo "• Conectar una pantalla por HDMI/DisplayPort nativo"
else
    echo "✅ Distribución correcta - aplicando optimizaciones..."
    
    # Optimizaciones para DisplayLink
    echo ""
    echo "5. APLICANDO OPTIMIZACIONES:"
    
    # Desactivar cursor blinking para reducir carga
    sudo sh -c 'echo 0 > /sys/module/evdi/parameters/enable_cursor_blinking' 2>/dev/null && echo "✓ Cursor blinking desactivado" || echo "⚠ Módulo EVDI no encontrado"
    
    # Optimizar memoria virtual
    sudo sysctl -w vm.dirty_ratio=5 2>/dev/null && echo "✓ Dirty ratio optimizado"
    sudo sysctl -w vm.dirty_background_ratio=2 2>/dev/null && echo "✓ Background ratio optimizado"
    
    # Reconfigurar pantallas con refresh rate optimizado
    echo ""
    echo "6. RECONFIGURANDO PANTALLAS:"
    xrandr --output DVI-I-1 --off 2>/dev/null
    xrandr --output DVI-I-2 --off 2>/dev/null
    sleep 2
    
    # Configurar pantalla principal
    xrandr --output DVI-I-1 --mode 1920x1080 --rate 60 --primary 2>/dev/null && echo "✓ Pantalla principal configurada"
    sleep 1
    
    # Configurar pantalla secundaria
    xrandr --output DVI-I-2 --mode 1920x1080 --rate 60 --right-of DVI-I-1 2>/dev/null && echo "✓ Pantalla secundaria configurada"
    
    echo ""
    echo "✅ OPTIMIZACIONES APLICADAS CORRECTAMENTE"
fi

echo ""
echo "=== VERIFICACION FINAL ==="
echo "Pantallas activas:"
xrandr --listmonitors
echo ""
echo "Si los glitches persisten, el problema es físico del ancho de banda USB."
echo "La única solución definitiva es separar las pantallas en buses USB diferentes."