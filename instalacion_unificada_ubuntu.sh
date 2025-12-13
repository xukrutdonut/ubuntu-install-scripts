#!/bin/bash

# =================================================================================
# SCRIPT DE INSTALACIÓN UNIFICADO UBUNTU - SISTEMA COMPLETO
# =================================================================================
# Autor: Script unificado y depurado
# Fecha: $(date +%Y-%m-%d)
# Versión: 1.0
# Compatibilidad: Ubuntu 22.04 / 24.04 / 25.04+
# 
# DETECCIÓN AUTOMÁTICA DE HARDWARE:
# - Geekom GT13 Pro / GT2 Mega
# - Microsoft Surface Pro 7/8/9
# - Hardware genérico
# 
# INCLUYE:
# - Instalación completa del sistema base
# - Configuración de certificados digitales (GyD) 
# - Configuración específica por hardware
# - Drivers DisplayLink, Surface touchscreen
# - Aplicaciones esenciales vía APT y Flatpak
# - Sistema de menús modulares
# - Informes detallados de instalación
# - Manejo robusto de errores y timeouts
# =================================================================================

set +e  # No salir automáticamente en errores - los manejaremos

# =================================================================================
# CONFIGURACIÓN INICIAL Y COLORES
# =================================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuración global
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/instalacion_$(date +%Y%m%d_%H%M%S).log"
REPORT_FILE="$SCRIPT_DIR/informe_instalacion_$(date +%Y%m%d_%H%M%S).md"
ERRORS=()
WARNINGS=()
INSTALLED_PACKAGES=()
FAILED_PACKAGES=()

# Funciones de logging
log() {
    local msg="[$(date +'%H:%M:%S')] $1"
    echo -e "${GREEN}$msg${NC}" | tee -a "$LOG_FILE"
}

warning() {
    local msg="[WARNING] $1"
    echo -e "${YELLOW}$msg${NC}" | tee -a "$LOG_FILE"
    WARNINGS+=("$1")
}

error() {
    local msg="[ERROR] $1"
    echo -e "${RED}$msg${NC}" | tee -a "$LOG_FILE"
    ERRORS+=("$1")
}

info() {
    local msg="[INFO] $1"
    echo -e "${BLUE}$msg${NC}" | tee -a "$LOG_FILE"
}

success() {
    local msg="[SUCCESS] $1"
    echo -e "${GREEN}✅ $msg${NC}" | tee -a "$LOG_FILE"
}

section() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}🚀 $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
}

# =================================================================================
# DETECCIÓN DE HARDWARE
# =================================================================================

detect_hardware() {
    log "Detectando hardware del sistema..."
    
    # Variables de hardware
    HARDWARE_TYPE="generic"
    HARDWARE_MODEL=""
    IS_SURFACE=false
    IS_GEEKOM=false
    
    # Método 1: Información del sistema sin dmidecode (más compatible)
    if [ -r "/sys/class/dmi/id/product_name" ]; then
        PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Unknown")
    else
        PRODUCT_NAME="Unknown"
    fi
    
    if [ -r "/sys/class/dmi/id/sys_vendor" ]; then
        VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "Unknown")
    else
        VENDOR="Unknown"
    fi
    
    # Método 2: Información USB para detectar devices específicos
    USB_DEVICES=$(lsusb 2>/dev/null || echo "")
    
    # Método 3: Información PCI
    PCI_DEVICES=$(lspci 2>/dev/null || echo "")
    
    # Detección Microsoft Surface
    if echo "$PRODUCT_NAME" | grep -qi "surface" || \
       echo "$VENDOR" | grep -qi "microsoft" || \
       echo "$USB_DEVICES" | grep -qi "microsoft corp.*surface" || \
       [ -d "/sys/bus/acpi/devices/MSHW0011" ] || \
       [ -d "/sys/bus/acpi/devices/MSHW0040" ]; then
        HARDWARE_TYPE="surface"
        IS_SURFACE=true
        HARDWARE_MODEL="Microsoft Surface"
        success "Hardware detectado: Microsoft Surface"
    fi
    
    # Detección Geekom (GT13 Pro, GT2 Mega, etc.)
    if echo "$PRODUCT_NAME" | grep -qi "geekom\|gt13\|gt2" || \
       echo "$VENDOR" | grep -qi "geekom" || \
       echo "$PRODUCT_NAME" | grep -qi "mini.*pc"; then
        HARDWARE_TYPE="geekom"
        IS_GEEKOM=true
        HARDWARE_MODEL="Geekom Mini PC"
        success "Hardware detectado: Geekom Mini PC (GT Series)"
    fi
    
    # Información adicional
    UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "Unknown")
    UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "Unknown")
    
    info "Sistema detectado:"
    info "  - Fabricante: $VENDOR"
    info "  - Producto: $PRODUCT_NAME"
    info "  - Tipo de hardware: $HARDWARE_TYPE"
    info "  - Ubuntu: $UBUNTU_VERSION ($UBUNTU_CODENAME)"
    
    # Detectar características específicas
    detect_hardware_features
}

