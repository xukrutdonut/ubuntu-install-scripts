#!/bin/bash
echo "========================================="
echo "Optimización VirtualBox y Docker para 91GB RAM"
echo "========================================="

# OPTIMIZACIONES VIRTUALBOX
echo -e "\n=== Optimizando VirtualBox VMs ==="

# macOS-Fixed: aumentar a 16GB RAM, 8 CPUs, optimizar rendimiento
echo "Optimizando macOS-Fixed..."
VBoxManage modifyvm "macOS-Fixed" --memory 16384 --cpus 8 --vram 256
VBoxManage modifyvm "macOS-Fixed" --largepages on --vtxvpid on --vtxux on
VBoxManage modifyvm "macOS-Fixed" --cpu-profile "host"
VBoxManage modifyvm "macOS-Fixed" --cpuexecutioncap 100
VBoxManage modifyvm "macOS-Fixed" --paravirtprovider kvm

# Windows11: aumentar a 16GB RAM, 8 CPUs, optimizar
echo "Optimizando Windows11..."
VBoxManage modifyvm "Windows11" --memory 16384 --cpus 8 --vram 128
VBoxManage modifyvm "Windows11" --largepages on --vtxvpid on --vtxux on
VBoxManage modifyvm "Windows11" --nestedpaging on --paravirtprovider kvm

# Android-x86: aumentar a 4GB RAM, 4 CPUs
echo "Optimizando Android-x86..."
VBoxManage modifyvm "Android-x86" --memory 4096 --cpus 4 --vram 256
VBoxManage modifyvm "Android-x86" --largepages on --vtxvpid on --vtxux on

echo -e "\n✓ VirtualBox VMs optimizadas"

# OPTIMIZACIONES DOCKER
echo -e "\n=== Optimizando Docker ==="

sudo mkdir -p /etc/docker

sudo tee /etc/docker/daemon.json << 'DOCKER_CONF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "default-shm-size": "2G",
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
DOCKER_CONF

echo -e "\n✓ Configuración de Docker creada"
echo -e "\nReiniciando Docker..."
sudo systemctl restart docker

echo -e "\n========================================="
echo "✓ Optimización completada"
echo "========================================="
echo -e "\nResumen de asignaciones:"
echo "  • macOS-Fixed: 16GB RAM, 8 CPUs"
echo "  • Windows11: 16GB RAM, 8 CPUs"
echo "  • Android-x86: 4GB RAM, 4 CPUs"
echo "  • Docker: Optimizado con límites aumentados"
echo "  • Total asignado: ~36GB (quedando 55GB libres)"
echo -e "\nVerificando configuración..."
docker info | grep -E "Total Memory|CPUs|Server Version|Storage Driver"
