# Ubuntu Install Scripts - Estructura Organizativa

## Estructura de Carpetas

### `/touchscreen/`
Scripts para configuración de pantallas táctiles y tabletas:
- `advanced_touchscreen_fix.sh` - Soluciones avanzadas
- `configure_samsung_stylus.sh` - Configuración específica Samsung
- `configure_tablet_mode.sh` - Modo tableta
- `configure_touchscreen_sensitivity.sh` - Ajustes de sensibilidad
- `gnome_tablet_mode.sh` - Integración con GNOME
- `install_surface_touchpad.sh` - Soporte Surface touchpad
- `install_surface_touchscreen.sh` - Soporte Surface touchscreen
- `toggle_tablet_mode.sh` - Alternador de modo
- `ultra_sensitive_touchscreen.sh` - Configuración ultra-sensible

### `/MacOS/`
Scripts para virtualización de macOS:
- `setup_new.sh` - Configuración nueva VM macOS Ventura
- `configure_macos_vm.sh` - Configuraciones adicionales macOS

### `/displaylink/`
Scripts para DisplayLink USB displays:
- `fix_displaylink_final.sh` - Solución final DisplayLink

## Scripts Principales

### Instalación Base
- `instalacion_completa_ubuntu.sh` - Script maestro de instalación
- `instalacion_ubuntu_alberto.sh` - Versión personalizada unificada

### Configuraciones Específicas
- `VPN-SAN-GVA-MEJORADO.sh` - VPN Generalitat Valenciana (versión mejorada)
- `InstalaciónGyD.sh` - Certificados digitales
- `post_instalacion_certificados.sh` - Post-instalación certificados
- `network_optimization.sh` - Optimización de red
- `fix-repositories.sh` - Reparación de repositorios

## Archivos Eliminados (Redundantes)
- `VPN-SAN-GVA.sh` (versión antigua)
- `instalacionescritorio.sh` (funcionalidad integrada)
- `install-displaylink.sh` (reemplazado por versión final)
- Scripts de touchscreen simplificados (consolidados)