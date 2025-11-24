#!/bin/bash

# ================================================================================================
# SCRIPT DE INSTALACIÓN UNIFICADO UBUNTU - ALBERTO
# ================================================================================================
# Autor: Alberto - Script unificado y depurado
# Fecha: 2024-11-24
# Versión: 3.0 UNIFICADA
# Compatibilidad: Ubuntu 22.04 / 24.04 / 25.04+
# 
# INCLUYE:
# - Instalación completa del sistema
# - Configuración de certificados digitales (GyD)
# - Post-instalación para Ubuntu 25.04+
# - Configuración de escritorio personalizada
# - Instalación DisplayLink para pantallas USB
# ================================================================================================

set -e  # Salir inmediatamente si hay un error

# ================================================================================================
# CONFIGURACIÓN INICIAL Y COLORES
# ================================================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funciones de logging
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

section() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🚀 $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ================================================================================================
# VERIFICACIONES INICIALES
# ================================================================================================

# Verificar que no se ejecute como root
if [[ $EUID -eq 0 ]]; then
   error "Este script NO debe ejecutarse como root (sin sudo)"
   error "Ejecutar como: ./instalacion_ubuntu_alberto.sh"
   exit 1
fi

# Obtener información del sistema
UBUNTU_VERSION=$(lsb_release -rs)
UBUNTU_CODENAME=$(lsb_release -cs)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

section "INSTALACIÓN UNIFICADA UBUNTU - ALBERTO"
info "Ubuntu versión: $UBUNTU_VERSION ($UBUNTU_CODENAME)"
info "Directorio: $SCRIPT_DIR"
echo ""

read -p "¿Continuar con la instalación completa? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log "Instalación cancelada por el usuario"
    exit 0
fi

# ================================================================================================
# PASO 1: ACTUALIZACIÓN DEL SISTEMA BASE
# ================================================================================================

section "PASO 1: ACTUALIZACIÓN DEL SISTEMA"

log "Actualizando lista de paquetes..."
sudo apt update

log "Actualizando sistema base..."
sudo apt upgrade -y

log "Instalando herramientas básicas esenciales..."
sudo apt install -y \
    wget \
    curl \
    gdebi \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    dkms \
    linux-headers-generic \
    build-essential

# ================================================================================================
# PASO 2: CONFIGURACIÓN DE REPOSITORIOS Y PPAs
# ================================================================================================

section "PASO 2: CONFIGURACIÓN DE REPOSITORIOS"

# Configurar PPAs solo si son compatibles con la versión de Ubuntu
if dpkg --compare-versions "$UBUNTU_VERSION" "lt" "25.04"; then
    log "Añadiendo PPAs compatibles con Ubuntu < 25.04..."
    
    # PPAs verificados para Ubuntu 22.04/24.04
    sudo add-apt-repository -y ppa:flatpak/stable || warning "PPA flatpak no disponible"
    sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer || warning "PPA grub-customizer no disponible" 
    sudo add-apt-repository -y ppa:oguzhaninan/stacer || warning "PPA stacer no disponible"
    
else
    warning "Ubuntu 25.04+ detectada - Saltando PPAs potencialmente incompatibles"
fi

# Configurar repositorio Mozilla para Firefox
log "Configurando repositorio Mozilla para Firefox..."
if [ ! -f /etc/apt/keyrings/packages.mozilla.org.asc ]; then
    sudo install -d -m 0755 /etc/apt/keyrings
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
    
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
    
    echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla > /dev/null
fi

sudo apt update

# ================================================================================================
# PASO 3: ELIMINACIÓN DE FIREFOX SNAP E INSTALACIÓN DESDE MOZILLA
# ================================================================================================

section "PASO 3: CONFIGURACIÓN DE FIREFOX"

# Eliminar Firefox Snap si existe
if snap list firefox 2>/dev/null | grep -q firefox; then
    warning "Eliminando Firefox Snap..."
    sudo snap remove firefox
fi

log "Instalando Firefox desde repositorio Mozilla..."
sudo apt install -y firefox

# ================================================================================================
# PASO 4: CONFIGURACIÓN DE FLATPAK
# ================================================================================================

section "PASO 4: CONFIGURACIÓN DE FLATPAK"

log "Instalando Flatpak y plugin GNOME Software..."
sudo apt install -y flatpak gnome-software-plugin-flatpak

log "Añadiendo repositorio Flathub..."
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# ================================================================================================
# PASO 5: INSTALACIÓN DE SOFTWARE ESENCIAL
# ================================================================================================

