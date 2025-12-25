#!/bin/bash

# Script para descargar versión MÁS ANTIGUA de BambuStudio
# Las versiones nuevas tienen bugs con Intel Arrow Lake

echo "=========================================="
echo "Descargando BambuStudio v02.02.00.24"
echo "Versión más antigua y estable"
echo "=========================================="

cd /home/arkantu

# Verificar si ya existe
if [ -f "BambuStudio-v02.02.00.24.AppImage" ]; then
    echo "Ya existe BambuStudio-v02.02.00.24.AppImage"
    exit 0
fi

# Descargar versión v02.02.00.24 (más estable)
echo "Descargando desde GitHub..."
wget -O BambuStudio-v02.02.00.24.AppImage \
    "https://github.com/bambulab/BambuStudio/releases/download/v02.02.00.24/BambuStudio-v02.02.00.24-Linux-x86_64.AppImage"

if [ $? -eq 0 ]; then
    chmod +x BambuStudio-v02.02.00.24.AppImage
    echo ""
    echo "✓ Descarga completa"
    echo "Archivo: /home/arkantu/BambuStudio-v02.02.00.24.AppImage"
    echo ""
    echo "Para usar:"
    echo "  ./BambuStudio-v02.02.00.24.AppImage"
else
    echo "Error en la descarga"
    exit 1
fi
