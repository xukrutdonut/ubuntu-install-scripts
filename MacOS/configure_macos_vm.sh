#!/bin/bash

VM_NAME="macOS-Working"
ISO_PATH="/home/arkantu/Descargas/Monterey 12.iso"

echo "🍎 Configurando macOS para VirtualBox..."

# Eliminar VM existente si existe
VBoxManage unregistervm "$VM_NAME" --delete 2>/dev/null

# Crear nueva VM
VBoxManage createvm --name "$VM_NAME" --ostype "MacOS_64" --register

# Configuración básica
VBoxManage modifyvm "$VM_NAME" \
    --memory 4096 \
    --cpus 2 \
    --vram 128 \
    --firmware efi \
    --chipset ich9 \
    --mouse ps2 \
    --keyboard ps2 \
    --rtcuseutc on \
    --audio-driver pulse \
    --audio-controller hda \
    --nic1 nat \
    --nictype1 82540EM \
    --usbohci on \
    --usbehci on

# Configuraciones EFI críticas para macOS
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct" "iMac11,3"
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion" "1.0"
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct" "Iloveapple"
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/smc/0/Config/DeviceKey" "ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/smc/0/Config/GetKeyFromRealSMC" 1

# Configuraciones adicionales
VBoxManage setextradata "$VM_NAME" "VBoxInternal2/EfiGraphicsResolution" "1280x720"
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemVendor" "Apple Inc."
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemFamily" "iMac"
VBoxManage setextradata "$VM_NAME" "VBoxInternal/TM/TSCMode" "RealTSCOffset"

# CPU específico
VBoxManage modifyvm "$VM_NAME" --cpu-profile "Intel Core2 X6800 2.93GHz"

# Crear disco
VBoxManage createmedium disk --filename "$HOME/VirtualBox VMs/$VM_NAME/macOS.vdi" --size 81920 --format VDI

# Configurar almacenamiento
VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAHCI
VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$HOME/VirtualBox VMs/$VM_NAME/macOS.vdi"

VBoxManage storagectl "$VM_NAME" --name "IDE Controller" --add ide --controller PIIX4
VBoxManage storageattach "$VM_NAME" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "$ISO_PATH"

# Configurar arranque
VBoxManage modifyvm "$VM_NAME" --boot1 dvd --boot2 disk --boot3 none --boot4 none

echo "✅ VM configurada. Iniciando..."
VBoxManage startvm "$VM_NAME" --type gui
