#!/bin/bash
# =============================================================================
# Setup Bit4id Middleware + Tarjeta Criptográfica CNS (BIT4ID JCOP4 / NXP SecID P71)
# Probado en: Ubuntu 25.10 + pcscd 2.3.3 + kernel 6.17
#
# Tarjeta: BIT4ID JCOP4 (NXP SecID P71) - ACCV/FNMT - Conselleria de Sanidad GVA
# Lectores probados:
#   - Sveon SLW20 (Alcor Micro AU9540) ✅ RECOMENDADO
#   - C3PO LTC31 v2 (0783:0006)        ❌ Fallo hardware (no hace PowerOn)
#
# FIXES APLICADOS (problemas con Ubuntu 25.10):
#   1. libccid 1.6.x tiene regresión con tarjetas CNS → downgrade a 1.5.5
#   2. Bit4id Card Manager usa libpcsclite.so.1 bundled incompatible con pcscd 2.x
#   3. USB autosuspend desactiva los lectores → reglas udev necesarias
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()     { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIT4ID_URL="https://cdn.bit4id.com/es/soporte/downloads/middleware/Bit4id_Middleware.zip"
LIBCCID_155_URL="http://archive.ubuntu.com/ubuntu/pool/universe/c/ccid/libccid_1.5.5-1_amd64.deb"

echo ""
echo "========================================================"
echo "   Setup Bit4id Middleware - Tarjeta Criptográfica GVA"
echo "========================================================"
echo ""

# ── 1. Dependencias base ──────────────────────────────────────────────────────
log "Instalando dependencias base..."
sudo apt install -y pcscd libccid pcsc-tools opensc gnutls-bin unzip curl
success "Dependencias instaladas"

# ── 2. Downgrade libccid a 1.5.5 ─────────────────────────────────────────────
# libccid 1.6.x tiene una regresión: las tarjetas BIT4ID JCOP4/CNS no emiten ATR
LIBCCID_VER=$(dpkg -l libccid 2>/dev/null | grep "^ii" | awk '{print $3}')
log "Versión actual de libccid: $LIBCCID_VER"

if dpkg --compare-versions "$LIBCCID_VER" "gt" "1.5.5"; then
    warn "libccid $LIBCCID_VER tiene regresión con tarjetas CNS → instalando 1.5.5"
    TMP_DEB=$(mktemp /tmp/libccid_1.5.5_XXXXXX.deb)
    curl -sL "$LIBCCID_155_URL" -o "$TMP_DEB"
    sudo dpkg -i "$TMP_DEB"
    rm -f "$TMP_DEB"
    success "libccid 1.5.5 instalado"
else
    success "libccid $LIBCCID_VER OK (no requiere downgrade)"
fi

# Fijar versión para evitar upgrades accidentales
sudo apt-mark hold libccid
success "libccid fijado en versión actual (apt-mark hold)"

# ── 3. Instalar Bit4id Middleware ─────────────────────────────────────────────
if ! dpkg -l libbit4xpki &>/dev/null; then
    log "Descargando Bit4id Middleware desde ACCV ($BIT4ID_URL)..."
    TMP_ZIP=$(mktemp /tmp/Bit4id_XXXXXX.zip)
    curl -L "$BIT4ID_URL" -o "$TMP_ZIP"
    TMP_DIR=$(mktemp -d /tmp/bit4id_XXXXXX)
    unzip -q "$TMP_ZIP" -d "$TMP_DIR"
    DEB_FILE=$(find "$TMP_DIR" -name "*.deb" | head -1)
    if [ -z "$DEB_FILE" ]; then
        error "No se encontró .deb en el zip descargado"
        exit 1
    fi
    sudo dpkg -i "$DEB_FILE"
    rm -rf "$TMP_ZIP" "$TMP_DIR"
    success "Bit4id Middleware instalado: $(dpkg -l libbit4xpki | grep "^ii" | awk '{print $3}')"
else
    success "Bit4id Middleware ya instalado: $(dpkg -l libbit4xpki | grep "^ii" | awk '{print $3}')"
fi

# ── 4. Fix: libpcsclite bundled incompatible con pcscd 2.x ───────────────────
# El Bit4id Card Manager incluye su propia libpcsclite.so.1 compilada para pcscd 1.9.x
# Con pcscd 2.x devuelve SCARD_E_NO_SERVICE (0x8010001E)
BUNDLED_LIB="/usr/share/bit4id/x/pinmanager/lib/libpcsclite.so.1"
SYSTEM_LIB="/usr/lib/x86_64-linux-gnu/libpcsclite.so.1"

if [ -f "$BUNDLED_LIB" ] && [ -f "$SYSTEM_LIB" ]; then
    BUNDLED_SIZE=$(stat -c%s "$BUNDLED_LIB")
    SYSTEM_SIZE=$(stat -c%s "$SYSTEM_LIB")
    if [ "$BUNDLED_SIZE" != "$SYSTEM_SIZE" ]; then
        warn "Reemplazando libpcsclite bundled de Bit4id con versión del sistema..."
        sudo cp "$BUNDLED_LIB" "${BUNDLED_LIB}.bak"
        sudo cp "$SYSTEM_LIB" "$BUNDLED_LIB"
        success "libpcsclite del sistema copiada al Card Manager"
    else
        success "libpcsclite bundled ya está sincronizada"
    fi
fi

# ── 5. Reglas udev: deshabilitar autosuspend USB en lectores ─────────────────
UDEV_RULES_FILE="/etc/udev/rules.d/92-smartcard-readers.rules"
if [ ! -f "$UDEV_RULES_FILE" ]; then
    log "Instalando reglas udev para lectores de tarjeta..."
    sudo tee "$UDEV_RULES_FILE" > /dev/null << 'EOF'
# Desactivar USB autosuspend en lectores de tarjeta criptográfica
# Sin esto, el lector se suspende y la tarjeta aparece como "Unresponsive"

# C3PO LTC31 v2 (0783:0006)
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0783", ATTR{idProduct}=="0006", ATTR{power/control}="on"

# Sveon SLW20 / Alcor Micro AU9540 (058f:9540)
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="058f", ATTR{idProduct}=="9540", ATTR{power/control}="on"
EOF
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    success "Reglas udev instaladas"
else
    success "Reglas udev ya existen"
fi

# ── 6. Habilitar y arrancar pcscd ─────────────────────────────────────────────
log "Habilitando pcscd..."
sudo systemctl enable pcscd.socket pcscd
sudo systemctl restart pcscd
sleep 2
if systemctl is-active --quiet pcscd; then
    success "pcscd activo"
else
    error "pcscd no arrancó correctamente"
    sudo systemctl status pcscd --no-pager
    exit 1
fi

# ── 7. Configurar módulo PKCS#11 en p11-kit ───────────────────────────────────
P11KIT_MODULE="/usr/share/p11-kit/modules/bit4id.module"
if [ ! -f "$P11KIT_MODULE" ]; then
    log "Registrando módulo Bit4id en p11-kit..."
    sudo tee "$P11KIT_MODULE" > /dev/null << 'EOF'
module: /usr/lib/bit4id/libbit4xpki.so
EOF
    success "Módulo Bit4id registrado en p11-kit"
fi

# ── 8. Verificación final ─────────────────────────────────────────────────────
echo ""
echo "========================================================"
log "Verificando instalación..."
echo ""

# Verificar lector
log "Lectores detectados:"
timeout 5 pcsc_scan -t 4 2>/dev/null | grep -E "Reader|Card state|ATR" || warn "No se detectaron lectores (inserta la tarjeta)"

echo ""

# Verificar PKCS11
log "Verificando módulo Bit4id PKCS#11..."
if pkcs11-tool --module /usr/lib/bit4id/libbit4xpki.so --list-slots 2>/dev/null | grep -q "token label"; then
    success "Tarjeta detectada por Bit4id:"
    pkcs11-tool --module /usr/lib/bit4id/libbit4xpki.so --list-slots 2>/dev/null | grep -E "token label|token model|serial"
else
    warn "No se detectó tarjeta. Asegúrate de que el lector Sveon está conectado con la tarjeta insertada."
fi

echo ""
echo "========================================================"
echo ""
success "Instalación completada"
echo ""
echo "  Módulo PKCS#11:  /usr/lib/bit4id/libbit4xpki.so"
echo "  Card Manager:    /usr/share/bit4id/x/bit4pin.sh"
echo ""
echo "  Para Firefox:"
echo "    Preferencias → Privacidad → Dispositivos de Seguridad"
echo "    → Cargar → /usr/lib/bit4id/libbit4xpki.so"
echo ""
echo "  Para VPN SAN GVA:"
echo "    ./VPN-SAN-GVA-MEJORADO.sh"
echo ""
