# InputLeap Server en GNOME/Wayland — Configuración para pantalla siempre autorizada

## Problema

En GNOME con sesión Wayland, el servidor InputLeap requiere autorización del portal Wayland
(`xdg-desktop-portal-gnome`) para acceder al RemoteDesktop. Este permiso se **revoca
automáticamente** cuando el screensaver de GNOME se activa, incluso aunque el bloqueo de
pantalla esté desactivado.

Síntomas:
- Al apagarse la pantalla aparece el diálogo "Compartir pantalla — Permitir"
- InputLeap deja de funcionar hasta que se vuelve a autorizar manualmente

## Solución

Separar el apagado físico del monitor del sistema de screensaver de GNOME:

1. **Desactivar el screensaver de GNOME** → el portal Wayland nunca se revoca
2. **Apagar el monitor via Mutter (DPMS)** → ahorro de energía sin pasar por el screensaver

```
GNOME screensaver (idle-delay=0) → DESACTIVADO
        ↓ no revoca el portal
InputLeap portal Wayland → SIEMPRE ACTIVO
        
Mutter DisplayConfig.PowerSaveMode → apaga/enciende el monitor directamente
```

## Arquitectura

```
~/.config/systemd/user/
├── screen-wake-monitor.service   ← watchdog: reinicia InputLeap si muere
└── dpms-idle-monitor.service     ← apaga/enciende monitor sin screensaver
```

```
~/ubuntu-install-scripts/  (ruta en producción)
├── screen-wake-monitor.sh        ← script watchdog
└── dpms-idle-monitor.sh          ← script DPMS via Mutter
```

## Componentes

### `screen-wake-monitor.service` + `screen-wake-monitor.sh`

Watchdog que:
- Arranca InputLeap (Flatpak `io.github.input_leap.input-leap`) al inicio de sesión
- Lo reinicia si muere por cualquier motivo
- Monitoriza `org.gnome.ScreenSaver` y `org.freedesktop.login1` (por si el screensaver
  se activara igualmente) para reiniciar si es necesario
- **No mata InputLeap** si ya está vivo — así el portal Wayland no se revoca nunca

### `dpms-idle-monitor.service` + `dpms-idle-monitor.sh`

Monitor DPMS que:
- Usa `xprintidle` (vía XWayland) para detectar inactividad del usuario
- Cuando idle ≥ 5 minutos: llama a `org.gnome.Mutter.DisplayConfig.PowerSaveMode = 3`
  (apaga el monitor a nivel hardware sin activar screensaver)
- Cuando se detecta actividad: restaura `PowerSaveMode = 0` (enciende el monitor)
- Comprueba cada 15 segundos

## Configuración de GNOME aplicada

```bash
# Screensaver desactivado (clave del fix)
gsettings set org.gnome.desktop.session idle-delay 0

# Bloqueo de pantalla desactivado
gsettings set org.gnome.desktop.screensaver lock-enabled false

# Suspensión por inactividad desactivada (servidor siempre encendido)
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
```

## Instalación

### 1. Copiar scripts

```bash
mkdir -p ~/ubuntu-install-scripts
cp screen-wake-monitor.sh ~/ubuntu-install-scripts/
cp dpms-idle-monitor.sh ~/ubuntu-install-scripts/
chmod +x ~/ubuntu-install-scripts/*.sh
```

### 2. Instalar servicios systemd de usuario

```bash
mkdir -p ~/.config/systemd/user
cp screen-wake-monitor.service ~/.config/systemd/user/
cp dpms-idle-monitor.service ~/.config/systemd/user/

systemctl --user daemon-reload
systemctl --user enable screen-wake-monitor.service dpms-idle-monitor.service
systemctl --user start screen-wake-monitor.service dpms-idle-monitor.service
```

### 3. Aplicar configuración GNOME

```bash
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
```

### 4. Verificar

```bash
systemctl --user status screen-wake-monitor.service dpms-idle-monitor.service
journalctl --user -u dpms-idle-monitor.service -f
```

## Ajuste del tiempo de apagado

En `dpms-idle-monitor.sh`, modificar la variable:

```bash
IDLE_THRESHOLD_MS=300000   # 5 minutos (en milisegundos)
```

Tras cambiarla, reiniciar el servicio:

```bash
systemctl --user restart dpms-idle-monitor.service
```

## Dependencias del sistema

| Herramienta | Paquete | Uso |
|---|---|---|
| `xprintidle` | `xprintidle` | Detectar tiempo de inactividad vía XWayland |
| `gdbus` | `glib2` (preinstalado) | Llamar a D-Bus de Mutter y GNOME |
| `flatpak` | `flatpak` | Ejecutar InputLeap |
| XWayland | preinstalado en Ubuntu | Compatibilidad X11 en sesión Wayland |

```bash
# Instalar si falta xprintidle
sudo apt install xprintidle
```

## Por qué no funciona DPMS estándar vía xset

En GNOME/Wayland, el servidor XWayland no expone la extensión DPMS de X11 (`DPMS Extension`),
por lo que `xset dpms` no tiene efecto. La solución es usar la API nativa de Mutter
(`org.gnome.Mutter.DisplayConfig`) que es el compositor Wayland de GNOME.

## Entorno de desarrollo/pruebas

- **Máquina**: Rivendel
- **OS**: Ubuntu GNOME (Wayland)
- **InputLeap**: Flatpak `io.github.input_leap.input-leap`
- **Rol**: servidor InputLeap (comparte teclado/ratón con otros equipos)
