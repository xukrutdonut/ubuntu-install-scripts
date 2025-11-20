
#!/bin/bash

# Script depurado para instalación de certificados digitales
# Compatible con Ubuntu 22.04, 24.04 y 25.04

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

log "=== INSTALACIÓN CERTIFICADOS DIGITALES GENERALITAT ==="

# Verificar versión Ubuntu
UBUNTU_VERSION=$(lsb_release -rs)
log "Ubuntu versión detectada: $UBUNTU_VERSION"

# Instalar dependencias base
log "Instalando dependencias base..."
sudo apt-get update
sudo apt-get install -y pcscd libpcsclite1 libccid opensc-pkcs11 libpam-pkcs11 wget

# Función para descargar si no existe
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
        log "$filename ya existe"
    fi
}

# Descargar archivos necesarios
log "Descargando paquetes SafeSign..."
download_if_missing "https://certificaat.kpn.com/files/drivers/SafeSign/SafeSign%20IC%20Standard%20Linux%204.1.0.0-AET.000%20ub2204%20x86_64.deb" "SafeSign_IC_Standard_Linux.deb"
download_if_missing "http://security.ubuntu.com/ubuntu/pool/universe/w/wxwidgets3.0/libwxgtk3.0-gtk3-0v5_3.0.5.1+dfsg-4_amd64.deb" "libwxgtk3.0-gtk3-0v5.deb"
download_if_missing "http://security.ubuntu.com/ubuntu/pool/universe/w/wxwidgets3.0/libwxbase3.0-0v5_3.0.5.1+dfsg-4_amd64.deb" "libwxbase3.0-0v5.deb"

# Intentar instalar según versión de Ubuntu
if dpkg --compare-versions "$UBUNTU_VERSION" "lt" "25.04"; then
    log "Instalando paquetes SafeSign (Ubuntu < 25.04)..."
    
    # Instalar dependencias primero
    sudo dpkg -i libwxbase3.0-0v5.deb || warning "Error instalando libwxbase"
    sudo dpkg -i libwxgtk3.0-gtk3-0v5.deb || warning "Error instalando libwxgtk"
    
    # Arreglar dependencias si hay problemas
    sudo apt-get install -f -y
    
    # Instalar SafeSign
    sudo dpkg -i SafeSign_IC_Standard_Linux.deb || {
        warning "Error instalando SafeSign, intentando arreglar dependencias..."
        sudo apt-get install -f -y
    }
    
else
    warning "Ubuntu 25.04+ detectada"
    warning "La instalación automática de SafeSign puede fallar"
    warning "Los paquetes se han descargado para instalación manual"
    
    log "Configurando OpenSC como alternativa..."
    sudo apt-get install -y opensc opensc-pkcs11
fi

# Configurar módulo SafeSign
log "Configurando módulo SafeSign..."
sudo mkdir -p /usr/share/p11-kit/modules/
echo 'module: /usr/lib/libaetpkss.so' | sudo tee /usr/share/p11-kit/modules/safesign.module > /dev/null

# Configurar módulo OpenSC como alternativa
log "Configurando módulo OpenSC alternativo..."
echo 'module: /usr/lib/x86_64-linux-gnu/opensc-pkcs11.so' | sudo tee /usr/share/p11-kit/modules/opensc.module > /dev/null

# Habilitar y arrancar servicios
log "Habilitando servicios..."
sudo systemctl enable pcscd
sudo systemctl start pcscd

# Verificaciones finales
log "Realizando verificaciones..."

if systemctl is-active --quiet pcscd; then
    log "✅ Servicio pcscd activo"
else
    warning "❌ Servicio pcscd no está activo"
fi

if [ -f /usr/share/p11-kit/modules/safesign.module ]; then
    log "✅ Módulo SafeSign configurado"
else
    warning "❌ Módulo SafeSign no configurado"
fi

log "=== INSTALACIÓN COMPLETADA ==="
echo ""
log "Pasos siguientes:"
echo "1. Conectar lector de tarjetas USB"
echo "2. Insertar certificado digital"
echo "3. Probar con: pcsc_scan"
echo "4. Listar certificados: p11tool --list-tokens"
echo ""
if dpkg --compare-versions "$UBUNTU_VERSION" "ge" "25.04"; then
    warning "Para Ubuntu 25.04+: Usar ./post_instalacion_certificados.sh"
fi