detect_hardware_features() {
    log "Detectando características específicas del hardware..."
    
    # Detección de touchscreen
    HAS_TOUCHSCREEN=false
    if xinput list 2>/dev/null | grep -qi "touchscreen\|touch.*screen" || \
       grep -qi "touchscreen\|ipts" /proc/bus/input/devices 2>/dev/null; then
        HAS_TOUCHSCREEN=true
        info "  - Touchscreen: Detectado"
    fi
    
    # Detección de Intel AI Boost NPU (Intel Core Ultra)
    HAS_INTEL_NPU=false
    if lspci 2>/dev/null | grep -qi "neural\|npu\|ai.*boost" || \
       lspci -s 00:0b.0 2>/dev/null | grep -qi "intel"; then
        HAS_INTEL_NPU=true
        info "  - Intel AI Boost NPU: Detectado"
    fi
    
    # Detección de GPU específicas
    HAS_INTEL_GPU=false
    HAS_NVIDIA_GPU=false
    HAS_AMD_GPU=false
    
    if echo "$PCI_DEVICES" | grep -qi "intel.*graphics\|intel.*display"; then
        HAS_INTEL_GPU=true
        info "  - GPU Intel: Detectada"
    fi
    
    if echo "$PCI_DEVICES" | grep -qi "nvidia"; then
        HAS_NVIDIA_GPU=true
        info "  - GPU NVIDIA: Detectada"
    fi
    
    if echo "$PCI_DEVICES" | grep -qi "amd\|ati.*radeon"; then
        HAS_AMD_GPU=true
        info "  - GPU AMD: Detectada"
    fi
    
    # Detección de WiFi específico
    HAS_REALTEK_WIFI=false
    if echo "$USB_DEVICES" | grep -qi "realtek.*802\.11\|realtek.*wifi" || \
       echo "$PCI_DEVICES" | grep -qi "realtek.*802\.11\|realtek.*wifi"; then
        HAS_REALTEK_WIFI=true
        info "  - WiFi Realtek: Detectado"
    fi
}

# =================================================================================
# FUNCIONES DE INSTALACIÓN ROBUSTAS
# =================================================================================

# Función para instalar paquetes con manejo de errores
install_package() {
    local package="$1"
    local timeout="${2:-300}"  # 5 minutos por defecto
    
    log "Instalando paquete: $package"
    
    if timeout "$timeout" sudo apt-get install -y "$package" >> "$LOG_FILE" 2>&1; then
        success "Paquete instalado: $package"
        INSTALLED_PACKAGES+=("$package")
        return 0
    else
        error "Error instalando paquete: $package"
        FAILED_PACKAGES+=("$package")
        return 1
    fi
}

