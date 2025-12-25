#!/bin/bash

echo "=== Instalación de VNC Server con XFCE ==="
echo ""

# Instalar paquetes necesarios
echo "Instalando paquetes..."
sudo apt install -y tigervnc-standalone-server tigervnc-common xfce4 xfce4-goodies dbus-x11

# Dar permisos al archivo xstartup
chmod +x ~/.vnc/xstartup

# Configurar contraseña VNC
echo ""
echo "Configura tu contraseña VNC (máximo 8 caracteres):"
vncpasswd

# Copiar servicio systemd
sudo cp ~/vncserver@.service /etc/systemd/system/

# Recargar systemd
sudo systemctl daemon-reload

# Habilitar servicio en el puerto 5901 (display :1)
sudo systemctl enable vncserver@1.service

# Iniciar servicio
sudo systemctl start vncserver@1.service

# Mostrar estado
echo ""
echo "Estado del servicio VNC:"
sudo systemctl status vncserver@1.service

echo ""
echo "=== Configuración completada ==="
echo ""
echo "Conexión VNC:"
echo "  - Host: $(hostname -I | awk '{print $1}') o localhost"
echo "  - Puerto: 5901"
echo "  - Contraseña: la que configuraste con vncpasswd"
echo ""
echo "Para Guacamole usa:"
echo "  - Connection Name: VNC Desktop"
echo "  - Protocol: VNC"
echo "  - Hostname: localhost"
echo "  - Port: 5901"
echo "  - Password: tu contraseña VNC"
