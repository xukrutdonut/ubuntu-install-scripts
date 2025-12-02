#!/bin/bash

echo "=== Configuración Ultra-Sensible del Touchscreen ==="
echo ""

# Obtener ID del touchscreen
TOUCH_ID=$(xinput list | grep -i "xwayland-touch\|touchscreen" | grep -o "id=[0-9]*" | cut -d= -f2 | head -1)

if [ -z "$TOUCH_ID" ]; then
    echo "❌ No se encontró dispositivo touchscreen"
    exit 1
fi

echo "🔍 Dispositivo encontrado: ID $TOUCH_ID"

# Aplicar configuración ultra-sensible
echo "🚀 Aplicando configuración ultra-sensible..."

# Factor de sensibilidad extremo
xinput set-prop "$TOUCH_ID" "Coordinate Transformation Matrix" 4.0 0 0 0 4.0 0 0 0 1

# Configuraciones GNOME para máxima respuesta
echo "⚙️ Configurando GNOME..."
gsettings set org.gnome.desktop.peripherals.touchscreen orientation-lock false
gsettings set org.gnome.settings-daemon.peripherals.touchscreen orientation-lock false

# Configurar todas las propiedades libinput disponibles
echo "🔧 Configurando libinput..."

# Intentar configurar todas las propiedades de sensibilidad posibles
xinput set-prop "$TOUCH_ID" "libinput Accel Speed" 1.0 2>/dev/null || echo "  - Accel Speed: no disponible"
xinput set-prop "$TOUCH_ID" "libinput Natural Scrolling Enabled" 0 2>/dev/null || echo "  - Natural Scrolling: no disponible"
xinput set-prop "$TOUCH_ID" "libinput Disable While Typing Enabled" 0 2>/dev/null || echo "  - Disable While Typing: desactivado"
xinput set-prop "$TOUCH_ID" "libinput Tap Enabled" 1 2>/dev/null || echo "  - Tap: no disponible"
xinput set-prop "$TOUCH_ID" "libinput Tap-and-Drag Enabled" 1 2>/dev/null || echo "  - Tap-and-Drag: no disponible"

# Configuraciones específicas para touchscreen
xinput set-prop "$TOUCH_ID" "libinput Calibration Matrix" 4.0 0 0 0 4.0 0 0 0 1 2>/dev/null || echo "  - Calibration Matrix: usando Coordinate Transform"

echo ""
echo "📊 Configuración actual:"
xinput list-props "$TOUCH_ID" | grep "Coordinate Transformation Matrix"

echo ""
echo "✅ Configuración ultra-sensible aplicada!"
echo ""
echo "📝 IMPORTANTE:"
echo "1. Toca la pantalla SUAVEMENTE para probar"
echo "2. Si es demasiado sensible, ejecuta: $0 reset"
echo "3. Si sigue siendo poco sensible, puede ser un problema de hardware/driver"
echo ""
echo "🔧 Para diagnosticar problemas de hardware:"
echo "   sudo evtest /dev/input/event5   # IPTSD Virtual Touchscreen"
echo "   (presiona Ctrl+C para salir)"
echo ""

# Función de reset
if [ "$1" = "reset" ]; then
    echo "🔄 Restaurando configuración normal..."
    xinput set-prop "$TOUCH_ID" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
    echo "✅ Configuración restaurada"
fi

# Función de diagnóstico
if [ "$1" = "test" ]; then
    echo "🧪 Iniciando test de hardware..."
    echo "Presiona Ctrl+C para salir del test"
    echo "Si no ves eventos al tocar, hay un problema de hardware/driver"
    echo ""
    sudo evtest /dev/input/event5 2>/dev/null || echo "❌ No se puede acceder al dispositivo de hardware"
fi