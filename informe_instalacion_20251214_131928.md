# Informe de Instalación Ubuntu

**Fecha:** dom 14 dic 2025 14:02:37 CET  
**Sistema:** Microsoft Surface (surface)  
**Ubuntu:** 25.10 (questing)  

## 📊 Resumen de Instalación

- **Paquetes instalados exitosamente:** 29
- **Paquetes fallidos:** 65
- **Advertencias:** 1
- **Errores:** 65

## ✅ Paquetes Instalados Exitosamente

- wget
- curl
- gdebi
- software-properties-common
- apt-transport-https
- ca-certificates
- lsb-release
- build-essential
- unzip
- zip
- p7zip-full
- tree
- htop
- firefox
- gnome-software-plugin-flatpak
- gimp
- audacity
- cheese
- ffmpeg
- timeshift
- synaptic
- gdebi
- gnome-tweaks
- flatpak:VLC Media Player
- flatpak:Foliate (ebook reader)
- flatpak:ZapZap (WhatsApp)
- flatpak:Telegram
- flatpak:Discord
- flatpak:Visual Studio Code

## ❌ Paquetes con Errores

- gnupg
- dkms
- linux-headers-generic
- flatpak
- vlc
- ubuntu-restricted-extras
- gstreamer1.0-plugins-good
- gstreamer1.0-plugins-bad
- dconf-editor
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
- iptsd
- touchpad-indicator
- libinput-tools
- xserver-xorg-input-libinput
- thermald
- evtest
- xinput
- bc
- xournalpp
- gromit-mpx
- krita
- mypaint
- inkscape
- xinput-calibrator
- evtest
- input-utils
- xinput
- xinput-calibrator
- iio-sensor-proxy
- inotify-tools
- bc
- linux-firmware
- firmware-linux-free
- firmware-linux-nonfree
- flatpak:Input Leap
- git
- vim
- nano
- curl
- wget
- jq
- nodejs
- npm
- python3-pip
- default-jdk
- @githubnext/github-copilot-cli
- docker-ce
- docker-ce-cli
- containerd.io
- docker-buildx-plugin
- docker-compose-plugin

## ⚠️ Advertencias

- Ubuntu 25.04+ - SafeSign requiere configuración manual

## 🚨 Errores Críticos

- Error instalando paquete: gnupg
- Error instalando paquete: dkms
- Error instalando paquete: linux-headers-generic
- Error instalando paquete: flatpak
- Error instalando paquete: vlc
- Error instalando paquete: ubuntu-restricted-extras
- Error instalando paquete: gstreamer1.0-plugins-good
- Error instalando paquete: gstreamer1.0-plugins-bad
- Error instalando paquete: dconf-editor
- Error instalando paquete: filezilla
- Error instalando paquete: thunderbird
- Error instalando paquete: qbittorrent
- Error instalando paquete: pcscd
- Error instalando paquete: libpcsclite1
- Error instalando paquete: libccid
- Error instalando paquete: opensc-pkcs11
- Error instalando paquete: libpam-pkcs11
- Error instalando paquete: pcsc-tools
- Error instalando paquete: opensc
- Error instalando paquete: gnutls-bin
- Error instalando paquete: opensc
- Error instalando paquete: openconnect
- Error instalando paquete: network-manager-openconnect
- Error instalando paquete: network-manager-openconnect-gnome
- Error instalando paquete: iptsd
- Error instalando paquete: touchpad-indicator
- Error instalando paquete: libinput-tools
- Error instalando paquete: xserver-xorg-input-libinput
- Error instalando paquete: thermald
- Error instalando paquete: evtest
- Error instalando paquete: xinput
- Error instalando paquete: bc
- Error instalando paquete: xournalpp
- Error instalando paquete: gromit-mpx
- Error instalando paquete: krita
- Error instalando paquete: mypaint
- Error instalando paquete: inkscape
- Error instalando paquete: xinput-calibrator
- Error instalando paquete: evtest
- Error instalando paquete: input-utils
- Error instalando paquete: xinput
- Error instalando paquete: xinput-calibrator
- Error instalando paquete: iio-sensor-proxy
- Error instalando paquete: inotify-tools
- Error instalando paquete: bc
- Error instalando paquete: linux-firmware
- Error instalando paquete: firmware-linux-free
- Error instalando paquete: firmware-linux-nonfree
- Error instalando Input Leap
- Error instalando paquete: git
- Error instalando paquete: vim
- Error instalando paquete: nano
- Error instalando paquete: curl
- Error instalando paquete: wget
- Error instalando paquete: jq
- Error instalando paquete: nodejs
- Error instalando paquete: npm
- Error instalando paquete: python3-pip
- Error instalando paquete: default-jdk
- Error instalando GitHub Copilot CLI
- Error instalando paquete: docker-ce
- Error instalando paquete: docker-ce-cli
- Error instalando paquete: containerd.io
- Error instalando paquete: docker-buildx-plugin
- Error instalando paquete: docker-compose-plugin

## 📋 Scripts Creados

- **VPN:** `/home/arkantu/ubuntu-install-scripts/conectar_vpn_gva.sh`
- **Touchscreen:** `/home/arkantu/ubuntu-install-scripts/configure_touchscreen.sh`
- **Surface Pen:** `/home/arkantu/ubuntu-install-scripts/configure_surface_pen.sh`
- **Surface Start:** `/home/arkantu/ubuntu-install-scripts/start_surface_pen.sh`
- **Tablet Mode:** `/home/arkantu/ubuntu-install-scripts/tablet_mode.sh`
- **Red:** `/home/arkantu/ubuntu-install-scripts/optimize_network.sh`
- **Input Leap:** `/home/arkantu/ubuntu-install-scripts/configure_input_leap.sh`
- **Log completo:** `/home/arkantu/ubuntu-install-scripts/instalacion_20251214_131928.log`

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

# Configurar touchscreen
./configure_touchscreen.sh sensitivity 7

# Surface Pen (solo Surface)
./start_surface_pen.sh
./configure_surface_pen.sh sensitivity 7

# Modo tablet Surface
./tablet_mode.sh auto

# Optimizar red
./optimize_network.sh

# Configurar Input Leap
./configure_input_leap.sh help

# Actualizar Flatpaks
flatpak update

# Ver log completo
less /home/arkantu/ubuntu-install-scripts/instalacion_20251214_131928.log
```
