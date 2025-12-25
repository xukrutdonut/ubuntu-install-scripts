#!/bin/bash

# Configurar variables de entorno para mejor rendimiento
export QT_SCALE_FACTOR=1
export GDK_SCALE=1
export DISPLAY=:0

# Configurar límites de proceso
ulimit -n 65536

# Iniciar InputLeap con prioridad alta
nice -n -10 flatpak run io.github.input_leap.input-leap &

# Esperar a que inicie y ajustar prioridades
sleep 5
INPUTLEAP_PID=$(pgrep -f "inputleap")
if [ ! -z "$INPUTLEAP_PID" ]; then
    echo "Ajustando prioridad del proceso InputLeap (PID: $INPUTLEAP_PID)"
    renice -10 $INPUTLEAP_PID 2>/dev/null || echo "No se pudo cambiar la prioridad (normal)"
fi