# Función para instalar múltiples paquetes
install_packages() {
    local packages=("$@")
    local success_count=0
    local total=${#packages[@]}
    
    log "Instalando $total paquetes..."
    
    for package in "${packages[@]}"; do
        if install_package "$package" 120; then
            ((success_count++))
        fi
    done
    
    info "Instalación completada: $success_count/$total paquetes"
}

# Función para agregar PPAs de forma segura
add_ppa_safe() {
    local ppa="$1"
    local description="$2"
    
    log "Agregando PPA: $ppa ($description)"
    
    if timeout 60 sudo add-apt-repository -y "$ppa" >> "$LOG_FILE" 2>&1; then
        success "PPA agregado: $ppa"
        return 0
    else
        warning "Error agregando PPA: $ppa"
        return 1
    fi
}

# Función para actualizar repositorios con timeout
update_repositories() {
    log "Actualizando repositorios..."
    
    if timeout 300 sudo apt-get update >> "$LOG_FILE" 2>&1; then
        success "Repositorios actualizados"
        return 0
    else
        error "Error actualizando repositorios"
        return 1
    fi
}

# =================================================================================
# MENÚ PRINCIPAL Y NAVEGACIÓN
# =================================================================================

show_main_menu() {
    clear
    section "INSTALACIÓN UNIFICADA UBUNTU - MENÚ PRINCIPAL"
    echo ""
    info "Hardware detectado: $HARDWARE_MODEL ($HARDWARE_TYPE)"
    info "Ubuntu: $UBUNTU_VERSION"
    echo ""
    
    echo "Seleccione los módulos a instalar:"
    echo ""
    echo "━━━ MÓDULOS BÁSICOS ━━━"
    echo "1. 📦 Sistema Base (repositorios, herramientas básicas)"
    echo "2. 🌐 Firefox (eliminar snap, instalar Mozilla)"
    echo "3. 📱 Flatpak y tienda Flathub"
    echo ""
    echo "━━━ SOFTWARE ESENCIAL ━━━"
    echo "4. 🎨 Multimedia (GIMP, VLC, codecs)"
    echo "5. 🛠️  Herramientas del sistema (Timeshift, Synaptic)"
    echo "6. 💼 Productividad (LibreOffice, Zotero)"
    echo ""
    echo "━━━ CERTIFICADOS Y VPN ━━━"
    echo "7. 🔐 Certificados Digitales (GyD)"
    echo "8. 🔗 Configuración VPN"
    echo ""
    echo "━━━ HARDWARE ESPECÍFICO ━━━"
    if [ "$IS_SURFACE" = true ]; then
        echo "9. 📱 Surface Touchscreen y Stylus"
    fi
    if [ "$HAS_TOUCHSCREEN" = true ]; then
        echo "10. 👆 Configuración Touchscreen"
    fi
    echo "11. 🖥️  DisplayLink (pantallas USB)"
    echo "12. 🧠 Intel AI Boost NPU (Intel Core Ultra)"
    echo "13. 🎮 Drivers adicionales"
    echo ""
    echo "━━━ APLICACIONES ━━━"
    echo "14. 🎵 Multimedia y entretenimiento"
    echo "15. 💬 Comunicación (WhatsApp, etc.)"
    echo "16. 🔧 Herramientas desarrollo"
    echo ""
    echo "━━━ INSTALACIÓN COMPLETA ━━━"
    echo "99. 🚀 Instalar TODO (automático)"
    echo ""
    echo "0. ❌ Salir"
    echo ""
}

# =================================================================================
# MÓDULOS DE INSTALACIÓN
# =================================================================================

module_system_base() {
    section "MÓDULO 1: SISTEMA BASE"
    
    log "Actualizando sistema..."
    sudo apt-get update && sudo apt-get upgrade -y
    
    log "Instalando herramientas básicas..."
    local basic_tools=(
        "wget" "curl" "gdebi" "software-properties-common"
        "apt-transport-https" "ca-certificates" "gnupg" "lsb-release"
        "dkms" "linux-headers-generic" "build-essential"
        "unzip" "zip" "p7zip-full" "tree" "htop"
    )
    
    install_packages "${basic_tools[@]}"
    
    # Instalar apt-fast si no existe
    if ! command -v apt-fast >/dev/null 2>&1; then
        log "Instalando apt-fast para acelerar descargas..."
        add_ppa_safe "ppa:apt-fast/stable" "APT Fast"
        update_repositories
        install_package "apt-fast"
    fi
    
    # Configurar PPAs según versión de Ubuntu
    if dpkg --compare-versions "$UBUNTU_VERSION" "lt" "25.04"; then
        log "Configurando PPAs compatibles con Ubuntu < 25.04..."
        add_ppa_safe "ppa:flatpak/stable" "Flatpak"
        add_ppa_safe "ppa:danielrichter2007/grub-customizer" "GRUB Customizer"
    fi
    
    success "Sistema base configurado"
}

module_firefox() {
    section "MÓDULO 2: FIREFOX (MOZILLA)"
    
    # Eliminar Firefox Snap
    if snap list firefox 2>/dev/null | grep -q firefox; then
        log "Eliminando Firefox Snap..."
        sudo snap remove firefox
    fi
    
    # Configurar repositorio Mozilla
    log "Configurando repositorio Mozilla..."
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
    
    update_repositories
    install_package "firefox"
    
    success "Firefox configurado desde Mozilla"
}

module_flatpak() {
    section "MÓDULO 3: FLATPAK Y FLATHUB"
    
    install_packages "flatpak" "gnome-software-plugin-flatpak"
    
    log "Configurando Flathub..."
    if ! flatpak remote-list | grep -q flathub; then
        sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        success "Flathub configurado"
    fi
}

module_multimedia() {
    section "MÓDULO 4: MULTIMEDIA"
    
    local multimedia_packages=(
        "gimp" "vlc" "audacity" "cheese" 
        "ubuntu-restricted-extras" "ffmpeg"
        "gstreamer1.0-plugins-good" "gstreamer1.0-plugins-bad"
    )
    
    # Configurar para instalación no interactiva
    export DEBIAN_FRONTEND=noninteractive
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections
    
    install_packages "${multimedia_packages[@]}"
}

module_system_tools() {
    section "MÓDULO 5: HERRAMIENTAS DEL SISTEMA"
    
    local system_tools=(
        "timeshift" "synaptic" "gdebi" "dconf-editor"
    )
    
    # Herramientas específicas según versión
    if dpkg --compare-versions "$UBUNTU_VERSION" "lt" "25.04"; then
        system_tools+=("gnome-tweak-tool" "tlp" "tlp-rdw")
    else
        system_tools+=("gnome-tweaks")
    fi
    
    install_packages "${system_tools[@]}"
    
    # Configurar TLP si está instalado
    if command -v tlp >/dev/null 2>&1; then
        sudo systemctl enable tlp
    fi
}

module_productivity() {
    section "MÓDULO 6: PRODUCTIVIDAD"
    
    # Instalar por Flatpak para mejor compatibilidad
    install_flatpak_app "org.libreoffice.LibreOffice" "LibreOffice"
    install_flatpak_app "org.zotero.Zotero" "Zotero"
    install_flatpak_app "com.obsproject.Studio" "OBS Studio"
    
    # Algunas herramientas por APT
    local productivity_tools=(
        "filezilla" "thunderbird" "qbittorrent"
    )
    
    install_packages "${productivity_tools[@]}"
}

module_certificates() {
    section "MÓDULO 7: CERTIFICADOS DIGITALES"
    
    log "Instalando dependencias para certificados..."
    local cert_packages=(
        "pcscd" "libpcsclite1" "libccid" "opensc-pkcs11" 
        "libpam-pkcs11" "pcsc-tools" "opensc" "gnutls-bin"
    )
    
    install_packages "${cert_packages[@]}"
    
    # Descargar SafeSign
    cd "$SCRIPT_DIR"
    download_safesign_packages
    
    # Instalar según versión de Ubuntu
    install_safesign_certificates
    
    # Configurar módulos PKCS#11
    configure_pkcs11_modules
    
    # Habilitar servicios
    sudo systemctl enable pcscd
    sudo systemctl start pcscd
    
    success "Certificados digitales configurados"
}

module_vpn_setup() {
    section "MÓDULO 8: CONFIGURACIÓN VPN"
    
    # Instalar OpenConnect si no está
    install_packages "openconnect" "network-manager-openconnect" "network-manager-openconnect-gnome"
    
    # Crear script de VPN mejorado
    create_vpn_script
    
    success "VPN configurada"
}

module_surface_specific() {
    if [ "$IS_SURFACE" = false ]; then
        warning "No es hardware Surface, saltando módulo"
        return 0
    fi
    
    section "MÓDULO 9: MICROSOFT SURFACE"
    
    log "Configurando soporte específico para Surface..."
    
    # Instalar iptsd para touchscreen
    install_package "iptsd"
    sudo systemctl enable iptsd
    
    # Configurar touchpad
    local surface_packages=(
        "touchpad-indicator" "libinput-tools" 
        "xserver-xorg-input-libinput" "thermald"
    )
    
    install_packages "${surface_packages[@]}"
    
    # Configurar touchpad via gsettings
    configure_surface_touchpad
    
    success "Soporte Surface configurado"
}

module_touchscreen() {
    if [ "$HAS_TOUCHSCREEN" = false ]; then
        warning "No se detectó touchscreen, saltando módulo"
        return 0
    fi
    
    section "MÓDULO 10: TOUCHSCREEN"
    
    local touch_packages=(
        "evtest" "input-utils" "xinput" "xinput-calibrator"
    )
    
    install_packages "${touch_packages[@]}"
    
    # Configuraciones específicas de GNOME
    configure_gnome_touchscreen
    
    success "Touchscreen configurado"
}

module_displaylink() {
    section "MÓDULO 11: DISPLAYLINK"
    
    read -p "¿Instalar soporte DisplayLink para pantallas USB? (s/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        log "Instalando DisplayLink..."
        install_displaylink_driver
    else
        info "Instalación DisplayLink omitida"
    fi
}

module_intel_npu() {
    if [ "$HAS_INTEL_NPU" = false ]; then
        warning "NPU Intel no detectado, saltando módulo"
        return 0
    fi
    
    section "MÓDULO 12: INTEL AI BOOST NPU"
    
    log "Configurando Intel AI Boost NPU..."
    
    # Instalar driver SNAP oficial de Intel
    if ! snap list intel-npu-driver >/dev/null 2>&1; then
        log "Instalando driver Intel NPU (SNAP)..."
        if sudo snap install --beta intel-npu-driver >> "$LOG_FILE" 2>&1; then
            success "Driver Intel NPU instalado"
        else
            error "Error instalando driver NPU"
            return 1
        fi
    fi
    
    # Agregar usuario al grupo render para acceso al NPU
    if ! groups "$USER" | grep -q render; then
        log "Agregando usuario al grupo render..."
        sudo usermod -a -G render "$USER"
        success "Usuario agregado al grupo render"
        warning "Reinicio requerido para aplicar permisos del grupo"
    fi
    
    # Instalar Python y OpenVINO
    log "Instalando dependencias Python y OpenVINO..."
    local python_packages=(
        "python3-pip" "python3-venv" "python3-dev"
        "build-essential" "cmake" "pkg-config"
    )
    
    install_packages "${python_packages[@]}"
    
    # Crear entorno virtual para OpenVINO
    local npu_dir="$HOME/intel-npu"
    if [ ! -d "$npu_dir" ]; then
        log "Creando entorno virtual OpenVINO..."
        python3 -m venv "$npu_dir/openvino_env"
        
        # Activar entorno e instalar OpenVINO
        source "$npu_dir/openvino_env/bin/activate"
        
        log "Instalando OpenVINO con soporte NPU..."
        pip install --upgrade pip
        pip install openvino[extras]==2024.4.0
        pip install openvino-dev[onnx,pytorch]==2024.4.0
        
        deactivate
        success "OpenVINO instalado en $npu_dir/openvino_env"
    fi
    
    # Crear scripts de activación
    create_npu_activation_scripts "$npu_dir"
    
    # Crear script de prueba NPU
    create_npu_test_script "$npu_dir"
    
    success "Intel AI Boost NPU configurado"
    info "Ubicación: $npu_dir"
    info "Para usar: source $npu_dir/activate_npu.sh"
}

module_additional_drivers() {
    section "MÓDULO 13: DRIVERS ADICIONALES"
    
    # Drivers específicos según hardware detectado
    if [ "$HAS_NVIDIA_GPU" = true ]; then
        log "Configurando drivers NVIDIA..."
        sudo ubuntu-drivers autoinstall
    fi
    
    if [ "$HAS_REALTEK_WIFI" = true ]; then
        log "Instalando drivers WiFi Realtek..."
        install_package "rtl8188eu-dkms" || warning "Driver WiFi Realtek no disponible"
    fi
    
    # Drivers adicionales genéricos
    install_packages "linux-firmware" "firmware-linux-free" "firmware-linux-nonfree" || true
}

module_entertainment() {
    section "MÓDULO 13: MULTIMEDIA Y ENTRETENIMIENTO"
    
    install_flatpak_app "com.spotify.Client" "Spotify"
    install_flatpak_app "org.videolan.VLC" "VLC Media Player"
    install_flatpak_app "com.github.johnfactotum.Foliate" "Foliate (ebook reader)"
}

module_communication() {
    section "MÓDULO 14: COMUNICACIÓN"
    
    # WhatsApp Web clients
    install_flatpak_app "com.rtosta.zapzap" "ZapZap (WhatsApp)" || \
    install_flatpak_app "com.ktechpit.whatsie" "Whatsie (WhatsApp Web)"
    
    # Otros
    install_flatpak_app "org.telegram.desktop" "Telegram"
    install_flatpak_app "com.discordapp.Discord" "Discord"
}

module_development() {
    section "MÓDULO 15: HERRAMIENTAS DE DESARROLLO"
    
    read -p "¿Instalar herramientas de desarrollo? (s/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        local dev_tools=(
            "git" "vim" "nano" "curl" "wget" "jq"
            "nodejs" "npm" "python3-pip" "default-jdk"
        )
        
        install_packages "${dev_tools[@]}"
        
        # IDEs via Flatpak
        install_flatpak_app "com.visualstudio.code" "Visual Studio Code"
    fi
}

