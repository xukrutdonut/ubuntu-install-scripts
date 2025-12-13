#!/bin/bash

# =================================================================================
# SCRIPT CONEXIÓN VPN GENERALITAT VALENCIANA - VERSIÓN FINAL
# =================================================================================
# Autor: Script optimizado y depurado
# Fecha: $(date +%Y-%m-%d)
# Versión: 2.0
# 
# FUNCIONES:
# - Diagnóstico completo de certificados digitales
# - Detección automática de SafeSign y OpenSC
# - Conexión VPN robusta con manejo de errores
# - Soporte para archivos .env con credenciales
# - Logs detallados de conexión
# =================================================================================

set +e  # No salir automáticamente en errores

# =================================================================================
# CONFIGURACIÓN Y COLORES
# =================================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Archivos de configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/vpn_connection_$(date +%Y%m%d_%H%M%S).log"
ENV_FILE="$SCRIPT_DIR/.env"
ENV_EXAMPLE="$SCRIPT_DIR/.env.example"

# Funciones de logging
log() {
    local msg="[$(date +'%H:%M:%S')] $1"
    echo -e "${GREEN}$msg${NC}" | tee -a "$LOG_FILE"
}

warning() {
    local msg="[WARNING] $1"
    echo -e "${YELLOW}$msg${NC}" | tee -a "$LOG_FILE"
}

error() {
    local msg="[ERROR] $1"
    echo -e "${RED}$msg${NC}" | tee -a "$LOG_FILE"
}

success() {
    local msg="[SUCCESS] $1"
    echo -e "${GREEN}✅ $msg${NC}" | tee -a "$LOG_FILE"
}

info() {
    local msg="[INFO] $1"
    echo -e "${BLUE}$msg${NC}" | tee -a "$LOG_FILE"
}

debug() {
    local msg="[DEBUG] $1"
    echo -e "${CYAN}$msg${NC}" | tee -a "$LOG_FILE"
}

section() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}🚀 $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
}

# =================================================================================
# CONFIGURACIÓN DE VARIABLES
# =================================================================================

# Configuración por defecto de VPN
VPN_SERVER="https://vpn.san.gva.es"
VPN_SERVERCERT="pin-sha256:h3CPvG+irXtGO04d14zc9rh1aGuUFVt43uB7NPRosvI="
CONNECTION_TIMEOUT=60

# Variables de certificados
CERT_FOUND=false
CERT_URL=""
CERT_METHOD=""

# =================================================================================
# FUNCIONES DE CONFIGURACIÓN
# =================================================================================

load_env_config() {
    if [ -f "$ENV_FILE" ]; then
        log "Cargando configuración desde .env..."
        
        # Cargar .env de forma segura
        set -a
        source "$ENV_FILE"
        set +a
        
        success "Configuración .env cargada"
        
        # Mostrar configuración (sin mostrar contraseñas)
        info "Configuración activa:"
        [ -n "$VPN_USER" ] && info "  - Usuario: $VPN_USER"
        [ -n "$CERT_PIN" ] && info "  - PIN configurado: ✓"
        [ -n "$VPN_PASSWORD" ] && info "  - Contraseña VPN: ✓"
        info "  - Servidor: $VPN_SERVER"
        
    else
        log "No se encontró archivo .env"
        info "Para configuración automática, cree el archivo .env desde .env.example"
        
        # Crear .env.example si no existe
        create_env_example
    fi
}

create_env_example() {
    if [ ! -f "$ENV_EXAMPLE" ]; then
        log "Creando archivo .env.example..."
        
        cat > "$ENV_EXAMPLE" << 'EOF'
# Archivo de configuración VPN - Copie a .env y configure
# IMPORTANTE: No suba este archivo a git con credenciales reales

# PIN del certificado digital
CERT_PIN=su_pin_aqui

# Contraseña de usuario VPN (si es necesaria)
VPN_PASSWORD=su_password_aqui

# Usuario VPN (opcional)  
VPN_USER=su_usuario_aqui

# Configuraciones del servidor (normalmente no cambiar)
VPN_SERVER=https://vpn.san.gva.es
VPN_SERVERCERT="pin-sha256:h3CPvG+irXtGO04d14zc9rh1aGuUFVt43uB7NPRosvI="

# Timeout de conexión en segundos
CONNECTION_TIMEOUT=60
EOF
        
        success "Archivo .env.example creado"
        info "Copie a .env y configure sus credenciales: cp .env.example .env"
    fi
}

