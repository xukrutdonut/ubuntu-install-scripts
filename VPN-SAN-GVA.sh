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

# Verificar dependencias
if ! command -v openconnect >/dev/null 2>&1; then
    error "openconnect no está instalado"
    echo "Instalar con: sudo apt install openconnect"
    exit 1
fi

if ! command -v p11tool >/dev/null 2>&1; then
    error "p11tool no está instalado"
    echo "Instalar con: sudo apt install gnutls-bin"
    exit 1
fi

# Verificar servicio pcscd
if ! systemctl is-active --quiet pcscd; then
    warning "Servicio pcscd no está activo, intentando iniciarlo..."
    sudo systemctl start pcscd || {
        error "No se pudo iniciar pcscd"
        exit 1
    }
fi

log "Buscando certificados digitales disponibles..."
echo ""

# Listar certificados disponibles
if p11tool --list-privkeys --login pkcs11:manufacturer=A.E.T.%20Europe%20B.V. 2>/dev/null; then
    echo ""
    log "Certificados encontrados ✅"
    
    echo ""
    read -p "¿Desea continuar con la conexión VPN? (s/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        log "Iniciando conexión VPN..."
        log "Se abrirá solicitud de PIN del certificado"
        echo ""
        
        # Comando de conexión VPN
        # NOTA: Ajustar el certificado específico según el usuario
        sudo openconnect \
            -c 'pkcs11:model=19C41B06010D0000;manufacturer=A.E.T.%20Europe%20B.V.;serial=027600260045FD17;token=ACCV;id=%F4%E7%DF%65%5C%DE%ED%63%DF%55%43%F1%35%AE%F4%28%69%2B%57%42;object=EPN1;type=private' \
            https://vpn.san.gva.es \
            --servercert pin-sha256:h3CPvG+irXtGO04d14zc9rh1aGuUFVt43uB7NPRosvI= \
            --verbose
    else
        log "Conexión cancelada por el usuario"
    fi
    
else
    error "No se encontraron certificados digitales"
    echo ""
    echo "Posibles soluciones:"
    echo "1. Verificar que el lector de tarjetas está conectado"
    echo "2. Verificar que el certificado digital está insertado"
    echo "3. Ejecutar: pcsc_scan para verificar el lector"
    echo "4. Verificar instalación de drivers SafeSign"
    echo ""
    echo "Para verificar certificados:"
    echo "  p11tool --list-tokens"
    echo "  p11tool --list-privkeys --login"
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



