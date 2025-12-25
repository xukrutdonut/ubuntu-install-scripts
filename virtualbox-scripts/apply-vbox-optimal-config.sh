#!/bin/bash
VM_NAME="Windows11"

echo "=== Configuración segura para apagado correcto ==="
echo ""

# Esperar a que la VM esté apagada
if vboxmanage showvminfo "$VM_NAME" | grep -q "running"; then
    echo "⚠️  La VM debe estar apagada para aplicar cambios"
    echo "Apágala primero y luego ejecuta este script"
    exit 1
fi

# 1. Desactivar Nested VT-x (causa problemas de apagado)
echo "1. Desactivando Nested VT-x..."
vboxmanage modifyvm "$VM_NAME" --nested-hw-virt off

# 2. Desactivar VT-x VPID (puede causar cuelgues)
echo "2. Desactivando VT-x VPID..."
vboxmanage modifyvm "$VM_NAME" --vtxvpid off

# 3. Desactivar Large Pages
echo "3. Desactivando Large Pages..."
vboxmanage modifyvm "$VM_NAME" --large-pages off

# 4. Desactivar aceleración 3D
echo "4. Desactivando aceleración 3D..."
vboxmanage modifyvm "$VM_NAME" --accelerate3d off

# 5. Configurar GUI para usar shutdown ACPI
echo "5. Configurando comportamiento de cierre de ventana..."
vboxmanage setextradata "$VM_NAME" "GUI/LastCloseAction" "Shutdown"
vboxmanage setextradata "$VM_NAME" "GUI/DefaultCloseAction" "Shutdown"

# 6. Reducir VRAM si es muy alto (opcional, comentado por defecto)
# echo "6. Ajustando VRAM..."
# vboxmanage modifyvm "$VM_NAME" --vram 64

echo ""
echo "✅ Configuración aplicada correctamente"
echo ""
echo "=== Configuración actual ==="
vboxmanage showvminfo "$VM_NAME" | grep -E "(Nested|VPID|Large|Graphics|3D)"
echo ""
echo "=== Próximos pasos DENTRO de Windows ==="
echo "1. Desactivar inicio rápido:"
echo "   powercfg /h off"
echo ""
echo "2. Desactivar Hyper-V (si está instalado):"
echo "   bcdedit /set hypervisorlaunchtype off"
echo ""
echo "3. Instalar Guest Additions actualizados"
echo ""
echo "4. CRUCIAL - Registro de Windows (cmd como Admin):"
echo '   reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f'
echo ""
echo "Después de estos cambios, al cerrar la ventana de VirtualBox"
echo "se enviará señal ACPI y Windows se apagará limpiamente."
