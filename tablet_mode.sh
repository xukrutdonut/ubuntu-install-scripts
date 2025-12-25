#!/bin/bash

DEVICE_NAME="IPTSD Virtual Touchscreen 1B96:006A"
DISPLAY_OUTPUT="eDP-1"

echo "=== Modo Tablet Surface ==="
echo "Dispositivo: $DEVICE_NAME"
echo "Pantalla: $DISPLAY_OUTPUT"

# Función para rotación manual
rotate_display() {
    case "$1" in
        "normal")
            xrandr --output $DISPLAY_OUTPUT --rotate normal
            xinput set-prop "$DEVICE_NAME" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1 2>/dev/null || true
            echo "✅ Rotación: Normal"
            ;;
        "left")
            xrandr --output $DISPLAY_OUTPUT --rotate left
            xinput set-prop "$DEVICE_NAME" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1 2>/dev/null || true
            echo "✅ Rotación: Izquierda"
            ;;
        "right") 
            xrandr --output $DISPLAY_OUTPUT --rotate right
            xinput set-prop "$DEVICE_NAME" "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1 2>/dev/null || true
            echo "✅ Rotación: Derecha"
            ;;
        "inverted")
            xrandr --output $DISPLAY_OUTPUT --rotate inverted
            xinput set-prop "$DEVICE_NAME" "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1 2>/dev/null || true
            echo "✅ Rotación: Invertida"
            ;;
        "auto")
            echo "🔄 Iniciando rotación automática..."
            if command -v monitor-sensor >/dev/null 2>&1; then
                monitor-sensor | while read orientation; do
                    case "$orientation" in
                        "normal") rotate_display "normal" ;;
                        "left-up") rotate_display "left" ;;
                        "right-up") rotate_display "right" ;;
                        "bottom-up") rotate_display "inverted" ;;
                    esac
                done
            else
                echo "❌ monitor-sensor no disponible"
                echo "💡 Instala: sudo apt install iio-sensor-proxy"
            fi
            ;;
        *)
            echo "Uso: $0 [normal|left|right|inverted|auto]"
            echo "  normal   - Orientación normal"
            echo "  left     - Rotar a la izquierda"
            echo "  right    - Rotar a la derecha"
            echo "  inverted - Rotar 180°"
            echo "  auto     - Rotación automática"
            ;;
    esac
}

rotate_display "$1"
