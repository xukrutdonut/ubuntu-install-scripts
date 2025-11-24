#!/bin/bash

# Script mejorado para VPN Generalitat Valenciana
# Versión depurada con verificaciones

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

log "=== CONEXIÓN VPN GENERALITAT VALENCIANA ==="
echo ""

# Verificar dependencias principales
MISSING_DEPS=()

if ! command -v openconnect >/dev/null 2>&1; then
    MISSING_DEPS+=("openconnect")
fi

if ! command -v p11tool >/dev/null 2>&1; then
    MISSING_DEPS+=("gnutls-bin")
fi

if ! command -v pkcs15-tool >/dev/null 2>&1; then
    MISSING_DEPS+=("opensc")
fi

# Herramientas adicionales de diagnóstico
OPTIONAL_TOOLS=()
if ! command -v pcsc_scan >/dev/null 2>&1; then
    OPTIONAL_TOOLS+=("pcsc-tools")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    error "Faltan dependencias: ${MISSING_DEPS[*]}"
    echo ""
    read -p "¿Desea instalar las dependencias automáticamente? (s/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        log "Instalando dependencias..."
        sudo apt update && sudo apt install -y ${MISSING_DEPS[*]}
        if [ $? -eq 0 ]; then
            log "Dependencias instaladas correctamente"
        else
            error "Error al instalar dependencias"
            exit 1
        fi
    else
        echo "Instalar manualmente con: sudo apt install ${MISSING_DEPS[*]}"
        exit 1
    fi
fi

