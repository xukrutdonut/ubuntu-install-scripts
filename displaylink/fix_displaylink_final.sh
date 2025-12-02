#!/bin/bash
# Solución definitiva para DisplayLink tearing

echo "=== FIX DEFINITIVO DISPLAYLINK ==="

# 1. Usar compositor alternativo (compton/picom)
sudo apt install -y picom

# 2. Configurar picom para DisplayLink
mkdir -p ~/.config/picom
cat > ~/.config/picom/picom.conf << 'EOF'
backend = "glx";
vsync = true;
glx-no-stencil = true;
glx-no-rebind-pixmap = true;
use-damage = false;
refresh-rate = 60;

# Reglas específicas para DisplayLink
wintypes: {
    tooltip = { fade = true; shadow = false; opacity = 0.85; focus = true; };
    dock = { shadow = false; };
    dnd = { shadow = false; };
    popup_menu = { opacity = 0.85; };
    dropdown_menu = { opacity = 0.85; };
};
EOF

# 3. Matar GNOME Shell y usar picom
killall gnome-shell 2>/dev/null || true
picom --config ~/.config/picom/picom.conf &

echo "Compositor alternativo iniciado. Las rayas deberían desaparecer."
echo "Para volver a GNOME Shell: killall picom && gnome-shell --replace &"