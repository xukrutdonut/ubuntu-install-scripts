#!/bin/bash

echo "=== Configurando InputLeap para GDM (inicio automático) ==="
echo

# Verificar si el usuario tiene permisos de sudo
if ! sudo -n true 2>/dev/null; then
    echo "Este script requiere permisos de sudo."
    exit 1
fi

# 1. Actualizar el servicio systemd para GDM
echo "1. Actualizando servicio systemd para GDM..."
sudo cp inputleap-autostart.service /etc/systemd/system/

# 2. Verificar usuario gdm
echo "2. Verificando usuario GDM..."
id gdm >/dev/null 2>&1 || {
    echo "Error: Usuario gdm no encontrado. Usando configuración alternativa..."
    # Crear servicio alternativo que ejecute como root
    sudo tee /etc/systemd/system/inputleap-autostart.service > /dev/null << 'EOF'
[Unit]
Description=InputLeap Client Auto-start
Before=display-manager.service
After=network-online.target graphical-session-pre.target
Wants=network-online.target

[Service]
Type=simple
Environment=DISPLAY=:0
Environment=WAYLAND_DISPLAY=wayland-0
ExecStartPre=/bin/sleep 10
ExecStart=/bin/bash -c 'export DISPLAY=:0; export WAYLAND_DISPLAY=wayland-0; /usr/bin/flatpak run --system io.github.input_leap.input-leap'
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=graphical.target
EOF
}

# 3. Instalar InputLeap a nivel del sistema si no está
echo "3. Verificando instalación de InputLeap a nivel del sistema..."
if ! flatpak list --system | grep -q input-leap; then
    echo "Instalando InputLeap a nivel del sistema..."
    sudo flatpak install --system -y flathub io.github.input_leap.input-leap
else
    echo "InputLeap ya está instalado a nivel del sistema"
fi

# 4. Crear configuración para autoconexión
echo "4. Creando configuración de autoconexión..."
sudo mkdir -p /etc/inputleap
sudo tee /etc/inputleap/inputleap-client.conf > /dev/null << EOF
# InputLeap Client Configuration
section: screens
    # Define los nombres de las pantallas
    Rivendel:
    end
section: aliases
    # Aliases para las pantallas
    end
section: links
    # Configuración de enlaces entre pantallas
    end
section: options
    # Opciones globales
    screenSaverSync = false
    relativeMouseMoves = false
    switchCorners = none
    switchCornerSize = 0
    end
EOF

# 5. Crear script de inicio simple
echo "5. Creando script de inicio..."
sudo tee /usr/local/bin/inputleap-client-start > /dev/null << 'EOF'
#!/bin/bash
# Script de inicio para InputLeap Cliente

export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0

# Esperar a que el display esté disponible
while ! xset q >/dev/null 2>&1 && [ ! -S "/run/user/$(id -u gdm 2>/dev/null || echo 1000)/wayland-0" ]; do
    sleep 1
done

# Configurar cliente InputLeap
SERVER_IP="192.168.0.114"
CLIENT_NAME="Rivendel"

# Ejecutar InputLeap en modo cliente
/usr/bin/flatpak run --system io.github.input_leap.input-leap --client --server $SERVER_IP --name $CLIENT_NAME --config /etc/inputleap/inputleap-client.conf
EOF

sudo chmod +x /usr/local/bin/inputleap-client-start

# 6. Actualizar el servicio para usar el script
sudo tee /etc/systemd/system/inputleap-autostart.service > /dev/null << 'EOF'
[Unit]
Description=InputLeap Client Auto-start
After=network-online.target graphical-session-pre.target
Wants=network-online.target
Before=gdm.service

[Service]
Type=simple
ExecStart=/usr/local/bin/inputleap-client-start
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=graphical.target
EOF

# 7. Habilitar el servicio
echo "6. Habilitando servicio..."
sudo systemctl daemon-reload
sudo systemctl enable inputleap-autostart.service

echo
echo "=== CONFIGURACIÓN COMPLETADA ==="
echo
echo "InputLeap se iniciará automáticamente antes del login de GDM."
echo "Servidor configurado: 192.168.0.114"
echo "Nombre del cliente: Rivendel"
echo
echo "Para probar:"
echo "  sudo systemctl start inputleap-autostart.service"
echo "  sudo systemctl status inputleap-autostart.service"
echo
echo "Para ver logs:"
echo "  sudo journalctl -u inputleap-autostart.service -f"
echo
echo "Para deshabilitar:"
echo "  sudo systemctl disable inputleap-autostart.service"
echo
echo "NOTA: Reinicia el sistema para probar el inicio automático completo."