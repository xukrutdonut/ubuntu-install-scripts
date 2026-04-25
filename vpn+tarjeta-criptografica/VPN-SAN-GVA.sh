#!/bin/bash

# Script mejorado para VPN Generalitat Valenciana
# Versión depurada con verificaciones completas y soluciones automáticas
# Fecha: 2025-11-27
# Actualizado: 2026-04-25 - Migrado de SafeSign (G&D) a Bit4id (BIT4ID JCOP4 / NXP SecID P71)
#
# Tarjeta: BIT4ID JCOP4 - Certificado Empleado Público - Conselleria de Sanitat GVA
# Módulo PKCS#11: /usr/lib/bit4id/libbit4xpki.so
# Lector recomendado: Sveon SLW20 (Alcor Micro AU9540)
# Setup: ./setup-bit4id-smartcard.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Función para ejecutar comandos con sudo de manera segura
run_sudo() {
    if [ "$EUID" -eq 0 ]; then
        # Ya somos root, ejecutar directamente
        "$@"
    else
        # Usar sudo
        sudo "$@"
    fi
}

# Función para verificar y crear grupo scard si no existe
setup_scard_group() {
    if ! getent group scard >/dev/null 2>&1; then
        log "Creando grupo scard..."
        if run_sudo groupadd scard 2>/dev/null; then
            success "Grupo scard creado correctamente"
        else
            warning "No se pudo crear el grupo scard (puede que ya exista)"
        fi
    fi
    
    # Añadir usuario al grupo scard
    if ! groups "$USER" | grep -q scard; then
        log "Añadiendo usuario $USER al grupo scard..."
        if run_sudo usermod -a -G scard "$USER" 2>/dev/null; then
            success "Usuario añadido al grupo scard"
            warning "Debe reiniciar la sesión para que los cambios de grupo surtan efecto"
        fi
    fi
}

# Función para limpiar repositorios problemáticos
clean_repositories() {
    log "Verificando repositorios problemáticos..."
    
    # Lista de PPAs problemáticos conocidos
    PROBLEMATIC_PPAS=(
        "flatpak/stable"
        "nilarimogard/webupd8"
        "oguzhaninan/stacer"
        "tomtomtom/woeusb"
        "webupd8team/y-ppa-manager"
    )
    
    for ppa in "${PROBLEMATIC_PPAS[@]}"; do
        PPA_FILE="/etc/apt/sources.list.d/$(echo $ppa | sed 's/\//-/')-*.list"
        if ls $PPA_FILE 2>/dev/null; then
            warning "Repositorio problemático detectado: $ppa"
            read -p "¿Desea deshabilitarlo temporalmente? (s/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Ss]$ ]]; then
                run_sudo sed -i 's/^deb/#deb/' $PPA_FILE
                log "Repositorio $ppa deshabilitado temporalmente"
            fi
        fi
    done
}

# Función para verificar sistema completo antes de empezar
system_pre_check() {
    log "=== VERIFICACIÓN COMPLETA DEL SISTEMA ==="
    echo ""
    
    # Verificar distribución Ubuntu
    if ! grep -q "Ubuntu" /etc/os-release; then
        error "Este script está diseñado para Ubuntu. Detectado: $(lsb_release -d | cut -f2)"
        exit 1
    fi
    
    # Verificar versión Ubuntu compatible
    UBUNTU_VERSION=$(lsb_release -rs)
    log "Detectado Ubuntu $UBUNTU_VERSION"
    
    # Verificar conectividad de red
    log "Verificando conectividad de red..."
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        error "Sin conectividad de red. Verifique su conexión a Internet"
        exit 1
    fi
    success "Conectividad de red: OK"
    
    # Verificar espacio en disco
    AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
    if [ "$AVAILABLE_SPACE" -lt 1048576 ]; then # Menos de 1GB
        warning "Poco espacio en disco disponible: $((AVAILABLE_SPACE/1024)) MB"
    else
        success "Espacio en disco: OK"
    fi
    
    # Verificar permisos sudo (solo si no somos root)
    if [ "$EUID" -ne 0 ]; then
        log "Verificando permisos sudo..."
        # Intentar primero sin contraseña
        if ! sudo -n true 2>/dev/null; then
            log "Se requieren permisos de administrador para continuar"
            log "Por favor, ingrese su contraseña cuando se le solicite..."
            # Solicitar contraseña explícitamente
            if sudo true; then
                success "Permisos sudo: OK"
            else
                error "No se pudieron obtener permisos sudo"
                exit 1
            fi
        else
            success "Permisos sudo: OK"
        fi
    else
        success "Ejecutándose como root: OK"
    fi
    
    echo ""
}

