#!/bin/bash

echo "=== Configuración Input Leap ==="
echo ""
echo "Input Leap permite compartir teclado y ratón entre múltiples computadoras."
echo ""

# Función para mostrar ayuda
show_help() {
    echo "Configuración paso a paso:"
    echo ""
    echo "1. SERVIDOR (computadora principal):"
    echo "   - Abre Input Leap desde el menú de aplicaciones"
    echo "   - Selecciona 'Configure interactively'"
    echo "   - Arrastra la pantalla 'Unnamed screen' para posicionar tu Surface"
    echo "   - Haz doble clic en 'Unnamed screen' y nómbrala 'surface'"
    echo "   - Configura > Start > Start Server"
    echo ""
    echo "2. CLIENTE (Surface):"
    echo "   - Abre Input Leap"
    echo "   - Selecciona 'Use another computer's shared keyboard and mouse (client)'"
    echo "   - Introduce la IP del servidor: [IP_DEL_SERVIDOR]"
    echo "   - Start > Start Client"
    echo ""
    echo "3. VERIFICAR CONEXIÓN:"
    echo "   - Mueve el ratón hacia el borde donde configuraste la Surface"
    echo "   - El ratón debería 'saltar' a la Surface"
    echo "   - El teclado funcionará en la pantalla activa"
    echo ""
    echo "📋 Configuración de ejemplo incluida en: input-leap-server.conf"
    echo ""
}

# Función para obtener IP local
get_local_ip() {
    echo "🌐 Tu IP local es:"
    ip route get 1 2>/dev/null | awk '{print $7}' | head -1 || \
    hostname -I | awk '{print $1}'
    echo ""
}

# Función para abrir puertos del firewall
configure_firewall() {
    echo "🔥 Configurando firewall para Input Leap..."
    
    if command -v ufw >/dev/null 2>&1; then
        echo "Abriendo puerto 24800 (Input Leap)..."
        sudo ufw allow 24800/tcp
        echo "✅ Puerto 24800 abierto"
    else
        echo "⚠️  UFW no encontrado. Configura manualmente el puerto 24800/tcp"
    fi
    echo ""
}

# Función principal
case "$1" in
    "help"|"")
        show_help
        ;;
    "ip")
        get_local_ip
        ;;
    "firewall")
        configure_firewall
        ;;
    "server")
        echo "🖥️  Iniciando modo servidor..."
        flatpak run com.github.input_leap.input-leap --server
        ;;
    "client")
        if [ -z "$2" ]; then
            echo "❌ Especifica la IP del servidor:"
            echo "   $0 client 192.168.1.100"
            exit 1
        fi
        echo "🖱️  Conectando a servidor: $2"
        flatpak run com.github.input_leap.input-leap --client "$2"
        ;;
    *)
        echo "Uso: $0 [help|ip|firewall|server|client IP]"
        echo ""
        echo "Ejemplos:"
        echo "  $0 help                    # Mostrar guía completa"
        echo "  $0 ip                      # Mostrar IP local"
        echo "  $0 firewall                # Configurar firewall"
        echo "  $0 server                  # Iniciar como servidor"
        echo "  $0 client 192.168.1.100    # Conectar a servidor"
        ;;
esac
