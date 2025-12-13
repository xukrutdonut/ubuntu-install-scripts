#!/bin/bash

# Script de diagnóstico rápido para VPN SAN GVA
# Fecha: 2025-12-08

echo "=== DIAGNÓSTICO RÁPIDO VPN SAN-GVA ==="
echo ""

echo "1. Dependencias:"
echo -n "  - openconnect: "
command -v openconnect >/dev/null 2>&1 && echo "✅ Instalado" || echo "❌ No instalado"
echo -n "  - p11tool: "
command -v p11tool >/dev/null 2>&1 && echo "✅ Instalado" || echo "❌ No instalado"
echo -n "  - pcsc_scan: "
command -v pcsc_scan >/dev/null 2>&1 && echo "✅ Instalado" || echo "❌ No instalado"

echo ""
echo "2. Servicios:"
echo -n "  - pcscd: "
systemctl is-active --quiet pcscd 2>/dev/null && echo "✅ Activo" || echo "❌ Inactivo"

echo ""
echo "3. Hardware:"
echo "  - Lectores USB detectados:"
lsusb | grep -i -E "(smart|card|reader|aet|gemalto|omnikey)" || echo "    Ninguno específico detectado"

if command -v pcsc_scan >/dev/null 2>&1; then
    echo "  - Lectores pcscd:"
    timeout 3s pcsc_scan 2>/dev/null | grep "Reader" || echo "    Ninguno detectado"
fi

echo ""
echo "4. SafeSign:"
echo -n "  - Instalación: "
dpkg -l 2>/dev/null | grep -q -i safesign && echo "✅ Instalado" || echo "❌ No instalado"

echo -n "  - Biblioteca: "
if [ -f "/usr/lib/libaetpkss.so" ] || [ -f "/usr/lib/x86_64-linux-gnu/libaetpkss.so" ]; then
    echo "✅ Encontrada"
else
    echo "❌ No encontrada"
fi

echo ""
echo "5. Certificados:"
if p11tool --list-tokens 2>/dev/null | grep -v "System Trust" | grep -q "Token"; then
    echo "  ✅ Tokens PKCS#11 detectados"
else
    echo "  ❌ No se detectaron tokens útiles"
fi

echo ""
echo "=== FIN DEL DIAGNÓSTICO ==="
echo ""
echo "Para solucionar problemas:"
echo "1. Instalar dependencias: sudo apt install openconnect gnutls-bin pcsc-tools opensc"
echo "2. Iniciar pcscd: sudo systemctl start pcscd"
echo "3. Instalar SafeSign: sudo dpkg -i SafeSign_IC_Standard_Linux.deb"
echo "4. Ejecutar VPN: ./VPN-SAN-GVA.sh"