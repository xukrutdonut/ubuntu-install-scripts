#!/bin/bash

# Script para limpiar repositorios problemáticos
# Especialmente útil para Ubuntu 25.10 (Questing Quetzal) que aún no tiene soporte en algunos PPAs

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

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

log "=== LIMPIEZA DE REPOSITORIOS PROBLEMÁTICOS ==="
echo ""

# Lista de PPAs problemáticos conocidos para Ubuntu 25.10
PROBLEMATIC_PPAS=(
    "flatpak/stable"
    "nilarimogard/webupd8"
    "oguzhaninan/stacer"
    "tomtomtom/woeusb"
    "webupd8team/y-ppa-manager"
)

FIXED_COUNT=0

for ppa in "${PROBLEMATIC_PPAS[@]}"; do
    # Buscar archivos de lista relacionados
    PPA_PATTERN=$(echo "$ppa" | sed 's/\//-/')
    PPA_FILES=$(find /etc/apt/sources.list.d/ -name "*${PPA_PATTERN}*" 2>/dev/null)
    
    if [ -n "$PPA_FILES" ]; then
        echo "$PPA_FILES" | while read -r ppa_file; do
            if [ -f "$ppa_file" ] && grep -q "^deb" "$ppa_file"; then
                warning "Repositorio problemático encontrado: $ppa"
                echo "Archivo: $ppa_file"
                
                # Mostrar contenido actual
                echo "Contenido actual:"
                cat "$ppa_file" | grep "^deb" | head -2
                echo ""
                
                read -p "¿Desea deshabilitar este repositorio? (s/N): " -n 1 -r
                echo
                
                if [[ $REPLY =~ ^[Ss]$ ]]; then
                    # Hacer backup
                    sudo cp "$ppa_file" "${ppa_file}.backup.$(date +%Y%m%d)"
                    
                    # Comentar las líneas
                    sudo sed -i 's/^deb/#deb/g' "$ppa_file"
                    
                    success "Repositorio $ppa deshabilitado"
                    ((FIXED_COUNT++))
                    echo ""
                else
                    log "Repositorio $ppa mantenido activo"
                    echo ""
                fi
            fi
        done
    fi
done

if [ "$FIXED_COUNT" -gt 0 ]; then
    log "Se deshabilitaron $FIXED_COUNT repositorios problemáticos"
    log "Actualizando lista de paquetes..."
    
    if sudo apt update; then
        success "Repositorios actualizados correctamente"
    else
        warning "Hubo algunos errores al actualizar repositorios"
    fi
else
    log "No se encontraron repositorios problemáticos activos"
fi

echo ""
log "=== VERIFICACIÓN FINAL ==="

# Mostrar repositorios activos
echo "Repositorios activos:"
find /etc/apt/sources.list.d/ -name "*.list" -exec grep -l "^deb" {} \; 2>/dev/null | while read -r file; do
    echo "  - $(basename "$file")"
done

echo ""
log "Para revertir cambios, use los archivos .backup creados en /etc/apt/sources.list.d/"