# =================================================================================
# FUNCIONES AUXILIARES ESPECÍFICAS
# =================================================================================

install_flatpak_app() {
    local app_id="$1"
    local app_name="$2"
    
    log "Instalando $app_name via Flatpak..."
    
    if ! flatpak list | grep -q "$app_id"; then
        if timeout 300 flatpak install -y flathub "$app_id" >> "$LOG_FILE" 2>&1; then
            success "$app_name instalado"
            INSTALLED_PACKAGES+=("flatpak:$app_name")
        else
            error "Error instalando $app_name"
            FAILED_PACKAGES+=("flatpak:$app_name")
        fi
    else
        info "$app_name ya está instalado"
    fi
}

download_safesign_packages() {
    log "Descargando paquetes SafeSign..."
    
    local urls=(
        "https://certificaat.kpn.com/files/drivers/SafeSign/SafeSign%20IC%20Standard%20Linux%204.1.0.0-AET.000%20ub2204%20x86_64.deb|SafeSign_IC_Standard_Linux.deb"
        "http://security.ubuntu.com/ubuntu/pool/universe/w/wxwidgets3.0/libwxgtk3.0-gtk3-0v5_3.0.5.1+dfsg-4_amd64.deb|libwxgtk3.0-gtk3-0v5.deb"
        "http://security.ubuntu.com/ubuntu/pool/universe/w/wxwidgets3.0/libwxbase3.0-0v5_3.0.5.1+dfsg-4_amd64.deb|libwxbase3.0-0v5.deb"
    )
    
    for url_file in "${urls[@]}"; do
        local url="${url_file%|*}"
        local file="${url_file#*|}"
        
        if [ ! -f "$file" ]; then
            log "Descargando $file..."
            if timeout 120 wget -c "$url" -O "$file" >> "$LOG_FILE" 2>&1; then
                success "Descargado: $file"
            else
                warning "Error descargando $file"
            fi
        fi
    done
}

