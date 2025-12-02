#!/bin/bash

TOUCHSCREEN="IPTSD Virtual Touchscreen 1B96:006A"
DISPLAY="eDP-1"

case "$1" in
    "portrait")
        echo "Rotando a modo retrato..."
        xrandr --output $DISPLAY --rotate left
        xinput set-prop "$TOUCHSCREEN" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
        ;;
    "landscape")
        echo "Rotando a modo paisaje..."
        xrandr --output $DISPLAY --rotate normal  
        xinput set-prop "$TOUCHSCREEN" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
        ;;
    "inverted")
        echo "Rotando 180 grados..."
        xrandr --output $DISPLAY --rotate inverted
        xinput set-prop "$TOUCHSCREEN" "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
        ;;
    "right")
        echo "Rotando a la derecha..."
        xrandr --output $DISPLAY --rotate right
        xinput set-prop "$TOUCHSCREEN" "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1
        ;;
    "auto")
        echo "Iniciando rotación automática..."
        monitor-sensor | while read orientation; do
            case "$orientation" in
                "normal")
                    xrandr --output $DISPLAY --rotate normal
                    xinput set-prop "$TOUCHSCREEN" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
                    echo "Rotado a normal"
                    ;;
                "left-up")
                    xrandr --output $DISPLAY --rotate left
                    xinput set-prop "$TOUCHSCREEN" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
                    echo "Rotado a la izquierda"
                    ;;
                "right-up")
                    xrandr --output $DISPLAY --rotate right
                    xinput set-prop "$TOUCHSCREEN" "Coordinate Transformation Matrix" 0 1 0 -1 0 1 0 0 1
                    echo "Rotado a la derecha"
                    ;;
                "bottom-up")
                    xrandr --output $DISPLAY --rotate inverted
                    xinput set-prop "$TOUCHSCREEN" "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
                    echo "Rotado invertido"
                    ;;
            esac
        done
        ;;
    *)
        echo "Uso: $0 [portrait|landscape|inverted|right|auto]"
        echo ""
        echo "Orientación actual:"
        xrandr --query --verbose | grep eDP-1 | grep -o "rotate [a-z]*"
        ;;
esac
