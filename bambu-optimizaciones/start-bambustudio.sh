#!/bin/bash

# BambuStudio - Configuración optimizada para Intel Arrow Lake
# Evita freezes y mantiene rendimiento aceptable

echo "Deteniendo procesos anteriores..."
pkill -9 -f "bambu-studio" 2>/dev/null
pkill -9 -f "BambuStudio" 2>/dev/null
sleep 1

# Configuración balanceada para Intel Arrow Lake Graphics
# Evita los freezes que causaban las configuraciones anteriores
export MESA_GL_VERSION_OVERRIDE=4.5
export __GL_SYNC_TO_VBLANK=0
export MESA_NO_DITHER=1
export vblank_mode=0
export __GL_YIELD="NOTHING"

# Limitar threads para evitar contención de recursos
export OMP_NUM_THREADS=4
export OMP_WAIT_POLICY=PASSIVE

# Usar versión más nueva (menos bugs)
APPIMAGE="/home/arkantu/BambuStudio-v02.04.00.70.AppImage.old"

if [ ! -f "$APPIMAGE" ]; then
    echo "Error: No se encuentra $APPIMAGE"
    echo "Versiones disponibles:"
    ls -lh /home/arkantu/BambuStudio*.AppImage*
    exit 1
fi

echo "=========================================="
echo "Iniciando BambuStudio v02.04.00.70"
echo "Optimizado para Intel Arrow Lake"
echo "=========================================="

"$APPIMAGE" "$@" 2>&1 | tee ~/bambustudio.log &

PID=$!
echo ""
echo "BambuStudio iniciado (PID: $PID)"
echo "Log: ~/bambustudio.log"
echo ""
echo "Si experimenta freezes:"
echo "  1. Prueba: ./start-bambustudio-software.sh (lento pero estable)"
echo "  2. O limpia config: mv ~/.config/BambuStudio ~/.config/BambuStudio.backup"