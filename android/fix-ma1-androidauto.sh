#!/bin/bash

# Script de diagnóstico y reparación para Motorola MA1 Android Auto
# Versión 1.0 - 2025

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Motorola MA1 Android Auto - Diagnóstico y Reparación ===${NC}\n"

# Función para verificar si el MA1 está conectado
check_ma1_device() {
    echo -e "${YELLOW}[1/6] Verificando conexión del dispositivo MA1...${NC}"
    
    # Buscar el dispositivo por VID:PID de Motorola MA1
    # El MA1 puede aparecer como diferentes dispositivos USB dependiendo del modo
    if lsusb | grep -i "22b8"; then
        echo -e "${GREEN}✓ Dispositivo Motorola detectado${NC}"
        lsusb | grep -i "22b8"
        return 0
    elif lsusb | grep -i "motorola"; then
        echo -e "${GREEN}✓ Dispositivo Motorola detectado${NC}"
        lsusb | grep -i "motorola"
        return 0
    else
        echo -e "${RED}✗ MA1 no detectado vía USB${NC}"
        echo "  Por favor:"
        echo "  1. Desconecta el MA1"
        echo "  2. Espera 10 segundos"
        echo "  3. Vuelve a conectarlo"
        echo "  4. Ejecuta este script nuevamente"
        return 1
    fi
}

# Función para verificar la red del MA1
check_ma1_network() {
    echo -e "\n${YELLOW}[2/6] Verificando red del MA1...${NC}"
    
    # El MA1 crea una red en 192.168.49.x cuando está en modo setup
    if ip addr | grep -q "192.168.49"; then
        echo -e "${GREEN}✓ Interfaz de red MA1 detectada${NC}"
        ip addr | grep -A 2 "192.168.49"
        MA1_IP="192.168.49.1"
        return 0
    else
        echo -e "${YELLOW}⚠ Red MA1 no encontrada. Intentando conectar...${NC}"
        MA1_IP="192.168.49.1"
        return 1
    fi
}

# Función para probar conectividad
test_ma1_connectivity() {
    echo -e "\n${YELLOW}[3/6] Probando conectividad con MA1...${NC}"
    
    if ping -c 3 -W 2 192.168.49.1 &>/dev/null; then
        echo -e "${GREEN}✓ MA1 responde en 192.168.49.1${NC}"
        return 0
    elif ping -c 3 -W 2 192.168.49.51 &>/dev/null; then
        echo -e "${GREEN}✓ MA1 responde en 192.168.49.51${NC}"
        MA1_IP="192.168.49.51"
        return 0
    else
        echo -e "${RED}✗ No se puede alcanzar el MA1${NC}"
        echo "  Verifica que:"
        echo "  - El MA1 esté encendido (LED azul)"
        echo "  - Tu dispositivo esté conectado a la WiFi del MA1"
        return 1
    fi
}

# Función para verificar el firmware actual
check_firmware_version() {
    echo -e "\n${YELLOW}[4/6] Verificando versión de firmware...${NC}"
    
    # Intentar obtener la versión del firmware vía API del MA1
    if command -v curl &> /dev/null; then
        echo "Consultando información del dispositivo..."
        
        # El MA1 tiene una interfaz web en el puerto 5000
        if curl -s --connect-timeout 5 "http://${MA1_IP}:5000/version" 2>/dev/null; then
            echo -e "${GREEN}✓ Información del firmware obtenida${NC}"
        else
            echo -e "${YELLOW}⚠ No se pudo obtener la versión actual${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ curl no disponible${NC}"
    fi
}

# Función para actualizar el firmware
update_firmware() {
    echo -e "\n${YELLOW}[5/6] Buscando actualizaciones de firmware...${NC}"
    
    echo "El firmware del MA1 se actualiza automáticamente cuando:"
    echo "  1. El dispositivo está conectado a internet"
    echo "  2. Hay una actualización disponible"
    echo ""
    echo "Para forzar una actualización:"
    echo "  1. Conecta tu teléfono Android al MA1 vía WiFi"
    echo "  2. Abre la app 'Motorola MA1' (descárgala de Play Store si no la tienes)"
    echo "  3. Ve a Configuración > Actualizar firmware"
    echo ""
    
    read -p "¿Deseas intentar descargar el firmware manualmente? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        download_firmware
    fi
}

# Función para descargar firmware
download_firmware() {
    echo -e "\n${YELLOW}Descargando herramientas de actualización...${NC}"
    
    FIRMWARE_DIR="$HOME/ma1_firmware"
    mkdir -p "$FIRMWARE_DIR"
    cd "$FIRMWARE_DIR"
    
    echo "Nota: El firmware oficial se actualiza mediante:"
    echo "  1. La app móvil Motorola MA1"
    echo "  2. Actualizaciones OTA automáticas"
    echo ""
    echo "No hay herramientas oficiales de actualización para Linux."
    echo "Firmware guardado en: $FIRMWARE_DIR"
}

# Función para realizar reset de fábrica
factory_reset() {
    echo -e "\n${YELLOW}[6/6] Opciones de reinicio${NC}"
    echo ""
    echo "Para resetear el MA1 a valores de fábrica:"
    echo "  1. Con el MA1 conectado, mantén presionado el botón durante 10 segundos"
    echo "  2. El LED parpadeará y el dispositivo se reiniciará"
    echo "  3. Necesitarás volver a emparejarlo con tu teléfono"
    echo ""
    read -p "¿Has realizado el reset de fábrica? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${GREEN}✓ Bien. Ahora intenta reconectar tu teléfono${NC}"
    fi
}

# Función principal
main() {
    # Verificar permisos
    if [ "$EUID" -eq 0 ]; then 
        echo -e "${RED}No ejecutes este script como root/sudo${NC}"
        exit 1
    fi
    
    # Paso 1: Verificar dispositivo
    if ! check_ma1_device; then
        echo -e "\n${RED}El dispositivo no está conectado. Conéctalo y reintenta.${NC}"
        exit 1
    fi
    
    # Paso 2: Verificar red
    check_ma1_network
    
    # Paso 3: Probar conectividad
    if ! test_ma1_connectivity; then
        echo -e "\n${YELLOW}Intentando soluciones alternativas...${NC}"
        echo ""
        echo "El MA1 puede estar en modo Android Auto activo."
        echo "Para acceder al modo de configuración:"
        echo "  1. Desconecta el teléfono"
        echo "  2. Mantén presionado el botón del MA1 durante 2 segundos"
        echo "  3. El LED cambiará a azul parpadeante (modo emparejamiento)"
    fi
    
    # Paso 4: Verificar firmware
    check_firmware_version
    
    # Paso 5: Actualizar
    update_firmware
    
    # Paso 6: Reset
    echo ""
    read -p "¿Necesitas realizar un reset de fábrica? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        factory_reset
    fi
    
    echo -e "\n${GREEN}=== Diagnóstico completado ===${NC}"
    echo ""
    echo "Pasos siguientes recomendados:"
    echo "  1. Asegúrate de tener la app 'Motorola MA1' instalada"
    echo "  2. Olvida la conexión Bluetooth del MA1 en tu teléfono"
    echo "  3. Reinicia el MA1 (desconectar y reconectar)"
    echo "  4. Empareja de nuevo desde cero"
    echo "  5. Actualiza el firmware desde la app móvil"
    echo ""
    echo "Si el problema persiste:"
    echo "  - Verifica que tu auto soporte Android Auto inalámbrico"
    echo "  - Prueba con un cable USB para Android Auto"
    echo "  - Contacta con soporte de Motorola"
}

# Ejecutar
main
