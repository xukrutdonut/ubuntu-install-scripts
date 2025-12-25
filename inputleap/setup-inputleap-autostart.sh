#!/bin/bash

echo "=== Configurando InputLeap para inicio automático ==="
echo

# Verificar si el usuario tiene permisos de sudo
if ! sudo -n true 2>/dev/null; then
    echo "Este script requiere permisos de sudo. Ejecuta: sudo $0"
    exit 1
fi

# 1. Crear el servicio systemd
echo "1. Creando servicio systemd..."
sudo cp inputleap-autostart.service /etc/systemd/system/

# 2. Configurar permisos para lightdm (usuario del display manager)
echo "2. Configurando permisos para lightdm..."
sudo usermod -a -G audio,video lightdm
sudo mkdir -p /var/lib/lightdm/.local/share/flatpak
sudo chown lightdm:lightdm /var/lib/lightdm/.local/share/flatpak

# 3. Instalar InputLeap para el usuario lightdm
echo "3. Instalando InputLeap para el usuario del sistema..."
sudo -u lightdm flatpak install --user -y flathub io.github.input_leap.input-leap 2>/dev/null || echo "InputLeap ya está instalado"

# 4. Crear configuración de InputLeap para lightdm
echo "4. Creando configuración básica..."
sudo mkdir -p /var/lib/lightdm/.config/inputleap
sudo tee /var/lib/lightdm/.config/inputleap/InputLeap.conf > /dev/null << EOF
[General]
autoConnect=true
autoHide=false
autoStart=true
cryptoEnabled=true
edition=1
elevateMode=0
gameDevice=false
groupClientChecked=false
groupServerChecked=false
interface=
invertConnection=false
invertScrollDirection=false
language=
loadFromSystemTray=true
logLevel=3
logToFile=false
minimizeToTray=true
processMode=Service
serverGroupChecked=false
serverHostname=192.168.0.114
serverPort=24800
startedBefore=true

[internalConfig]
useExternalConfig=false
configFile=
useInternalConfig=true
EOF

sudo chown -R lightdm:lightdm /var/lib/lightdm/.config/

# 5. Habilitar y iniciar el servicio
echo "5. Habilitando servicio..."
sudo systemctl daemon-reload
sudo systemctl enable inputleap-autostart.service

echo
echo "=== CONFIGURACIÓN COMPLETADA ==="
echo
echo "InputLeap se iniciará automáticamente antes del login."
echo "Configuración del servidor: 192.168.0.114:24800"
echo
echo "Para probar la configuración:"
echo "  sudo systemctl start inputleap-autostart.service"
echo "  sudo systemctl status inputleap-autostart.service"
echo
echo "Para deshabilitar:"
echo "  sudo systemctl disable inputleap-autostart.service"
echo