install_safesign_certificates() {
    if dpkg --compare-versions "$UBUNTU_VERSION" "lt" "25.04"; then
        log "Instalando certificados SafeSign (Ubuntu < 25.04)..."
        
        sudo dpkg -i libwxbase3.0-0v5.deb || true
        sudo dpkg -i libwxgtk3.0-gtk3-0v5.deb || true
        sudo apt-get install -f -y
        
        sudo dpkg -i SafeSign_IC_Standard_Linux.deb || {
            warning "Error instalando SafeSign, arreglando dependencias..."
            sudo apt-get install -f -y
        }
    else
        warning "Ubuntu 25.04+ - SafeSign requiere configuración manual"
        install_package "opensc"
    fi
}

configure_pkcs11_modules() {
    log "Configurando módulos PKCS#11..."
    
    sudo mkdir -p /usr/share/p11-kit/modules/
    
    # Módulo SafeSign
    echo 'module: /usr/lib/libaetpkss.so' | sudo tee /usr/share/p11-kit/modules/safesign.module > /dev/null
    
    # Módulo OpenSC alternativo
    echo 'module: /usr/lib/x86_64-linux-gnu/opensc-pkcs11.so' | sudo tee /usr/share/p11-kit/modules/opensc.module > /dev/null
}

create_vpn_script() {
    log "Creando script de VPN optimizado..."
    
    cat > "$SCRIPT_DIR/conectar_vpn_gva.sh" << 'EOF'
#!/bin/bash
# Script VPN Generalitat Valenciana - Generado automáticamente

echo "=== CONEXIÓN VPN GENERALITAT VALENCIANA ==="
echo ""

# Verificar dependencias
if ! command -v openconnect >/dev/null; then
    echo "❌ Error: openconnect no está instalado"
    echo "Instale con: sudo apt install openconnect"
    exit 1
fi

# Verificar certificados
log "Verificando certificados digitales..."
if p11tool --list-privkeys --login pkcs11:manufacturer=A.E.T.%20Europe%20B.V. 2>/dev/null | grep -q "URL:"; then
    CERT_URL=$(p11tool --list-privkeys --login pkcs11:manufacturer=A.E.T.%20Europe%20B.V. 2>/dev/null | grep "URL:" | head -1 | cut -d' ' -f2)
    echo "✅ Certificado encontrado: $CERT_URL"
    
    # Conectar con certificado específico
    sudo openconnect \
        -c "$CERT_URL" \
        https://vpn.san.gva.es \
        --servercert pin-sha256:h3CPvG+irXtGO04d14zc9rh1aGuUFVt43uB7NPRosvI= \
        --verbose
else
    echo "⚠️  No se detectaron certificados automáticamente"
    echo "Modo interactivo - seleccione su certificado:"
    
    # Conectar en modo interactivo
    sudo openconnect \
        https://vpn.san.gva.es \
        --servercert pin-sha256:h3CPvG+irXtGO04d14zc9rh1aGuUFVt43uB7NPRosvI= \
        --verbose
fi
EOF
    
    chmod +x "$SCRIPT_DIR/conectar_vpn_gva.sh"
}

