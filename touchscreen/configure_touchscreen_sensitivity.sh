#!/bin/bash

echo "=== Configuración de Sensibilidad del Touchscreen ==="
echo ""

# Función para mostrar uso
show_usage() {
    echo "Uso: $0 [opción] [valor]"
    echo ""
    echo "Opciones disponibles:"
    echo "  sensitivity <1-10>   - Ajustar sensibilidad general (5 = normal)"
    echo "  pressure <1-10>      - Ajustar sensibilidad de presión (5 = normal)"
    echo "  palm-rejection <on|off> - Activar/desactivar rechazo de palma"
    echo "  touch-size <1-10>    - Ajustar tamaño mínimo de toque (3 = normal)"
    echo "  show                 - Mostrar configuraciones actuales"
    echo "  reset                - Restaurar valores por defecto"
    echo ""
    echo "Ejemplos:"
    echo "  $0 sensitivity 7     # Aumentar sensibilidad"
    echo "  $0 sensitivity 3     # Reducir sensibilidad"
    echo "  $0 pressure 8        # Mayor sensibilidad a presión"
    echo "  $0 palm-rejection on # Activar rechazo de palma"
    echo ""
}

# Función para obtener el ID del dispositivo touchscreen
get_touchscreen_id() {
    TOUCH_ID=$(xinput list | grep -i "xwayland-touch\|touchscreen" | grep -o "id=[0-9]*" | cut -d= -f2 | head -1)
    if [ -z "$TOUCH_ID" ]; then
        # Buscar otros patrones comunes
        TOUCH_ID=$(xinput list | grep -i "virtual.*touch\|ipts.*touch" | grep -o "id=[0-9]*" | cut -d= -f2 | head -1)
    fi
    echo "$TOUCH_ID"
}

# Función para mostrar configuraciones actuales
show_current_config() {
    echo "📊 Configuraciones actuales del touchscreen:"
    echo ""
    
    TOUCH_ID=$(get_touchscreen_id)
    if [ -n "$TOUCH_ID" ]; then
        echo "🔍 Dispositivo encontrado (ID: $TOUCH_ID)"
        echo "Propiedades actuales:"
        xinput list-props "$TOUCH_ID" | grep -E "(Coordinate|Matrix|Pressure|Size|Palm|Touch)" | head -10
    else
        echo "❌ No se encontró dispositivo touchscreen"
        echo "Dispositivos disponibles:"
        xinput list | grep -i touch
    fi
    
    echo ""
    echo "⚙️ Configuraciones GNOME:"
    echo "Bloqueo de orientación: $(gsettings get org.gnome.settings-daemon.peripherals.touchscreen orientation-lock 2>/dev/null || echo 'N/A')"
    echo "Teclado virtual: $(gsettings get org.gnome.desktop.a11y.applications screen-keyboard-enabled 2>/dev/null || echo 'N/A')"
    echo ""
}

# Función para configurar sensibilidad general
set_sensitivity() {
    local level=$1
    
    if [ "$level" -lt 1 ] || [ "$level" -gt 10 ]; then
        echo "❌ Error: La sensibilidad debe estar entre 1 y 10"
        return 1
    fi
    
    TOUCH_ID=$(get_touchscreen_id)
    if [ -z "$TOUCH_ID" ]; then
        echo "❌ No se encontró dispositivo touchscreen"
        return 1
    fi
    
    echo "🎯 Configurando sensibilidad a nivel $level..."
    
    # Calcular factor de sensibilidad (0.5 = muy baja, 2.0 = muy alta)
    local factor=$(echo "scale=2; 0.4 + ($level * 0.16)" | bc -l 2>/dev/null || echo "1.0")
    
    # Aplicar matriz de transformación
    xinput set-prop "$TOUCH_ID" "Coordinate Transformation Matrix" "$factor" 0 0 0 "$factor" 0 0 0 1 2>/dev/null
    
    # Configurar threshold si está disponible
    xinput set-prop "$TOUCH_ID" "libinput Pressure Threshold" "$((11-level))" 2>/dev/null || true
    
    echo "✅ Sensibilidad configurada a nivel $level (factor: $factor)"
}

# Función para configurar sensibilidad de presión
set_pressure_sensitivity() {
    local level=$1
    
    if [ "$level" -lt 1 ] || [ "$level" -gt 10 ]; then
        echo "❌ Error: La presión debe estar entre 1 y 10"
        return 1
    fi
    
    TOUCH_ID=$(get_touchscreen_id)
    if [ -z "$TOUCH_ID" ]; then
        echo "❌ No se encontró dispositivo touchscreen"
        return 1
    fi
    
    echo "🎯 Configurando sensibilidad de presión a nivel $level..."
    
    # Configurar threshold de presión (valores más bajos = mayor sensibilidad)
    local threshold=$((11-level))
    xinput set-prop "$TOUCH_ID" "libinput Pressure Threshold" "$threshold" 2>/dev/null || echo "⚠️  Propiedad de presión no disponible"
    
    echo "✅ Sensibilidad de presión configurada a nivel $level"
}

