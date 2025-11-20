#!/bin/bash

# Script de Instalación Completa para Ubuntu 24.04/25.04
# Versión depurada y unificada
# Autor: Generado automáticamente
# Fecha: $(date +%Y-%m-%d)

set -e  # Salir en caso de error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Verificar si se ejecuta como root
if [[ $EUID -eq 0 ]]; then
   error "Este script no debe ejecutarse como root"
   exit 1
fi

# Verificar versión de Ubuntu
UBUNTU_VERSION=$(lsb_release -rs)
info "Detectada Ubuntu versión: $UBUNTU_VERSION"

log "=== INICIANDO INSTALACIÓN COMPLETA DEL SISTEMA ==="

# 1. ACTUALIZAR SISTEMA BASE
log "Paso 1: Actualizando sistema base..."
sudo apt update
sudo apt upgrade -y

# 2. INSTALAR HERRAMIENTAS BÁSICAS
log "Paso 2: Instalando herramientas básicas..."
sudo apt install -y \
    wget \
    curl \
    gdebi \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# 3. CONFIGURAR FIREFOX (ELIMINAR SNAP, INSTALAR APT)
log "Paso 3: Configurando Firefox desde Mozilla..."

# Eliminar Firefox Snap si existe
if snap list | grep -q firefox; then
    warning "Eliminando Firefox Snap..."
    sudo snap remove firefox
fi

# Configurar repositorio Mozilla
if [ ! -f /etc/apt/keyrings/packages.mozilla.org.asc ]; then
    log "Configurando repositorio Mozilla..."
    sudo install -d -m 0755 /etc/apt/keyrings
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
    
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
    
    echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla > /dev/null
fi

# 4. CONFIGURAR FLATPAK
log "Paso 4: Configurando Flatpak..."
sudo apt install -y flatpak gnome-software-plugin-flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# 5. INSTALAR SOFTWARE ESENCIAL
log "Paso 5: Instalando software esencial..."

# Usar DEBIAN_FRONTEND=noninteractive para evitar diálogos
export DEBIAN_FRONTEND=noninteractive

sudo apt update

# Instalar paquetes principales
sudo apt install -y \
    firefox \
    gimp \
    vlc \
    filezilla \
    cheese \
    synaptic \
    timeshift \
    openconnect \
    network-manager-openconnect \
    network-manager-openconnect-gnome

# Instalar herramientas de sistema (opcional según versión)
if dpkg --compare-versions "$UBUNTU_VERSION" "lt" "25.04"; then
    log "Instalando paquetes específicos para Ubuntu < 25.04..."
    sudo apt install -y tlp tlp-rdw gnome-tweak-tool || warning "Algunos paquetes no están disponibles"
else
    log "Instalando paquetes para Ubuntu 25.04+..."
    sudo apt install -y gnome-tweaks || warning "gnome-tweaks no disponible"
fi

# 6. CONFIGURAR CERTIFICADOS DIGITALES
log "Paso 6: Configurando certificados digitales..."

# Instalar dependencias base para certificados
sudo apt install -y pcscd libpcsclite1 libccid opensc-pkcs11 libpam-pkcs11 pcsc-tools

# Crear directorio para descargas si no existe
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Función para descargar archivos si no existen
download_if_missing() {
    local url="$1"
    local filename="$2"
    
    if [ ! -f "$filename" ]; then
        log "Descargando $filename..."
        wget -c "$url" -O "$filename" || warning "Error descargando $filename"
    else
        info "$filename ya existe, saltando descarga"
    fi
}

# Descargar certificados digitales
log "Descargando paquetes de certificados digitales..."
download_if_missing "https://certificaat.kpn.com/files/drivers/SafeSign/SafeSign%20IC%20Standard%20Linux%204.1.0.0-AET.000%20ub2204%20x86_64.deb" "SafeSign_IC_Standard_Linux_4.1.0.0-AET.000_ub2204_x86_64.deb"
download_if_missing "http://security.ubuntu.com/ubuntu/pool/universe/w/wxwidgets3.0/libwxgtk3.0-gtk3-0v5_3.0.5.1+dfsg-4_amd64.deb" "libwxgtk3.0-gtk3-0v5_3.0.5.1+dfsg-4_amd64.deb"
download_if_missing "http://security.ubuntu.com/ubuntu/pool/universe/w/wxwidgets3.0/libwxbase3.0-0v5_3.0.5.1+dfsg-4_amd64.deb" "libwxbase3.0-0v5_3.0.5.1+dfsg-4_amd64.deb"

# Intentar instalar certificados (puede fallar en Ubuntu 25.04+)
if dpkg --compare-versions "$UBUNTU_VERSION" "lt" "25.04"; then
    log "Intentando instalar certificados digitales..."
    if sudo dpkg -i libwxbase3.0-0v5_*.deb libwxgtk3.0-gtk3-0v5_*.deb SafeSign_IC_*.deb 2>/dev/null; then
        log "Certificados digitales instalados correctamente"
    else
        warning "Error instalando certificados digitales. Esto es normal en Ubuntu 25.04+"
        warning "Los archivos están descargados para instalación manual futura"
    fi
