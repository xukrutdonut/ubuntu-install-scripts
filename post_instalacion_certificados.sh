#!/bin/bash

# Script especializado para certificados digitales Ubuntu 25.04+
# Manejo alternativo para versiones nuevas de Ubuntu

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

log "=== CONFIGURACIÓN ALTERNATIVA DE CERTIFICADOS DIGITALES ==="

UBUNTU_VERSION=$(lsb_release -rs)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if dpkg --compare-versions "$UBUNTU_VERSION" "ge" "25.04"; then
    log "Ubuntu 25.04+ detectada - Usando método alternativo"
    
    # Instalar Firefox ESR que puede tener mejor soporte
    log "Instalando Firefox ESR para certificados..."
    sudo apt update
    sudo apt install -y firefox-esr 2>/dev/null || warning "Firefox ESR no disponible"
    
    # Configurar OpenSC para certificados
    log "Configurando OpenSC..."
    sudo apt install -y opensc opensc-pkcs11 pcscd pcsc-tools
    
    # Crear script de verificación
    cat > "$SCRIPT_DIR/verificar_certificados.sh" << 'EOF'
#!/bin/bash
echo "=== VERIFICACIÓN DE CERTIFICADOS DIGITALES ==="
echo ""

echo "1. Verificando servicios..."
sudo systemctl status pcscd --no-pager || echo "pcscd no está corriendo"
echo ""

echo "2. Verificando lectores de tarjetas..."
pcsc_scan -n 2>/dev/null || echo "No se detectan lectores activos"
echo ""

echo "3. Listando módulos PKCS#11..."
p11-kit list-modules 2>/dev/null || echo "Error listando módulos"
echo ""

echo "4. Verificando OpenSC..."
opensc-tool --list-readers 2>/dev/null || echo "OpenSC: No hay lectores"
echo ""

echo "INSTRUCCIONES:"
echo "1. Conecta tu lector de tarjetas USB"
echo "2. Inserta tu certificado digital"
echo "3. Ejecuta: pcsc_scan"
echo "4. En Firefox: Preferencias > Privacidad y Seguridad > Certificados > Dispositivos de Seguridad"
echo "5. Cargar módulo: /usr/lib/x86_64-linux-gnu/opensc-pkcs11.so"
EOF

    chmod +x "$SCRIPT_DIR/verificar_certificados.sh"
    
    # Instrucciones para usuario
    log "Configuración completada para Ubuntu 25.04+"
    echo ""
    warning "PASOS MANUALES REQUERIDOS:"
    echo "1. Ejecutar: $SCRIPT_DIR/verificar_certificados.sh"
    echo "2. Para SafeSign, descargar drivers actualizados desde:"
    echo "   https://www.a-et.com/products/smart-card-middleware/"
    echo "3. Configurar certificados en Firefox manualmente"
    echo ""
    
else
    log "Ubuntu < 25.04 detectada - Instalación estándar"
    
    # Instalar dependencias específicas
    sudo apt install -y pcscd libpcsclite1 libccid opensc-pkcs11
    
    # Intentar instalar SafeSign
    cd "$SCRIPT_DIR"
    if [ -f "SafeSign_IC_Standard_Linux_4.1.0.0-AET.000_ub2204_x86_64.deb" ]; then
        log "Instalando SafeSign..."
        # Forzar instalación ignorando dependencias menores
        sudo dpkg -i --force-depends SafeSign_IC_Standard_Linux_4.1.0.0-AET.000_ub2204_x86_64.deb || warning "Instalación con advertencias"
        sudo apt-get install -f -y  # Arreglar dependencias
    fi
    
    log "Instalación estándar completada"
fi

# Configurar módulo SafeSign universal
if [ ! -f /usr/share/p11-kit/modules/safesign.module ]; then
    log "Configurando módulo SafeSign..."
    sudo mkdir -p /usr/share/p11-kit/modules/
    echo 'module: /usr/lib/libaetpkss.so' | sudo tee /usr/share/p11-kit/modules/safesign.module > /dev/null
fi

# Configurar OpenSC como alternativa
if [ ! -f /usr/share/p11-kit/modules/opensc.module ]; then
    log "Configurando módulo OpenSC..."
    echo 'module: /usr/lib/x86_64-linux-gnu/opensc-pkcs11.so' | sudo tee /usr/share/p11-kit/modules/opensc.module > /dev/null
fi

# Habilitar servicios
sudo systemctl enable pcscd
sudo systemctl start pcscd

log "Configuración de certificados completada"
log "Ejecuta verificar_certificados.sh para comprobar el estado"