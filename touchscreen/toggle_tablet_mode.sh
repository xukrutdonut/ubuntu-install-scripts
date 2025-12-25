#!/bin/bash
# toggle_tablet_mode.sh - Script para rotar pantalla manualmente

set -e

ORIENTATION="${1:-normal}"
LOG_FILE="$HOME/.tablet-mode.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

# Detectar displays conectados
get_displays() {
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        # En Wayland, intentar con gnome-randr si está disponible
        if command -v gnome-randr >/dev/null 2>&1; then
            gnome-randr | grep -E "^\s*[A-Z]" | awk '{print $1}'
        else
            log "⚠️ Rotación manual no disponible en Wayland sin gnome-randr"
            return 1
        fi
    else
        # En X11, usar xrandr
        xrandr --query | grep " connected" | cut -d' ' -f1
    fi
}

# Rotar pantalla
rotate_display() {
    local display="$1"
    local orientation="$2"
    
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        if command -v gnome-randr >/dev/null 2>&1; then
            case "$orientation" in
                "normal")
                    gnome-randr --output "$display" --rotate normal
                    ;;
                "left")
                    gnome-randr --output "$display" --rotate left
                    ;;
                "right")
                    gnome-randr --output "$display" --rotate right
                    ;;
                "inverted")
                    gnome-randr --output "$display" --rotate inverted
                    ;;
            esac
        else
            log "❌ No se puede rotar en Wayland sin gnome-randr"
            return 1
        fi
    else
        case "$orientation" in
            "normal")
                xrandr --output "$display" --rotate normal
                ;;
            "left")
                xrandr --output "$display" --rotate left
                ;;
            "right")
                xrandr --output "$display" --rotate right
                ;;
            "inverted")
                xrandr --output "$display" --rotate inverted
                ;;
        esac
    fi
}

# Función principal
main() {
    log "Intentando rotar pantalla a: $ORIENTATION"
    
    # Obtener displays
    displays=$(get_displays)
    
    if [ -z "$displays" ]; then
        log "❌ No se encontraron displays"
        exit 1
    fi
    
    # Rotar cada display
    echo "$displays" | while read -r display; do
        if [ -n "$display" ]; then
            log "Rotando display: $display"
            rotate_display "$display" "$ORIENTATION"
            log "✓ Display $display rotado a $ORIENTATION"
        fi
    done
    
    log "✓ Rotación completada"
}

main "$@"