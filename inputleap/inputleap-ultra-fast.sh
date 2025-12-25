#!/bin/bash

echo "=== Configuración Ultra-Rápida para InputLeap ==="

# Detener InputLeap
flatpak kill io.github.input_leap.input-leap 2>/dev/null

# Configurar sistema para mínima latencia
echo "Configurando sistema para latencia mínima..."
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 20
gsettings set org.gnome.desktop.peripherals.keyboard delay 200

# Deshabilitar composición para reducir latencia (si está en X11)
if [ "$XDG_SESSION_TYPE" = "x11" ]; then
    echo "Deshabilitando efectos de composición..."
    kwriteconfig5 --file ~/.config/kwinrc --group Compositing --key Enabled false 2>/dev/null || true
fi

# Configurar prioridad de CPU para InputLeap
echo "Configurando scheduler para tiempo real..."
echo 'kernel.sched_rt_runtime_us = -1' | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1 || true

# Crear configuración optimizada
mkdir -p ~/.config/inputleap-optimized

cat > ~/.config/inputleap-optimized/launch.sh << 'EOF'
#!/bin/bash

# Variables de entorno para máximo rendimiento
export QT_SCALE_FACTOR=1
export GDK_SCALE=1
export DISPLAY=:0
export QT_X11_NO_MITSHM=1

# Configurar límites del sistema
ulimit -n 65536
ulimit -l unlimited 2>/dev/null || true

# Configurar prioridad de red
echo "Iniciando InputLeap con máxima prioridad..."

# Usar taskset para fijar CPU (si tienes múltiples cores)
CORES=$(nproc)
if [ $CORES -gt 1 ]; then
    LAST_CORE=$((CORES-1))
    taskset -c $LAST_CORE flatpak run io.github.input_leap.input-leap &
else
    flatpak run io.github.input_leap.input-leap &
fi

sleep 3
PID=$(pgrep -f "input.*leap")
if [ ! -z "$PID" ]; then
    echo "InputLeap PID: $PID"
    # Intentar configurar prioridad tiempo real
    sudo chrt -p 99 $PID 2>/dev/null || echo "Prioridad normal (sin permisos RT)"
    # Configurar nice
    renice -20 $PID 2>/dev/null || echo "Nice configurado"
fi
EOF

chmod +x ~/.config/inputleap-optimized/launch.sh

echo
echo "=== Script de lanzamiento ultra-rápido creado ==="
echo "Ejecuta: ~/.config/inputleap-optimized/launch.sh"
echo
echo "RECOMENDACIONES ADICIONALES:"
echo "1. Usa cable Ethernet en lugar de WiFi si es posible"
echo "2. En el servidor (192.168.0.114):"
echo "   - Reduce el 'Heartbeat' a 1000ms o menos"
echo "   - Activa 'Relative mouse moves' si tienes problemas"
echo "3. Cierra aplicaciones innecesarias para liberar CPU/RAM"
echo "4. Considera cambiar el canal WiFi si hay interferencia"