#!/bin/bash

echo "=== Configuración Modo Tableta para Surface ==="

# Verificar sensores
echo "Paso 1: Verificando sensores..."
if [ -d "/sys/bus/iio/devices/" ]; then
    echo "✅ Sensores IIO detectados:"
    for device in /sys/bus/iio/devices/*/name; do
        if [ -f "$device" ]; then
            echo "  - $(cat $device)"
        fi
    done
else
    echo "❌ No se encontraron sensores IIO"
    exit 1
fi

echo ""
echo "Paso 2: Instalando paquetes necesarios..."
sudo apt update
sudo apt install -y \
    iio-sensor-proxy \
    inotify-tools \
    dbus-x11 \
    gnome-shell-extension-prefs \
    gnome-tweaks

echo ""
echo "Paso 3: Configurando rotación automática..."

# Habilitar rotación automática en GNOME
gsettings set org.gnome.settings-daemon.peripherals.touchscreen orientation-lock false
gsettings set org.gnome.desktop.a11y.applications screen-reader-enabled false

echo ""
echo "Paso 4: Creando script de rotación automática..."

cat > /tmp/tablet-rotation.sh << 'EOF'
#!/bin/bash

DEVICE_NAME="IPTSD Virtual Touchscreen 1B96:006A"
DISPLAY_OUTPUT="eDP-1"

monitor_rotation() {
    # Monitorear cambios en el sensor de rotación
    inotifywait -m -e modify /sys/bus/iio/devices/iio:device*/in_rot_from_north_magnetic_tilt_comp_raw 2>/dev/null | \
    while read path action file; do
        # Obtener orientación actual
        ORIENTATION=$(cat /sys/class/drm/card*/device/drm/card*/enabled 2>/dev/null | head -1)
        
        # Rotar pantalla según orientación
        case "$ORIENTATION" in
            *) 
                # Rotación automática basada en acelerómetro
                if command -v monitor-sensor >/dev/null 2>&1; then
                    monitor-sensor | while read orientation; do
                        case "$orientation" in
                            "normal")
                                xrandr --output $DISPLAY_OUTPUT --rotate normal
                                xinput set-prop "$DEVICE_NAME" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
                                ;;
                            "left-up")
                                xrandr --output $DISPLAY_OUTPUT --rotate left
                                xinput set-prop "$DEVICE_NAME" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
                                ;;
                            "right-up") 
                                xrandr --output $DISPLAY_OUTPUT --rotate right
                                xinput set-prop "$DEVICE_NAME" "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1
                                ;;
                            "bottom-up")
                                xrandr --output $DISPLAY_OUTPUT --rotate inverted
                                xinput set-prop "$DEVICE_NAME" "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
                                ;;
                        esac
                    done
                fi
                ;;
        esac
    done
}

# Iniciar monitoreo si está en modo X11
if [ "$XDG_SESSION_TYPE" = "x11" ]; then
    monitor_rotation &
    echo "Rotación automática iniciada para X11"
else
    echo "Rotación automática nativa en Wayland"
fi
EOF

chmod +x /tmp/tablet-rotation.sh
sudo mv /tmp/tablet-rotation.sh /usr/local/bin/tablet-rotation.sh

echo ""
echo "Paso 5: Configurando servicio de rotación..."

cat > /tmp/tablet-rotation.service << EOF
[Unit]
Description=Surface Tablet Rotation Service
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/local/bin/tablet-rotation.sh
Restart=always
User=%i
Environment=DISPLAY=:0

[Install]
WantedBy=default.target
EOF

sudo mv /tmp/tablet-rotation.service /etc/systemd/user/tablet-rotation.service

echo ""
echo "Paso 6: Habilitando rotación automática en GNOME..."
# Configurar GNOME para rotación automática
gsettings set org.gnome.settings-daemon.plugins.orientation active true
dbus-send --session --type=method_call --dest=net.hadess.SensorProxy /net/hadess/SensorProxy net.hadess.SensorProxy.ClaimAccelerometer

echo ""
echo "Paso 7: Configurando teclado virtual..."
gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true

echo ""
echo "=== CONFIGURACIÓN COMPLETADA ==="
echo ""
echo "Para activar el modo tableta:"
echo "1. Ejecuta: systemctl --user enable tablet-rotation.service"
echo "2. Ejecuta: systemctl --user start tablet-rotation.service"
echo "3. En Configuración > Pantallas, habilita 'Rotación automática'"
echo ""
echo "Controles del modo tableta:"
echo "- Rotación manual: xrandr --output eDP-1 --rotate [normal|left|right|inverted]"
echo "- Teclado virtual: Configuración > Accesibilidad > Teclado en pantalla"
echo "- Gestos táctiles: Instala 'touchegg' para gestos personalizados"
echo ""
echo "Para probar rotación: Gira físicamente la tableta"