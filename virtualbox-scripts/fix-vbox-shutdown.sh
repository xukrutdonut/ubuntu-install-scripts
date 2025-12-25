#!/bin/bash
# Script para resolver problemas de apagado de VirtualBox

VM_NAME="Windows11"

echo "=== Aplicando configuraciones para evitar cuelgues al apagar ==="

# Desactivar 3D (causa problemas al apagar)
vboxmanage modifyvm "$VM_NAME" --accelerate3d off

# Desactivar Audio (puede causar hang al apagar)
vboxmanage modifyvm "$VM_NAME" --audio-enabled off

# Usar controlador gráfico VBoxSVGA (más estable)
vboxmanage modifyvm "$VM_NAME" --graphicscontroller vboxsvga

# Desactivar USB 3.0 (puede causar problemas)
vboxmanage modifyvm "$VM_NAME" --usbxhci off

# Habilitar PAE/NX
vboxmanage modifyvm "$VM_NAME" --pae on

# Configurar paravirtualización KVM (más compatible con Windows)
vboxmanage modifyvm "$VM_NAME" --paravirtprovider kvm

echo -e "\n=== Configuración aplicada correctamente ==="
echo ""
echo "RECOMENDACIONES ADICIONALES:"
echo "1. Dentro de Windows: Instalar/actualizar Guest Additions"
echo "2. En Windows: Deshabilitar Hyper-V (Panel de Control > Programas > Activar/Desactivar características)"
echo "3. Al apagar: Usar 'Máquina > ACPI Shutdown' en lugar de cerrar ventana"
echo "4. Si persiste: Ejecutar 'shutdown /s /t 0' dentro de Windows antes de cerrar"
echo ""
vboxmanage showvminfo "$VM_NAME" | grep -E "(State|Graphics|3D|Audio|USB)"