# Función para verificar y reparar repositorios
fix_repositories() {
    log "Limpiando y actualizando repositorios..."
    
    # Limpiar caché de apt
    run_sudo apt clean
    
    # Actualizar repositorios con manejo de errores
    if run_sudo apt update 2>&1 | grep -q "NO_PUBKEY\|404\|Release"; then
        warning "Problemas detectados en repositorios"
        clean_repositories
        
        # Intentar actualizar de nuevo
        log "Reintentando actualización de repositorios..."
        run_sudo apt update --fix-missing
    fi
    
    success "Repositorios actualizados"
}

log "=== CONEXIÓN VPN GENERALITAT VALENCIANA - VERSIÓN MEJORADA ==="
echo ""

# Ejecutar verificación completa del sistema
system_pre_check

# Configurar grupo scard
setup_scard_group

# Verificar y reparar repositorios
fix_repositories

# Verificar dependencias principales
MISSING_DEPS=()
REQUIRED_PACKAGES=("openconnect" "gnutls-bin" "opensc" "pcsc-tools")

log "Verificando dependencias necesarias..."
for package in "${REQUIRED_PACKAGES[@]}"; do
    case $package in
        "openconnect")
            if ! command -v openconnect >/dev/null 2>&1; then
                MISSING_DEPS+=("openconnect")
            fi
            ;;
        "gnutls-bin")
            if ! command -v p11tool >/dev/null 2>&1; then
                MISSING_DEPS+=("gnutls-bin")
            fi
            ;;
        "opensc")
            if ! command -v pkcs15-tool >/dev/null 2>&1; then
                MISSING_DEPS+=("opensc")
            fi
            ;;
        "pcsc-tools")
            if ! command -v pcsc_scan >/dev/null 2>&1; then
                MISSING_DEPS+=("pcsc-tools")
            fi
            ;;
    esac
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    warning "Faltan dependencias: ${MISSING_DEPS[*]}"
    echo ""
    
    log "Instalando dependencias automáticamente..."
    if run_sudo apt install -y "${MISSING_DEPS[@]}"; then
        success "Dependencias instaladas correctamente"
    else
        error "Error al instalar dependencias"
        echo "Intente manualmente: sudo apt install ${MISSING_DEPS[*]}"
        exit 1
    fi
else
    success "Todas las dependencias están instaladas"
fi

# Verificar e iniciar servicio pcscd
log "Verificando servicio pcscd..."
if ! systemctl is-active --quiet pcscd; then
    log "Iniciando servicio pcscd..."
    run_sudo systemctl start pcscd
    run_sudo systemctl enable pcscd
fi

if systemctl is-active --quiet pcscd; then
    success "Servicio pcscd: ACTIVO"
else
    error "No se pudo iniciar el servicio pcscd"
    exit 1
fi

# Verificar Bit4id Middleware
BIT4ID_MODULE="/usr/lib/bit4id/libbit4xpki.so"

log "Verificando Bit4id Middleware..."
if [ -f "$BIT4ID_MODULE" ] && dpkg -l libbit4xpki &>/dev/null 2>&1; then
    success "Bit4id Middleware detectado ✅ (tarjeta BIT4ID JCOP4 / CNS)"
    if [ ! -f "/usr/share/p11-kit/modules/bit4id.module" ]; then
        echo "module: $BIT4ID_MODULE" | run_sudo tee /usr/share/p11-kit/modules/bit4id.module > /dev/null
    fi
else
    error "Bit4id Middleware no instalado. Ejecuta primero: ./setup-bit4id-smartcard.sh"
    exit 1
fi

# Verificación avanzada de lectores de tarjetas
log "Verificando lectores de tarjetas..."
echo ""

# Verificar USB
log "Dispositivos USB conectados:"
USB_READERS=$(lsusb | grep -i -E "(smart|card|reader|0783|058f|ccid)")
if [ -n "$USB_READERS" ]; then
    echo "$USB_READERS"
    success "Lectores USB detectados ✅"
else
    warning "No se detectaron lectores de tarjetas USB"
    echo "Conecta el lector Sveon SLW20 directamente a un puerto USB del equipo"
fi

echo ""

