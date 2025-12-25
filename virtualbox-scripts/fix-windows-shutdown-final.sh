#!/bin/bash
VM_UUID="9259f798-13ce-416b-a588-b2769661adf8"
VM_NAME="Windows11"

echo "========================================="
echo "Solución definitiva apagado Windows11"
echo "========================================="

echo -e "\n1. Configurando ACPI mejorado..."
VBoxManage modifyvm "$VM_UUID" --acpi on --ioapic on

echo "2. Habilitando APM (Advanced Power Management)..."
VBoxManage modifyvm "$VM_UUID" --biosapic apic

echo "3. Configurando RTC y HPET..."
VBoxManage modifyvm "$VM_UUID" --rtcuseutc off --hpet on

echo "4. Desactivando características que causan problemas en apagado..."
VBoxManage modifyvm "$VM_UUID" --nested-hw-virt off

echo "5. Configurando timeouts ACPI agresivos..."
VBoxManage setextradata "$VM_UUID" "VBoxInternal/PDM/HaltOnReset" "1"
VBoxManage setextradata "$VM_UUID" "VBoxInternal/TM/WarpDrivePercentage" "100"

echo "6. Mejorando señales ACPI para Windows..."
VBoxManage setextradata "$VM_UUID" "GUI/LastCloseAction" "PowerOff"

echo "7. Configurando apagado ACPI limpio..."
VBoxManage setextradata "$VM_UUID" "VBoxInternal/Devices/acpi/0/Config/SLICTable" ""

echo -e "\n=== Verificando configuración ==="
VBoxManage showvminfo "$VM_UUID" | grep -E "ACPI|IOAPIC|HPET|RTC|Firmware|Chipset"

echo -e "\n========================================="
echo "✓ Configuración aplicada"
echo "========================================="
echo -e "\nAHORA DENTRO DE WINDOWS:"
echo "1. Abre PowerShell como Administrador"
echo "2. Ejecuta: powercfg /h off"
echo "3. Ejecuta: reg add \"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power\" /v HiberbootEnabled /t REG_DWORD /d 0 /f"
echo "4. Reinicia Windows"
echo ""
echo "Para cerrar Windows limpiamente desde host:"
echo "  VBoxManage controlvm \"$VM_NAME\" acpipowerbutton"
echo "  (espera 10-15 segundos)"
echo ""
echo "Si no responde después de 30 seg:"
echo "  VBoxManage controlvm \"$VM_NAME\" poweroff"
echo "========================================="