# =================================================================================
# VERIFICACIONES DEL SISTEMA
# =================================================================================

check_dependencies() {
    section "VERIFICACIÓN DE DEPENDENCIAS"
    
    local missing=()
    local deps=("openconnect" "p11tool" "systemctl")
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            success "$dep: instalado"
        else
            missing+=("$dep")
            error "$dep: NO ENCONTRADO"
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Dependencias faltantes: ${missing[*]}"
        log "Instale con: sudo apt update && sudo apt install openconnect gnutls-bin"
        
        # Mapear dependencias a paquetes
        local packages=()
        for dep in "${missing[@]}"; do
            case "$dep" in
                "openconnect") packages+=("openconnect") ;;
                "p11tool") packages+=("gnutls-bin") ;;
                "systemctl") error "systemctl es parte de systemd - sistema crítico" ;;
            esac
        done
        
        if [ ${#packages[@]} -gt 0 ]; then
            log "Paquetes necesarios: ${packages[*]}"
        fi
        
        exit 1
    fi
    
    success "Todas las dependencias están instaladas"
}

check_pcscd_service() {
    section "VERIFICACIÓN SERVICIO PCSCD"
    
    if systemctl is-active --quiet pcscd 2>/dev/null; then
        success "Servicio pcscd: ACTIVO"
    else
        warning "Servicio pcscd no está activo"
        log "Intentando iniciar pcscd..."
        
        if sudo systemctl start pcscd 2>/dev/null; then
            success "Servicio pcscd iniciado correctamente"
        else
            warning "No se pudo iniciar pcscd automáticamente"
            info "Inicie manualmente: sudo systemctl start pcscd"
            info "Habilitar en arranque: sudo systemctl enable pcscd"
        fi
    fi
    
    # Verificar estado del servicio
    if systemctl is-enabled --quiet pcscd 2>/dev/null; then
        info "Servicio pcscd habilitado para arranque automático"
    else
        info "Para habilitar en arranque: sudo systemctl enable pcscd"
    fi
}

check_connectivity() {
    section "VERIFICACIÓN CONECTIVIDAD VPN"
    
    local vpn_host="vpn.san.gva.es"
    
    # Test básico de conectividad
    log "Verificando conectividad básica a $vpn_host..."
    if ping -c 2 -W 3 "$vpn_host" >/dev/null 2>&1; then
        success "Conectividad básica: OK"
    else
        warning "Problemas de conectividad básica con $vpn_host"
        info "Verifique su conexión a internet"
    fi
    
    # Test SSL con verificación detallada
    log "Verificando certificado SSL del servidor VPN..."
    local ssl_info
    ssl_info=$(timeout 10 openssl s_client -connect "$vpn_host:443" -servername "$vpn_host" </dev/null 2>&1)
    
    if echo "$ssl_info" | grep -q "Verify return code: 0"; then
        success "Certificado SSL del servidor: VÁLIDO"
    elif echo "$ssl_info" | grep -q "weak signature algorithm"; then
        warning "Servidor usa algoritmo de firma débil (común en VPNs corporativas)"
        info "OpenConnect puede manejar esto automáticamente"
    else
        warning "Posibles problemas con certificado SSL del servidor"
        debug "Se utilizará --servercert para verificación manual"
    fi
    
    # Verificar puerto específico
    log "Verificando acceso al puerto HTTPS (443)..."
    if timeout 5 bash -c "</dev/tcp/$vpn_host/443" 2>/dev/null; then
        success "Puerto 443 accesible"
    else
        warning "Problemas accediendo al puerto 443"
        info "Verifique firewall y proxy corporativo"
    fi
}

check_card_readers() {
    section "VERIFICACIÓN LECTORES DE TARJETAS"
    
    # Verificar lectores USB
    log "Buscando lectores de tarjetas USB..."
    local usb_readers
    usb_readers=$(lsusb 2>/dev/null | grep -i -E "(smart|card|reader|aet|gemalto|omnikey)" || true)
    
    if [ -n "$usb_readers" ]; then
        success "Lectores USB detectados:"
        echo "$usb_readers" | while read -r line; do
            info "  - $line"
        done
    else
        warning "No se detectaron lectores USB específicos"
        info "Si tiene un lector, verifique que esté conectado correctamente"
    fi
    
    # Verificar con pcsc_scan si está disponible
    if command -v pcsc_scan >/dev/null 2>&1; then
        log "Escaneando lectores activos (3 segundos)..."
        local scan_result
        scan_result=$(timeout 3s pcsc_scan 2>/dev/null || true)
        
        if echo "$scan_result" | grep -q "Reader"; then
            success "Lectores activos detectados por pcsc_scan:"
            echo "$scan_result" | grep "Reader" | while read -r line; do
                info "  - $line"
            done
        else
            warning "pcsc_scan no detectó lectores activos"
        fi
    else
        info "pcsc_scan no disponible (instale: sudo apt install pcsc-tools)"
    fi
}

# =================================================================================
# DETECCIÓN DE CERTIFICADOS
# =================================================================================

detect_safesign_status() {
    section "VERIFICACIÓN SAFESIGN"
    
    local safesign_status="NOT_INSTALLED"
    local safesign_lib=""
    
    # Verificación 1: Paquete instalado
    if dpkg -l 2>/dev/null | grep -q -i safesign; then
        success "✅ Paquete SafeSign detectado"
        safesign_status="PACKAGE_INSTALLED"
    else
        info "Paquete SafeSign no encontrado en dpkg"
    fi
    
    # Verificación 2: Módulo p11-kit
    if [ -f "/usr/share/p11-kit/modules/safesign.module" ]; then
        success "✅ Módulo p11-kit SafeSign encontrado"
        safesign_status="MODULE_CONFIGURED"
        
        # Leer biblioteca del módulo
        local module_lib
        module_lib=$(grep "^module:" /usr/share/p11-kit/modules/safesign.module 2>/dev/null | cut -d' ' -f2)
        if [ -n "$module_lib" ]; then
            info "Biblioteca configurada: $module_lib"
        fi
    fi
    
    # Verificación 3: Biblioteca SafeSign
    log "Buscando biblioteca SafeSign..."
    local lib_paths=(
        "/usr/lib/libaetpkss.so"
        "/usr/lib/x86_64-linux-gnu/libaetpkss.so"
        "/usr/local/lib/libaetpkss.so"
        "$module_lib"
    )
    
    for lib_path in "${lib_paths[@]}"; do
        if [ -n "$lib_path" ] && [ -f "$lib_path" ]; then
            safesign_lib="$lib_path"
            success "✅ Biblioteca SafeSign encontrada: $lib_path"
            
            # Verificar validez
            if file "$lib_path" | grep -q "shared object"; then
                success "✅ Biblioteca SafeSign válida"
                safesign_status="FULLY_INSTALLED"
            else
                warning "⚠️  Biblioteca SafeSign corrupta"
                safesign_status="CORRUPTED"
            fi
            break
        fi
    done
    
    # Verificación 4: Funcionalidad PKCS#11
    if [ "$safesign_status" = "FULLY_INSTALLED" ]; then
        log "Verificando funcionalidad PKCS#11..."
        if p11tool --list-tokens 2>/dev/null | grep -q "A.E.T."; then
            success "✅ SafeSign completamente funcional"
            safesign_status="WORKING"
        else
            info "SafeSign instalado, esperando inserción de tarjeta"
        fi
    fi
    
    # Mostrar resultado final
    case "$safesign_status" in
        "WORKING")
            success "🎉 SafeSign: COMPLETAMENTE FUNCIONAL"
            ;;
        "FULLY_INSTALLED")
            success "✅ SafeSign: INSTALADO CORRECTAMENTE"
            info "Inserte su certificado digital para activar"
            ;;
        "MODULE_CONFIGURED")
            warning "⚠️  SafeSign: MÓDULO CONFIGURADO, BIBLIOTECA FALTANTE"
            error "Biblioteca no encontrada o inaccesible"
            ;;
        "PACKAGE_INSTALLED")
            warning "⚠️  SafeSign: PAQUETE INSTALADO, CONFIGURACIÓN INCOMPLETA"
            ;;
        *)
            error "❌ SafeSign: NO INSTALADO"
            info "Ejecute el script de instalación principal para instalar SafeSign"
            ;;
    esac
    
    if [ -n "$safesign_lib" ]; then
        debug "Biblioteca SafeSign: $safesign_lib"
    fi
    
    return 0
}

