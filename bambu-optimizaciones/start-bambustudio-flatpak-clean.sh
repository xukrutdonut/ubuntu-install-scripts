#!/bin/bash

# BambuStudio Flatpak LIMPIO - sin variables de entorno
# Última opción si AppImage no funciona

echo "Deteniendo procesos anteriores..."
pkill -9 -f "bambu-studio" 2>/dev/null
pkill -9 -f "BambuStudio" 2>/dev/null
sleep 1

# Verificar que Flatpak está instalado
if ! flatpak list | grep -q "com.bambulab.BambuStudio"; then
    echo "Error: BambuStudio Flatpak no está instalado"
    echo "Instalar con: flatpak install flathub com.bambulab.BambuStudio"
    exit 1
fi

echo "=========================================="
echo "Iniciando BambuStudio FLATPAK"
echo "Sin variables de entorno - limpio"
echo "=========================================="

# Ejecutar Flatpak SIN variables de entorno problemáticas
flatpak run com.bambulab.BambuStudio "$@" 2>&1 | tee ~/bambustudio.log &

echo ""
echo "BambuStudio Flatpak iniciado"
echo "Log: ~/bambustudio.log"
