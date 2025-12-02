# 🚀 Ubuntu Install Scripts - Reorganized

[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20|%2024.04%20|%2025.04-orange.svg)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

**Colección reorganizada y optimizada** de scripts para instalación completa de Ubuntu con estructura modular.

## 📁 Nueva Estructura Organizada

### 🏠 Scripts Principales (Raíz)
- **`instalacion_ubuntu_alberto.sh`** ⭐ - Script unificado TODO-EN-UNO (RECOMENDADO)
- `instalacion_completa_ubuntu.sh` - Script maestro de instalación base
- `VPN-SAN-GVA-MEJORADO.sh` - VPN Generalitat (versión optimizada)
- `InstalaciónGyD.sh` - Certificados digitales GyD
- `post_instalacion_certificados.sh` - Post-instalación certificados
- `network_optimization.sh` - Optimización de red
- `fix-repositories.sh` - Reparación de repositorios

### 📱 Carpetas Especializadas
- **`touchscreen/`** - Scripts para pantallas táctiles, tablets y stylus Samsung
- **`MacOS/`** - Configuración de máquinas virtuales macOS en VirtualBox  
- **`displaylink/`** - Soporte para DisplayLink USB displays

## 🚀 Uso Rápido

```bash
# ⭐ Instalación completa recomendada
chmod +x instalacion_ubuntu_alberto.sh
./instalacion_ubuntu_alberto.sh

# Scripts específicos por categoría
chmod +x touchscreen/configure_tablet_mode.sh
./touchscreen/configure_tablet_mode.sh
```

## 🔧 Optimizaciones Realizadas

### ❌ Scripts Eliminados (Redundantes)
- `VPN-SAN-GVA.sh` → Reemplazado por versión MEJORADO
- `instalacionescritorio.sh` → Funcionalidad integrada
- `install-displaylink.sh` → Consolidado en carpeta displaylink/
- Scripts touchscreen básicos → Mantenidos solo los avanzados

### ✅ Scripts Mantenidos y Optimizados
- **Touchscreen**: 12 scripts especializados para diferentes casos
- **DisplayLink**: 1 script final optimizado
- **MacOS**: 2 scripts para virtualización completa
- **Principales**: Scripts depurados sin redundancias

## 📱 Aplicaciones y Características

### Sistema Base
- Firefox Mozilla (elimina Snap), Flatpak + Flathub
- Certificados digitales automáticos
- VPN Generalitat con verificaciones

### Aplicaciones Incluidas
- **Productividad**: LibreOffice, GIMP, VLC, Zotero
- **Flatpak**: Spotify, WhatsApp Desktop, InputLeap
- **Sistema**: Timeshift, GNOME Tweaks, TLP

### Especialidades
- **Touchscreen**: Soporte Samsung S-Pen, modo tablet GNOME
- **DisplayLink**: Pantallas USB plug-and-play
- **macOS VMs**: Configuración completa VirtualBox

## 🖥️ Compatibilidad

| Ubuntu | Base | Certificados | VPN | Touchscreen | DisplayLink |
|--------|------|-------------|-----|-------------|-------------|
| 22.04  | ✅   | ✅ SafeSign  | ✅  | ✅          | ✅          |
| 24.04  | ✅   | ✅ SafeSign  | ✅  | ✅          | ✅          |
| 25.04+ | ✅   | 🔄 OpenSC   | ✅  | ✅          | ✅          |

## 📋 Documentación Detallada

- `README_STRUCTURE.md` - Detalles completos de cada script
- `MEJORAS-REALIZADAS.md` - Log de optimizaciones
- `resumen_instalacion.md` - Registro de instalación

## 🤝 Contribuir

Mejoras y sugerencias bienvenidas. Abre un issue o envía un pull request.

---

⭐ **Scripts optimizados y organizados - Ubuntu 22.04/24.04/25.04**

*Reorganizado y mantenido por [@arkantu](https://github.com/arkantu) - Diciembre 2024*
