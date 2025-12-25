#!/bin/bash
VM_UUID="9259f798-13ce-416b-a588-b2769661adf8"
VM_NAME="Windows11"

echo "========================================="
echo "Apagando y reconfigurando Windows11"
echo "========================================="

# Verificar si está corriendo
STATE=$(VBoxManage showvminfo "$VM_UUID" | grep "State:" | awk '{print $2}')
echo "Estado actual: $STATE"

if [ "$STATE" = "running" ]; then
    echo -e "\n1. Enviando señal ACPI de apagado..."
    VBoxManage controlvm "$VM_UUID" acpipowerbutton
    
    echo "2. Esperando apagado limpio (30 segundos)..."
    for i in {30..1}; do
        sleep 1
        STATE=$(VBoxManage showvminfo "$VM_UUID" | grep "State:" | awk '{print $2}')
        if [ "$STATE" = "powered" ]; then
            echo "✓ VM apagada limpiamente"
            break
        fi
        echo -n "."
    done
    echo ""
    
    # Si sigue corriendo, forzar apagado
    STATE=$(VBoxManage showvminfo "$VM_UUID" | grep "State:" | awk '{print $2}')
    if [ "$STATE" = "running" ]; then
        echo "⚠ Apagado limpio falló, forzando apagado..."
        VBoxManage controlvm "$VM_UUID" poweroff
        sleep 3
    fi
fi

echo -e "\n3. Aplicando configuraciones de apagado mejoradas..."

# Configuraciones que funcionan con VM apagada
VBoxManage modifyvm "$VM_UUID" --acpi on --ioapic on
VBoxManage modifyvm "$VM_UUID" --biosapic apic
VBoxManage modifyvm "$VM_UUID" --rtcuseutc off --hpet on
VBoxManage modifyvm "$VM_UUID" --nested-hw-virt off

# ExtraData para mejorar apagado
VBoxManage setextradata "$VM_UUID" "VBoxInternal/PDM/HaltOnReset" "1"
VBoxManage setextradata "$VM_UUID" "VBoxInternal/Devices/acpi/0/Config/PowerButtonHandled" "0"
VBoxManage setextradata "$VM_UUID" "GUI/LastCloseAction" "PowerOff"

echo -e "\n✓ Configuración aplicada exitosamente"
echo -e "\n========================================="
echo "PRÓXIMOS PASOS:"
echo "========================================="
echo "1. Inicia Windows11"
echo "2. Dentro de Windows, abre PowerShell como Administrador"
echo "3. Ejecuta estos comandos:"
echo ""
echo "   powercfg /h off"
echo "   reg add \"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power\" /v HiberbootEnabled /t REG_DWORD /d 0 /f"
echo "   shutdown /r /t 5"
echo ""
echo "4. Después del reinicio, prueba cerrar desde VirtualBox"
echo ""
echo "COMANDO PARA APAGADO LIMPIO DESDE TERMINAL:"
echo "   VBoxManage controlvm Windows11 acpipowerbutton"
echo "========================================="
