#!/bin/bash

echo "=== Configurador de Surface Pen ==="

# Función para obtener IDs de dispositivos Surface Pen
get_surface_pen_devices() {
    STYLUS_ID=$(xinput list | grep -i "tablet stylus\|stylus" | grep -o "id=[0-9]*" | cut -d= -f2 | head -1)
    ERASER_ID=$(xinput list | grep -i "tablet eraser\|eraser" | grep -o "id=[0-9]*" | cut -d= -f2 | head -1)
    echo "STYLUS_ID=$STYLUS_ID ERASER_ID=$ERASER_ID"
}

# Función para configurar sensibilidad
set_pen_sensitivity() {
    local level=$1
    
    if [ "$level" -lt 1 ] || [ "$level" -gt 10 ]; then
        echo "❌ Error: La sensibilidad debe estar entre 1 y 10"
        return 1
    fi
    
    eval $(get_surface_pen_devices)
    
    if [ -z "$STYLUS_ID" ]; then
        echo "❌ No se encontró Surface Pen stylus"
        return 1
    fi
    
    echo "🎯 Configurando sensibilidad de Surface Pen a nivel $level..."
    
    # Ajustar matriz de transformación
    local factor=$(echo "scale=3; 0.7 + ($level * 0.04)" | bc -l 2>/dev/null || echo "1.0")
    
    xinput set-prop "$STYLUS_ID" "Coordinate Transformation Matrix" "$factor" 0 0 0 "$factor" 0 0 0 0 1 2>/dev/null
    
    echo "✅ Surface Pen configurado a nivel $level (factor: $factor)"
}

# Función para mostrar configuración actual
show_pen_config() {
    echo "🖊️ Surface Pen - Estado actual:"
    
    eval $(get_surface_pen_devices)
    
    if [ -n "$STYLUS_ID" ]; then
        echo "📝 Surface Pen encontrado (ID: $STYLUS_ID)"
        xinput list-props "$STYLUS_ID" | grep -E "(Transformation|Accel)" | head -3 2>/dev/null || echo "  • Propiedades básicas disponibles"
    else
        echo "❌ Surface Pen no detectado"
    fi
    
    # Verificar iptsd
    if pgrep iptsd > /dev/null; then
        echo "✅ iptsd ejecutándose (driver Surface Pen activo)"
    else
        echo "❌ iptsd no está ejecutándose"
        echo "   Ejecuta: ./start_surface_pen.sh"
    fi
}

# Función para resetear configuración
reset_pen() {
    eval $(get_surface_pen_devices)
    
    if [ -n "$STYLUS_ID" ]; then
        xinput set-prop "$STYLUS_ID" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1 2>/dev/null
        echo "✅ Surface Pen configurado con valores por defecto"
    fi
}

case "$1" in
    "sensitivity")
        if [ -z "$2" ]; then
            echo "❌ Especifica nivel (1-10): $0 sensitivity 7"
            exit 1
        fi
        set_pen_sensitivity "$2"
        ;;
    "show")
        show_pen_config
        ;;
    "reset")
        reset_pen
        ;;
    *)
        echo "Uso: $0 [sensitivity|show|reset] [1-10]"
        echo "Ejemplos:"
        echo "  $0 sensitivity 7    # Configurar sensibilidad"
        echo "  $0 show            # Ver configuración actual"
        echo "  $0 reset           # Valores por defecto"
        show_pen_config
        ;;
esac
