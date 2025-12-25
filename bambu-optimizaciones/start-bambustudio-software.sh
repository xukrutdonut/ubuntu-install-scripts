#!/bin/bash

# BambuStudio con software rendering - MUY LENTO pero NO se congela
# Usar solo si la versión normal se congela

echo "Deteniendo procesos anteriores..."
pkill -9 -f "bambu-studio" 2>/dev/null
pkill -9 -f "BambuStudio" 2>/dev/null
sleep 1

# Forzar software rendering completo
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export MESA_LOADER_DRIVER_OVERRIDE=swrast

APPIMAGE="/home/arkantu/BambuStudio-v02.04.00.70.AppImage.old"

if [ ! -f "$APPIMAGE" ]; then
    echo "Error: No se encuentra $APPIMAGE"
    exit 1
fi

echo "=========================================="
echo "Iniciando BambuStudio en MODO SOFTWARE"
echo "=========================================="
echo "ADVERTENCIA: Será LENTO pero no se congelará"
echo "- No muevas la vista 3D frecuentemente"
echo "- Evita modelos muy complejos"
echo "=========================================="

"$APPIMAGE" "$@" 2>&1 | tee ~/bambustudio.log &

echo ""
echo "BambuStudio iniciado en modo software rendering"
echo "Log: ~/bambustudio.log"
