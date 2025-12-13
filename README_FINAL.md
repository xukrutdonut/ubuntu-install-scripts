# Ubuntu Install Scripts - Versión Unificada

Script de instalación completo y unificado para Ubuntu con detección automática de hardware y configuración modular.

## 📋 Características Principales

### 🔍 Detección Automática de Hardware
- **Microsoft Surface Pro 7/8/9**: Configuración específica de touchscreen, stylus y optimizaciones
- **Geekom GT13 Pro / GT2 Mega**: Optimizaciones para mini PC
- **Hardware genérico**: Configuración base compatible

### 🎛️ Sistema Modular
- Instalación por módulos seleccionables
- Menú interactivo intuitivo
- Posibilidad de instalación completa automática
- Manejo robusto de errores y timeouts

### 📦 Software Incluido
- **Sistema base**: Repositorios, herramientas básicas, apt-fast
- **Firefox**: Eliminación de snap, instalación desde Mozilla
- **Flatpak**: Configuración de Flathub y aplicaciones esenciales
- **Multimedia**: GIMP, VLC, codecs, herramientas de audio/video
- **Productividad**: LibreOffice, Zotero, OBS Studio
- **Certificados digitales**: SafeSign, OpenSC, configuración GyD
- **Drivers específicos**: DisplayLink, Surface touchscreen, GPU

## 🚀 Uso

### Instalación Completa (Recomendado)
```bash
chmod +x instalacion_unificada_ubuntu.sh
./instalacion_unificada_ubuntu.sh
# Seleccionar opción 99 para instalación automática completa
```

### Instalación Modular
```bash
./instalacion_unificada_ubuntu.sh
# Seleccionar módulos individuales desde el menú
```

### Solo VPN (Sin instalación del sistema)
```bash
chmod +x VPN-SAN-GVA.sh
./VPN-SAN-GVA.sh
```

## 📂 Archivos Principales

### Scripts de Instalación
- `instalacion_unificada_ubuntu.sh` - Script principal de instalación
- `VPN-SAN-GVA.sh` - Conexión VPN Generalitat (independiente)

### Archivos de Soporte
- `diagnostico-vpn-completo.sh` - Diagnóstico avanzado VPN
- `diagnostico-vpn.sh` - Diagnóstico básico VPN
- `.env.example` - Plantilla de configuración VPN

### Directorios Especializados
- `displaylink/` - Scripts para pantallas USB DisplayLink
- `touchscreen/` - Configuraciones específicas de touchscreen
- `intel/` - Optimizaciones para hardware Intel
- `MacOS/` - Scripts para macOS (separado)

## 🔧 Módulos de Instalación

### Módulos Básicos
1. **Sistema Base** - Repositorios, herramientas fundamentales
2. **Firefox** - Eliminación snap, instalación Mozilla
3. **Flatpak** - Tienda Flathub y configuración

### Software Esencial  
4. **Multimedia** - GIMP, VLC, codecs
5. **Herramientas del Sistema** - Timeshift, Synaptic, TLP
6. **Productividad** - LibreOffice, Zotero, herramientas ofimática

### Certificados y VPN
7. **Certificados Digitales** - SafeSign, OpenSC, módulos PKCS#11
8. **Configuración VPN** - OpenConnect, scripts de conexión

### Hardware Específico
9. **Surface Touchscreen** - Solo si se detecta hardware Surface
10. **Configuración Touchscreen** - Solo si se detecta touchscreen
11. **DisplayLink** - Soporte pantallas USB (opcional)
12. **Drivers Adicionales** - GPU, WiFi, firmware

### Aplicaciones
13. **Multimedia y Entretenimiento** - Spotify, reproductores
14. **Comunicación** - WhatsApp, Telegram, Discord  
15. **Herramientas Desarrollo** - VSCode, Node.js, Python (opcional)

## 🔐 Certificados Digitales y VPN

