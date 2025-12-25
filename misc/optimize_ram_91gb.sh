#!/bin/bash
echo "=== Optimizando sistema para 91GB de RAM ==="

# Aplicar configuraciones temporalmente
echo "Aplicando configuraciones..."
sudo sysctl vm.swappiness=10
sudo sysctl vm.vfs_cache_pressure=50
sudo sysctl vm.dirty_ratio=15
sudo sysctl vm.dirty_background_ratio=5
sudo sysctl fs.file-max=2097152
sudo sysctl vm.max_map_count=262144

# Hacer permanente
echo ""
echo "Haciendo cambios permanentes en /etc/sysctl.conf..."
sudo tee -a /etc/sysctl.conf << 'CONF'

# Optimización de RAM para 91GB (añadido el $(date))
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=15
vm.dirty_background_ratio=5
fs.file-max=2097152
vm.max_map_count=262144
CONF

echo ""
echo "=== Configuración aplicada ==="
echo "Verificando valores actuales:"
sysctl vm.swappiness vm.vfs_cache_pressure vm.dirty_ratio vm.dirty_background_ratio
echo ""
echo "✓ Optimización completada"