# Función para configurar rechazo de palma
set_palm_rejection() {
    local state=$1
    
    TOUCH_ID=$(get_touchscreen_id)
    if [ -z "$TOUCH_ID" ]; then
        echo "❌ No se encontró dispositivo touchscreen"
        return 1
    fi
    
    case "$state" in
        "on"|"1"|"true")
            echo "🖐️ Activando rechazo de palma..."
            xinput set-prop "$TOUCH_ID" "libinput Disable While Typing Enabled" 1 2>/dev/null || echo "⚠️  Propiedad no disponible"
            xinput set-prop "$TOUCH_ID" "libinput Palm Detection Enabled" 1 2>/dev/null || echo "⚠️  Detección de palma no disponible"
            echo "✅ Rechazo de palma activado"
            ;;
        "off"|"0"|"false")
            echo "🖐️ Desactivando rechazo de palma..."
            xinput set-prop "$TOUCH_ID" "libinput Disable While Typing Enabled" 0 2>/dev/null || echo "⚠️  Propiedad no disponible"
            xinput set-prop "$TOUCH_ID" "libinput Palm Detection Enabled" 0 2>/dev/null || echo "⚠️  Detección de palma no disponible"
            echo "✅ Rechazo de palma desactivado"
            ;;
        *)
            echo "❌ Error: Usa 'on' o 'off'"
            return 1
            ;;
    esac
}

# Función para configurar tamaño mínimo de toque
set_touch_size() {
    local level=$1
    
    if [ "$level" -lt 1 ] || [ "$level" -gt 10 ]; then
        echo "❌ Error: El tamaño debe estar entre 1 y 10"
        return 1
    fi
    
    TOUCH_ID=$(get_touchscreen_id)
    if [ -z "$TOUCH_ID" ]; then
        echo "❌ No se encontró dispositivo touchscreen"
        return 1
    fi
    
    echo "👆 Configurando tamaño mínimo de toque a nivel $level..."
    
    # Configurar área mínima de toque
    local min_area=$((level * 10))
    xinput set-prop "$TOUCH_ID" "libinput Touch Minimum Area" "$min_area" 2>/dev/null || echo "⚠️  Propiedad de área no disponible"
    
    echo "✅ Tamaño mínimo de toque configurado a nivel $level"
}

# Función para resetear configuraciones
reset_config() {
    echo "🔄 Restaurando configuraciones por defecto..."
    
    TOUCH_ID=$(get_touchscreen_id)
    if [ -n "$TOUCH_ID" ]; then
        # Resetear matriz de transformación
        xinput set-prop "$TOUCH_ID" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1 2>/dev/null || true
        
        # Resetear propiedades de libinput a valores por defecto
        xinput set-prop "$TOUCH_ID" "libinput Pressure Threshold" 5 2>/dev/null || true
        xinput set-prop "$TOUCH_ID" "libinput Disable While Typing Enabled" 1 2>/dev/null || true
        xinput set-prop "$TOUCH_ID" "libinput Palm Detection Enabled" 1 2>/dev/null || true
        xinput set-prop "$TOUCH_ID" "libinput Touch Minimum Area" 30 2>/dev/null || true
        
        echo "✅ Configuraciones restauradas"
    else
        echo "❌ No se pudo encontrar el dispositivo touchscreen"
    fi
}

# Verificar que bc esté instalado (para cálculos decimales)
if ! command -v bc &> /dev/null; then
    echo "⚠️  Instalando bc para cálculos de sensibilidad..."
    sudo apt-get update && sudo apt-get install -y bc
fi

# Función principal
main() {
    case "$1" in
        "sensitivity")
            if [ -z "$2" ]; then
                echo "❌ Error: Especifica un nivel de sensibilidad (1-10)"
                show_usage
                exit 1
            fi
            set_sensitivity "$2"
            ;;
        "pressure")
            if [ -z "$2" ]; then
                echo "❌ Error: Especifica un nivel de presión (1-10)"
                show_usage
                exit 1
            fi
            set_pressure_sensitivity "$2"
            ;;
        "palm-rejection")
            if [ -z "$2" ]; then
                echo "❌ Error: Especifica 'on' o 'off'"
                show_usage
                exit 1
            fi
            set_palm_rejection "$2"
            ;;
        "touch-size")
            if [ -z "$2" ]; then
                echo "❌ Error: Especifica un nivel de tamaño (1-10)"
                show_usage
                exit 1
            fi
            set_touch_size "$2"
            ;;
        "show")
            show_current_config
            ;;
        "reset")
            reset_config
            ;;
        *)
            show_usage
            echo ""
            echo "📊 Estado actual:"
            show_current_config
            ;;
    esac
}

main "$@"