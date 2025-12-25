#!/bin/bash
# Script de prueba para verificar que el apagado funciona

VM_NAME="Windows11"

echo "=== Test de apagado de VirtualBox ==="
echo ""
echo "1. Inicia la VM Windows11"
echo "2. Ejecuta los comandos de ~/windows-shutdown-fix-commands.txt"
echo "3. Luego ejecuta este script para probar el apagado"
echo ""
read -p "¿La VM está lista para probar? (s/n): " READY

if [ "$READY" != "s" ]; then
    echo "Abortado. Prepara la VM primero."
    exit 0
fi

echo ""
echo "Enviando señal ACPI shutdown..."
vboxmanage controlvm "$VM_NAME" acpipowerbutton

echo "Esperando 30 segundos para apagado limpio..."
for i in {30..1}; do
    echo -ne "  $i segundos restantes...\r"
    sleep 1
    
    # Verificar si ya se apagó
    STATE=$(vboxmanage showvminfo "$VM_NAME" 2>/dev/null | grep "State:" | cut -d: -f2 | xargs | cut -d' ' -f1)
    if [ "$STATE" = "powered" ]; then
        echo -e "\n✅ VM apagada correctamente en $(( 30 - i )) segundos"
        exit 0
    fi
done

echo ""
STATE=$(vboxmanage showvminfo "$VM_NAME" 2>/dev/null | grep "State:")
echo "Estado actual: $STATE"

if echo "$STATE" | grep -q "powered off\|aborted"; then
    echo "✅ VM apagada correctamente"
elif echo "$STATE" | grep -q "stopping"; then
    echo "❌ VM todavía bloqueada en 'stopping'"
    echo "Ejecutando forzado..."
    ~/vbox-force-shutdown.sh "$VM_NAME"
else
    echo "⚠️  Estado inesperado, forzando apagado..."
    ~/vbox-force-shutdown.sh "$VM_NAME"
fi
