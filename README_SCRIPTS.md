# 📜 Scripts de Instalación Ubuntu - Guía Completa

## 🎯 Scripts Disponibles

### 1. **instalacion_completa_ubuntu.sh** ⭐ 
**Script principal unificado y depurado**
```bash
./instalacion_completa_ubuntu.sh
```
**Qué hace:**
- ✅ Actualiza el sistema base
- ✅ Configura Firefox (elimina Snap, instala desde Mozilla)
- ✅ Instala Flatpak + Flathub
- ✅ Instala software esencial (GIMP, VLC, FileZilla, etc.)
- ✅ Configura certificados digitales (según versión Ubuntu)
- ✅ Instala apps adicionales via Flatpak
- ✅ Aplica configuraciones del sistema
- ✅ Crea script de VPN automáticamente

### 2. **InstalaciónGyD.sh**
**Script especializado para certificados digitales**
```bash
./InstalaciónGyD.sh
```
**Características:**
- Detecta versión de Ubuntu automáticamente
- Descarga drivers SafeSign si no existen
- Configura módulos PKCS#11
- Maneja incompatibilidades de Ubuntu 25.04+

### 3. **post_instalacion_certificados.sh**
**Script alternativo para Ubuntu 25.04+**
```bash
./post_instalacion_certificados.sh
```
**Para cuando SafeSign no es compatible:**
- Configura OpenSC como alternativa
- Crea scripts de verificación
- Instrucciones para configuración manual

### 4. **VPN-SAN-GVA.sh** 
**Script mejorado para VPN Generalitat**
```bash
./VPN-SAN-GVA.sh
```
**Mejoras:**
- Verificaciones previas de servicios
- Detección automática de certificados
- Mensajes informativos claros
- Gestión de errores mejorada

## 🚀 Guía de Uso Recomendada

### Instalación Nueva (Recomendado)
```bash
# 1. Ejecutar script principal (hace todo)
./instalacion_completa_ubuntu.sh

# 2. Si hay problemas con certificados en Ubuntu 25.04+
./post_instalacion_certificados.sh

# 3. Para conectar VPN (cuando tengas certificados)
./VPN-SAN-GVA.sh
```

### Instalación por Partes
```bash
# 1. Solo certificados digitales
./InstalaciónGyD.sh

# 2. Verificar certificados
./post_instalacion_certificados.sh

# 3. Configurar VPN
./VPN-SAN-GVA.sh
```

## 🔧 Correcciones Aplicadas

### ❌ Problemas del Script Original → ✅ Soluciones

| Problema Original | Solución Implementada |
|-------------------|----------------------|
| PPAs incompatibles con Ubuntu 25.04+ | ✅ Detecta versión y usa repositorios compatibles |
| Diálogos interactivos colgaban | ✅ `DEBIAN_FRONTEND=noninteractive` |
| SafeSign falla en Ubuntu 25.04+ | ✅ Detecta versión y usa OpenSC alternativo |
| No manejo de errores | ✅ `set -e` y verificaciones en cada paso |
| Dependencias hardcoded | ✅ Descargas condicionales y verificaciones |
| Scripts sin logging | ✅ Sistema de logging con colores |
| No verificaba servicios | ✅ Verifica y arranca `pcscd` |
| Un solo script monolítico | ✅ Scripts modulares especializados |

## 📋 Compatibilidad

| Ubuntu Version | instalacion_completa | InstalaciónGyD | Certificados |
|----------------|---------------------|----------------|--------------|
| 22.04 LTS | ✅ Completa | ✅ Completa | ✅ SafeSign |
| 24.04 LTS | ✅ Completa | ✅ Completa | ✅ SafeSign |
| 25.04+ | ✅ Completa | ⚠️ Parcial | 🔄 OpenSC |

## 🛠️ Verificaciones Post-Instalación

### Verificar Flatpak
```bash
flatpak --version
flatpak remote-list
flatpak list
```

### Verificar Certificados
```bash
systemctl status pcscd
pcsc_scan
p11tool --list-tokens
```

### Verificar Firefox
```bash
firefox --version
# En Firefox: about:preferences#privacy -> Certificados
```

## 🆘 Solución de Problemas

### Error: "apt lock"
```bash
sudo killall apt-get
sudo rm /var/lib/dpkg/lock-frontend
sudo dpkg --configure -a
```

### Certificados no detectados
```bash
# 1. Verificar lector conectado
lsusb | grep -i smart

# 2. Reiniciar servicio
sudo systemctl restart pcscd

# 3. Verificar módulos
p11-kit list-modules
```

### VPN no conecta
```bash
# 1. Verificar certificados
p11tool --list-privkeys --login

# 2. Instalar dependencias VPN
sudo apt install network-manager-openconnect-gnome

# 3. Verificar conectividad
ping vpn.san.gva.es
```

## 📁 Archivos Generados

Después de ejecutar los scripts encontrarás:
```
/home/arkantu/Escritorio/scripts/
├── conectar_vpn_gva.sh          # Auto-generado
├── verificar_certificados.sh    # Si usas post_instalacion
├── SafeSign_*.deb              # Drivers descargados
├── libwx*.deb                  # Dependencias descargadas
└── resumen_instalacion.md      # Resumen de lo instalado
```

## 🎉 ¿Qué Está Instalado Después?

**Navegadores:**
- Firefox (repositorio Mozilla oficial)

**Multimedia:**
- VLC Media Player
- GIMP (editor imágenes)

**Herramientas:**
- FileZilla (cliente FTP)
- Flatpak + Flathub
- Herramientas certificados digitales
- OpenConnect (VPN)

**Flatpak Apps:**
- Spotify
- Zotero
- OBS Studio
- LibreOffice

---
*Scripts depurados y unificados - Versión 2.0*
*Compatible Ubuntu 22.04/24.04/25.04*