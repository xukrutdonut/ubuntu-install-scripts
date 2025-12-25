#!/bin/bash

echo "=== Iniciando Surface Pen ==="

# Buscar dispositivo Surface Pen
HIDRAW_DEVICE=""
for device in /sys/class/hidraw/hidraw*/device/uevent; do
    if grep -q "1B96:006A" "$device" 2>/dev/null; then
        HIDRAW_NUM=$(echo "$device" | grep -o 'hidraw[0-9]*' | grep -o '[0-9]*')
        HIDRAW_DEVICE="/dev/hidraw$HIDRAW_NUM"
        break
    fi
done

if [ -n "$HIDRAW_DEVICE" ]; then
    echo "🖊️ Surface Pen encontrado en: $HIDRAW_DEVICE"
    
    # Detener iptsd si ya está corriendo
    if pgrep iptsd > /dev/null; then
        echo "Deteniendo iptsd anterior..."
        sudo pkill iptsd
        sleep 2
    fi
    
    echo "Iniciando iptsd para Surface Pen..."
    sudo iptsd "$HIDRAW_DEVICE" &
    
    echo "✅ Surface Pen iniciado correctamente"
    echo ""
    echo "Para configurar sensibilidad:"
    echo "  ./configure_surface_pen.sh sensitivity 7"
else
    echo "❌ No se encontró Surface Pen (ID: 1B96:006A)"
    echo ""
    echo "Intentando iniciar iptsd genérico..."
    sudo systemctl start iptsd
    
    if systemctl is-active --quiet iptsd; then
        echo "✅ Servicio iptsd iniciado"
    else
        echo "❌ Error iniciando iptsd"
    fi
fi

echo ""
echo "Para verificar estado:"
echo "  ./configure_surface_pen.sh show"
