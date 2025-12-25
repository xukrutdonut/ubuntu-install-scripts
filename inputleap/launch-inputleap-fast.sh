#!/bin/bash

echo "=== Iniciando InputLeap Ultra-Rápido ==="

# Detener cualquier instancia previa
flatpak kill io.github.input_leap.input-leap 2>/dev/null

# Configurar variables de entorno para máximo rendimiento
export QT_X11_NO_MITSHM=1
export QT_SCALE_FACTOR=1
export GDK_SCALE=1
export DISPLAY=:0

# Configurar límites
ulimit -n 65536

echo "Iniciando con configuraciones optimizadas..."

# Iniciar en core dedicado si es posible
CORES=$(nproc)
if [ $CORES -gt 1 ]; then
    LAST_CORE=$((CORES-1))
    echo "Usando CPU core $LAST_CORE para InputLeap"
    taskset -c $LAST_CORE flatpak run io.github.input_leap.input-leap &
else
    flatpak run io.github.input_leap.input-leap &
fi

# Esperar y configurar prioridad
sleep 5
PID=$(pgrep -f "input.*leap")
if [ ! -z "$PID" ]; then
    echo "InputLeap iniciado con PID: $PID"
    renice -20 $PID 2>/dev/null && echo "Prioridad alta configurada" || echo "Prioridad normal"
else
    echo "No se encontró el proceso de InputLeap"
fi

echo "InputLeap configurado para mínima latencia"