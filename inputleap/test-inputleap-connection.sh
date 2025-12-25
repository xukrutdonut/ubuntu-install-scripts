#!/bin/bash

echo "=== Prueba de Conexión InputLeap ==="
echo

# Verificar estado del servicio
echo "1. Estado del servicio InputLeap:"
sudo systemctl status inputleap-autostart.service --no-pager

echo
echo "2. Logs recientes:"
sudo journalctl -u inputleap-autostart.service --no-pager -n 20

echo
echo "3. Procesos InputLeap activos:"
ps aux | grep -i inputleap | grep -v grep

echo
echo "4. Conectividad al servidor (192.168.0.114:24800):"
timeout 5 nc -zv 192.168.0.114 24800 2>&1 || echo "No se puede conectar al servidor"

echo
echo "5. Información de red:"
ip route | grep default
echo "IP local: $(hostname -I)"

echo
echo "=== Comandos útiles ==="
echo "Reiniciar servicio:    sudo systemctl restart inputleap-autostart.service"
echo "Ver logs en tiempo real: sudo journalctl -u inputleap-autostart.service -f"
echo "Deshabilitar servicio: sudo systemctl disable inputleap-autostart.service"