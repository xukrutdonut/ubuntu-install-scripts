#!/bin/bash
# Script para instalar DietPi en SD con configuración personalizada
# Usuario: arkantu | Contraseña: akelarre
# WiFi SSID: Casa-Aiz-Al | WiFi Pass: akelarre

set -e

echo "=== Instalador DietPi Personalizado ==="
echo ""
echo "CONFIGURACIÓN:"
echo "- Usuario SSH: arkantu"
echo "- Contraseña: akelarre"
echo "- WiFi SSID: Casa-Aiz-Al"
echo "- WiFi Password: akelarre"
echo ""

# Detectar tarjeta SD
echo "Detectando tarjetas SD disponibles..."
lsblk -p | grep -E "sd[a-z]|mmcblk"
echo ""
read -p "Introduce el dispositivo de la SD (ejemplo: /dev/sda): " SD_DEVICE

if [ ! -b "$SD_DEVICE" ]; then
    echo "ERROR: $SD_DEVICE no es un dispositivo válido"
    exit 1
fi

echo ""
echo "⚠️  ADVERTENCIA: Se borrará TODO el contenido de $SD_DEVICE"
read -p "¿Continuar? (escribir 'SI' en mayúsculas): " CONFIRM

if [ "$CONFIRM" != "SI" ]; then
    echo "Instalación cancelada"
    exit 0
fi

# Descargar imagen DietPi
echo ""
echo "Paso 1: Descargando DietPi..."
cd ~/Downloads

# Usar Raspberry Pi Imager CLI si está disponible
if command -v rpi-imager &> /dev/null; then
    echo "Usando Raspberry Pi Imager..."
    echo ""
    echo "INSTRUCCIONES:"
    echo "1. Se abrirá Raspberry Pi Imager"
    echo "2. Selecciona 'CHOOSE OS' > 'Other specific-purpose OS' > 'DietPi'"
    echo "3. Selecciona la versión para tu Raspberry Pi"
    echo "4. Click en 'CHOOSE STORAGE' y selecciona: $SD_DEVICE"
    echo "5. Click en el ícono de configuración (⚙️) o CTRL+SHIFT+X"
    echo "6. Configura:"
    echo "   - Hostname: dietpi"
    echo "   - Enable SSH"
    echo "   - Username: arkantu"
    echo "   - Password: akelarre"
    echo "   - Configure WiFi:"
    echo "     * SSID: Casa-Aiz-Al"
    echo "     * Password: akelarre"
    echo "     * WiFi country: ES"
    echo "7. Click 'WRITE'"
    echo ""
    read -p "Presiona ENTER para abrir Raspberry Pi Imager..."
    
    rpi-imager
    
    echo ""
    echo "✅ Si completaste la instalación con Raspberry Pi Imager,"
    echo "   tu tarjeta SD está lista. Insértala en tu Raspberry Pi."
    echo ""
    echo "Conexión SSH:"
    echo "  ssh arkantu@dietpi.local"
    echo "  o busca la IP en tu router"
    
else
    echo "ERROR: Raspberry Pi Imager no encontrado"
    echo "Instálalo con: snap install rpi-imager"
    exit 1
fi
