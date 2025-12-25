#!/bin/bash

echo "=== Configurador de Teclado Virtual para InputLeap ==="

# Función para configurar automáticamente
setup_auto() {
    echo "Iniciando servicio automático..."
    systemctl --user start virtual-keyboard-toggle.service
    echo "✓ Servicio iniciado. El teclado virtual se desactivará automáticamente con InputLeap."
    systemctl --user status virtual-keyboard-toggle.service --no-pager
}

# Función para desactivar manualmente
disable_keyboard() {
    gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled false
    pkill onboard 2>/dev/null
    echo "✓ Teclado virtual desactivado manualmente"
}

# Función para activar manualmente
enable_keyboard() {
    gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true
    echo "✓ Teclado virtual GNOME activado"
}

# Función para mostrar estado
status() {
    echo "Estado del teclado virtual GNOME:"
    gsettings get org.gnome.desktop.a11y.applications screen-keyboard-enabled
    echo "Estado de InputLeap:"
    if pgrep -f inputleap > /dev/null; then
        echo "InputLeap está corriendo"
    else
        echo "InputLeap no está corriendo"
    fi
    echo "Estado del servicio:"
    systemctl --user is-active virtual-keyboard-toggle.service
}

case "$1" in
    "auto")
        setup_auto
        ;;
    "disable"|"off")
        disable_keyboard
        ;;
    "enable"|"on")
        enable_keyboard
        ;;
    "status")
        status
        ;;
    "stop")
        systemctl --user stop virtual-keyboard-toggle.service
        echo "✓ Servicio automático detenido"
        ;;
    *)
        echo "Uso: $0 {auto|disable|enable|status|stop}"
        echo ""
        echo "  auto     - Iniciar monitoreo automático"
        echo "  disable  - Desactivar teclado virtual manualmente"
        echo "  enable   - Activar teclado virtual manualmente"
        echo "  status   - Mostrar estado actual"
        echo "  stop     - Detener servicio automático"
        ;;
esac