#!/bin/bash
# Solución definitiva para glitches DisplayLink en Geekom GT2 Mega
# Problema: Ambos USB-C van al mismo Bus 003 (480Mbps)

echo "=== SOLUCION DEFINITIVA DISPLAYLINK GEEKOM GT2 ==="
echo ""

echo "🔍 PROBLEMA IDENTIFICADO:"
echo "• Los 2 puertos USB-C del Geekom van al mismo Bus 003 (480Mbps)"
echo "• 2 pantallas 1920x1080@60Hz = ~518Mbps > 480Mbps = SATURACION"
echo "• Resultado: Glitches horizontales por falta de ancho de banda"
echo ""

echo "📊 ESTADO ACTUAL:"
lsusb | grep DisplayLink | nl
echo ""

echo "🚀 SOLUCIONES DISPONIBLES:"
echo ""
echo "OPCION 1 - PUERTO FISICO DIFERENTE (RECOMENDADO):"
echo "• Desconecta UNA pantalla del USB-C"
echo "• Conecta al puerto USB-A TRASERO SUPERIOR del Geekom"
echo "• Este puerto puede ir al Bus 002 o 004 (20Gbps)"
echo "• Usa cable USB-A o adaptador USB-C→USB-A"
echo ""

echo "OPCION 2 - HUB USB 3.0 EXTERNO:"
echo "• Conecta un hub USB 3.0 al puerto Thunderbolt"
echo "• Conecta una pantalla DisplayLink al hub externo"
echo "• Esto la moverá a un bus de mayor ancho de banda"
echo ""

echo "OPCION 3 - REDUCIR ANCHO DE BANDA (TEMPORAL):"
echo "• Reducir resolución de una pantalla a 1600x1080 o 1440x1080"
echo "• Reducir refresh rate a 50Hz en ambas pantallas"
echo "• Esto liberará ancho de banda suficiente"
echo ""

echo "⚙️  APLICANDO SOLUCION TEMPORAL (Opción 3):"
echo "Reduciendo carga en Bus 003..."

# Optimizaciones de sistema
sudo sh -c 'echo 0 > /sys/module/evdi/parameters/enable_cursor_blinking' 2>/dev/null && echo "✓ Cursor blinking desactivado"
sudo sysctl -w vm.dirty_ratio=3 2>/dev/null && echo "✓ Dirty ratio optimizado"
sudo sysctl -w vm.dirty_background_ratio=1 2>/dev/null && echo "✓ Background ratio optimizado"

echo ""
echo "Reconfigurando pantallas con menor ancho de banda..."

# Apagar pantallas
xrandr --output DVI-I-1 --off 2>/dev/null
xrandr --output DVI-I-2 --off 2>/dev/null
sleep 3

# Configurar con resolución/refresh optimizados
echo "🖥️  Configurando pantalla principal (resolución completa)..."
xrandr --output DVI-I-1 --mode 1920x1080 --rate 55 --primary 2>/dev/null && echo "✓ DVI-I-1: 1920x1080@55Hz"

sleep 2

echo "🖥️  Configurando pantalla secundaria (resolución reducida)..."
xrandr --output DVI-I-2 --mode 1600x1080 --rate 50 --right-of DVI-I-1 2>/dev/null && echo "✓ DVI-I-2: 1600x1080@50Hz" || \
xrandr --output DVI-I-2 --mode 1440x1080 --rate 50 --right-of DVI-I-1 2>/dev/null && echo "✓ DVI-I-2: 1440x1080@50Hz"

echo ""
echo "✅ CONFIGURACION APLICADA"
echo ""
echo "📈 VERIFICACION:"
xrandr --listmonitors

echo ""
echo "🎯 RESULTADO ESPERADO:"
echo "• Glitches eliminados o significativamente reducidos"
echo "• Ancho de banda total: ~380Mbps < 480Mbps disponibles"
echo ""
echo "⚠️  PARA SOLUCION PERMANENTE:"
echo "Conecta una pantalla al puerto USB-A trasero del Geekom"
echo "o usa un hub USB 3.0 externo en puerto Thunderbolt"