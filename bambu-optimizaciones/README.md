# BambuStudio - Solución para Intel Arrow Lake Graphics

## Problema
BambuStudio se congela constantemente con Intel Arrow Lake Graphics debido a bugs conocidos en las versiones 2.3+ y 2.4+.

## Solución
Script unificado con múltiples modos de ejecución para diferentes escenarios.

## Uso

### Modo Interactivo (Recomendado)
```bash
./bambustudio-launcher.sh
```
Muestra un menú para seleccionar el modo de ejecución.

### Modo Directo
```bash
# Flatpak (recomendado para Arrow Lake)
./bambustudio-launcher.sh flatpak

# Software rendering (lento pero estable)
./bambustudio-launcher.sh software

# Balanceado con optimizaciones
./bambustudio-launcher.sh balanced

# AppImage simple sin optimizaciones
./bambustudio-launcher.sh appimage

# Limpiar configuración corrupta
./bambustudio-launcher.sh clean
```

## Modos Disponibles

### 1. Flatpak (RECOMENDADO)
- **Mejor compatibilidad** con hardware Intel Arrow Lake nuevo
- Sin variables de entorno problemáticas
- Usa la versión de Flathub
- **Estado**: Funcionando correctamente

### 2. Software Rendering
- Renderizado por software (llvmpipe)
- **MUY LENTO** pero garantiza que no se congela
- Útil para login, configuración inicial y tareas básicas
- No usar para modelado 3D intensivo

### 3. Balanceado
- AppImage con optimizaciones para Arrow Lake
- Balance entre rendimiento y estabilidad
- Variables de entorno ajustadas (MESA_GL_VERSION_OVERRIDE=4.5, etc.)

### 4. AppImage Simple
- Sin optimizaciones ni variables de entorno
- Configuración por defecto del sistema
- Puede funcionar o no dependiendo de los drivers

## Requisitos

### Para modo Flatpak
```bash
flatpak install flathub com.bambulab.BambuStudio
```

### Para modos AppImage
Tener al menos una de estas versiones:
- `BambuStudio-v02.04.00.70.AppImage.old` (recomendado)
- `BambuStudio-v02.03.01.51.AppImage.old`
- Otras versiones AppImage

## Solución de Problemas

### Si sigue congelándose

1. **Actualizar drivers Intel**:
```bash
sudo dnf update --refresh mesa-* intel-* libdrm*
sudo reboot
```

2. **Limpiar configuración**:
```bash
./bambustudio-launcher.sh clean
```

3. **Usar modo software** (lento pero funcional):
```bash
./bambustudio-launcher.sh software
```

4. **Descargar versión más antigua**:
```bash
# Versión v02.02.00.24 (más estable)
wget -O ~/BambuStudio-v02.02.00.24.AppImage \
  "https://github.com/bambulab/BambuStudio/releases/download/v02.02.00.24/BambuStudio-v02.02.00.24-Linux-x86_64.AppImage"
chmod +x ~/BambuStudio-v02.02.00.24.AppImage
```

### Logs
Los logs se guardan automáticamente en:
```
~/bambustudio.log
```

## Información Técnica

### Hardware Afectado
- Intel Arrow Lake Graphics (Integrated)
- Puede afectar otras GPUs Intel nuevas

### Versiones Problemáticas
- BambuStudio 2.3.x
- BambuStudio 2.4.x

### Variables de Entorno Usadas

**Modo Balanceado**:
- `MESA_GL_VERSION_OVERRIDE=4.5` - Forzar OpenGL 4.5
- `__GL_SYNC_TO_VBLANK=0` - Desactivar vsync
- `MESA_NO_DITHER=1` - Desactivar dithering
- `vblank_mode=0` - Control de vblank
- `__GL_YIELD="NOTHING"` - Reducir latencia
- `OMP_NUM_THREADS=4` - Limitar threads OpenMP
- `OMP_WAIT_POLICY=PASSIVE` - Política de espera pasiva

**Modo Software**:
- `LIBGL_ALWAYS_SOFTWARE=1` - Forzar software rendering
- `GALLIUM_DRIVER=llvmpipe` - Usar llvmpipe
- `MESA_LOADER_DRIVER_OVERRIDE=swrast` - Override a swrast

## Enlaces
- [Repositorio BambuStudio](https://github.com/bambulab/BambuStudio)
- [Issues relacionados](https://github.com/bambulab/BambuStudio/issues)
- [Bambu Lab Web](https://bambulab.com/bambu-studio)

## Fecha
24 diciembre 2024

## Versión
1.0
