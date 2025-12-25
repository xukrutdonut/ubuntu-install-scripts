#!/bin/bash
# gnome_tablet_mode.sh - Script para gestionar el modo tablet en GNOME

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.tablet-mode.log"

# Función de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

# Detectar tipo de sesión
detect_session() {
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        echo "wayland"
    else
        echo "x11"
    fi
}

# Verificar sensores de orientación
check_sensors() {
    log "Verificando sensores de orientación..."
    
    local sensor_count=0
    if [ -d "/sys/bus/iio/devices" ]; then
        sensor_count=$(find /sys/bus/iio/devices -name "iio:device*" | wc -l)
        log "Encontrados $sensor_count dispositivos IIO"
        
        # Verificar específicamente sensores de acelerómetro
        for device in /sys/bus/iio/devices/iio:device*; do
            if [ -f "$device/name" ]; then
                name=$(cat "$device/name")
                log "Sensor: $name en $device"
                
                # Verificar si tiene datos de aceleración
                if ls "$device"/in_accel_* >/dev/null 2>&1; then
                    log "  ✓ Sensor de aceleración detectado"
                fi
            fi
        done
    else
        log "❌ No se encontró directorio de sensores IIO"
    fi
    
    # Verificar monitor-sensor
    if command -v monitor-sensor >/dev/null 2>&1; then
        log "✓ monitor-sensor disponible"
    else
        log "❌ monitor-sensor no encontrado (instalar: sudo apt install iio-sensor-proxy)"
    fi
}

# Habilitar rotación automática
enable_auto_rotation() {
    log "Habilitando rotación automática..."
    
    # En Wayland, usar configuración de GNOME
    if [ "$(detect_session)" = "wayland" ]; then
        gsettings set org.gnome.settings-daemon.peripherals.touchscreen orientation-lock false
        log "✓ Rotación automática habilitada en Wayland"
    else
        log "⚠️ Rotación automática en X11 requiere configuración manual"
    fi
}

# Deshabilitar rotación automática
disable_auto_rotation() {
    log "Deshabilitando rotación automática..."
    
    if [ "$(detect_session)" = "wayland" ]; then
        gsettings set org.gnome.settings-daemon.peripherals.touchscreen orientation-lock true
        log "✓ Rotación automática deshabilitada"
    fi
}

# Habilitar gestos táctiles
enable_gestures() {
    log "Configurando gestos táctiles..."
    
    # Configuraciones de GNOME para mejor experiencia táctil
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
    
    log "✓ Gestos táctiles configurados"
}

# Mostrar estado del sistema
show_status() {
    log "=== Estado del Sistema de Tablet ==="
    
    echo "Tipo de sesión: $(detect_session)"
    
    # Estado del teclado virtual
    keyboard_enabled=$(gsettings get org.gnome.desktop.a11y.applications screen-keyboard-enabled)
    echo "Teclado virtual: $keyboard_enabled"
    
    # Estado de rotación
    if [ "$(detect_session)" = "wayland" ]; then
        rotation_lock=$(gsettings get org.gnome.settings-daemon.peripherals.touchscreen orientation-lock 2>/dev/null || echo "unknown")
        echo "Bloqueo de rotación: $rotation_lock"
    fi
    
    # Verificar sensores
    check_sensors
    
    # Verificar herramientas instaladas
    echo ""
    echo "=== Herramientas Disponibles ==="
    command -v monitor-sensor >/dev/null && echo "✓ monitor-sensor" || echo "❌ monitor-sensor"
    command -v onboard >/dev/null && echo "✓ onboard (teclado en pantalla)" || echo "⚠️ onboard no instalado"
    command -v xinput >/dev/null && echo "✓ xinput" || echo "❌ xinput"
}

# Instalar dependencias
install_dependencies() {
    log "Instalando dependencias para modo tablet..."
    
    sudo apt update
    sudo apt install -y iio-sensor-proxy onboard
    
    log "✓ Dependencias instaladas"
}

# Función principal
main() {
    case "${1:-status}" in
        "status")
            show_status
            ;;
        "auto-rotation")
            enable_auto_rotation
            ;;
        "no-auto-rotation")
            disable_auto_rotation
            ;;
        "gestures")
            enable_gestures
            ;;
        "install")
            install_dependencies
            ;;
        "check")
            check_sensors
            ;;
        *)
            echo "Uso: $0 {status|auto-rotation|no-auto-rotation|gestures|install|check}"
            echo ""
            echo "Comandos:"
            echo "  status           - Mostrar estado actual"
            echo "  auto-rotation    - Habilitar rotación automática"
            echo "  no-auto-rotation - Deshabilitar rotación automática"
            echo "  gestures         - Configurar gestos táctiles"
            echo "  install          - Instalar dependencias"
            echo "  check            - Verificar sensores"
            exit 1
            ;;
    esac
}

main "$@"