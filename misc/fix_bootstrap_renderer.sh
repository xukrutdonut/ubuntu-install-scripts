#!/bin/bash
# Script para corregir el error de compatibilidad en el renderer de Bootstrap

cd /home/arkantu/moodlesagunto

# Hacer backup del archivo original
sudo cp theme/bootstrap/renderers/core_renderer.php theme/bootstrap/renderers/core_renderer.php.backup

# Aplicar la corrección
sudo sed -i 's/public function notification($message, $classes = '\''notifyproblem'\'')/public function notification($message, $type = null, $closebutton = true)/' theme/bootstrap/renderers/core_renderer.php

# También necesitamos actualizar la lógica interna para usar $type en lugar de $classes
sudo sed -i 's/$classes == '\''notifyproblem'\''/$type == '\''notifyproblem'\'' || $type === null/' theme/bootstrap/renderers/core_renderer.php
sudo sed -i 's/$classes == '\''notifywarning'\''/$type == '\''notifywarning'\''/' theme/bootstrap/renderers/core_renderer.php
sudo sed -i 's/$classes == '\''notifysuccess'\''/$type == '\''notifysuccess'\'' || $type == '\''success'\''/' theme/bootstrap/renderers/core_renderer.php

echo "Corrección aplicada. Verifica el archivo theme/bootstrap/renderers/core_renderer.php"