### Configuración Automática
El script detecta y configura automáticamente:
- SafeSign IC Standard (para Ubuntu < 25.04)
- OpenSC como alternativa (Ubuntu 25.04+)
- Módulos PKCS#11
- Servicio pcscd

### Conexión VPN Optimizada
- Detección automática de certificados
- Diagnóstico completo del sistema
- Manejo de errores robusto
- Soporte para configuración .env
- Logs detallados

### Uso de VPN
```bash
# Diagnóstico completo y conexión
./VPN-SAN-GVA.sh

# Solo diagnóstico
./VPN-SAN-GVA.sh -d

# Conexión directa (sin diagnósticos)
./VPN-SAN-GVA.sh -c

# Ayuda
./VPN-SAN-GVA.sh -h
```

## 📊 Informes y Logs

### Informes Automáticos
- `informe_instalacion_YYYYMMDD_HHMMSS.md` - Resumen detallado de instalación
- `instalacion_YYYYMMDD_HHMMSS.log` - Log completo de instalación
- `vpn_connection_YYYYMMDD_HHMMSS.log` - Logs de conexiones VPN

### Contenido de Informes
- ✅ Paquetes instalados exitosamente
- ❌ Paquetes con errores  
- ⚠️ Advertencias del sistema
- 🔧 Scripts y configuraciones creadas
- 🚀 Pasos siguientes recomendados

## 🛠️ Características Técnicas

### Manejo de Errores
- No se detiene por timeouts de servidores
- Continúa con la siguiente tarea en caso de error
- Registro detallado de todos los errores
- Resumen final con estadísticas

### Compatibilidad
- **Ubuntu 22.04 LTS** ✅
- **Ubuntu 24.04 LTS** ✅  
- **Ubuntu 25.04+** ✅ (con adaptaciones)

### Detección de Hardware
- Información DMI del sistema
- Dispositivos USB conectados
- Dispositivos PCI
- Características específicas (touchscreen, GPU, WiFi)

## 🔄 Migración desde Scripts Anteriores

Los siguientes scripts han sido **unificados** y **eliminados**:
- `instalacion_completa_ubuntu.sh` → `instalacion_unificada_ubuntu.sh`
- `instalacion_ubuntu_alberto.sh` → `instalacion_unificada_ubuntu.sh`  
- `InstalaciónGyD.sh` → Módulo 7 del script unificado
- `VPN-SAN-GVA-*.sh` → `VPN-SAN-GVA.sh`
- `install_safesign.sh` → Módulo 7 del script unificado
- Scripts auxiliares → Integrados en el script principal

## 🆘 Solución de Problemas

### Errores Comunes

**Error: "No se detectaron certificados"**
```bash
# Verificar lector USB conectado
lsusb | grep -i reader

# Reiniciar servicio
sudo systemctl restart pcscd

# Diagnóstico completo
./VPN-SAN-GVA.sh -d
```

**Error: "Paquete no encontrado"**
- El script continúa automáticamente
- Los errores se registran en el informe
- Verificar conectividad de repositorios

**Problemas de Hardware específico**
- Surface: Verificar que iptsd esté activo
- DisplayLink: Requiere reinicio después de instalación
- Drivers: Usar ubuntu-drivers para autodetección

### Logs y Diagnóstico
```bash
# Ver último log de instalación
ls -t instalacion_*.log | head -1 | xargs less

# Ver último informe
ls -t informe_*.md | head -1 | xargs cat

# Diagnóstico VPN completo
./diagnostico-vpn-completo.sh
```

## 📞 Soporte

1. **Revisar informes generados** automáticamente
2. **Consultar logs detallados** en archivos .log
3. **Ejecutar diagnósticos específicos** con scripts incluidos
4. **Verificar compatibilidad** de hardware detectado

---

**Versión**: 1.0  
**Última actualización**: $(date +%Y-%m-%d)  
**Compatibilidad**: Ubuntu 22.04+ con detección automática de hardware