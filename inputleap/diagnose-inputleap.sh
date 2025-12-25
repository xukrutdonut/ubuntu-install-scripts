#!/bin/bash

echo "=== Diagnóstico de InputLeap ==="
echo
echo "Procesos de InputLeap:"
ps aux | grep -i inputleap
echo
echo "Conexiones de red:"
ss -tuln | grep -E "(24800|24801)"
echo
echo "Configuración de teclado:"
echo "Repeat interval: $(gsettings get org.gnome.desktop.peripherals.keyboard repeat-interval)"
echo "Delay: $(gsettings get org.gnome.desktop.peripherals.keyboard delay)"
echo
echo "Uso de CPU de InputLeap:"
top -b -n 1 | grep inputleap
echo
echo "Configuración actual de InputLeap:"
echo "Puerto: $(grep port ~/.var/app/io.github.input_leap.input-leap/config/InputLeap/InputLeap.conf 2>/dev/null || echo '24800 (default)')"
echo "Switch Delay: $(grep switchDelay ~/.var/app/io.github.input_leap.input-leap/config/InputLeap/InputLeap.conf 2>/dev/null || echo 'No configurado')"
echo
echo "Test de conectividad al servidor:"
SERVIDOR=$(grep serverHostname ~/.var/app/io.github.input_leap.input-leap/config/InputLeap/InputLeap.conf | cut -d'=' -f2)
if [ ! -z "$SERVIDOR" ]; then
    echo "Ping a $SERVIDOR:"
    ping -c 3 $SERVIDOR 2>/dev/null || echo "No se puede hacer ping al servidor"
    echo "Conectividad puerto 24800:"
    nc -z $SERVIDOR 24800 && echo "Puerto abierto" || echo "Puerto cerrado/bloqueado"
fi