section "PASO 5: SOFTWARE ESENCIAL"

export DEBIAN_FRONTEND=noninteractive

log "Instalando aplicaciones principales..."
sudo apt install -y \
    gimp \
    vlc \
    filezilla \
    cheese \
    synaptic \
    timeshift \
    openconnect \
    network-manager-openconnect \
    network-manager-openconnect-gnome \
    libfuse2t64 \
    wine \
    virtualbox \
    gdebi

# Instalar paquetes específicos según versión
if dpkg --compare-versions "$UBUNTU_VERSION" "lt" "25.04"; then
    log "Instalando paquetes para Ubuntu < 25.04..."
    sudo apt install -y \
        tlp \
        tlp-rdw \
        gnome-tweak-tool \
        ubuntu-restricted-extras \
        grub-customizer \
        stacer || warning "Algunos paquetes opcionales no están disponibles"
else
    log "Instalando paquetes para Ubuntu 25.04+..."
    sudo apt install -y \
        gnome-tweaks \
        ubuntu-restricted-extras || warning "Algunos paquetes no están disponibles en 25.04+"
fi

# ================================================================================================
# PASO 6: CERTIFICADOS DIGITALES GENERALITAT VALENCIANA
# ================================================================================================

section "PASO 6: CERTIFICADOS DIGITALES (GyD)"

log "Instalando dependencias para certificados digitales..."
sudo apt install -y \
    pcscd \
    libpcsclite1 \
    libccid \
    opensc-pkcs11 \
    libpam-pkcs11 \
    pcsc-tools \
    opensc \
    gnutls-bin

# Función para descargar archivos
download_if_missing() {
    local url="$1"
    local filename="$2"
    
    if [ ! -f "$filename" ]; then
        log "Descargando $filename..."
        wget -c "$url" -O "$filename" || {
            warning "Error descargando $filename"
            return 1
        }
    else
        info "$filename ya existe"
    fi
}

# Descargar paquetes de certificados
cd "$SCRIPT_DIR"
log "Descargando paquetes SafeSign..."
download_if_missing "https://certificaat.kpn.com/files/drivers/SafeSign/SafeSign%20IC%20Standard%20Linux%204.1.0.0-AET.000%20ub2204%20x86_64.deb" "SafeSign_IC_Standard_Linux.deb"
download_if_missing "http://security.ubuntu.com/ubuntu/pool/universe/w/wxwidgets3.0/libwxgtk3.0-gtk3-0v5_3.0.5.1+dfsg-4_amd64.deb" "libwxgtk3.0-gtk3-0v5.deb"
download_if_missing "http://security.ubuntu.com/ubuntu/pool/universe/w/wxwidgets3.0/libwxbase3.0-0v5_3.0.5.1+dfsg-4_amd64.deb" "libwxbase3.0-0v5.deb"

# Instalación según versión de Ubuntu
if dpkg --compare-versions "$UBUNTU_VERSION" "lt" "25.04"; then
    log "Instalando certificados SafeSign (Ubuntu < 25.04)..."
    
    # Instalar dependencias
    sudo dpkg -i libwxbase3.0-0v5.deb || warning "Advertencias en libwxbase"
    sudo dpkg -i libwxgtk3.0-gtk3-0v5.deb || warning "Advertencias en libwxgtk" 
    sudo apt-get install -f -y  # Arreglar dependencias
    
    # Instalar SafeSign
    sudo dpkg -i SafeSign_IC_Standard_Linux.deb || {
        warning "Error instalando SafeSign, arreglando dependencias..."
        sudo apt-get install -f -y
    }
    
    log "✅ SafeSign instalado para Ubuntu $UBUNTU_VERSION"
    
else
    warning "Ubuntu 25.04+ detectada - Configuración alternativa"
    warning "SafeSign puede no ser compatible, usando OpenSC"
    
    # Configurar Firefox ESR como alternativa
    sudo apt install -y firefox-esr 2>/dev/null || warning "Firefox ESR no disponible"
    
    log "Configurando OpenSC como alternativa..."
fi

# Configurar módulos PKCS#11
log "Configurando módulos PKCS#11..."
sudo mkdir -p /usr/share/p11-kit/modules/

# Módulo SafeSign
echo 'module: /usr/lib/libaetpkss.so' | sudo tee /usr/share/p11-kit/modules/safesign.module > /dev/null

