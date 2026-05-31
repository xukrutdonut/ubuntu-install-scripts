#!/bin/bash
# Apaga el monitor vía Mutter cuando InputLeap mueve el foco al cliente.
# No usa idle (Mutter resetea el idle aunque el input vaya al cliente).
# Monitoriza los eventos "leaving screen" / "entering screen" de input-leaps
# via strace sobre su stdout, y controla la pantalla con PowerSaveMode:
#   0 = encendido, 3 = apagado (sin screensaver, sin bloqueo, sin contraseña)

FOCUS_TIMEOUT=30  # segundos sin foco → apagar pantalla

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] inputleap-screen: $*"; }

set_power() {
    gdbus call --session \
        --dest org.gnome.Mutter.DisplayConfig \
        --object-path /org/gnome/Mutter/DisplayConfig \
        --method org.freedesktop.DBus.Properties.Set \
        "org.gnome.Mutter.DisplayConfig" "PowerSaveMode" "<int32 $1>" 2>/dev/null
}

# FIFO para comunicar eventos del monitor al bucle principal
EVENTS_FIFO=$(mktemp -u /tmp/inputleap-focus-XXXXXX)
mkfifo "$EVENTS_FIFO"
trap "rm -f '$EVENTS_FIFO'; kill 0" EXIT INT TERM

# Proceso en segundo plano: monitoriza el stdout de input-leaps via strace
# y escribe LEAVE/ENTER en el FIFO cuando detecta cambios de foco
(
    while true; do
        PID=$(pgrep -x input-leaps 2>/dev/null | head -1)
        if [[ -z "$PID" ]]; then
            sleep 5
            continue
        fi
        log "Adjuntando strace a input-leaps PID=$PID"
        strace -p "$PID" -e trace=write -s 500 -qq 2>&1 \
            | grep --line-buffered -oP 'write\(1, "\K[^"]+' \
            | while IFS= read -r line; do
                if [[ "$line" == *"leaving screen"* ]]; then
                    echo "LEAVE" > "$EVENTS_FIFO"
                elif [[ "$line" == *"entering screen"* ]]; then
                    echo "ENTER" > "$EVENTS_FIFO"
                fi
              done
        log "strace terminó (input-leaps se reinició?). Reintentando en 3s..."
        sleep 3
    done
) &

log "Iniciado. Timeout de foco: ${FOCUS_TIMEOUT}s"
log "Pantalla: Mutter DisplayConfig PowerSaveMode (sin screensaver)"

# Abrir FIFO en modo lectura+escritura para evitar EOF al reconectar el productor
exec 3<>"$EVENTS_FIFO"

timer_pid=""

while IFS= read -r event <&3; do
    case "$event" in
        LEAVE)
            log "Foco → cliente. Apagando en ${FOCUS_TIMEOUT}s si no vuelve"
            [[ -n "$timer_pid" ]] && kill "$timer_pid" 2>/dev/null
            ( sleep "$FOCUS_TIMEOUT"
              log "Timeout alcanzado — apagando pantalla (PowerSaveMode=3)"
              set_power 3
            ) &
            timer_pid=$!
            ;;
        ENTER)
            log "Foco → servidor. Encendiendo pantalla (PowerSaveMode=0)"
            [[ -n "$timer_pid" ]] && kill "$timer_pid" 2>/dev/null
            timer_pid=""
            set_power 0
            ;;
    esac
done

