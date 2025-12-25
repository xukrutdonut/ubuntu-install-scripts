#!/bin/bash

################################################################################
#                                                                              #
#            BAMBUSTUDIO LAUNCHER - Solución para Intel Arrow Lake            #
#                                                                              #
#  Problema: BambuStudio se congela con Intel Arrow Lake Graphics             #
#  Solución: Múltiples modos de ejecución (Flatpak, Software, Balanceado)    #
#                                                                              #
#  Uso: ./bambustudio-launcher.sh [modo]                                      #
#        Modos: flatpak, software, balanced, appimage                         #
#        Sin argumento: muestra menú interactivo                              #
#                                                                              #
################################################################################

VERSION="1.0"
FECHA="24 diciembre 2024"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar banner
show_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║        BAMBUSTUDIO LAUNCHER - Intel Arrow Lake Fix          ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Función para detener procesos anteriores
stop_bambustudio() {
    echo -e "${YELLOW}Deteniendo procesos anteriores de BambuStudio...${NC}"
    pkill -9 -f "bambu-studio" 2>/dev/null
    pkill -9 -f "BambuStudio" 2>/dev/null
    pkill -9 -f "com.bambulab.BambuStudio" 2>/dev/null
    sleep 1
}

# Función para limpiar configuración
clean_config() {
    echo -e "${YELLOW}¿Limpiar configuración corrupta? (s/n)${NC}"
    read -r response
    if [[ "$response" =~ ^[Ss]$ ]]; then
        echo "Respaldando configuración..."
        BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
        mv ~/.config/BambuStudio ~/.config/BambuStudio.backup-$BACKUP_DATE 2>/dev/null
        mv ~/.cache/BambuStudio ~/.cache/BambuStudio.backup-$BACKUP_DATE 2>/dev/null
        mv ~/.local/share/BambuStudio ~/.local/share/BambuStudio.backup-$BACKUP_DATE 2>/dev/null
        echo -e "${GREEN}✓ Configuración limpiada${NC}"
    fi
}

