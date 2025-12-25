#!/bin/bash

# Script para desactivar/activar el teclado virtual según el estado de InputLeap
# Configurable para diferentes métodos de teclado virtual

INPUTLEAP_PROCESS="inputleap"
VIRTUAL_KEYBOARD_METHOD="gnome"  # opciones: gnome, onboard

check_inputleap() {
    pgrep -f "$INPUTLEAP_PROCESS" > /dev/null
    return $?
}

disable_virtual_keyboard() {
    case "$VIRTUAL_KEYBOARD_METHOD" in
        "gnome")
            gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled false
            echo "Teclado virtual GNOME desactivado"
            ;;
        "onboard")
            pkill onboard 2>/dev/null
            echo "Onboard desactivado"
            ;;
    esac
}

enable_virtual_keyboard() {
    case "$VIRTUAL_KEYBOARD_METHOD" in
        "gnome")
            gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true
            echo "Teclado virtual GNOME activado"
            ;;
        "onboard")
            onboard &
            echo "Onboard activado"
            ;;
    esac
}

# Bucle principal para monitorear InputLeap
while true; do
    if check_inputleap; then
        # InputLeap está corriendo, desactivar teclado virtual
        disable_virtual_keyboard
        
        # Esperar hasta que InputLeap se cierre
        while check_inputleap; do
            sleep 2
        done
        
        # InputLeap se cerró, reactivar teclado virtual
        enable_virtual_keyboard
    fi
    
    sleep 5
done