#!/bin/bash

# Script de diagnóstico completo para VPN Generalitat Valenciana
# Fecha: 2025-12-11

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO] $1${NC}"; }
warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }
success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
debug() { echo -e "${BLUE}[DEBUG] $1${NC}"; }

echo ""
echo "=========================================="
log "🔍 DIAGNÓSTICO COMPLETO VPN SAN-GVA"
echo "=========================================="
echo ""

# 1. Verificar dependencias
echo "1. DEPENDENCIAS"
echo "==============="

DEPS=("openconnect" "p11tool" "pcsc_scan" "pkcs15-tool")
for dep in "${DEPS[@]}"; do
    if command -v "$dep" >/dev/null 2>&1; then
        success "$dep: INSTALADO"
    else
        error "$dep: NO ENCONTRADO"
        case $dep in
            "openconnect") log "Instale: sudo apt install openconnect" ;;
            "p11tool") log "Instale: sudo apt install gnutls-bin" ;;
            "pcsc_scan") log "Instale: sudo apt install pcsc-tools" ;;
            "pkcs15-tool") log "Instale: sudo apt install opensc" ;;
        esac
    fi
done

echo ""

# 2. Servicios
echo "2. SERVICIOS"
echo "============"

if systemctl is-active --quiet pcscd 2>/dev/null; then
    success "pcscd: ACTIVO"
else
    error "pcscd: INACTIVO"
    log "Inicie con: sudo systemctl start pcscd"
fi

echo ""

# 3. Conectividad
echo "3. CONECTIVIDAD VPN"
echo "==================="

log "Probando conectividad básica..."
if ping -c 2 -W 3 vpn.san.gva.es >/dev/null 2>&1; then
    success "Ping a vpn.san.gva.es: OK"
else
    error "Ping a vpn.san.gva.es: FALLO"
fi

log "Probando puerto 443..."
if timeout 5 bash -c "</dev/tcp/vpn.san.gva.es/443" 2>/dev/null; then
    success "Puerto 443: ABIERTO"
else
    error "Puerto 443: NO ACCESIBLE"
fi

log "Verificando certificado SSL..."
SSL_CHECK=$(echo | timeout 5 openssl s_client -connect vpn.san.gva.es:443 -servername vpn.san.gva.es 2>/dev/null)
if echo "$SSL_CHECK" | grep -q "CONNECTED"; then
    success "Conexión SSL: ESTABLECIDA"
    
    # Verificar detalles del certificado
    if echo "$SSL_CHECK" | grep -q "Verify return code: 0"; then
        success "Certificado SSL: VÁLIDO"
    else
        warning "Certificado SSL: Problemas de verificación (común en VPNs corporativas)"
    fi
    
    # Mostrar información del certificado
    CERT_INFO=$(echo "$SSL_CHECK" | openssl x509 -noout -subject -issuer -dates 2>/dev/null)
    if [ -n "$CERT_INFO" ]; then
        debug "Información del certificado:"
        echo "$CERT_INFO" | while read line; do
            debug "  $line"
        done
    fi
else
    error "Conexión SSL: FALLO"
fi

echo ""

# 4. Hardware de certificados
echo "4. HARDWARE CERTIFICADOS"
echo "========================"

log "Verificando lectores de tarjetas..."
if command -v pcsc_scan >/dev/null 2>&1; then
    READERS_OUTPUT=$(timeout 3s pcsc_scan 2>/dev/null || true)
    if echo "$READERS_OUTPUT" | grep -q "Reader"; then
        success "Lectores detectados:"
        echo "$READERS_OUTPUT" | grep "Reader" | while read line; do
            debug "  $line"
        done
        
        # Verificar si hay tarjeta insertada
        if echo "$READERS_OUTPUT" | grep -q "Card state:"; then
            CARD_STATE=$(echo "$READERS_OUTPUT" | grep "Card state:" | head -1)
            if echo "$CARD_STATE" | grep -q "Card present"; then
                success "Tarjeta detectada"
            else
                warning "No se detecta tarjeta en el lector"
            fi
        fi
    else
        warning "No se detectaron lectores PCSC"
    fi
else
    warning "pcsc_scan no disponible"
fi

echo ""

# 5. SafeSign
echo "5. SAFESIGN"
echo "==========="

if dpkg -l 2>/dev/null | grep -q -i safesign; then
    success "SafeSign: INSTALADO"
    
    SAFESIGN_VERSION=$(dpkg -l | grep -i safesign | awk '{print $3}' | head -1)
    debug "Versión: $SAFESIGN_VERSION"
    
    # Verificar biblioteca
    SAFESIGN_LIBS=("/usr/lib/libaetpkss.so" "/usr/lib/x86_64-linux-gnu/libaetpkss.so" "/usr/local/lib/libaetpkss.so")
    LIB_FOUND=false
    for lib in "${SAFESIGN_LIBS[@]}"; do
        if [ -f "$lib" ]; then
            success "Biblioteca SafeSign: $lib"
            LIB_FOUND=true
            break
        fi
    done
    
    if [ "$LIB_FOUND" = false ]; then
        error "Biblioteca SafeSign no encontrada"
    fi