# Modo 1: Flatpak (RECOMENDADO)
launch_flatpak() {
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  MODO: FLATPAK (Recomendado para Arrow Lake)${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    
    if ! flatpak list | grep -q "com.bambulab.BambuStudio"; then
        echo -e "${RED}Error: BambuStudio Flatpak no está instalado${NC}"
        echo "Instalar con: flatpak install flathub com.bambulab.BambuStudio"
        exit 1
    fi
    
    stop_bambustudio
    
    echo "Iniciando BambuStudio Flatpak (sin variables problemáticas)..."
    flatpak run com.bambulab.BambuStudio "$@" 2>&1 | tee ~/bambustudio.log &
    
    echo -e "${GREEN}✓ BambuStudio Flatpak iniciado${NC}"
    echo "Log: ~/bambustudio.log"
}

# Modo 2: Software Rendering (LENTO pero ESTABLE)
launch_software() {
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  MODO: SOFTWARE RENDERING (Lento pero no se congela)${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}ADVERTENCIA: Será MUY LENTO pero estable${NC}"
    echo "- No muevas la vista 3D frecuentemente"
    echo "- Evita modelos muy complejos"
    
    stop_bambustudio
    
    # Forzar software rendering completo
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    export MESA_LOADER_DRIVER_OVERRIDE=swrast
    
    APPIMAGE="/home/arkantu/BambuStudio-v02.04.00.70.AppImage.old"
    
    if [ ! -f "$APPIMAGE" ]; then
        echo -e "${RED}Error: No se encuentra $APPIMAGE${NC}"
        echo "Versiones disponibles:"
        ls -lh /home/arkantu/BambuStudio*.AppImage* 2>/dev/null
        exit 1
    fi
    
    "$APPIMAGE" "$@" 2>&1 | tee ~/bambustudio.log &
    
    echo -e "${GREEN}✓ BambuStudio iniciado en modo software${NC}"
    echo "Log: ~/bambustudio.log"
}

# Modo 3: Balanceado (AppImage con optimizaciones)
launch_balanced() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  MODO: BALANCEADO (Optimizado para Arrow Lake)${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    
    stop_bambustudio
    
    # Configuración balanceada para Intel Arrow Lake
    export MESA_GL_VERSION_OVERRIDE=4.5
    export __GL_SYNC_TO_VBLANK=0
    export MESA_NO_DITHER=1
    export vblank_mode=0
    export __GL_YIELD="NOTHING"
    export OMP_NUM_THREADS=4
    export OMP_WAIT_POLICY=PASSIVE
    
    APPIMAGE="/home/arkantu/BambuStudio-v02.04.00.70.AppImage.old"
    
    if [ ! -f "$APPIMAGE" ]; then
        echo -e "${RED}Error: No se encuentra $APPIMAGE${NC}"
        echo "Versiones disponibles:"
        ls -lh /home/arkantu/BambuStudio*.AppImage* 2>/dev/null
        exit 1
    fi
    
    "$APPIMAGE" "$@" 2>&1 | tee ~/bambustudio.log &
    
    PID=$!
    echo -e "${GREEN}✓ BambuStudio iniciado (PID: $PID)${NC}"
    echo "Log: ~/bambustudio.log"
}

# Modo 4: AppImage simple (sin optimizaciones)
launch_appimage() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  MODO: APPIMAGE SIMPLE (Sin optimizaciones)${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    
    stop_bambustudio
    
    APPIMAGE="/home/arkantu/BambuStudio-v02.04.00.70.AppImage.old"
    
    if [ ! -f "$APPIMAGE" ]; then
        echo -e "${RED}Error: No se encuentra $APPIMAGE${NC}"
        echo "Versiones disponibles:"
        ls -lh /home/arkantu/BambuStudio*.AppImage* 2>/dev/null
        exit 1
    fi
    
    "$APPIMAGE" "$@" 2>&1 | tee ~/bambustudio.log &
    
    echo -e "${GREEN}✓ BambuStudio iniciado${NC}"
    echo "Log: ~/bambustudio.log"
}

# Menú interactivo
show_menu() {
    show_banner
    echo "Selecciona el modo de ejecución:"
    echo ""
    echo "  1) Flatpak           - Recomendado para Arrow Lake (ACTUAL)"
    echo "  2) Software          - Lento pero estable"
    echo "  3) Balanceado        - AppImage con optimizaciones"
    echo "  4) AppImage Simple   - Sin optimizaciones"
    echo ""
    echo "  c) Limpiar configuración corrupta"
    echo "  q) Salir"
    echo ""
    echo -n "Opción: "
    read -r option
    
    case $option in
        1)
            launch_flatpak
            ;;
        2)
            launch_software
            ;;
        3)
            launch_balanced
            ;;
        4)
            launch_appimage
            ;;
        c|C)
            clean_config
            show_menu
            ;;
        q|Q)
            echo "Saliendo..."
            exit 0
            ;;
        *)
            echo -e "${RED}Opción inválida${NC}"
            sleep 1
            show_menu
            ;;
    esac
}

# Script principal
main() {
    # Si se pasa un argumento, ejecutar directamente
    if [ $# -gt 0 ]; then
        case "$1" in
            flatpak)
                shift
                launch_flatpak "$@"
                ;;
            software)
                shift
                launch_software "$@"
                ;;
            balanced)
                shift
                launch_balanced "$@"
                ;;
            appimage)
                shift
                launch_appimage "$@"
                ;;
            clean)
                clean_config
                ;;
            --help|-h)
                show_banner
                echo "Uso: $0 [modo]"
                echo ""
                echo "Modos disponibles:"
                echo "  flatpak    - Ejecutar Flatpak (recomendado)"
                echo "  software   - Software rendering (lento pero estable)"
                echo "  balanced   - AppImage con optimizaciones"
                echo "  appimage   - AppImage sin optimizaciones"
                echo "  clean      - Limpiar configuración"
                echo ""
                echo "Sin argumentos: muestra menú interactivo"
                ;;
            *)
                echo -e "${RED}Modo desconocido: $1${NC}"
                echo "Usa: flatpak, software, balanced, appimage"
                echo "O ejecuta sin argumentos para menú interactivo"
                exit 1
                ;;
        esac
    else
        # Menú interactivo si no se pasan argumentos
        show_menu
    fi
}

# Ejecutar
main "$@"