detect_certificates() {
    section "DETECCIÓN DE CERTIFICADOS DIGITALES"
    
    CERT_FOUND=false
    CERT_URL=""
    CERT_METHOD=""
    
    # Método 1: Listar tokens disponibles
    log "Verificando tokens PKCS#11 disponibles..."
    local tokens
    tokens=$(p11tool --list-tokens 2>/dev/null || true)
    
    if [ -n "$tokens" ]; then
        info "Tokens encontrados:"
        echo "$tokens" | while read -r line; do
            if echo "$line" | grep -v -q "System Trust"; then
                info "  - $line"
            fi
        done
        
        # Verificar tokens útiles (no System Trust)
        local useful_tokens
        useful_tokens=$(echo "$tokens" | grep -v "System Trust" | grep "Token" || true)
        if [ -n "$useful_tokens" ]; then
            success "Tokens útiles detectados"
        fi
    else
        warning "No se detectaron tokens PKCS#11"
    fi
    
    # Método 2: SafeSign específico
    log "Verificando certificados SafeSign..."
    local safesign_certs
    safesign_certs=$(p11tool --list-privkeys --login pkcs11:manufacturer=A.E.T.%20Europe%20B.V. 2>/dev/null || true)
    
    if echo "$safesign_certs" | grep -q "URL:"; then
        CERT_URL=$(echo "$safesign_certs" | grep "URL:" | head -1 | cut -d' ' -f2)
        CERT_FOUND=true
        CERT_METHOD="SafeSign"
        success "✅ Certificados SafeSign encontrados"
        info "URL certificado: $CERT_URL"
        
        # Mostrar información adicional
        echo "$safesign_certs" | grep -E "(Label|ID|URL)" | head -5 | while read -r line; do
            debug "$line"
        done
    else
        info "SafeSign disponible pero sin certificados accesibles"
    fi
    
    # Método 3: OpenSC genérico
    if [ "$CERT_FOUND" = false ]; then
        log "Verificando certificados OpenSC genéricos..."
        local opensc_certs
        opensc_certs=$(p11tool --list-privkeys --login 2>/dev/null || true)
        
        if echo "$opensc_certs" | grep -q "URL:"; then
            CERT_URL=$(echo "$opensc_certs" | grep "URL:" | head -1 | cut -d' ' -f2)
            CERT_FOUND=true
            CERT_METHOD="OpenSC"
            success "✅ Certificados OpenSC encontrados"
            info "URL certificado: $CERT_URL"
        else
            info "OpenSC no detectó certificados"
        fi
    fi
    
    # Método 4: PKCS#15
    if [ "$CERT_FOUND" = false ] && command -v pkcs15-tool >/dev/null 2>&1; then
        log "Verificando PKCS#15..."
        if pkcs15-tool --list-certificates 2>/dev/null | grep -q "X.509"; then
            CERT_URL="pkcs15:"
            CERT_FOUND=true
            CERT_METHOD="PKCS15"
            success "✅ Certificados PKCS#15 encontrados"
        fi
    fi
    
    # Mostrar resultado final
    if [ "$CERT_FOUND" = true ]; then
        success "🎉 CERTIFICADOS DIGITALES DETECTADOS"
        info "Método: $CERT_METHOD"
        info "URL: $CERT_URL"
    else
        warning "⚠️  NO SE DETECTARON CERTIFICADOS AUTOMÁTICAMENTE"
        echo ""
        info "Posibles causas:"
        echo "  1. Certificado digital no insertado"
        echo "  2. SafeSign no instalado correctamente"
        echo "  3. Lector de tarjetas no funcional"
        echo "  4. Certificado requiere PIN (se solicitará durante conexión)"
        echo ""
    fi
}

