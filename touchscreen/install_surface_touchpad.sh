#!/bin/bash

echo "Instalando soporte completo para touchpad de Surface..."

# Actualizar repositorios
sudo apt update

# Instalar paquetes necesarios
sudo apt install -y \
    touchpad-indicator \
    libinput-tools \
    xserver-xorg-input-libinput \
    gnome-tweaks

# Para mejorar compatibilidad con Surface
sudo apt install -y \
    thermald \
    tlp \
    tlp-rdw

echo "Configurando touchpad..."

# Configurar touchpad via gsettings
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true  
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
gsettings set org.gnome.desktop.peripherals.touchpad speed 0.3
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true
gsettings set org.gnome.desktop.peripherals.touchpad middle-click-emulation true

echo "¡Instalación completada!"
echo "Reinicia el sistema para aplicar todos los cambios."
echo "Después puedes configurar más opciones en:"
echo "- Configuración > Mouse y Touchpad"  
echo "- gnome-tweaks (Herramientas de Ajuste)"