else
    warning "Ubuntu 25.04+ detectada. Los certificados digitales requieren instalación manual."
    warning "Los archivos están disponibles en: $SCRIPT_DIR"
fi

# Configurar módulo SafeSign
log "Configurando módulo SafeSign..."
if [ ! -f /usr/share/p11-kit/modules/safesign.module ]; then
    echo 'module: /usr/lib/libaetpkss.so' | sudo tee /usr/share/p11-kit/modules/safesign.module > /dev/null
    log "Módulo SafeSign configurado"
fi

# 7. INSTALAR SOFTWARE ADICIONAL VIA FLATPAK
log "Paso 7: Instalando software adicional via Flatpak..."

install_flatpak() {
    local app_id="$1"
    local app_name="$2"
    
    if ! flatpak list | grep -q "$app_id"; then
        log "Instalando $app_name via Flatpak..."
        flatpak install -y flathub "$app_id" || warning "Error instalando $app_name"
    else
        info "$app_name ya está instalado"
    fi
}

# Lista de aplicaciones Flatpak recomendadas
install_flatpak "com.spotify.Client" "Spotify"
install_flatpak "org.zotero.Zotero" "Zotero"
install_flatpak "com.obsproject.Studio" "OBS Studio"
install_flatpak "org.libreoffice.LibreOffice" "LibreOffice"

# 8. CONFIGURACIONES DEL SISTEMA
log "Paso 8: Aplicando configuraciones del sistema..."

# Configurar dash-to-dock para minimizar al hacer clic
if command -v gsettings >/dev/null; then
    gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize' 2>/dev/null || warning "No se pudo configurar dash-to-dock"
fi

# Habilitar servicios importantes
sudo systemctl enable pcscd 2>/dev/null || warning "No se pudo habilitar pcscd"

# 9. LIMPIAR SISTEMA
log "Paso 9: Limpiando sistema..."
sudo apt autoremove -y
sudo apt autoclean

# 10. CREAR SCRIPT DE VPN (si no existe)
if [ ! -f "$SCRIPT_DIR/conectar_vpn_gva.sh" ]; then
    log "Creando script de VPN..."
    cat > "$SCRIPT_DIR/conectar_vpn_gva.sh" << 'EOF'
#!/bin/bash
# Script para conectar VPN SAN-GVA
# Requiere certificado digital instalado

echo "=== CONEXIÓN VPN GENERALITAT VALENCIANA ==="
echo "NOTA: Requiere certificado digital configurado"
echo ""

# Listar certificados disponibles
echo "Certificados disponibles:"
p11tool --list-privkeys --login pkcs11:manufacturer=A.E.T.%20Europe%20B.V. 2>/dev/null || {
    echo "ERROR: No se encontraron certificados digitales"
    echo "Instala primero tu certificado digital"
    exit 1
}

echo ""
echo "Iniciando conexión VPN..."
echo "Se abrirá una ventana de autenticación del certificado"

# Comando de conexión (ajustar según certificado específico)
sudo openconnect -c 'pkcs11:model=19C41B06010D0000;manufacturer=A.E.T.%20Europe%20B.V.;serial=027600260045FD17;token=ACCV;id=%F4%E7%DF%65%5C%DE%ED%63%DF%55%43%F1%35%AE%F4%28%69%2B%57%42;object=EPN1;type=private' https://vpn.san.gva.es --servercert pin-sha256:h3CPvG+irXtGO04d14zc9rh1aGuUFVt43uB7NPRosvI=
EOF
    chmod +x "$SCRIPT_DIR/conectar_vpn_gva.sh"
fi

# RESUMEN FINAL
log "=== INSTALACIÓN COMPLETADA ==="
echo ""
info "Software instalado:"
echo "  ✅ Firefox (Mozilla repository)"
echo "  ✅ GIMP, VLC, FileZilla"
echo "  ✅ Flatpak con Flathub"
echo "  ✅ Herramientas de certificados digitales"
echo "  ✅ Software adicional via Flatpak"
echo ""

if dpkg --compare-versions "$UBUNTU_VERSION" "ge" "25.04"; then
    warning "NOTA PARA UBUNTU 25.04+:"
    echo "  - Algunos certificados digitales requieren instalación manual"
    echo "  - Archivos descargados en: $SCRIPT_DIR"
fi

echo ""
info "Scripts disponibles:"
echo "  📄 $SCRIPT_DIR/conectar_vpn_gva.sh - Conectar VPN GVA"
echo ""

info "Comandos útiles post-instalación:"
echo "  flatpak update                    # Actualizar apps Flatpak"
echo "  sudo apt update && sudo apt upgrade # Actualizar sistema"
echo "  pcsc_scan                         # Verificar lector tarjetas"
echo ""

log "¡Instalación completada! Reinicia el sistema para aplicar todos los cambios."