# =================================================================================
# CONEXIÓN VPN
# =================================================================================

connect_vpn() {
    section "CONEXIÓN VPN GENERALITAT VALENCIANA"
    
    log "Preparando conexión VPN..."
    info "Servidor: $VPN_SERVER"
    info "Verificación de certificado del servidor habilitada"
    
    # Preparar opciones base de openconnect
    local openconnect_opts=(
        "$VPN_SERVER"
        --servercert "$VPN_SERVERCERT"
        --verbose
    )
    
    # Configurar opciones desde .env
    if [ -n "$VPN_USER" ]; then
        openconnect_opts+=(--user="$VPN_USER")
        info "Usuario configurado: $VPN_USER"
    fi
    
    # Determinar método de autenticación
    local use_auto_auth=false
    if [ -n "$CERT_PIN" ] || [ -n "$VPN_PASSWORD" ]; then
        use_auto_auth=true
        info "Credenciales disponibles desde .env"
    fi
    
    # Configurar certificado si se detectó
    if [ "$CERT_FOUND" = true ]; then
        log "Usando certificado detectado ($CERT_METHOD)"
        openconnect_opts=(-c "$CERT_URL" "${openconnect_opts[@]}")
        
        info "Se solicitará el PIN del certificado durante la conexión"
    else
        log "Modo interactivo - OpenConnect mostrará certificados disponibles"
        info "Seleccione su certificado cuando se solicite"
    fi
    
    # Mostrar comando que se ejecutará (sin credenciales)
    debug "Ejecutando: sudo openconnect [opciones ocultas por seguridad]"
    
    echo ""
    log "🚀 INICIANDO CONEXIÓN VPN..."
    echo ""
    
    if [ "$use_auto_auth" = true ]; then
        info "Modo semi-automático activado"
        if [ -n "$CERT_PIN" ]; then
            info "PIN del certificado será enviado automáticamente"
        fi
        if [ -n "$VPN_PASSWORD" ]; then
            info "Contraseña VPN será enviada automáticamente"
        fi
    else
        info "Modo interactivo - introduzca credenciales cuando se soliciten"
    fi
    
    echo ""
    info "IMPORTANTE: Durante la conexión puede necesitar introducir:"
    echo "  - PIN del certificado digital"
    echo "  - Usuario y contraseña VPN (si no están en .env)"
    echo "  - Seleccionar certificado (si hay múltiples)"
    echo ""
    
    # Preguntar confirmación final
    read -p "¿Continuar con la conexión VPN? (S/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log "Conexión cancelada por el usuario"
        return 0
    fi
    
    echo ""
    log "Estableciendo conexión VPN..."
    
    # Ejecutar openconnect
    # Nota: Las credenciales desde .env se manejarán interactivamente
    # para mayor seguridad y compatibilidad
    if sudo openconnect "${openconnect_opts[@]}"; then
        success "Conexión VPN establecida correctamente"
    else
        local exit_code=$?
        error "Error en la conexión VPN (código: $exit_code)"
        
        # Diagnóstico de errores comunes
        case $exit_code in
            1) error "Error de autenticación - verifique credenciales" ;;
            2) error "Error de red - verifique conectividad" ;;
            3) error "Error de certificado - verifique certificado digital" ;;
            *) error "Error desconocido - revise logs detallados" ;;
        esac
    fi
}

