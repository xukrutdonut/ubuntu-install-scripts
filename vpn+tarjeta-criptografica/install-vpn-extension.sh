#!/bin/bash

# =================================================================================
# INSTALADOR EXTENSIÓN VPN GVA PARA GNOME SHELL
# =================================================================================
# Instala la extensión VPN GVA en GNOME Shell para gestionar la conexión
# desde el system tray sin necesidad de abrir terminal
# =================================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directorios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSION_SOURCE="$SCRIPT_DIR/vpn-gva-extension"
EXTENSION_UUID="vpn-gva@arkantu.local"
USER_EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"
EXTENSION_DIR="$USER_EXTENSIONS_DIR/$EXTENSION_UUID"

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

section() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🚀 $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

check_gnome_shell() {
    section "VERIFICACIÓN GNOME SHELL"
    
    if ! command -v gnome-shell >/dev/null 2>&1; then
        error "GNOME Shell no encontrado"
        error "Esta extensión requiere GNOME Shell"
        exit 1
    fi
    
    local gnome_version
    gnome_version=$(gnome-shell --version | grep -oE '[0-9]+\.[0-9]+')
    success "GNOME Shell detectado: versión $gnome_version"
    
    # Verificar versión compatible
    local major_version
    major_version=$(echo "$gnome_version" | cut -d. -f1)
    
    if [ "$major_version" -lt 42 ]; then
        warning "Versión de GNOME Shell posiblemente no compatible"
        warning "Se recomienda GNOME Shell 42 o superior"
    else
        success "Versión de GNOME Shell compatible"
    fi
}

check_vpn_script() {
    section "VERIFICACIÓN SCRIPT VPN"
    
    local vpn_script="$SCRIPT_DIR/VPN-SAN-GVA.sh"
    
    if [ ! -f "$vpn_script" ]; then
        error "Script VPN-SAN-GVA.sh no encontrado en $SCRIPT_DIR"
        error "Asegúrese de que el script esté en el mismo directorio"
        exit 1
    fi
    
    if [ ! -x "$vpn_script" ]; then
        log "Haciendo ejecutable el script VPN..."
        chmod +x "$vpn_script"
    fi
    
    success "Script VPN encontrado y ejecutable"
}

install_extension() {
    section "INSTALACIÓN EXTENSIÓN VPN GVA"
    
    # Crear directorio de extensiones si no existe
    if [ ! -d "$USER_EXTENSIONS_DIR" ]; then
        log "Creando directorio de extensiones..."
        mkdir -p "$USER_EXTENSIONS_DIR"
    fi
    
    # Remover instalación anterior si existe
    if [ -d "$EXTENSION_DIR" ]; then
        log "Removiendo instalación anterior..."
        rm -rf "$EXTENSION_DIR"
    fi
    
    # Copiar archivos de la extensión
    log "Instalando archivos de la extensión..."
    cp -r "$EXTENSION_SOURCE" "$EXTENSION_DIR"
    
    success "Extensión instalada en $EXTENSION_DIR"
}

enable_extension() {
    section "HABILITACIÓN EXTENSIÓN"
    
    # Verificar si gnome-extensions está disponible
    if command -v gnome-extensions >/dev/null 2>&1; then
        log "Habilitando extensión con gnome-extensions..."
        
        # Deshabilitar si ya está habilitada (para refrescar)
        gnome-extensions disable "$EXTENSION_UUID" 2>/dev/null || true
        
        # Habilitar extensión
        if gnome-extensions enable "$EXTENSION_UUID"; then
            success "Extensión habilitada correctamente"
        else
            warning "Error habilitando extensión automáticamente"
            log "Habilite manualmente desde Extensiones o Tweaks"
        fi
    else
        warning "gnome-extensions no disponible"
        log "Para habilitar la extensión:"
        log "1. Abra 'Extensiones' (Extensions) desde el menú de aplicaciones"
        log "2. O use GNOME Tweaks"
        log "3. Busque 'VPN GVA Connector' y habilítela"
    fi
}

restart_gnome_shell() {
    section "REINICIO GNOME SHELL"
    
    # Solo en X11, no funciona en Wayland
    if [ "$XDG_SESSION_TYPE" = "x11" ]; then
        log "Reiniciando GNOME Shell para cargar la extensión..."
        log "Presione Alt+F2, escriba 'r' y presione Enter"
        
        read -p "¿Desea que el script reinicie GNOME Shell automáticamente? (s/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            # Método alternativo para reiniciar en X11
            busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart("Reiniciando para cargar extensión VPN GVA")'
        fi
    else
        warning "Sesión Wayland detectada"
        log "En Wayland, debe cerrar sesión y volver a iniciar para cargar la extensión"
        log "O usar 'Extensiones' para habilitar/deshabilitar la extensión"
    fi
}

show_usage_instructions() {
    section "INSTRUCCIONES DE USO"
    
    echo "La extensión VPN GVA ha sido instalada. Características:"
    echo ""
    echo "📍 UBICACIÓN:"
    echo "   • Icono en la barra superior de GNOME (system tray)"
    echo "   • Clic para abrir menú de opciones"
    echo ""
    echo "🎛️  FUNCIONES DISPONIBLES:"
    echo "   • Conectar/Desconectar VPN"
    echo "   • Ejecutar diagnóstico del sistema"
    echo "   • Abrir terminal en el directorio del script"
    echo "   • Configurar credenciales (.env)"
    echo ""
    echo "🔧 CONFIGURACIÓN:"
    echo "   • Cree el archivo .env con sus credenciales"
    echo "   • Use el botón 'Configurar (.env)' del menú"
    echo "   • O copie manualmente: cp .env.example .env"
    echo ""
    echo "📊 ESTADOS DEL ICONO:"
    echo "   • 🔒 Desconectado: icono VPN normal"
    echo "   • 🔄 Conectando: icono con spinner"
    echo "   • ✅ Conectado: icono VPN activo"
    echo "   • ❌ Error: icono de error"
    echo ""
    echo "⚠️  NOTAS IMPORTANTES:"
    echo "   • La extensión ejecuta el script VPN-SAN-GVA.sh"
    echo "   • Se abrirá una terminal para introducir credenciales"
    echo "   • Configure el archivo .env para mayor comodidad"
    echo "   • Use diagnóstico si hay problemas de conexión"
    echo ""
    success "¡Disfrute de su nueva extensión VPN GVA!"
}

main() {
    log "=== INSTALADOR EXTENSIÓN VPN GVA ==="
    log "Instalando extensión GNOME Shell para gestión VPN"
    echo ""
    
    check_gnome_shell
    check_vpn_script
    install_extension
    enable_extension
    restart_gnome_shell
    
    echo ""
    show_usage_instructions
    
    echo ""
    success "Instalación completada correctamente"
    log "Busque el icono VPN en la barra superior de GNOME"
}

# Ejecutar instalación
main "$@"