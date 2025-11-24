#!/bin/bash

# DisplayLink Driver Installation Script for Ubuntu
# Created: 2025-11-20
# Description: Installs DisplayLink drivers to enable USB displays

set -e

echo "🖥️  Iniciando instalación de DisplayLink para Ubuntu..."

# Crear directorio temporal
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "📦 Descargando repositorio de Synaptics..."
wget https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/main/all/synaptics-repository-keyring.deb

echo "🔧 Instalando keyring de Synaptics..."
sudo dpkg -i synaptics-repository-keyring.deb

echo "🔄 Actualizando repositorios..."
sudo apt update

echo "📥 Instalando DisplayLink driver..."
sudo apt install -y displaylink-driver

# Método alternativo si el anterior falla
echo "📋 Preparando método alternativo (por si acaso)..."
echo "Si la instalación anterior falló, ejecuta estos comandos:"
echo "wget https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/main/all/displaylink-driver_1.9.1-A.159.181_all.deb"
echo "sudo apt install -y dkms linux-headers-generic"
echo "sudo dpkg -i displaylink-driver_1.9.1-A.159.181_all.deb"

# Limpiar archivos temporales
cd /home/arkantu
rm -rf "$TEMP_DIR"

echo "✅ Instalación completada!"
echo "🔄 REINICIA el sistema para que los cambios surtan efecto:"
echo "    sudo reboot"
echo ""
echo "🖥️  Después del reinicio, conecta tu pantalla USB y debería funcionar automáticamente."
echo ""
echo "🔍 Para verificar que funciona:"
echo "    xrandr"
echo "    lsusb | grep DisplayLink"