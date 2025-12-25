#!/bin/bash

echo "=== Configuración de Sensibilidad del Touchscreen ==="
echo ""

# Función para obtener el ID del dispositivo touchscreen
get_touchscreen_id() {
    TOUCH_ID=$(xinput list | grep -i "xwayland-touch\|touchscreen" | grep -o "id=[0-9]*" | cut -d= -f2 | head -1)
    if [ -z "$TOUCH_ID" ]; then
        TOUCH_ID=$(xinput list | grep -i "virtual.*touch\|ipts.*touch" | grep -o "id=[0-9]*" | cut -d= -f2 | head -1)
    fi
    echo "$TOUCH_ID"
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
    
    # Calcular factor de sensibilidad
    local factor=$(echo "scale=2; 0.4 + ($level * 0.16)" | bc -l 2>/dev/null || echo "1.0")
    
    # Aplicar matriz de transformación
    xinput set-prop "$TOUCH_ID" "Coordinate Transformation Matrix" "$factor" 0 0 0 "$factor" 0 0 0 1 2>/dev/null
    
    echo "✅ Sensibilidad configurada a nivel $level"
}

# Función para mostrar configuraciones actuales
show_config() {
    echo "📊 Configuraciones actuales del touchscreen:"
    
    TOUCH_ID=$(get_touchscreen_id)
    if [ -n "$TOUCH_ID" ]; then
        echo "🔍 Dispositivo encontrado (ID: $TOUCH_ID)"
        echo "Propiedades:"
        xinput list-props "$TOUCH_ID" | grep -E "(Coordinate|Matrix|Pressure)" | head -5
    else
        echo "❌ No se encontró dispositivo touchscreen"
    fi
}

# Función principal
case "$1" in
    "sensitivity")
        if [ -z "$2" ]; then
            echo "❌ Error: Especifica nivel (1-10): $0 sensitivity 7"
            exit 1
        fi
        set_sensitivity "$2"
        ;;
    "show")
        show_config
        ;;
    "reset")
        TOUCH_ID=$(get_touchscreen_id)
        if [ -n "$TOUCH_ID" ]; then
            xinput set-prop "$TOUCH_ID" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
            echo "✅ Configuración restaurada"
        fi
        ;;
    *)
        echo "Uso: $0 [sensitivity|show|reset] [1-10]"
        echo "Ejemplos:"
        echo "  $0 sensitivity 7    # Mayor sensibilidad"
        echo "  $0 show            # Ver configuración actual"
        echo "  $0 reset           # Valores por defecto"
        ;;
esac
