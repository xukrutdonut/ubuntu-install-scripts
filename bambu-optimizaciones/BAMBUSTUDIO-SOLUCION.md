# Solución al problema de lentitud de BambuStudio

## Problema
BambuStudio arrancaba extremadamente lento y era inutilizable después de aplicar optimizaciones agresivas.

## Causa
Los scripts `start-bambustudio.sh` y `bambustudio-safe.sh` tenían configuraciones problemáticas:
- Usaban Flatpak con variables de entorno muy agresivas (INTEL_DEBUG, LIBGL_DRI3_DISABLE, etc.)
- Forzaban configuraciones de OpenGL/Mesa que causaban conflictos
- Limitaban recursos de forma excesiva (OMP_NUM_THREADS, MALLOC_ARENA_MAX)

## Solución Aplicada

### 1. Usar versión AppImage más reciente
- **Antes**: Usaba Flatpak (com.bambulab.BambuStudio v2.4.0) con configs agresivas
- **Ahora**: Usa AppImage v02.04.00.70 (más reciente, menos bugs)

### 2. Configuración balanceada para Intel Arrow Lake
- **Antes**: Configuraciones muy agresivas que causaban freezes
- **Ahora**: Configuración balanceada que evita congelamiento
  - MESA_GL_VERSION_OVERRIDE=4.5 (no 4.6)
  - OMP_NUM_THREADS=4 (no 8)
  - __GL_YIELD="NOTHING" (reduce latencia)
  - Eliminado INTEL_DEBUG y LIBGL_DRI3_DISABLE problemáticos

### 3. Configuración limpia
- Respaldadas configuraciones corruptas en `~/.config/BambuStudio.backup-*`
- Inicio limpio sin cache corrupto

### 4. Scripts disponibles
- `start-bambustudio.sh` - **Script principal (RECOMENDADO)** - Balanceado
- `start-bambustudio-software.sh` - Modo software (lento pero NO se congela)
- `start-bambustudio-balanced.sh` - Alternativa balanceada
- `start-bambustudio.sh.backup-problematico` - Backup del script problemático

## Cómo usar

### Opción 1: Script principal (RECOMENDADO)
```bash
./start-bambustudio.sh
```
Configuración balanceada para Intel Arrow Lake - evita freezes

### Opción 2: Modo software rendering (si sigue congelándose)
```bash
./start-bambustudio-software.sh
```
**MUY LENTO** pero garantiza que no se congela. Úsalo si el principal se queda freeze.

### Opción 3: Alternativa balanceada
```bash
./start-bambustudio-balanced.sh
```

## Si sigue teniendo problemas (freezes)

### 1. Usar modo software rendering
El más estable aunque lento:
```bash
./start-bambustudio-software.sh
```

### 2. Limpiar configuración completamente
```bash
rm -rf ~/.config/BambuStudio ~/.local/share/BambuStudio ~/.cache/BambuStudio
```
Luego reinicia BambuStudio.

### 3. Monitorear con strace (para diagnóstico)
```bash
strace -o /tmp/bambu-trace.log /home/arkantu/BambuStudio-v02.04.00.70.AppImage.old
```

### 4. Verificar drivers gráficos Intel
```bash
# Ver información de GPU
glxinfo | grep -E "OpenGL version|OpenGL renderer"

# Actualizar drivers Intel
sudo dnf update mesa-* intel-*
```

## Versiones disponibles
- `BambuStudio-v02.03.01.51.AppImage.old` - 141M - **Versión estable recomendada**
- `BambuStudio-v02.04.00.70.AppImage.old` - 160M - Versión más nueva
- `BambuStudio-fedora.AppImage` - 158M - Versión específica Fedora
- `BambuStudio.AppImage` - 137M - Versión base antigua

## Logs
Los logs se guardan en `~/bambustudio.log` para diagnóstico.

## Fecha de la solución
24 de diciembre de 2024
