#!/bin/bash

echo "=== Configuración mejorada de InputLeap para GDM ==="
echo

# Verificar permisos sudo
if ! sudo -n true 2>/dev/null; then
    echo "Este script requiere permisos de sudo."
    exit 1
fi

# 1. Detener y deshabilitar servicios conflictivos
echo "1. Deshabilitando servicios conflictivos..."
sudo systemctl stop inputleap-autostart.service 2>/dev/null || true
sudo systemctl disable inputleap-autostart.service 2>/dev/null || true
sudo systemctl stop gnome-remote-desktop.service 2>/dev/null || true
sudo systemctl disable gnome-remote-desktop.service 2>/dev/null || true
sudo systemctl mask gnome-remote-desktop.service 2>/dev/null || true

# 2. Instalar InputLeap a nivel del sistema
echo "2. Instalando InputLeap a nivel del sistema..."
if ! flatpak list --system | grep -q input-leap; then
    sudo flatpak install --system -y flathub io.github.input_leap.input-leap
fi

# 3. Crear directorio de configuración para gdm
echo "3. Configurando directorio para gdm..."
sudo mkdir -p /var/lib/gdm3/.config/inputleap
sudo mkdir -p /var/lib/gdm3/.local/share/flatpak

# 4. Crear configuración de InputLeap para gdm
echo "4. Creando configuración optimizada..."
sudo tee /var/lib/gdm3/.config/inputleap/InputLeap.conf > /dev/null << 'EOF'
[General]
autoConnect=true
autoHide=true
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
loadFromSystemTray=false
logLevel=1
logToFile=false
minimizeToTray=false
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

# 5. Establecer permisos correctos
sudo chown -R gdm:gdm /var/lib/gdm3/.config/
sudo chown -R gdm:gdm /var/lib/gdm3/.local/

# 6. Crear servicio mejorado
echo "5. Instalando servicio mejorado..."
sudo cp inputleap-gdm-fixed.service /etc/systemd/system/

# 7. Crear script de deshabilitación del escritorio remoto
echo "6. Deshabilitando escritorio remoto de GNOME..."
sudo tee /etc/dconf/db/gdm.d/01-disable-remote-desktop > /dev/null << 'EOF'
[org/gnome/desktop/remote-desktop/rdp]
enable=false

[org/gnome/desktop/remote-desktop/vnc]
enable=false

[org/gnome/settings-daemon/plugins/sharing]
active=false
EOF

# 8. Actualizar base de datos dconf
sudo dconf update

# 9. Habilitar el servicio
echo "7. Habilitando servicio..."
sudo systemctl daemon-reload
sudo systemctl enable inputleap-gdm-fixed.service

echo
echo "=== CONFIGURACIÓN COMPLETADA ==="
echo
echo "✓ InputLeap se iniciará automáticamente en la pantalla de login"
echo "✓ No mostrará iconos en system tray"
echo "✓ Escritorio remoto de GNOME deshabilitado"
echo "✓ Servidor configurado: 192.168.0.114:24800"
echo "✓ Cliente configurado: Rivendel"
echo
echo "Para probar ahora:"
echo "  sudo systemctl start inputleap-gdm-fixed.service"
echo "  sudo systemctl status inputleap-gdm-fixed.service"
echo
echo "Para ver logs en tiempo real:"
echo "  sudo journalctl -u inputleap-gdm-fixed.service -f"
echo
echo "NOTA: Reinicia el sistema para probar el funcionamiento completo."