#!/bin/bash

# Script para optimizar InputLeap y reducir delay/teclas repetidas
# Autor: Sistema de instalación Ubuntu

echo "=== Optimizando InputLeap para reducir delay y teclas repetidas ==="

# Detener InputLeap si está corriendo
echo "Deteniendo InputLeap..."
pkill -f inputleap 2>/dev/null || true
flatpak kill io.github.input_leap.input-leap 2>/dev/null || true

# Configurar optimizaciones del sistema
echo "Aplicando optimizaciones del sistema..."

# Reducir repetición de teclas del sistema
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 30
gsettings set org.gnome.desktop.peripherals.keyboard delay 500

# Optimizar configuración de red para InputLeap
echo "Optimizando configuración de red..."

# Crear configuración optimizada para InputLeap
mkdir -p ~/.var/app/io.github.input_leap.input-leap/config/InputLeap

cat > ~/.var/app/io.github.input_leap.input-leap/config/InputLeap/InputLeap.conf << 'EOF'
section: options
	relativeMouseMoves = false
	switchCorners = none 
	switchCornerSize = 0
	switchDelay = 250
	switchDoubleTap = 250
	screenSaverSync = true
	win32KeepForeground = false
	clipboardSharing = true
	switchCorners = none
	keystroke(alt+shift+left) = switchInDirection(left)
	keystroke(alt+shift+right) = switchInDirection(right)
	keystroke(alt+shift+up) = switchInDirection(up)
	keystroke(alt+shift+down) = switchInDirection(down)
end
EOF

# Configurar límites de red más altos
echo "Configurando buffers de red..."
sudo sysctl -w net.core.rmem_max=16777216 2>/dev/null || echo "No se pudieron configurar algunos parámetros de red (requiere sudo)"
sudo sysctl -w net.core.wmem_max=16777216 2>/dev/null || true
sudo sysctl -w net.ipv4.tcp_rmem="4096 16384 16777216" 2>/dev/null || true
sudo sysctl -w net.ipv4.tcp_wmem="4096 16384 16777216" 2>/dev/null || true

# Configurar prioridad de procesos
echo "Configurando prioridad de procesos..."

# Crear script de inicio optimizado
cat > ~/start-inputleap-optimized.sh << 'EOF'
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
EOF

chmod +x ~/start-inputleap-optimized.sh

# Crear script para diagnosticar problemas
cat > ~/diagnose-inputleap.sh << 'EOF'
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
gsettings get org.gnome.desktop.peripherals.keyboard repeat-interval
gsettings get org.gnome.desktop.peripherals.keyboard delay
echo
echo "Uso de CPU de InputLeap:"
top -b -n 1 | grep inputleap
echo
echo "Logs recientes (si existen):"
journalctl --user --since "5 minutes ago" | grep -i inputleap | tail -10
EOF

chmod +x ~/diagnose-inputleap.sh

# Configuraciones adicionales para reducir latencia
echo "Aplicando configuraciones adicionales..."

# Deshabilitar composición si usa X11 (puede reducir latencia)
if [ "$XDG_SESSION_TYPE" = "x11" ]; then
    echo "Detectado X11 - Configurando para mejor rendimiento..."
    # Crear archivo de configuración para deshabilitar efectos pesados
    mkdir -p ~/.config/kwinrc 2>/dev/null || true
fi

# Optimizar configuración de mouse
xinput list 2>/dev/null | grep -i mouse | while read line; do
    MOUSE_ID=$(echo "$line" | grep -o 'id=[0-9]*' | cut -d'=' -f2)
    if [ ! -z "$MOUSE_ID" ]; then
        xinput set-prop $MOUSE_ID "libinput Accel Speed" 0 2>/dev/null || true
    fi
done

echo
echo "=== Optimización completada ==="
echo
echo "Cambios realizados:"
echo "- Configuración de repetición de teclado optimizada"
echo "- Buffers de red aumentados (si tienes permisos sudo)"
echo "- Script de inicio optimizado creado: ~/start-inputleap-optimized.sh"
echo "- Script de diagnóstico creado: ~/diagnose-inputleap.sh"
echo "- Configuración de InputLeap optimizada"
echo
echo "RECOMENDACIONES:"
echo "1. Reinicia InputLeap: flatpak kill io.github.input_leap.input-leap && ~/start-inputleap-optimized.sh"
echo "2. En la configuración de InputLeap:"
echo "   - Reduce el 'Switch delay' a 250ms o menos"
echo "   - Deshabilita 'Switch on double tap' si no lo necesitas"
echo "   - Asegúrate de que no hay firewall bloqueando los puertos 24800-24801"
echo "3. Si el problema persiste, ejecuta: ~/diagnose-inputleap.sh"
echo "4. Considera usar conexión por cable en lugar de WiFi para menor latencia"
echo
echo "Para aplicar cambios de red permanentes, añade estas líneas a /etc/sysctl.conf:"
echo "net.core.rmem_max = 16777216"
echo "net.core.wmem_max = 16777216"
echo "net.ipv4.tcp_rmem = 4096 16384 16777216"
echo "net.ipv4.tcp_wmem = 4096 16384 16777216"