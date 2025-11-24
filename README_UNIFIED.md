# 🚀 Scripts Ubuntu - Instalación Completa y Certificados Digitales

[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20|%2024.04%20|%2025.04-orange.svg)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

**Scripts depurados y unificados** para instalación completa de Ubuntu con software esencial, certificados digitales y VPN para la Generalitat Valenciana.

## 🎯 Uso Rápido

```bash
# 1. Instalación completa (recomendado)
chmod +x instalacion_completa_ubuntu.sh
./instalacion_completa_ubuntu.sh

# 2. Solo certificados digitales
chmod +x InstalaciónGyD.sh
./InstalaciónGyD.sh

# 3. Conectar VPN (después de tener certificados)
chmod +x VPN-SAN-GVA.sh
./VPN-SAN-GVA.sh
```

## 📋 Scripts Disponibles

### 🌟 **instalacion_completa_ubuntu.sh** 
**Script principal que instala todo:**
- ✅ Actualiza sistema y repositorios
- ✅ Firefox desde Mozilla (elimina Snap)
- ✅ Flatpak + Flathub + aplicaciones
- ✅ Software esencial: GIMP, VLC, FileZilla
- ✅ Certificados digitales (SafeSign/OpenSC según versión)
- ✅ Apps Flatpak: Spotify, Zotero, OBS, LibreOffice

### 🔧 **InstalaciónGyD.sh**
**Especializado en certificados digitales:**
- Detecta versión Ubuntu automáticamente
- Descarga SafeSign si es necesario
- Configura módulos PKCS#11
- Fallback a OpenSC para Ubuntu 25.04+

### 📡 **VPN-SAN-GVA.sh**
**Conexión VPN Generalitat:**
- Verificaciones automáticas de certificados
- Detección inteligente de tokens
- Conexión automática con el certificado disponible
- Diagnóstico completo en caso de error

### 🛠️ **post_instalacion_certificados.sh**
**Alternativo para Ubuntu 25.04+:**
- Configura OpenSC cuando SafeSign no funciona
- Crea scripts de verificación
- Instrucciones para configuración manual

## 🖥️ Compatibilidad

| Ubuntu | instalacion_completa | InstalaciónGyD | Certificados | VPN |
|--------|---------------------|----------------|--------------|-----|
| 22.04  | ✅ Completa | ✅ SafeSign | ✅ Total | ✅ |
| 24.04  | ✅ Completa | ✅ SafeSign | ✅ Total | ✅ |
| 25.04+ | ✅ Completa | 🔄 OpenSC  | ⚠️ Manual | ✅ |

## 🔧 Correcciones Implementadas

| ❌ Problema Original | ✅ Solución |
|---------------------|-------------|
| PPAs incompatibles Ubuntu 25.04+ | Detecta versión automáticamente |
| Diálogos cuelgan instalación | `DEBIAN_FRONTEND=noninteractive` |
| SafeSign falla Ubuntu nuevas | OpenSC como alternativa |
| Sin manejo de errores | `set -e` + verificaciones |
| Scripts sin logs | Colores y logging completo |
| No verifica servicios | Arranca y verifica `pcscd` |

## 🛠️ Verificaciones Post-Instalación

### Certificados Digitales
```bash
# Verificar servicio
systemctl status pcscd

# Escanear lectores
pcsc_scan

# Listar tokens
p11tool --list-tokens

# Verificar certificados
p11tool --list-privkeys --login
```

### Aplicaciones
```bash
# Verificar Firefox
firefox --version

# Verificar Flatpak
flatpak --version
flatpak list

# Verificar VLC, GIMP
vlc --version
gimp --version
```

## 🆘 Solución de Problemas

### Error "apt lock"
```bash
sudo killall apt-get
sudo rm /var/lib/dpkg/lock-frontend
sudo dpkg --configure -a
```

### Certificados no detectados
```bash
# Verificar lector USB
lsusb | grep -i smart

# Reiniciar servicios
sudo systemctl restart pcscd

# Verificar módulos P11
p11-kit list-modules
```

### VPN no conecta
```bash
# Verificar certificados
p11tool --list-privkeys --login

# Verificar conectividad
ping vpn.san.gva.es

# Instalar dependencias VPN
sudo apt install network-manager-openconnect-gnome
```

## 📦 Software Instalado

**Sistema Base:**
- Firefox (Mozilla oficial), Flatpak + Flathub
- Certificados digitales (pcscd, SafeSign/OpenSC)
- OpenConnect VPN

**Aplicaciones:**
- GIMP, VLC, FileZilla
- Spotify, Zotero, OBS Studio, LibreOffice
- Timeshift (copias de seguridad)

## 📁 Archivos Generados

```
/home/arkantu/Escritorio/scripts/
├── SafeSign_*.deb                   # Drivers descargados
├── libwx*.deb                       # Dependencias
├── conectar_vpn_gva.sh             # Script VPN auto-generado
├── verificar_certificados.sh       # Verificación
└── resumen_instalacion.md          # Log de instalación
```

## 🔗 Enlaces Útiles

- [SafeSign Drivers](https://www.a-et.com/products/smart-card-middleware/)
- [OpenSC Project](https://github.com/OpenSC/OpenSC)
- [Flathub Apps](https://flathub.org/)
- [VPN Generalitat](https://vpn.san.gva.es)

---

⭐ **Scripts depurados y testados - Compatible Ubuntu 22.04/24.04/25.04**

*Mantenido por [@arkantu](https://github.com/arkantu) - Nov 2024*