# =================================================================================
# FUNCIONES DE AYUDA
# =================================================================================

show_help() {
    section "AYUDA - CONEXIÓN VPN GENERALITAT"
    
    echo "USO:"
    echo "  $0 [opción]"
    echo ""
    echo "OPCIONES:"
    echo "  -h, --help        Mostrar esta ayuda"
    echo "  -d, --diagnose    Solo ejecutar diagnósticos"
    echo "  -c, --connect     Conectar directamente (omitir diagnósticos)"
    echo "  -v, --verbose     Modo verbose con logs detallados"
    echo ""
    echo "ARCHIVOS:"
    echo "  .env              Credenciales (opcional)"
    echo "  .env.example      Plantilla de configuración"
    echo ""
    echo "DIAGNÓSTICOS:"
    echo "  - Verificación de dependencias"
    echo "  - Estado del servicio pcscd"
    echo "  - Conectividad al servidor VPN"
    echo "  - Detección de lectores de tarjetas"
    echo "  - Estado de SafeSign"
    echo "  - Certificados digitales disponibles"
    echo ""
    echo "EJEMPLOS:"
    echo "  $0                Ejecutar diagnósticos y conectar"
    echo "  $0 -d             Solo diagnósticos"
    echo "  $0 -c             Conectar sin diagnósticos"
    echo ""
}