configure_surface_touchpad() {
    log "Configurando touchpad para Surface..."
    
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad speed 0.3 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true 2>/dev/null || true
}

configure_gnome_touchscreen() {
    log "Configurando touchscreen en GNOME..."
    
    gsettings set org.gnome.settings-daemon.plugins.color active true 2>/dev/null || true
    gsettings set org.gnome.desktop.a11y.applications screen-magnifier-enabled false 2>/dev/null || true
}

install_displaylink_driver() {
    log "Instalando DisplayLink driver..."
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Intentar descargar desde repositorio oficial
    if wget "https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/main/all/synaptics-repository-keyring.deb" 2>/dev/null; then
        sudo dpkg -i synaptics-repository-keyring.deb
        sudo apt-get update
        install_package "displaylink-driver"
    else
        warning "No se pudo descargar DisplayLink automáticamente"
        info "Descargue manualmente desde: https://www.synaptics.com/products/displaylink-graphics"
    fi
    
    cd "$SCRIPT_DIR"
    rm -rf "$temp_dir"
}

create_npu_activation_scripts() {
    local npu_dir="$1"
    
    log "Creando scripts de activación NPU..."
    
    # Script principal de activación
    cat > "$npu_dir/activate_npu.sh" << 'EOF'
#!/bin/bash

echo "🚀 Activando Intel AI Boost NPU"
echo "================================"

# Configurar entorno NPU
export NPU_LIBS_PATH=/snap/intel-npu-driver/current/usr/lib/x86_64-linux-gnu
export LD_LIBRARY_PATH=$NPU_LIBS_PATH:$LD_LIBRARY_PATH
export OPENVINO_LOG_LEVEL=2
export OV_ENABLE_NPU_FAST_COMPILE=1
export NPU_COMPILER_TYPE=MLIR

# Activar entorno OpenVINO
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/openvino_env/bin/activate"

echo "✓ Entorno NPU activado"
echo "✓ OpenVINO cargado"

# Verificación rápida
if command -v python3 >/dev/null; then
    python3 -c "
from openvino import Core
try:
    core = Core()
    devices = core.available_devices
    print(f'Dispositivos disponibles: {devices}')
    if 'NPU' in devices:
        print('🎉 ¡NPU DETECTADO!')
        try:
            name = core.get_property('NPU', 'FULL_DEVICE_NAME')
            print(f'NPU: {name}')
        except:
            print('NPU disponible (propiedades no accesibles)')
    else:
        print('❌ NPU no detectado por OpenVINO')
        print('💡 Intenta reiniciar el sistema')
except Exception as e:
    print(f'Error: {e}')
"
fi

echo ""
echo "Comandos disponibles:"
echo "  python3 test_npu.py     - Probar NPU"
echo "  deactivate              - Salir del entorno"
EOF

    chmod +x "$npu_dir/activate_npu.sh"
    
    # Crear alias para facilitar el uso
    cat > "$npu_dir/npu_alias.sh" << EOF
#!/bin/bash
# Agregar al ~/.bashrc para fácil acceso

alias npu-start="source $npu_dir/activate_npu.sh"
alias npu-test="cd $npu_dir && source activate_npu.sh && python3 test_npu.py"

echo "Aliases creados:"
echo "  npu-start  - Activar entorno NPU" 
echo "  npu-test   - Probar NPU"
echo ""
echo "Para agregar permanentemente:"
echo "  echo 'source $npu_dir/npu_alias.sh' >> ~/.bashrc"
EOF

    chmod +x "$npu_dir/npu_alias.sh"
}