else
    error "SafeSign: NO INSTALADO"
    log "Descargue desde: https://www.aeteurope.com/download-center/"
    if [ -f "./SafeSign_IC_Standard_Linux.deb" ]; then
        log "Paquete encontrado en directorio actual"
    fi
fi

echo ""

# 6. Tokens PKCS#11
echo "6. TOKENS PKCS#11"
echo "================="

log "Listando todos los tokens..."
if command -v p11tool >/dev/null 2>&1; then
    TOKENS=$(p11tool --list-tokens 2>/dev/null || true)
    if [ -n "$TOKENS" ]; then
        echo "$TOKENS" | while read line; do
            if echo "$line" | grep -q "Token"; then
                TOKEN_NAME=$(echo "$line" | cut -d':' -f2 | xargs)
                if echo "$TOKEN_NAME" | grep -q "System Trust"; then
                    debug "  $TOKEN_NAME (sistema)"
                else
                    success "  $TOKEN_NAME"
                fi
            fi
        done
    else
        warning "No se detectaron tokens"
    fi
else
    error "p11tool no disponible"
fi

echo ""

# 7. Certificados
echo "7. CERTIFICADOS"
echo "==============="

CERT_METHODS=("SafeSign" "Genérico" "PKCS15")
CERT_FOUND=false

# SafeSign específico
log "Buscando certificados SafeSign..."
if SAFESIGN_CERTS=$(p11tool --list-privkeys pkcs11:manufacturer=A.E.T.%20Europe%20B.V. 2>/dev/null); then
    if echo "$SAFESIGN_CERTS" | grep -q "URL:"; then
        success "Certificados SafeSign: ENCONTRADOS"
        CERT_FOUND=true
        CERT_COUNT=$(echo "$SAFESIGN_CERTS" | grep -c "URL:" || echo "0")
        debug "$CERT_COUNT certificado(s) disponible(s)"
        
        echo "$SAFESIGN_CERTS" | grep "URL:" | head -3 | while read line; do
            debug "  $line"
        done
    else
        warning "SafeSign disponible pero sin certificados accesibles"
    fi
else
    log "No se detectaron certificados SafeSign"
fi

# Genérico
if [ "$CERT_FOUND" = false ]; then
    log "Buscando certificados genéricos..."
    if GENERIC_CERTS=$(p11tool --list-privkeys 2>/dev/null); then
        if echo "$GENERIC_CERTS" | grep -q "URL:"; then
            success "Certificados genéricos: ENCONTRADOS"
            CERT_FOUND=true
        fi
    fi
fi

# PKCS15
if command -v pkcs15-tool >/dev/null 2>&1; then
    log "Buscando certificados PKCS#15..."
    if pkcs15-tool --list-certificates 2>/dev/null | grep -q "X.509"; then
        success "Certificados PKCS#15: ENCONTRADOS"
        CERT_FOUND=true
    else
        log "No se detectaron certificados PKCS#15"
    fi
else
    warning "pkcs15-tool no disponible"
fi

echo ""

# 8. Resumen final
echo "8. RESUMEN DIAGNÓSTICO"
echo "======================"

if [ "$CERT_FOUND" = true ]; then
    success "✅ CERTIFICADOS DIGITALES DETECTADOS"
    log "La VPN debería funcionar si:"
    echo "   - El PIN del certificado es correcto"
    echo "   - El certificado no ha expirado"
    echo "   - No hay problemas de red"
else
    error "❌ NO SE DETECTARON CERTIFICADOS"
    log "Para solucionar:"
    echo "   1. Inserte la tarjeta/certificado USB"
    echo "   2. Instale SafeSign si no está instalado"
    echo "   3. Reinicie el servicio pcscd"
    echo "   4. Verifique que el lector funciona"
fi

echo ""

# Verificar si puede intentar conexión de prueba
log "¿Desea probar una conexión rápida a la VPN? (solo verificación inicial)"
read -p "(S/n): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    log "Probando conexión inicial (timeout 10s)..."
    
    if [ "$CERT_FOUND" = true ]; then
        # Con certificado
        CERT_URL=$(p11tool --list-privkeys 2>/dev/null | grep "URL:" | head -1 | cut -d' ' -f2)
        timeout 10s sudo openconnect -c "$CERT_URL" https://vpn.san.gva.es --servercert "pin-sha256:h3CPvG+irXtGO04d14zc9rh1aGuUFVt43uB7NPRosvI=" --authenticate 2>&1 | head -10
    else
        # Sin certificado específico
        timeout 10s sudo openconnect https://vpn.san.gva.es --servercert "pin-sha256:h3CPvG+irXtGO04d14zc9rh1aGuUFVt43uB7NPRosvI=" --authenticate 2>&1 | head -10
    fi
    
    log "Prueba completada (puede haber solicitado PIN)"
fi

echo ""
echo "=========================================="
log "📋 DIAGNÓSTICO COMPLETADO"
echo "=========================================="
echo ""
log "Si necesita ayuda adicional:"
echo "- Ejecute el script principal: ./VPN-SAN-GVA-fixed.sh"
echo "- Revise los logs del sistema: journalctl -u pcscd"
echo "- Contacte soporte técnico de la Generalitat"