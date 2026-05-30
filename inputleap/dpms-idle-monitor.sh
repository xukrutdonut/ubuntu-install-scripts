#!/bin/bash
# Apaga el monitor vía Mutter (sin activar el screensaver de GNOME)
# Así el portal Wayland de InputLeap nunca se revoca.
#
# Usa xprintidle (XWayland) para detectar inactividad y
# org.gnome.Mutter.DisplayConfig.PowerSaveMode para controlar la pantalla:
#   0 = encendido, 1 = standby, 2 = suspend, 3 = apagado

IDLE_THRESHOLD_MS=300000   # 5 minutos en milisegundos
CHECK_INTERVAL=15           # segundos entre comprobaciones
DISPLAY=${DISPLAY:-:0}
export DISPLAY

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] dpms-idle: $*"
}

set_power_mode() {
    gdbus call --session \
        --dest org.gnome.Mutter.DisplayConfig \
        --object-path /org/gnome/Mutter/DisplayConfig \
        --method org.freedesktop.DBus.Properties.Set \
        "org.gnome.Mutter.DisplayConfig" "PowerSaveMode" "<int32 $1>" 2>/dev/null
}

monitor_is_off() {
    local mode
    mode=$(gdbus call --session \
        --dest org.gnome.Mutter.DisplayConfig \
        --object-path /org/gnome/Mutter/DisplayConfig \
        --method org.freedesktop.DBus.Properties.Get \
        "org.gnome.Mutter.DisplayConfig" "PowerSaveMode" 2>/dev/null)
    # Devuelve true si PowerSaveMode != 0
    [[ "$mode" != "(<int32 0>,)" ]]
}

log "Iniciado. Umbral de inactividad: $((IDLE_THRESHOLD_MS / 60000)) minutos"

screen_off=false

while true; do
    idle_ms=$(DISPLAY="$DISPLAY" xprintidle 2>/dev/null)

    if [[ -z "$idle_ms" ]]; then
        sleep "$CHECK_INTERVAL"
        continue
    fi

    if [[ "$idle_ms" -ge "$IDLE_THRESHOLD_MS" ]] && [[ "$screen_off" == false ]]; then
        log "Inactivo ${idle_ms}ms — apagando monitor"
        set_power_mode 3
        screen_off=true

    elif [[ "$idle_ms" -lt 3000 ]] && [[ "$screen_off" == true ]]; then
        log "Actividad detectada — encendiendo monitor"
        set_power_mode 0
        screen_off=false
    fi

    sleep "$CHECK_INTERVAL"
done