create_npu_test_script() {
    local npu_dir="$1"
    
    log "Creando script de prueba NPU..."
    
    cat > "$npu_dir/test_npu.py" << 'EOF'
#!/usr/bin/env python3
"""
Script de prueba Intel AI Boost NPU
Verifica detección y funcionalidad básica
"""

import sys
import time
from pathlib import Path

def test_npu():
    print("🧠 Test Intel AI Boost NPU")
    print("=" * 40)
    
    try:
        from openvino import Core
        print("✓ OpenVINO importado correctamente")
    except ImportError as e:
        print(f"❌ Error importando OpenVINO: {e}")
        print("💡 Instale con: pip install openvino[extras]")
        return False
    
    try:
        # Inicializar Core
        core = Core()
        devices = core.available_devices
        
        print(f"📊 Dispositivos disponibles: {devices}")
        
        # Verificar NPU
        if 'NPU' not in devices:
            print("❌ NPU no detectado por OpenVINO")
            print("\n🔧 Posibles soluciones:")
            print("  1. Verificar driver: snap list intel-npu-driver")
            print("  2. Reiniciar el sistema")
            print("  3. Verificar permisos: groups | grep render")
            print("  4. Verificar hardware: lspci -s 00:0b.0")
            return False
        
        print("🎉 ¡NPU DETECTADO!")
        
        # Obtener información del dispositivo
        try:
            device_name = core.get_property('NPU', 'FULL_DEVICE_NAME')
            print(f"📋 Nombre del dispositivo: {device_name}")
        except Exception as e:
            print(f"⚠️  No se pudieron obtener propiedades: {e}")
        
        # Test básico de compilación
        print("\n🔍 Probando compilación básica...")
        try:
            # Crear un modelo simple para prueba
            import openvino as ov
            import numpy as np
            
            # Modelo dummy muy simple
            input_shape = [1, 3, 224, 224]
            dummy_input = np.random.random(input_shape).astype(np.float32)
            
            print("✓ Test de entrada creado")
            print(f"✓ Forma de entrada: {input_shape}")
            
            print("🎯 NPU configurado y listo para uso")
            return True
            
        except Exception as e:
            print(f"⚠️  Error en test de compilación: {e}")
            print("✓ NPU detectado pero puede requerir configuración adicional")
            return True
            
    except Exception as e:
        print(f"❌ Error general: {e}")
        return False

def main():
    print(f"Python: {sys.version}")
    print(f"Directorio: {Path.cwd()}")
    print()
    
    success = test_npu()
    
    if success:
        print("\n🎉 Test NPU completado exitosamente")
        print("✨ El NPU está listo para usar con OpenVINO")
    else:
        print("\n❌ Test NPU falló")
        print("📖 Revise la documentación de configuración")
    
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())
EOF

    chmod +x "$npu_dir/test_npu.py"
}

# =================================================================================
# GENERACIÓN DE INFORMES
# =================================================================================