# Módulo OpenSC (alternativo)
echo 'module: /usr/lib/x86_64-linux-gnu/opensc-pkcs11.so' | sudo tee /usr/share/p11-kit/modules/opensc.module > /dev/null

# Habilitar servicios
sudo systemctl enable pcscd
sudo systemctl start pcscd

# ================================================================================================
# PASO 7: DISPLAYLINK PARA PANTALLAS USB
# ================================================================================================

section "PASO 7: DISPLAYLINK (PANTALLAS USB)"

read -p "¿Instalar soporte DisplayLink para pantallas USB? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    log "Instalando DisplayLink..."
    
    # Crear directorio temporal
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    log "Descargando repositorio Synaptics..."
    wget https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/main/all/synaptics-repository-keyring.deb || {
        warning "Error descargando keyring, usando método alternativo..."
        wget https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/main/all/displaylink-driver_1.9.1-A.159.181_all.deb
        sudo dpkg -i displaylink-driver_1.9.1-A.159.181_all.deb
    }
    
    if [ -f synaptics-repository-keyring.deb ]; then
        sudo dpkg -i synaptics-repository-keyring.deb
        sudo apt update
        sudo apt install -y displaylink-driver
    fi
    
    # Limpiar
    cd "$SCRIPT_DIR"
    rm -rf "$TEMP_DIR"
    
    log "✅ DisplayLink instalado - Requiere reinicio para funcionar"
else
    info "Saltando instalación DisplayLink"
fi

# ================================================================================================
# PASO 8: APLICACIONES FLATPAK
# ================================================================================================

section "PASO 8: APLICACIONES FLATPAK"

install_flatpak() {
    local app_id="$1"
    local app_name="$2"
    
    if ! flatpak list | grep -q "$app_id"; then
        log "Instalando $app_name..."
        flatpak install -y flathub "$app_id" || warning "Error instalando $app_name"
    else
        info "$app_name ya está instalado"
    fi
}

log "Instalando aplicaciones esenciales vía Flatpak..."
install_flatpak "com.spotify.Client" "Spotify"
install_flatpak "org.zotero.Zotero" "Zotero"  
install_flatpak "com.obsproject.Studio" "OBS Studio"
install_flatpak "org.libreoffice.LibreOffice" "LibreOffice"

# ================================================================================================
# PASO 9: CONFIGURACIONES DEL SISTEMA
# ================================================================================================

section "PASO 9: CONFIGURACIONES PERSONALIZADAS"

log "Aplicando configuraciones de escritorio..."

# Configurar dash-to-dock
if command -v gsettings >/dev/null; then
    gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize' 2>/dev/null || warning "No se pudo configurar dash-to-dock"
fi

# Configurar TLP (si está instalado)
if command -v tlp >/dev/null; then
    sudo systemctl enable tlp 2>/dev/null || warning "No se pudo habilitar TLP"
fi

# ================================================================================================
# PASO 10: SCRIPTS DE UTILIDAD
# ================================================================================================

section "PASO 10: CREACIÓN DE SCRIPTS AUXILIARES"

# Script de conexión VPN
log "Creando script de VPN Generalitat..."
cat > "$SCRIPT_DIR/conectar_vpn_gva.sh" << 'EOF'
#!/bin/bash
# Script VPN Generalitat Valenciana - Generado automáticamente

echo "=== CONEXIÓN VPN GENERALITAT VALENCIANA ==="
echo ""

# Verificar certificados
if ! p11tool --list-privkeys --login pkcs11:manufacturer=A.E.T.%20Europe%20B.V. 2>/dev/null | grep -q "URL:"; then
    echo "❌ ERROR: No se encontraron certificados digitales"
    echo ""
    echo "Soluciones:"
    echo "1. Conectar lector de tarjetas USB" 
    echo "2. Insertar certificado digital"
    echo "3. Verificar con: pcsc_scan"
    echo "4. Reiniciar servicio: sudo systemctl restart pcscd"
    exit 1
fi

echo "✅ Certificados encontrados"
echo "🚀 Iniciando conexión VPN..."

# Detectar certificado automáticamente
CERT_URL=$(p11tool --list-privkeys --login pkcs11:manufacturer=A.E.T.%20Europe%20B.V. 2>/dev/null | grep "URL:" | head -1 | cut -d' ' -f2)

if [ -n "$CERT_URL" ]; then
    sudo openconnect \
        -c "$CERT_URL" \
        https://vpn.san.gva.es \
        --servercert pin-sha256:h3CPvG+irXtGO04d14zc9rh1aGuUFVt43uB7NPRosvI= \
        --verbose
