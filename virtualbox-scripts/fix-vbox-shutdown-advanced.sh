#!/bin/bash
# Solución avanzada para VirtualBox que se cuelga al apagar

VM_NAME="Windows11"

echo "=== Diagnóstico del problema ==="
echo "El problema común es con EFI/UEFI y el chipset ICH9 en VirtualBox"
echo ""

# Solución 1: Cambiar a BIOS legacy (más estable para apagado)
echo "1. Cambiando EFI a BIOS legacy..."
vboxmanage modifyvm "$VM_NAME" --firmware bios

# Solución 2: Cambiar chipset a PIIX3 (más antiguo pero más estable)
echo "2. Cambiando chipset ICH9 a PIIX3..."
vboxmanage modifyvm "$VM_NAME" --chipset piix3

# Solución 3: Desactivar ACPI temporalmente
# echo "3. Configurando ACPI..."
# vboxmanage modifyvm "$VM_NAME" --acpi on --ioapic on

# Solución 4: Reducir VRAM
echo "4. Reduciendo VRAM a 64MB..."
vboxmanage modifyvm "$VM_NAME" --vram 64

# Solución 5: Desactivar características problemáticas
echo "5. Desactivando características problemáticas..."
vboxmanage modifyvm "$VM_NAME" --nested-hw-virt off
vboxmanage modifyvm "$VM_NAME" --vtxvpid off
vboxmanage modifyvm "$VM_NAME" --large-pages off

# Solución 6: Configurar timeout más agresivo
echo "6. Configurando timeouts..."
vboxmanage setextradata "$VM_NAME" "VBoxInternal/PDM/HaltOnReset" "1"

echo ""
echo "=== IMPORTANTE ==="
echo "ADVERTENCIA: He cambiado EFI a BIOS y ICH9 a PIIX3"
echo "Esto puede hacer que Windows no arranque si fue instalado con EFI"
echo ""
echo "Si Windows no arranca después de estos cambios:"
echo "  vboxmanage modifyvm Windows11 --firmware efi"
echo "  vboxmanage modifyvm Windows11 --chipset ich9"
echo ""
echo "=== Alternativa: Usar poweroff forzado siempre ==="
echo "Añade esto a tu flujo de trabajo:"
echo "  vboxmanage controlvm Windows11 poweroff --force"
echo ""
echo "=== Estado actual ==="
vboxmanage showvminfo "$VM_NAME" | grep -E "(State|Firmware|Chipset|VRAM|Paravirt)"
