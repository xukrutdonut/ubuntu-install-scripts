#!/bin/bash

# Script para configurar macOS Ventura en VirtualBox
# NOTA: Solo para propósitos educativos y con hardware Apple

set -e

VM_NAME="macOS_Ventura_New"
RAM="8192"
VRAM="128"
CPU_COUNT="4"
DISK_SIZE="80000"

echo "=== Configurando macOS Ventura en VirtualBox ==="
echo "IMPORTANTE: Este script es solo para propósitos educativos."
echo "Necesitas una licencia válida de macOS y ejecutarlo en hardware Apple."
echo

# Verificar que VirtualBox esté instalado
if ! command -v VBoxManage &> /dev/null; then
    echo "Error: VirtualBox no está instalado."
    exit 1
fi

# Crear la máquina virtual
echo "1. Creando máquina virtual '$VM_NAME'..."
VBoxManage createvm --name "$VM_NAME" --ostype "MacOS_64" --register

# Configurar memoria y CPU
echo "2. Configurando memoria RAM (${RAM}MB) y CPUs (${CPU_COUNT})..."
VBoxManage modifyvm "$VM_NAME" --memory "$RAM"
VBoxManage modifyvm "$VM_NAME" --cpus "$CPU_COUNT"

# Configurar video
echo "3. Configurando video..."
VBoxManage modifyvm "$VM_NAME" --vram "$VRAM"
VBoxManage modifyvm "$VM_NAME" --graphicscontroller vmsvga

# Crear disco duro virtual
echo "4. Creando disco duro virtual (${DISK_SIZE}MB)..."
VBoxManage createhd --filename "$HOME/VirtualBox VMs/$VM_NAME/$VM_NAME.vdi" --size "$DISK_SIZE"

# Configurar controlador SATA
echo "5. Configurando controlador de almacenamiento..."
VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAHCI
VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$HOME/VirtualBox VMs/$VM_NAME/$VM_NAME.vdi"

# Configuraciones específicas para macOS
echo "6. Aplicando configuraciones específicas para macOS..."
VBoxManage modifyvm "$VM_NAME" --firmware efi
VBoxManage modifyvm "$VM_NAME" --chipset ich9
VBoxManage modifyvm "$VM_NAME" --mouse usbtablet
VBoxManage modifyvm "$VM_NAME" --keyboard usb

# Configurar red
echo "7. Configurando red..."
VBoxManage modifyvm "$VM_NAME" --nic1 nat

# Configuraciones adicionales para macOS (requeridas para boot)
echo "8. Aplicando configuraciones EFI para macOS..."
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct" "iMac19,1"
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion" "1.0"
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct" "Mac-AA95B1DDAB278B95"
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/smc/0/Config/DeviceKey" "ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/smc/0/Config/GetKeyFromRealSMC" 1

# Configurar resolución
VBoxManage setextradata "$VM_NAME" "VBoxInternal2/EfiGraphicsResolution" "1920x1080"

echo
echo "=== Configuración completada ==="
echo "Nombre de la VM: $VM_NAME"
echo "RAM: ${RAM}MB"
echo "CPUs: $CPU_COUNT"
echo "Disco: ${DISK_SIZE}MB"
echo
echo "PRÓXIMOS PASOS:"
echo "1. Descarga macOS Ventura desde la App Store (en Mac) o crea un instalador USB"
echo "2. Convierte el instalador a formato ISO si es necesario"
echo "3. Monta la ISO en la VM:"
echo "   VBoxManage storageattach '$VM_NAME' --storagectl 'SATA Controller' --port 1 --device 0 --type dvddrive --medium /ruta/a/ventura.iso"
echo "4. Inicia la VM: VBoxManage startvm '$VM_NAME'"
echo
echo "NOTA LEGAL: Solo usa este setup si tienes una licencia válida de macOS"
echo "y estás ejecutando en hardware Apple según los términos de Apple."