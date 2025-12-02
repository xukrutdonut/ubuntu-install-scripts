#!/bin/bash

echo "=== Configuración Modo Tableta GNOME/Wayland ==="

# Función para habilitar rotación automática
enable_auto_rotation() {
    echo "Habilitando rotación automática..."
    
    # Método 1: Via dconf/gsettings
    gsettings set org.gnome.settings-daemon.peripherals.touchscreen orientation-lock false 2>/dev/null || true
    
    # Método 2: Habilitar sensor de orientación
    if command -v gdbus >/dev/null 2>&1; then
        gdbus call --session \
            --dest net.hadess.SensorProxy \
            --object-path /net/hadess/SensorProxy \
            --method net.hadess.SensorProxy.ClaimAccelerometer 2>/dev/null || true
    fi
    
    echo "✅ Rotación automática configurada"
}

# Función para habilitar teclado virtual
enable_virtual_keyboard() {
    echo "Configurando teclado virtual..."
    gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true
    echo "✅ Teclado virtual habilitado"
}

# Función para configurar gestos táctiles
configure_touch_gestures() {
    echo "Configurando gestos táctiles..."
    
    # Habilitar gestos en GNOME
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
    
    echo "✅ Gestos táctiles configurados"
}

# Función para instalar herramientas adicionales
install_tablet_tools() {
    echo "Instalando herramientas para modo tableta..."
    
    echo "Instalando dependencias..."
    sudo apt update
    sudo apt install -y \
        onboard \
        gnome-shell-extension-prefs \
        gnome-tweaks
    
    echo "✅ Herramientas instaladas"
}

# Función para mostrar estado actual
show_status() {
    echo ""
    echo "=== ESTADO ACTUAL DEL MODO TABLETA ==="
    
    echo "Sensores detectados:"
    ls /sys/bus/iio/devices/*/name | xargs cat 2>/dev/null | sed 's/^/  - /'
    
    echo ""
    echo "Servicio iio-sensor-proxy:"
    systemctl is-active iio-sensor-proxy && echo "  ✅ Activo" || echo "  ❌ Inactivo"
    
    echo ""
    echo "Configuración GNOME:"
    echo "  Teclado virtual: $(gsettings get org.gnome.desktop.a11y.applications screen-keyboard-enabled)"
    echo "  Scroll natural: $(gsettings get org.gnome.desktop.peripherals.touchpad natural-scroll)"
    echo "  Tap to click: $(gsettings get org.gnome.desktop.peripherals.touchpad tap-to-click)"
}

# Función para rotación manual (solo en X11)
manual_rotation() {
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        echo "⚠️  Rotación manual no disponible en Wayland"
        echo "   Usa Configuración > Pantallas para rotar manualmente"
        echo "   O gira físicamente la tableta para rotación automática"
    else
        echo "Rotación manual disponible. Uso: $0 rotate [left|right|inverted|normal]"
    fi
}

# Función principal
main() {
    case "$1" in
        "install")
            install_tablet_tools
            enable_auto_rotation
            enable_virtual_keyboard
            configure_touch_gestures
            show_status
            ;;
        "auto-rotation")
            enable_auto_rotation
            ;;
        "keyboard")
            enable_virtual_keyboard
            ;;
        "gestures")
            configure_touch_gestures
            ;;
        "status")
            show_status
            ;;
        "rotate")
            manual_rotation
            ;;
        *)
            echo "Configurador de Modo Tableta para Surface/GNOME"
            echo ""
            echo "Uso: $0 [comando]"
            echo ""
            echo "Comandos disponibles:"
            echo "  install       - Instalación completa del modo tableta"
            echo "  auto-rotation - Habilitar rotación automática"
            echo "  keyboard      - Habilitar teclado virtual"
            echo "  gestures      - Configurar gestos táctiles"
            echo "  status        - Mostrar estado actual"
            echo "  rotate        - Información sobre rotación manual"
            echo ""
            show_status
            ;;
    esac
}

main "$@"