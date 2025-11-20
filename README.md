# 🚀 Scripts de Instalación Ubuntu

[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20|%2024.04%20|%2025.04-orange.svg)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

**Scripts depurados y unificados** para instalación completa de Ubuntu con software esencial, certificados digitales y configuración VPN para la Generalitat Valenciana.

## 🎯 Características

- ✅ **Detección automática** de versión Ubuntu (22.04/24.04/25.04+)
- ✅ **Instalación robusta** con manejo inteligente de errores
- ✅ **Firefox desde Mozilla** (elimina versión Snap automáticamente)
- ✅ **Flatpak + Flathub** configurado
- ✅ **Certificados digitales** con SafeSign + OpenSC alternativo
- ✅ **VPN Generalitat** con verificaciones automáticas
- ✅ **Software esencial** (GIMP, VLC, FileZilla, etc.)
- ✅ **Apps Flatpak** (Spotify, Zotero, OBS, LibreOffice)

## 🚀 Instalación Rápida

```bash
# Clonar repositorio
git clone https://github.com/arkantu/ubuntu-install-scripts.git
cd ubuntu-install-scripts

# Dar permisos de ejecución
chmod +x *.sh

# Ejecutar instalación completa
./instalacion_completa_ubuntu.sh
```

## 📋 Scripts Disponibles

### 🌟 Script Principal
- **`instalacion_completa_ubuntu.sh`** - Script unificado que hace todo automáticamente

### 🔧 Scripts Especializados
- **`InstalaciónGyD.sh`** - Solo certificados digitales Generalitat
- **`VPN-SAN-GVA.sh`** - Conexión VPN con verificaciones mejoradas
- **`post_instalacion_certificados.sh`** - Alternativo para Ubuntu 25.04+

## 📖 Documentación Completa

Ver **[README_SCRIPTS.md](README_SCRIPTS.md)** para:
- 📋 Guía detallada de uso
- 🔧 Solución de problemas
- 🛠️ Verificaciones post-instalación
- 📁 Archivos generados

## 🔧 Correcciones vs Versión Original

| ❌ Problema Original | ✅ Solución Implementada |
|---------------------|------------------------|
| PPAs incompatibles Ubuntu 25.04+ | Detecta versión, usa repos compatibles |
| Diálogos interactivos colgaban | `DEBIAN_FRONTEND=noninteractive` |
| SafeSign falla en Ubuntu nuevas | OpenSC como alternativa automática |
| Sin manejo de errores | `set -e` + verificaciones robustas |
| Scripts sin logging | Sistema completo con colores |
| No verificaba servicios | Verifica y arranca `pcscd` |

## 🖥️ Compatibilidad

| Ubuntu Version | Estado | Certificados | Notas |
|----------------|--------|--------------|-------|
| 22.04 LTS | ✅ Completa | SafeSign | Totalmente compatible |
| 24.04 LTS | ✅ Completa | SafeSign | Totalmente compatible |  
| 25.04+ | ✅ Completa | OpenSC | Alternativa automática |

## 📦 Software Instalado

**Sistema Base:**
- Firefox (Mozilla oficial)
- Flatpak + Flathub
- Certificados digitales (pcscd, OpenSC/SafeSign)
- OpenConnect VPN

**Aplicaciones:**
- GIMP, VLC, FileZilla
- Spotify, Zotero, OBS Studio
- LibreOffice, Timeshift

## 🆘 Soporte

### Issues Comunes

**Error "apt lock":**
```bash
sudo killall apt-get
sudo dpkg --configure -a
```

**Certificados no detectados:**
```bash
sudo systemctl restart pcscd
pcsc_scan
```

**VPN no conecta:**
```bash
p11tool --list-privkeys --login
ping vpn.san.gva.es
```

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama feature (`git checkout -b feature/mejora`)
3. Commit tus cambios (`git commit -am 'Añadir mejora'`)
4. Push a la rama (`git push origin feature/mejora`)
5. Abre un Pull Request

## 📄 Licencia

[MIT License](LICENSE) - Libre para uso personal y comercial.

## 🔗 Enlaces Útiles

- [SafeSign Drivers](https://www.a-et.com/products/smart-card-middleware/)
- [OpenSC Project](https://github.com/OpenSC/OpenSC)
- [Flathub](https://flathub.org/)
- [VPN Generalitat](https://vpn.san.gva.es)

---

⭐ **Si te resulta útil, dale una estrella al repo!**

*Mantenido por [@arkantu](https://github.com/arkantu) - Scripts depurados Nov 2024*