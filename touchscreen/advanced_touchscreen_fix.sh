#!/bin/bash

echo "=== Solución Avanzada Touchscreen Surface ==="

# 1. Verificar y configurar dispositivos de entrada
echo "🔍 Verificando dispositivos de entrada..."
if [ -e /dev/input/event23 ]; then
    echo "✅ Touchscreen virtual detectado: /dev/input/event23"
else
    echo "❌ No se encuentra touchscreen virtual"
fi

# 2. Configurar permisos específicos
echo "🔧 Configurando permisos..."
sudo chmod 666 /dev/input/event21 /dev/input/event23 2>/dev/null

# 3. Reiniciar IPTSD con configuración específica
echo "🔄 Reiniciando IPTSD..."
sudo pkill -f iptsd
sleep 1

# Buscar el dispositivo hidraw correcto para IPTS
HIDRAW_DEVICE=$(find /dev -name "hidraw*" -exec grep -l "1B96:006A" /sys/class/hidraw/{}/device/uevent \; 2>/dev/null | head -1)
if [ -n "$HIDRAW_DEVICE" ]; then
    echo "✅ Dispositivo HIDRAW encontrado: $HIDRAW_DEVICE"
    sudo iptsd "$HIDRAW_DEVICE" &
    sleep 2
else
    echo "⚠️  Usando dispositivo por defecto"
    sudo iptsd /dev/hidraw2 &
    sleep 2
fi

# 4. Configuraciones específicas de Wayland/GNOME
echo "⚙️  Aplicando configuraciones GNOME..."

# Desactivar bloqueo de orientación
gsettings set org.gnome.settings-daemon.peripherals.touchscreen orientation-lock false

# Configurar entrada táctil
gsettings set org.gnome.desktop.interface gtk-im-module ''
gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled false

# 5. Mapeo específico del touchscreen
echo "🎯 Configurando mapeo de touchscreen..."
TOUCH_ID=$(xinput list | grep -i "xwayland-touch" | grep -o "id=[0-9]*" | cut -d= -f2)
if [ -n "$TOUCH_ID" ]; then
    echo "✅ Touchscreen ID: $TOUCH_ID"
    # Mapear al display principal
    xinput map-to-output "$TOUCH_ID" eDP-1 2>/dev/null || xinput map-to-output "$TOUCH_ID" DP-1 2>/dev/null || true
else
    echo "⚠️  No se pudo obtener ID del touchscreen"
fi

# 6. Test final
echo ""
echo "🧪 Estado final:"
echo "IPTSD ejecutándose: $(pgrep -x iptsd >/dev/null && echo 'Sí' || echo 'No')"
echo "Dispositivos disponibles:"
xinput list | grep -i touch

echo ""
echo "✅ Configuración avanzada completada!"
echo ""
echo "🔬 Para diagnosticar problemas:"
echo "1. Ejecuta: journalctl -f | grep -i ipts"
echo "2. O ejecuta: ./fix_touchscreen.sh monitor"
echo "3. Toca la pantalla para verificar respuesta"