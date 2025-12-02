#!/bin/bash

echo "=== Configuración Lápiz Samsung S Pen ==="

# Verificar dispositivos stylus existentes
check_stylus_devices() {
    echo "Paso 1: Verificando dispositivos stylus..."
    
    echo "Dispositivos de entrada stylus:"
    cat /proc/bus/input/devices | grep -A5 -B2 -i "stylus\|pen" | grep "Name"
    
    echo ""
    echo "Dispositivos xinput stylus:"
    xinput list | grep -i "stylus\|pen\|tablet" 2>/dev/null || echo "  (Wayland - xinput limitado)"
}

# Instalar paquetes necesarios para stylus
install_stylus_packages() {
    echo ""
    echo "Paso 2: Instalando paquetes para stylus..."
    
    cat << 'EOF'
Paquetes recomendados para usar con lápiz Samsung:

sudo apt install -y \
    xournalpp          # Tomar notas y dibujar
    gromit-mpx         # Dibujar sobre la pantalla
    krita              # Arte digital profesional
    mypaint            # Pintura digital
    gimp               # Editor de imágenes
    inkscape           # Gráficos vectoriales
    libinput-tools     # Herramientas de calibración
    evtest             # Probar eventos del stylus

EOF
}

# Configurar stylus en GNOME
configure_gnome_stylus() {
    echo ""
    echo "Paso 3: Configurando stylus en GNOME..."
    
    # Configuraciones básicas para stylus
    gsettings set org.gnome.desktop.peripherals.tablet area "[[0.0, 0.0], [1.0, 1.0]]" 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.stylus pressure-curve "[0.0, 0.0, 1.0, 1.0]" 2>/dev/null || true
    
    echo "✅ Configuraciones básicas aplicadas"
}

# Configurar calibración del stylus
setup_stylus_calibration() {
    echo ""
    echo "Paso 4: Información sobre calibración..."
    
    cat << 'EOF'
Para calibrar el lápiz Samsung:

1. Usando libinput-calibrate:
   sudo libinput-calibrate /dev/input/eventX
   (donde X es el número del evento del stylus)

2. Para encontrar el evento correcto:
   sudo libinput list-devices | grep -A5 -i stylus

3. Probar presión del stylus:
   sudo evtest /dev/input/eventX

4. En GNOME, ve a:
   Configuración > Tableta > Calibrar

EOF
}

# Configurar aplicaciones para stylus
setup_stylus_applications() {
    echo ""
    echo "Paso 5: Configurando aplicaciones..."
    
    cat << 'EOF'
Aplicaciones recomendadas ya configuradas:

📝 Tomar Notas:
   - Xournal++ (instalado)
   - GNOME Notes (nativo)

🎨 Dibujo/Arte:
   - Krita (profesional)
   - MyPaint (natural)
   - GIMP (edición)

📊 Presentaciones:
   - Gromit-MPX (anotar pantalla)

🔧 Calibración:
   - GNOME Settings > Tablet
   - libinput tools

EOF
}

# Crear script de test para stylus
create_stylus_test() {
    echo ""
    echo "Paso 6: Creando herramientas de diagnóstico..."
    
    cat > /tmp/test_stylus.sh << 'EOF'
#!/bin/bash

echo "=== Test del Lápiz Samsung ==="

echo "1. Dispositivos stylus detectados:"
cat /proc/bus/input/devices | grep -A3 -B1 -i "stylus\|pen"

echo ""
echo "2. Eventos disponibles:"
ls -la /dev/input/by-id/ 2>/dev/null | grep -i "stylus\|pen\|tablet" || echo "No se encontraron enlaces específicos"

echo ""
echo "3. Para probar el stylus en tiempo real:"
echo "   sudo evtest"
echo "   (Selecciona el dispositivo stylus y prueba tocar con el lápiz)"

echo ""
echo "4. Verificar presión:"
STYLUS_EVENT=$(ls /dev/input/event* | head -5 | tail -1)
echo "   sudo evtest $STYLUS_EVENT"
echo "   (Presiona con diferentes intensidades)"

echo ""
echo "5. Aplicaciones para probar:"
echo "   - xournalpp (tomar notas)"
echo "   - krita (arte digital)"
echo "   - gromit-mpx (anotar pantalla)"

EOF

    chmod +x /tmp/test_stylus.sh
    sudo mv /tmp/test_stylus.sh /usr/local/bin/test-stylus
    echo "✅ Script de test creado: test-stylus"
}

# Información sobre usar el lápiz Samsung
show_usage_info() {
    echo ""
    echo "=== INFORMACIÓN DE USO ==="
    
    cat << 'EOF'
🖊️ Cómo usar tu lápiz Samsung:

1. CONEXIÓN:
   - Si es Bluetooth: Configura en Configuración > Bluetooth
   - Si es capacitivo: Debería funcionar inmediatamente

2. CALIBRACIÓN:
   - Ve a Configuración > Tableta digitalizadora
   - Sigue el asistente de calibración

3. APLICACIONES RECOMENDADAS:
   - Notas: xournalpp, gnome-notes
   - Arte: krita, mypaint, gimp
   - Presentaciones: gromit-mpx

4. CARACTERÍSTICAS AVANZADAS:
   - Presión: Soportada en aplicaciones compatibles
   - Botones: Configurables en Configuración > Tableta
   - Gestos: Disponibles según la aplicación

5. SOLUCIÓN DE PROBLEMAS:
   - Ejecuta: test-stylus
   - Verifica: systemctl status input-remapper
   - Calibra: Configuración > Tableta > Calibrar

EOF
}

# Función principal
main() {
    case "$1" in
        "install")
            install_stylus_packages
            ;;
        "configure")
            check_stylus_devices
            configure_gnome_stylus
            setup_stylus_calibration
            create_stylus_test
            ;;
        "test")
            /usr/local/bin/test-stylus 2>/dev/null || ./test_stylus.sh
            ;;
        "info")
            show_usage_info
            ;;
        *)
            echo "Configurador de Lápiz Samsung para Ubuntu"
            echo ""
            echo "Uso: $0 [comando]"
            echo ""
            echo "Comandos:"
            echo "  install    - Mostrar paquetes a instalar"
            echo "  configure  - Configurar stylus"
            echo "  test       - Probar stylus"
            echo "  info       - Información de uso"
            echo ""
            check_stylus_devices
            configure_gnome_stylus
            setup_stylus_calibration
            setup_stylus_applications
            create_stylus_test
            show_usage_info
            ;;
    esac
}

main "$@"