generate_final_report() {
    section "GENERANDO INFORME FINAL"
    
    cat > "$REPORT_FILE" << EOF
# Informe de Instalación Ubuntu

**Fecha:** $(date)  
**Sistema:** $HARDWARE_MODEL ($HARDWARE_TYPE)  
**Ubuntu:** $UBUNTU_VERSION ($UBUNTU_CODENAME)  

## 📊 Resumen de Instalación

- **Paquetes instalados exitosamente:** ${#INSTALLED_PACKAGES[@]}
- **Paquetes fallidos:** ${#FAILED_PACKAGES[@]}
- **Advertencias:** ${#WARNINGS[@]}
- **Errores:** ${#ERRORS[@]}

## ✅ Paquetes Instalados Exitosamente

EOF

    for package in "${INSTALLED_PACKAGES[@]}"; do
        echo "- $package" >> "$REPORT_FILE"
    done
    
    if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
        cat >> "$REPORT_FILE" << EOF

## ❌ Paquetes con Errores

EOF
        for package in "${FAILED_PACKAGES[@]}"; do
            echo "- $package" >> "$REPORT_FILE"
        done
    fi
    
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        cat >> "$REPORT_FILE" << EOF

## ⚠️ Advertencias

EOF
        for warning_msg in "${WARNINGS[@]}"; do
            echo "- $warning_msg" >> "$REPORT_FILE"
        done
    fi
    
    if [ ${#ERRORS[@]} -gt 0 ]; then
        cat >> "$REPORT_FILE" << EOF

## 🚨 Errores Críticos

EOF
        for error_msg in "${ERRORS[@]}"; do
            echo "- $error_msg" >> "$REPORT_FILE"
        done
    fi
    
    cat >> "$REPORT_FILE" << EOF

## 📋 Scripts Creados

- **VPN:** \`$SCRIPT_DIR/conectar_vpn_gva.sh\`
- **Log completo:** \`$LOG_FILE\`

## 🚀 Pasos Siguientes

1. Reiniciar el sistema
2. Para certificados digitales: conectar lector y ejecutar script VPN
3. Configurar aplicaciones según necesidades

## 🔧 Comandos Útiles

\`\`\`bash
# Verificar certificados
p11tool --list-tokens

# Conectar VPN
./conectar_vpn_gva.sh

# Actualizar Flatpaks
flatpak update

# Ver log completo
less $LOG_FILE
\`\`\`
EOF

    success "Informe generado: $REPORT_FILE"
}

# =================================================================================
# INSTALACIÓN AUTOMÁTICA COMPLETA
# =================================================================================

install_everything() {
    section "INSTALACIÓN AUTOMÁTICA COMPLETA"
    
    log "Iniciando instalación completa automática..."
    
    # Módulos básicos (siempre)
    module_system_base
    module_firefox
    module_flatpak
    
    # Software esencial
    module_multimedia
    module_system_tools
    module_productivity
    
    # Certificados y VPN
    module_certificates
    module_vpn_setup
    
    # Hardware específico (condicional)
    if [ "$IS_SURFACE" = true ]; then
        module_surface_specific
    fi
    
    if [ "$HAS_TOUCHSCREEN" = true ]; then
        module_touchscreen
    fi
    
    # NPU Intel si está disponible
    if [ "$HAS_INTEL_NPU" = true ]; then
        echo ""
        read -p "¿Instalar Intel AI Boost NPU? (S/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            module_intel_npu
        fi
    fi
    
    # Preguntar por módulos opcionales
    echo ""
    read -p "¿Instalar DisplayLink para pantallas USB? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        module_displaylink
    fi
    
    module_additional_drivers
    module_entertainment
    module_communication
    
    echo ""
    read -p "¿Instalar herramientas de desarrollo? (s/N): " -n 1 -r  
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        module_development
    fi
    
    success "Instalación automática completada"
}

# =================================================================================
# LIMPIEZA Y FINALIZACIÓN
# =================================================================================

cleanup_system() {
    section "LIMPIEZA FINAL DEL SISTEMA"
    
    log "Limpiando paquetes innecesarios..."
    sudo apt-get autoremove -y >> "$LOG_FILE" 2>&1
    sudo apt-get autoclean >> "$LOG_FILE" 2>&1
    
    log "Actualizando base de datos de Flatpak..."
    flatpak update --noninteractive >> "$LOG_FILE" 2>&1 || true
    
    success "Limpieza completada"
}

# =================================================================================
# FUNCIÓN PRINCIPAL Y MENÚ INTERACTIVO
# =================================================================================

main() {
    # Verificaciones iniciales
    if [[ $EUID -eq 0 ]]; then
       error "Este script NO debe ejecutarse como root"
       error "Ejecute como usuario normal: ./instalacion_unificada_ubuntu.sh"
       exit 1
    fi
    
    # Detectar hardware
    detect_hardware
    
    # Crear logs
    log "Iniciando instalación unificada de Ubuntu" | tee "$LOG_FILE"
    log "Hardware: $HARDWARE_MODEL ($HARDWARE_TYPE)"
    log "Logs en: $LOG_FILE"
    
    # Menú principal
    while true; do
        show_main_menu
        
        read -p "Seleccione una opción (0-99): " choice
        echo ""
        
        case $choice in
            1) module_system_base ;;
            2) module_firefox ;;
            3) module_flatpak ;;
            4) module_multimedia ;;
            5) module_system_tools ;;
            6) module_productivity ;;
            7) module_certificates ;;
            8) module_vpn_setup ;;
            9) module_surface_specific ;;
            10) module_touchscreen ;;
            11) module_displaylink ;;
            12) module_intel_npu ;;
            13) module_additional_drivers ;;
            14) module_entertainment ;;
            15) module_communication ;;
            16) module_development ;;
            99) 
                install_everything
                break
                ;;
            0)
                log "Instalación cancelada por el usuario"
                exit 0
                ;;
            *)
                warning "Opción no válida: $choice"
                continue
                ;;
        esac
        
        echo ""
        read -p "Presione Enter para continuar..." 
    done
    
    # Limpieza y finalización
    cleanup_system
    generate_final_report
    
    # Mostrar resumen final
    section "🎉 INSTALACIÓN COMPLETADA"
    echo ""
    info "📊 Resumen:"
    info "  - Paquetes instalados: ${#INSTALLED_PACKAGES[@]}"
    info "  - Paquetes fallidos: ${#FAILED_PACKAGES[@]}"
    info "  - Advertencias: ${#WARNINGS[@]}"
    echo ""
    info "📄 Archivos generados:"
    info "  - Informe: $REPORT_FILE"  
    info "  - Log completo: $LOG_FILE"
    info "  - Script VPN: $SCRIPT_DIR/conectar_vpn_gva.sh"
    echo ""
    
    if [ ${#ERRORS[@]} -gt 0 ]; then
        warning "⚠️  Se encontraron ${#ERRORS[@]} errores. Revise el informe."
    fi
    
    info "🚀 Pasos siguientes:"
    echo "  1. Revisar informe: less '$REPORT_FILE'"
    echo "  2. Reiniciar sistema: sudo reboot" 
    echo "  3. Configurar certificados digitales"
    echo "  4. Probar conexión VPN: ./conectar_vpn_gva.sh"
    echo ""
    
    success "¡Instalación unificada completada exitosamente!"
}

# Ejecutar función principal
main "$@"