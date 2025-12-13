# Informe de Instalación Ubuntu

**Fecha:** Sat Dec 13 22:13:51 CET 2025  
**Sistema:** Geekom Mini PC (geekom)  
**Ubuntu:** 25.10 (questing)  

## 📊 Resumen de Instalación

- **Paquetes instalados exitosamente:** 54
- **Paquetes fallidos:** 2
- **Advertencias:** 1
- **Errores:** 3

## ✅ Paquetes Instalados Exitosamente

- wget
- curl
- gdebi
- software-properties-common
- apt-transport-https
- ca-certificates
- gnupg
- lsb-release
- dkms
- linux-headers-generic
- build-essential
- unzip
- zip
- p7zip-full
- tree
- htop
- firefox
- flatpak
- gnome-software-plugin-flatpak
- gimp
- vlc
- audacity
- cheese
- ubuntu-restricted-extras
- ffmpeg
- gstreamer1.0-plugins-good
- gstreamer1.0-plugins-bad
- timeshift
- synaptic
- gdebi
- dconf-editor
- gnome-tweaks
- filezilla
- thunderbird
- qbittorrent
- pcscd
- libpcsclite1
- libccid
- opensc-pkcs11
- libpam-pkcs11
- pcsc-tools
- opensc
- gnutls-bin
- opensc
- openconnect
- network-manager-openconnect
- network-manager-openconnect-gnome
- python3-pip
- python3-venv
- python3-dev
- build-essential
- cmake
- pkg-config
- linux-firmware

## ❌ Paquetes con Errores

- firmware-linux-free
- firmware-linux-nonfree

## ⚠️ Advertencias

- Ubuntu 25.04+ - SafeSign requiere configuración manual

## 🚨 Errores Críticos

- Error actualizando repositorios
- Error instalando paquete: firmware-linux-free
- Error instalando paquete: firmware-linux-nonfree

## 📋 Scripts Creados

- **VPN:** `/home/arkantu/ubuntu-install-scripts/conectar_vpn_gva.sh`
- **Log completo:** `/home/arkantu/ubuntu-install-scripts/instalacion_20251213_220642.log`

## 🚀 Pasos Siguientes

1. Reiniciar el sistema
2. Para certificados digitales: conectar lector y ejecutar script VPN
3. Configurar aplicaciones según necesidades

## 🔧 Comandos Útiles

```bash
# Verificar certificados
p11tool --list-tokens

# Conectar VPN
./conectar_vpn_gva.sh

# Actualizar Flatpaks
flatpak update

# Ver log completo
less /home/arkantu/ubuntu-install-scripts/instalacion_20251213_220642.log
```
