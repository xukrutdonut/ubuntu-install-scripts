#!/bin/bash
# InputLeap - watchdog en modo Wayland
# NUNCA mata el proceso si está vivo: así el portal Wayland no revoca la sesión.
# Solo arranca InputLeap si ha muerto por algún motivo.

FLATPAK_APP="io.github.input_leap.input-leap"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

start_inputleap() {
    log "Arrancando InputLeap..."
    flatpak run "$FLATPAK_APP" &
    log "InputLeap iniciado (PID: $!)"
}

is_running() {
    # Comprobar que tanto la GUI como el servidor estén corriendo
    pgrep -f "input-leaps" > /dev/null 2>&1 && pgrep -x "input-leap" > /dev/null 2>&1
}

# Al arrancar el watchdog, esperar a que la sesión gráfica esté lista
sleep 5

# Arrancar si no está corriendo
if ! is_running; then
    log "InputLeap no está corriendo - arrancando..."
    start_inputleap
fi

# Monitor de screensaver: si la pantalla se enciende y el proceso murió, reiniciar
gdbus monitor --session \
    --dest org.gnome.ScreenSaver \
    --object-path /org/gnome/ScreenSaver 2>/dev/null | \
grep --line-buffered "ActiveChanged" | \
while IFS= read -r line; do
    if echo "$line" | grep -q "false"; then
        sleep 2
        if ! is_running; then
            log "Pantalla encendida y InputLeap caído - reiniciando"
            start_inputleap
        else
            log "Pantalla encendida, InputLeap sigue vivo - no se reinicia"
        fi
    fi
done &

# Monitor de suspensión del sistema
gdbus monitor --system \
    --dest org.freedesktop.login1 \
    --object-path /org/freedesktop/login1 2>/dev/null | \
grep --line-buffered "PrepareForSleep" | \
while IFS= read -r line; do
    if echo "$line" | grep -q "false"; then
        sleep 5
        if ! is_running; then
            log "Sistema reanudado e InputLeap caído - reiniciando"
            start_inputleap
        else
            log "Sistema reanudado, InputLeap sigue vivo - no se reinicia"
        fi
    fi
done &

# Watchdog principal: comprobar cada 30s (no cada 10s para no interferir)
while true; do
    sleep 30
    if ! is_running; then
        log "Servidor no detectado - arrancando..."
        start_inputleap
    fi
done
