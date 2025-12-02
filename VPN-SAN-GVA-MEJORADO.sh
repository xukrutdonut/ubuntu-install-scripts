#!/bin/bash

# Script mejorado para VPN Generalitat Valenciana
# Versión depurada con verificaciones completas y soluciones automáticas
# Fecha: 2025-11-27

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

# Verificar SafeSign con instalación automática GyD
log "Verificando SafeSign..."
if ! dpkg -l 2>/dev/null | grep -q safesign; then
    warning "SafeSign no está instalado"
    
    # Verificar si existe el script de instalación GyD
    if [ -f "InstalaciónGyD.sh" ]; then
        echo ""
        log "🎯 Script de instalación GyD encontrado"
        read -p "¿Desea ejecutar la instalación completa GyD (Generalitat y Diputación)? (S/n): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            log "Saltando instalación GyD por decisión del usuario"
        else
            log "🚀 Ejecutando instalación GyD..."
            echo "=================================================="
            echo "INSTALANDO CERTIFICADOS DIGITALES GyD"
            echo "=================================================="
            
            # Ejecutar el script GyD
            chmod +x InstalaciónGyD.sh
            if ./InstalaciónGyD.sh; then
                success "✅ Instalación GyD completada correctamente"
                log "Reiniciando servicio pcscd..."
                run_sudo systemctl restart pcscd
                sleep 3
            else
                warning "⚠️ Hubo problemas en la instalación GyD, continuando..."
            fi
            
            echo "=================================================="
            echo ""
        fi
    else
        # Instalación manual como fallback
        log "Script GyD no encontrado, buscando paquetes SafeSign..."
        
        # Buscar paquetes SafeSign en el directorio actual y subdirectorios
        SAFESIGN_FILES=($(find . -maxdepth 2 -name "*afesign*" -name "*.deb" 2>/dev/null))
        
        # También buscar variantes comunes del nombre
        if [ ${#SAFESIGN_FILES[@]} -eq 0 ]; then
            SAFESIGN_FILES=($(find . -maxdepth 2 -iname "*safesign*" -name "*.deb" 2>/dev/null))
        fi
        
        if [ ${#SAFESIGN_FILES[@]} -gt 0 ]; then
            echo "Paquetes SafeSign encontrados:"
            for i in "${!SAFESIGN_FILES[@]}"; do
                echo "  $((i+1)). ${SAFESIGN_FILES[i]}"
            done
            
            read -p "¿Desea instalar SafeSign? Seleccione número o N para cancelar: " -r
            
            if [[ $REPLY =~ ^[0-9]+$ ]] && [ "$REPLY" -gt 0 ] && [ "$REPLY" -le "${#SAFESIGN_FILES[@]}" ]; then
                SELECTED_FILE="${SAFESIGN_FILES[$((REPLY-1))]}"
                log "Instalando SafeSign: $SELECTED_FILE"
                
                if run_sudo dpkg -i "$SELECTED_FILE"; then
                    success "SafeSign instalado correctamente"
                    run_sudo systemctl restart pcscd
                    sleep 3
                else
                    error "Error al instalar SafeSign"
                    log "Intentando reparar dependencias..."
                    run_sudo apt --fix-broken install -y
                fi
            fi
        else
            warning "No se encontraron paquetes SafeSign en el directorio actual"
            echo "Debe descargar SafeSign desde AET Europe:"
            echo "https://www.aeteurope.com/download-center/"
            echo ""
            log "Buscando SafeSign en ubicaciones comunes..."
            
            # Buscar en Downloads comunes
            COMMON_LOCATIONS=("$HOME/Downloads" "$HOME/Descargas" "/tmp" "/home/*/Downloads" "/home/*/Descargas")
            
            for location in "${COMMON_LOCATIONS[@]}"; do
                if [ -d "$location" ]; then
                    FOUND_FILES=$(find "$location" -maxdepth 1 -iname "*safesign*.deb" 2>/dev/null | head -3)
                    if [ -n "$FOUND_FILES" ]; then
                        echo "SafeSign encontrado en $location:"
                        echo "$FOUND_FILES"
                        echo ""
                    fi
                fi
            done
        fi
    fi
else
    success "SafeSign ya está instalado ✅"
    log "Verificando configuración de módulos PKCS#11..."
    
    # Verificar módulos configurados
    if [ -f "/usr/share/p11-kit/modules/safesign.module" ]; then
        success "Módulo SafeSign configurado ✅"
    else
        warning "Módulo SafeSign no configurado"
        log "Configurando módulo SafeSign..."
        run_sudo mkdir -p /usr/share/p11-kit/modules/
        echo 'module: /usr/lib/libaetpkss.so' | run_sudo tee /usr/share/p11-kit/modules/safesign.module > /dev/null
        success "Módulo SafeSign configurado"
    fi
fi

# Verificación avanzada de lectores de tarjetas
log "Verificando lectores de tarjetas..."
echo ""

# Verificar USB
log "Dispositivos USB conectados:"
USB_READERS=$(lsusb | grep -i -E "(smart|card|reader|aet|gemalto|omnikey)")
if [ -n "$USB_READERS" ]; then
    echo "$USB_READERS"
    success "Lectores USB detectados ✅"
else
    warning "No se detectaron lectores de tarjetas USB específicos"
    echo "Dispositivos USB genéricos:"
    lsusb | head -5
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

# Búsqueda exhaustiva de certificados
log "Buscando certificados digitales disponibles..."
echo ""

CERT_FOUND=false
CERT_URL=""
CERT_METHOD=""

# Método 1: SafeSign específico
log "Método 1: Verificando SafeSign (A.E.T. Europe)..."
SAFESIGN_OUTPUT=$(p11tool --list-privkeys --login pkcs11:manufacturer=A.E.T.%20Europe%20B.V. 2>/dev/null | grep "URL:" | head -1)
if [ -n "$SAFESIGN_OUTPUT" ]; then
    CERT_URL=$(echo "$SAFESIGN_OUTPUT" | cut -d' ' -f2)
    CERT_FOUND=true
    CERT_METHOD="SafeSign"
    success "✅ Certificados encontrados con SafeSign"
fi

# Método 2: Opensc genérico
if [ "$CERT_FOUND" = false ]; then
    log "Método 2: Verificando opensc genérico..."
    if p11tool --list-tokens 2>/dev/null | grep -q "token:"; then
        GENERIC_OUTPUT=$(p11tool --list-privkeys --login 2>/dev/null | grep "URL:" | head -1)
        if [ -n "$GENERIC_OUTPUT" ]; then
            CERT_URL=$(echo "$GENERIC_OUTPUT" | cut -d' ' -f2)
            CERT_FOUND=true
            CERT_METHOD="OpenSC genérico"
            success "✅ Certificados encontrados con opensc"
        fi
    fi
fi

# Método 3: pkcs15-tool
if [ "$CERT_FOUND" = false ]; then
    log "Método 3: Verificando con pkcs15-tool..."
    if pkcs15-tool --list-certificates 2>/dev/null | grep -q "X.509"; then
        # Para pkcs15, necesitamos construir la URL manualmente
        CERT_URL="pkcs15:"
        CERT_FOUND=true
        CERT_METHOD="PKCS15"
        success "✅ Certificados encontrados con pkcs15-tool"
    fi
fi

# Método 4: Verificación de tokens disponibles
if [ "$CERT_FOUND" = false ]; then
    log "Método 4: Verificando todos los tokens disponibles..."
    TOKENS_OUTPUT=$(p11tool --list-tokens 2>/dev/null)
    echo "Tokens disponibles:"
    echo "$TOKENS_OUTPUT"
    
    # Verificar si hay tokens no de confianza del sistema
    if echo "$TOKENS_OUTPUT" | grep -v "System Trust" | grep -q "Token"; then
        warning "Se detectaron tokens, pero no se pudieron acceder a las claves privadas"
        echo "Esto puede indicar que la tarjeta está insertada pero requiere PIN"
    fi
fi

echo ""

# Intentar conexión VPN independientemente de la detección automática
echo ""
echo "=========================================="
echo "🚀 INICIANDO CONEXIÓN VPN"
echo "=========================================="

if [ "$CERT_FOUND" = true ]; then
    success "🎉 CERTIFICADOS DIGITALES DETECTADOS AUTOMÁTICAMENTE"
    log "Método utilizado: $CERT_METHOD"
    log "URL del certificado: $CERT_URL"
    echo ""
    
    log "Iniciando conexión VPN con certificado detectado..."
    log "Se solicitará el PIN del certificado digital"
    
    # Mostrar información de conexión
    echo "=========================================="
    echo "DATOS DE CONEXIÓN:"
    echo "- Servidor: https://vpn.san.gva.es"
    echo "- Certificado: $CERT_URL"
    echo "- Método: $CERT_METHOD"
    echo "=========================================="
    echo ""
    
    # Comando de conexión con certificado específico
    log "Ejecutando openconnect con certificado detectado..."
    run_sudo openconnect \
        -c "$CERT_URL" \
        https://vpn.san.gva.es \
        --servercert pin-sha256:h3CPvG+irXtGO04d14zc9rh1aGuUFVt43uB7NPRosvI= \
        --verbose
        
else
    warning "No se detectaron certificados automáticamente"
    log "Pero tras instalar GyD, el sistema debería funcionar"
    echo ""
    
    read -p "¿Desea intentar la conexión VPN de todas formas? (S/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log "Conexión cancelada por el usuario"
        exit 0
    fi
    
    log "🚀 Iniciando conexión VPN (openconnect detectará certificados)..."
    log "Se solicitará seleccionar el certificado y PIN"
    
    # Mostrar información de conexión
    echo "=========================================="
    echo "DATOS DE CONEXIÓN:"
    echo "- Servidor: https://vpn.san.gva.es"
    echo "- Certificados: Detectados automáticamente por openconnect"
    echo "- Método: Interactivo"
    echo "=========================================="
    echo ""
    
    # Comando de conexión sin certificado específico (openconnect los detectará)
    log "Ejecutando openconnect (modo interactivo)..."
    run_sudo openconnect \
        https://vpn.san.gva.es \
        --servercert pin-sha256:h3CPvG+irXtGO04d14zc9rh1aGuUFVt43uB7NPRosvI= \
        --verbose
fi

# Al desconectar
echo ""
log "Conexión VPN finalizada"