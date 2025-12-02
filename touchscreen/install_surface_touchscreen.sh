#!/bin/bash

echo "=== Instalación de Touchscreen para Surface ==="

# Verificar que estamos en una Surface
if ! lsusb | grep -i "Microsoft Corp" > /dev/null; then
    echo "⚠️  No se detectó hardware de Microsoft Surface"
fi

# Verificar dispositivo IPTS
if lsinput 2>/dev/null | grep -i "IPTS\|Touchscreen" > /dev/null; then
    echo "✅ Touchscreen IPTS detectado"
else
    echo "⚠️  Touchscreen IPTS no detectado claramente"
fi

echo ""
echo "Paso 1: Instalando paquetes necesarios..."
sudo apt update
sudo apt install -y iptsd

echo ""
echo "Paso 2: Configurando servicio IPTSD..."
sudo systemctl enable iptsd
sudo systemctl start iptsd

echo ""
echo "Paso 3: Verificando estado del servicio..."
sudo systemctl status iptsd --no-pager

echo ""
echo "Paso 4: Configurando touchscreen en GNOME..."
# Habilitar touchscreen
gsettings set org.gnome.desktop.a11y.applications screen-magnifier-enabled false
gsettings set org.gnome.settings-daemon.plugins.color active true

echo ""
echo "Paso 5: Instalando herramientas adicionales..."
sudo apt install -y \
    evtest \
    input-utils \
    xinput

echo ""
echo "=== DIAGNÓSTICO ==="
echo "Dispositivos de entrada detectados:"
cat /proc/bus/input/devices | grep -A5 -B2 "Touchscreen\|IPTS"

echo ""
echo "=== INSTRUCCIONES FINALES ==="
echo "1. Reinicia el sistema para aplicar todos los cambios"
echo "2. Después del reinicio, verifica que funciona:"
echo "   - Toca la pantalla para probar"
echo "   - Ejecuta: systemctl status iptsd"
echo "3. Si no funciona, ejecuta: sudo journalctl -u iptsd -f"
echo ""
echo "Para calibrar el touchscreen:"
echo "- Instala: sudo apt install xinput-calibrator"
echo "- Ejecuta: xinput_calibrator"