# Informar sobre herramientas opcionales de diagnóstico
if [ ${#OPTIONAL_TOOLS[@]} -gt 0 ]; then
    warning "Herramientas de diagnóstico recomendadas: ${OPTIONAL_TOOLS[*]}"
    echo "  Para instalar: sudo apt install ${OPTIONAL_TOOLS[*]}"
    echo ""
fi

# Verificar si SafeSign está instalado
if ! dpkg -l 2>/dev/null | grep -q safesign; then
    warning "SafeSign no está instalado"
    SAFESIGN_DEB=""
    
    if [ -f "SafeSign IC Standard Linux 4.1.0.0-AET.000 ub2204 x86_64.deb" ]; then
        SAFESIGN_DEB="SafeSign IC Standard Linux 4.1.0.0-AET.000 ub2204 x86_64.deb"
    elif [ -f "SafeSign_IC_Standard_Linux.deb" ]; then
        SAFESIGN_DEB="SafeSign_IC_Standard_Linux.deb"
    fi
    
    if [ -n "$SAFESIGN_DEB" ]; then
        echo "  Paquete disponible: $SAFESIGN_DEB"
        read -p "¿Desea instalar SafeSign ahora? (s/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            log "Instalando SafeSign..."
            sudo dpkg -i "$SAFESIGN_DEB" && log "SafeSign instalado correctamente" || error "Error al instalar SafeSign"
            log "Reiniciando servicio pcscd..."
            sudo systemctl restart pcscd
            sleep 2
        fi
    else
        echo "  Debe descargar e instalar SafeSign desde AET Europe"
        echo "  Para instalar: sudo dpkg -i <paquete_safesign.deb>"
    fi
    echo ""
else
    log "SafeSign ya está instalado ✅"
fi

# Verificar servicio pcscd
if ! systemctl is-active --quiet pcscd; then
    warning "Servicio pcscd no está activo, intentando iniciarlo..."
    sudo systemctl start pcscd || {
        error "No se pudo iniciar pcscd"
        exit 1
    }
fi

# Verificar lectores de tarjetas
log "Verificando lectores de tarjetas..."
if ! pgrep -x pcscd >/dev/null; then
    error "El servicio pcscd no está ejecutándose"
    exit 1
fi

# Verificar si hay lectores disponibles
if command -v pcsc_scan >/dev/null 2>&1; then
    timeout 3s pcsc_scan 2>/dev/null | grep -i reader >/dev/null || warning "No se detectaron lectores de tarjetas activos"
else
    # Método alternativo usando lsusb
    if ! lsusb | grep -i -E "(smart|card|reader|aet)" >/dev/null; then
        warning "No se detectaron lectores de tarjetas USB"
    fi
fi

log "Buscando certificados digitales disponibles..."
echo ""

# Intentar múltiples métodos para encontrar certificados
CERT_FOUND=false

# Método 1: Usando p11tool con SafeSign
log "Intentando método 1: p11tool con SafeSign..."
if p11tool --list-privkeys --login pkcs11:manufacturer=A.E.T.%20Europe%20B.V. 2>/dev/null | grep -q "URL:"; then
    CERT_FOUND=true
    log "✅ Certificados encontrados con SafeSign"
fi

# Método 2: Usando opensc genérico
if [ "$CERT_FOUND" = false ]; then
    log "Intentando método 2: opensc genérico..."
    if p11tool --list-tokens 2>/dev/null | grep -q "token:"; then
        if p11tool --list-privkeys --login 2>/dev/null | grep -q "URL:"; then
            CERT_FOUND=true
            log "✅ Certificados encontrados con opensc"
        fi
    fi
fi

# Método 3: Usando pkcs15-tool
if [ "$CERT_FOUND" = false ]; then
    log "Intentando método 3: pkcs15-tool..."
    if pkcs15-tool --list-certificates 2>/dev/null | grep -q "X.509"; then
        CERT_FOUND=true
        log "✅ Certificados encontrados con pkcs15-tool"
    fi
fi

if [ "$CERT_FOUND" = true ]; then
    echo ""
    log "Certificados encontrados ✅"
    
    echo ""
    read -p "¿Desea continuar con la conexión VPN? (s/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        log "Iniciando conexión VPN..."
        log "Se abrirá solicitud de PIN del certificado"
        echo ""
        
        # Detectar automáticamente el certificado disponible
        CERT_URL=""
        
        # Intentar obtener URL del certificado de SafeSign
        CERT_URL=$(p11tool --list-privkeys --login pkcs11:manufacturer=A.E.T.%20Europe%20B.V. 2>/dev/null | grep "URL:" | head -1 | cut -d' ' -f2)
        
        # Si no funciona SafeSign, intentar método genérico
        if [ -z "$CERT_URL" ]; then
            CERT_URL=$(p11tool --list-privkeys --login 2>/dev/null | grep "URL:" | head -1 | cut -d' ' -f2)
        fi
        
        if [ -n "$CERT_URL" ]; then
            log "Usando certificado: $CERT_URL"
            echo ""
            
            # Comando de conexión VPN con certificado detectado automáticamente
            sudo openconnect \
                -c "$CERT_URL" \
                https://vpn.san.gva.es \
                --servercert pin-sha256:h3CPvG+irXtGO04d14zc9rh1aGuUFVt43uB7NPRosvI= \
                --verbose
        else
            error "No se pudo detectar automáticamente la URL del certificado"
            echo "Debe especificar manualmente el certificado usando:"
            echo "  p11tool --list-privkeys --login"
            exit 1
        fi
    else
        log "Conexión cancelada por el usuario"
    fi
    
else
    error "No se encontraron certificados digitales"
    echo ""
    echo "=== DIAGNÓSTICO DEL SISTEMA ==="
    echo ""
    
    # Verificar tokens disponibles
    echo "Tokens disponibles:"
    p11tool --list-tokens 2>/dev/null || echo "  - Ninguno encontrado"
    echo ""
    
    # Verificar lectores con lsusb
    echo "Lectores USB detectados:"
    lsusb | grep -i -E "(smart|card|reader|aet)" || echo "  - Ninguno encontrado con lsusb"
    echo ""
    
    # Verificar procesos relacionados
    echo "Servicios activos:"
    systemctl is-active pcscd && echo "  - pcscd: ACTIVO" || echo "  - pcscd: INACTIVO"
    echo ""
    
    echo "=== POSIBLES SOLUCIONES ==="
    echo "1. Verificar que el lector de tarjetas está conectado (lsusb)"
    echo "2. Verificar que el certificado digital está insertado correctamente"
    echo "3. Instalar drivers SafeSign:"
    echo "   sudo dpkg -i 'SafeSign IC Standard Linux 4.1.0.0-AET.000 ub2204 x86_64.deb'"
    echo "4. Reiniciar el servicio: sudo systemctl restart pcscd"
    echo "5. Verificar permisos: sudo usermod -a -G scard $USER"
    echo ""
    echo "=== COMANDOS DE VERIFICACIÓN ==="
    echo "  p11tool --list-tokens"
    echo "  p11tool --list-privkeys --login"
    echo "  pkcs15-tool --list-certificates"
    echo "  systemctl status pcscd"
    exit 1
fi

# ========================================
# COMANDOS DE REFERENCIA
# ========================================
# 
# Listar todos los tokens disponibles:
# p11tool --list-tokens
#
# Listar claves privadas:
# p11tool --list-privkeys --login pkcs11:manufacturer=A.E.T.%20Europe%20B.V.
#
# Verificar lector de tarjetas:
# pcsc_scan
#
# Verificar servicio pcscd:
# systemctl status pcscd



