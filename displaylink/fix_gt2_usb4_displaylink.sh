#!/bin/bash
# Solución para DisplayLink en USB4 degradado a USB 2.0
# Geekom GT2 Mega - Forzar reconexión en alta velocidad

echo "=== SOLUCION USB4 DISPLAYLINK GT2 MEGA ==="
echo ""

echo "PROBLEMA DETECTADO:"
echo "• Ambas pantallas DisplayLink están en Bus 003 (480Mbps USB 2.0)"
echo "• Los puertos USB4 están degradando la conexión"
echo ""

echo "SOLUCION:"
echo "1. Reiniciar los controladores USB para forzar reconexión en alta velocidad"

# Desconectar DisplayLink temporalmente
echo "2. Desconectando DisplayLink..."
sudo modprobe -r evdi 2>/dev/null || true
sudo modprobe -r udl 2>/dev/null || true

# Reiniciar controladores USB4/Thunderbolt
echo "3. Reiniciando controladores USB4..."
echo '1' | sudo tee /sys/bus/pci/devices/*/remove 2>/dev/null | grep -v "Permission denied" || true
sleep 2
echo '1' | sudo tee /sys/bus/pci/rescan 2>/dev/null || true

# Recargar DisplayLink
echo "4. Recargando DisplayLink..."
sudo modprobe evdi
sudo modprobe udl

echo ""
echo "5. PASOS MANUALES REQUERIDOS:"
echo "   a) Desconecta físicamente AMBAS pantallas DisplayLink"
echo "   b) Espera 10 segundos"
echo "   c) Conecta PRIMERO la pantalla IZQUIERDA al puerto USB-C IZQUIERDO"
echo "   d) Espera 5 segundos hasta que aparezca la pantalla"
echo "   e) Conecta la pantalla DERECHA al puerto USB-C DERECHO"
echo ""

echo "6. Verificación después de reconectar:"
echo "   Ejecuta: lsusb | grep DisplayLink"
echo "   Las pantallas deben aparecer en Bus 002 y Bus 004 (no en Bus 003)"
echo ""

echo "7. ALTERNATIVAS SI NO FUNCIONA:"
echo "   • Usar cables USB-C nativos (no adaptadores USB-A→USB-C)"
echo "   • Verificar que los cables soportan datos (no solo carga)"
echo "   • Conectar solo UNA pantalla DisplayLink + una por HDMI nativo"
echo ""

echo "=== EJECUTA ESTE SCRIPT DESPUÉS DE RECONECTAR ==="