#!/bin/bash

# Verificar que existe la ISO
if [ ! -f ~/Downloads/android-x86_64-9.0-r2.iso ]; then
    echo "Error: No se encuentra la ISO en ~/Downloads/android-x86_64-9.0-r2.iso"
    echo "Por favor descárgala primero desde android-x86.org"
    exit 1
fi

# Crear VM de Android
VBoxManage createvm --name "Android-x86" --ostype "Linux_64" --register

# Configurar memoria y CPU
VBoxManage modifyvm "Android-x86" --memory 4096 --cpus 2

# Crear disco virtual (20GB)
VBoxManage createhd --filename "$HOME/VirtualBox VMs/Android-x86/Android-x86.vdi" --size 20480

# Crear controlador SATA y adjuntar disco
VBoxManage storagectl "Android-x86" --name "SATA Controller" --add sata --controller IntelAHCI
VBoxManage storageattach "Android-x86" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$HOME/VirtualBox VMs/Android-x86/Android-x86.vdi"

# Crear controlador IDE para la ISO
VBoxManage storagectl "Android-x86" --name "IDE Controller" --add ide
VBoxManage storageattach "Android-x86" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium ~/Downloads/android-x86_64-9.0-r2.iso

# Configurar video y red
VBoxManage modifyvm "Android-x86" --vram 128
VBoxManage modifyvm "Android-x86" --nic1 nat
VBoxManage modifyvm "Android-x86" --audio-driver pulse --audio-enabled on
VBoxManage modifyvm "Android-x86" --graphicscontroller vmsvga

# Habilitar aceleración 3D
VBoxManage modifyvm "Android-x86" --accelerate3d on

echo "¡VM creada exitosamente!"
echo "Ahora puedes iniciar la VM con: VBoxManage startvm Android-x86"
echo "O desde la interfaz gráfica de VirtualBox"
