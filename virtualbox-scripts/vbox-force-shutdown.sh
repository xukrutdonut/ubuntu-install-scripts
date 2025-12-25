#!/bin/bash
# Script para apagar VirtualBox de forma forzada (sin colgar)

VM_NAME="${1:-Windows11}"

echo "=== Método de apagado forzado para VirtualBox ==="
echo "VM: $VM_NAME"
echo ""

# Intentar apagado ACPI primero
echo "1. Intentando ACPI shutdown (5 segundos)..."
vboxmanage controlvm "$VM_NAME" acpipowerbutton 2>/dev/null &
ACPI_PID=$!

sleep 5

# Verificar si sigue ejecutándose
if vboxmanage showvminfo "$VM_NAME" 2>/dev/null | grep -q "running"; then
    echo "   ACPI no funcionó, probando poweroff..."
    vboxmanage controlvm "$VM_NAME" poweroff 2>/dev/null
    sleep 2
fi

# Si todavía está colgado, matar el proceso
if vboxmanage showvminfo "$VM_NAME" 2>/dev/null | grep -q "stopping\|running"; then
    echo "   VM bloqueada, matando proceso..."
    VM_PID=$(ps aux | grep "[V]irtualBoxVM.*$VM_NAME" | awk '{print $2}')
    if [ -n "$VM_PID" ]; then
        kill -9 $VM_PID
        echo "   Proceso $VM_PID eliminado"
    fi
fi

sleep 2
echo ""
echo "=== Estado final ==="
vboxmanage showvminfo "$VM_NAME" 2>/dev/null | grep State || echo "VM detenida"