else
    echo "❌ No se pudo detectar el certificado automáticamente"
    echo "Usar: p11tool --list-privkeys --login"
fi
EOF

chmod +x "$SCRIPT_DIR/conectar_vpn_gva.sh"

# Script de verificación de certificados
log "Creando script de verificación..."
cat > "$SCRIPT_DIR/verificar_certificados.sh" << 'EOF'
#!/bin/bash
echo "=== VERIFICACIÓN DE CERTIFICADOS DIGITALES ==="
echo ""

echo "1. Estado del servicio pcscd:"
sudo systemctl status pcscd --no-pager -l || echo "   ❌ pcscd no está activo"
echo ""

echo "2. Lectores de tarjetas conectados:"
lsusb | grep -i -E "(smart|card|reader|aet)" || echo "   ❌ No se detectan lectores USB"
echo ""

echo "3. Escaneando lectores (5 segundos):"
timeout 5s pcsc_scan 2>/dev/null || echo "   ❌ No hay lectores activos"
echo ""

echo "4. Módulos PKCS#11 configurados:"
p11-kit list-modules 2>/dev/null || echo "   ❌ Error listando módulos"
echo ""

echo "5. Tokens disponibles:"
p11tool --list-tokens 2>/dev/null || echo "   ❌ No se detectan tokens"
echo ""

echo "COMANDOS ÚTILES:"
echo "• Reiniciar servicio: sudo systemctl restart pcscd"
echo "• Escanear lectores: pcsc_scan"  
echo "• Listar certificados: p11tool --list-privkeys --login"
echo "• Conectar VPN: ./conectar_vpn_gva.sh"
EOF

chmod +x "$SCRIPT_DIR/verificar_certificados.sh"

# ================================================================================================
# PASO 11: LIMPIEZA Y FINALIZACIÓN
# ================================================================================================

section "PASO 11: LIMPIEZA FINAL"

log "Limpiando sistema..."
sudo apt autoremove -y
sudo apt autoclean

# Actualizar base de datos de flatpak
flatpak update --noninteractive 2>/dev/null || warning "Error actualizando Flatpak"

# ================================================================================================
# RESUMEN FINAL
# ================================================================================================

section "🎉 INSTALACIÓN COMPLETADA EXITOSAMENTE"

echo ""
info "📦 SOFTWARE INSTALADO:"
echo "   ✅ Firefox (Mozilla oficial)"
echo "   ✅ GIMP, VLC, FileZilla, Timeshift"  
echo "   ✅ Flatpak + Flathub (Spotify, Zotero, OBS, LibreOffice)"
echo "   ✅ Herramientas certificados digitales"
echo "   ✅ OpenConnect VPN"
if dpkg -l displaylink-driver 2>/dev/null | grep -q displaylink; then
    echo "   ✅ DisplayLink (pantallas USB)"
fi
echo ""

info "📋 SCRIPTS CREADOS:"
echo "   📄 $SCRIPT_DIR/conectar_vpn_gva.sh"
echo "   📄 $SCRIPT_DIR/verificar_certificados.sh"
echo ""

info "🔧 CERTIFICADOS DIGITALES:"
if dpkg --compare-versions "$UBUNTU_VERSION" "ge" "25.04"; then
    warning "   Ubuntu 25.04+: Configuración manual requerida"
    echo "   📋 Ejecutar: ./verificar_certificados.sh"
    echo "   🌐 En Firefox: Preferencias > Certificados > Dispositivos de Seguridad"
    echo "   📁 Cargar: /usr/lib/x86_64-linux-gnu/opensc-pkcs11.so"
else
    echo "   ✅ SafeSign configurado para Ubuntu $UBUNTU_VERSION"
    echo "   📋 Verificar con: ./verificar_certificados.sh"
fi
echo ""

info "📁 ARCHIVOS DESCARGADOS EN: $SCRIPT_DIR"
echo ""

info "🚀 PASOS SIGUIENTES:"
echo "   1. Reiniciar el sistema: sudo reboot"
echo "   2. Conectar lector de tarjetas USB"
echo "   3. Ejecutar: ./verificar_certificados.sh" 
echo "   4. Para VPN: ./conectar_vpn_gva.sh"
echo ""

warning "⚠️  IMPORTANTE: Reinicia el sistema para aplicar todos los cambios"
echo ""

log "Script unificado completado - Ubuntu personalizado por Alberto ✨"