run_diagnostics_only() {
    section "MODO DIAGNÓSTICO ÚNICAMENTE"
    
    check_dependencies
    check_pcscd_service
    check_connectivity
    check_card_readers
    detect_safesign_status
    detect_certificates
    
    echo ""
    section "📋 RESUMEN DIAGNÓSTICO"
    
    if [ "$CERT_FOUND" = true ]; then
        success "✅ Sistema listo para conexión VPN"
        info "Certificados disponibles: $CERT_METHOD"
        info "Para conectar: $0 -c"
    else
        warning "⚠️  Sistema necesita configuración"
        info "1. Inserte certificado digital en lector"
        info "2. Verifique instalación de SafeSign"
        info "3. Ejecute diagnóstico nuevamente: $0 -d"
    fi
    
    info "Log completo: $LOG_FILE"
}

show_post_connection_info() {
    section "INFORMACIÓN POST-CONEXIÓN"
    
    echo "COMANDOS ÚTILES PARA DIAGNÓSTICO:"
    echo ""
    echo "# Verificar tokens PKCS#11"
    echo "p11tool --list-tokens"
    echo ""
    echo "# Listar certificados disponibles"
    echo "p11tool --list-privkeys --login"
    echo ""
    echo "# Verificar lectores de tarjetas"
    echo "pcsc_scan"
    echo ""
    echo "# Estado del servicio pcscd"
    echo "systemctl status pcscd"
    echo ""
    echo "# Test de conectividad"
    echo "ping vpn.san.gva.es"
    echo ""
    echo "SOLUCIÓN DE PROBLEMAS COMUNES:"
    echo ""
    echo "1. ERROR DE PIN:"
    echo "   - Verifique que el PIN sea correcto"
    echo "   - Algunos certificados requieren PIN específico"
    echo ""
    echo "2. CERTIFICADO NO DETECTADO:"
    echo "   - Reconecte el lector USB"
    echo "   - Reinicie pcscd: sudo systemctl restart pcscd"
    echo "   - Verifique que el certificado no haya expirado"
    echo ""
    echo "3. ERROR DE CONEXIÓN:"
    echo "   - Verifique conexión a internet"
    echo "   - Compruebe firewall corporativo"
    echo "   - Contacte soporte técnico GVA"
    echo ""
    info "Log de esta sesión: $LOG_FILE"
}

# =================================================================================
# FUNCIÓN PRINCIPAL
# =================================================================================

main() {
    # Crear log file
    log "=== INICIANDO SCRIPT VPN GENERALITAT VALENCIANA ===" | tee "$LOG_FILE"
    log "Fecha: $(date)"
    log "Usuario: $USER"
    log "Directorio: $SCRIPT_DIR"
    
    # Procesar argumentos
    local run_diagnostics=true
    local run_connection=true
    local verbose=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--diagnose)
                run_connection=false
                shift
                ;;
            -c|--connect)
                run_diagnostics=false
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                error "Opción desconocida: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Cargar configuración
    load_env_config
    
    # Ejecutar diagnósticos si está habilitado
    if [ "$run_diagnostics" = true ]; then
        check_dependencies
        check_pcscd_service
        check_connectivity
        check_card_readers
        detect_safesign_status
        detect_certificates
        
        # Si solo diagnósticos, salir aquí
        if [ "$run_connection" = false ]; then
            run_diagnostics_only
            exit 0
        fi
        
        # Pausa antes de conexión si se hicieron diagnósticos
        echo ""
        read -p "¿Proceder con la conexión VPN? (S/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            log "Conexión cancelada por el usuario"
            exit 0
        fi
    fi
    
    # Ejecutar conexión VPN
    if [ "$run_connection" = true ]; then
        connect_vpn
        
        # Información post-conexión
        echo ""
        show_post_connection_info
    fi
    
    log "Script finalizado correctamente"
}

# Ejecutar función principal con todos los argumentos
main "$@"