# Verificar con pcsc_scan
log "Escaneando lectores con pcsc_scan..."
if command -v pcsc_scan >/dev/null 2>&1; then
    PCSC_OUTPUT=$(timeout 5s pcsc_scan 2>/dev/null || true)
    if echo "$PCSC_OUTPUT" | grep -q "Reader"; then
        success "Lectores detectados por pcscd ✅"
        echo "$PCSC_OUTPUT" | grep -A2 "Reader"
    else
        warning "No se detectaron lectores activos en pcscd"
    fi
else
    warning "pcsc_scan no disponible"
fi

echo ""

# Búsqueda de certificados Bit4id (BIT4ID JCOP4 / NXP SecID P71)
log "Buscando certificados en tarjeta Bit4id..."
echo ""

CERT_FOUND=false
CERT_URL=""

# Método 1: p11tool con módulo Bit4id directo
log "Método 1: Bit4id PKCS#11 (p11tool)..."
BIT4ID_OUTPUT=$(p11tool --provider "$BIT4ID_MODULE" --list-privkeys --login 2>/dev/null | grep "URL:" | head -1)
if [ -n "$BIT4ID_OUTPUT" ]; then
    CERT_URL=$(echo "$BIT4ID_OUTPUT" | awk '{print $2}')
    CERT_FOUND=true
    success "✅ Certificado encontrado (Bit4id)"
fi

# Método 2: p11tool con filtro NXP (token SecID P71)
if [ "$CERT_FOUND" = false ]; then
    log "Método 2: Bit4id por token NXP SecID P71..."
    NXP_OUTPUT=$(p11tool --list-privkeys --login "pkcs11:manufacturer=NXP" 2>/dev/null | grep "URL:" | head -1)
    if [ -n "$NXP_OUTPUT" ]; then
        CERT_URL=$(echo "$NXP_OUTPUT" | awk '{print $2}')
        CERT_FOUND=true
        success "✅ Certificado encontrado (token NXP)"
    fi
fi

# Método 3: pkcs11-tool con módulo Bit4id
if [ "$CERT_FOUND" = false ]; then
    log "Método 3: pkcs11-tool con módulo Bit4id..."
    if pkcs11-tool --module "$BIT4ID_MODULE" --list-objects --type cert 2>/dev/null | grep -q "Certificate"; then
        # Construir URL PKCS#11 para el certificado de Empleado Público
        CERT_URL="pkcs11:model=SecID%20P71;token=BIT4ID%20JCOP4;type=cert"
        CERT_FOUND=true
        success "✅ Certificado encontrado (pkcs11-tool)"
    fi
fi

echo ""

# Intentar conexión VPN independientemente de la detección automática
echo ""
echo "=========================================="
echo "🚀 INICIANDO CONEXIÓN VPN"
echo "=========================================="

if [ "$CERT_FOUND" = true ]; then
    success "🎉 CERTIFICADO DETECTADO AUTOMÁTICAMENTE"
    log "URL del certificado: $CERT_URL"
    echo ""
    
    echo "=========================================="
    echo "DATOS DE CONEXIÓN:"
    echo "- Servidor:     https://vpn.san.gva.es"
    echo "- Módulo:       $BIT4ID_MODULE"
    echo "- Certificado:  $CERT_URL"
    echo "=========================================="
    echo ""
    log "Conectando... se pedirá el PIN de la tarjeta."
    
    run_sudo openconnect \
        --certificate "$CERT_URL" \
        --sslkey "$CERT_URL" \
        --key-password-from-fsid \
        --pkcs11-provider "$BIT4ID_MODULE" \
        https://vpn.san.gva.es \
        --servercert pin-sha256:h3CPvG+irXtGO04d14zc9rh1aGuUFVt43uB7NPRosvI= \
        --verbose
        
else
    warning "No se detectó certificado automáticamente."
    echo ""
    echo "Comprueba que:"
    echo "  1. El lector Sveon está conectado directamente al USB (no en hub)"
    echo "  2. La tarjeta está insertada"
    echo "  3. pcscd está activo: systemctl status pcscd"
    echo "  4. La tarjeta responde: pkcs11-tool --module $BIT4ID_MODULE --list-slots"
    echo ""
    
    read -p "¿Intentar conexión VPN interactiva igualmente? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        log "Iniciando openconnect en modo interactivo..."
        run_sudo openconnect \
            --pkcs11-provider "$BIT4ID_MODULE" \
            https://vpn.san.gva.es \
            --servercert pin-sha256:h3CPvG+irXtGO04d14zc9rh1aGuUFVt43uB7NPRosvI= \
            --verbose
    else
        log "Conexión cancelada"
        exit 0
    fi
fi

# Al desconectar
echo ""
log "Conexión VPN finalizada"