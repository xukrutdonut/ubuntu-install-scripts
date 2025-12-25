# Extensión VPN GVA para GNOME Shell

Una extensión de GNOME Shell que permite gestionar la conexión VPN de la Generalitat Valenciana directamente desde el system tray, sin necesidad de abrir terminal.

## 🚀 Características

- **Icono en System Tray**: Acceso rápido desde la barra superior de GNOME
- **Estados Visuales**: Iconos diferentes para cada estado de conexión
- **Menú Contextual**: Opciones completas para gestionar la VPN
- **Notificaciones**: Información del estado de conexión
- **Configuración Fácil**: Acceso directo al archivo de configuración
- **Diagnósticos**: Ejecutar diagnósticos del sistema VPN

## 📦 Instalación

### Instalación Automática

```bash
cd ubuntu-install-scripts
./install-vpn-extension.sh
```

### Instalación Manual

1. **Copiar la extensión**:
   ```bash
   cp -r vpn-gva-extension ~/.local/share/gnome-shell/extensions/vpn-gva@arkantu.local
   ```

2. **Reiniciar GNOME Shell** (solo en X11):
   - Presione `Alt + F2`
   - Escriba `r` y presione Enter

3. **Habilitar la extensión**:
   - Abra "Extensiones" desde el menú de aplicaciones
   - Busque "VPN GVA Connector" y actívela

## 🎛️ Uso

### Acceso desde System Tray

1. Busque el icono VPN en la barra superior de GNOME
2. Haga clic para abrir el menú de opciones

### Opciones del Menú

- **Estado**: Muestra el estado actual de la conexión
- **Conectar/Desconectar VPN**: Inicia o termina la conexión
- **Ejecutar Diagnóstico**: Ejecuta verificaciones del sistema
- **Abrir Terminal VPN**: Abre terminal en el directorio del script
- **Configurar (.env)**: Abre el archivo de configuración

### Estados del Icono

| Estado | Icono | Descripción |
|--------|-------|-------------|
| Desconectado | 🔒 | VPN no conectada |
| Conectando | 🔄 | Estableciendo conexión |
| Conectado | ✅ | VPN activa y funcionando |
| Error | ❌ | Problema en la conexión |

## ⚙️ Configuración

### Archivo .env

Para evitar introducir credenciales manualmente cada vez:

1. **Crear archivo de configuración**:
   ```bash
   cp .env.example .env
   ```

2. **Editar credenciales**:
   ```bash
   nano .env
   ```

3. **Configurar variables**:
   ```bash
   # PIN del certificado digital
   CERT_PIN=su_pin_aqui
   
   # Contraseña de usuario VPN
   VPN_PASSWORD=su_password_aqui
   
   # Usuario VPN (opcional)
   VPN_USER=su_usuario_aqui
   ```

### Acceso Rápido a Configuración

- Use el botón "Configurar (.env)" del menú de la extensión
- Se abrirá automáticamente el editor de texto
- Si no existe .env, se creará desde .env.example

## 🔧 Funcionalidades Avanzadas

### Conexión Automática

La extensión puede usar credenciales del archivo .env para conexión semi-automática:

- El script se ejecutará en modo conexión directa (`-c`)
- Las credenciales del .env se usarán automáticamente
- Solo se solicitarán datos faltantes

### Diagnóstico del Sistema

El botón "Ejecutar Diagnóstico" lanza verificaciones completas:

- Estado de dependencias
- Servicio pcscd
- Conectividad al servidor
- Lectores de tarjetas
- Certificados digitales
- Estado de SafeSign

### Monitoreo de Estado

La extensión monitoriza automáticamente:

- Proceso openconnect activo
- Estado de la conexión VPN
- Cambios en el estado del sistema

## 🛠️ Solución de Problemas

### La extensión no aparece

1. **Verificar instalación**:
   ```bash
   ls ~/.local/share/gnome-shell/extensions/vpn-gva@arkantu.local
   ```

2. **Reiniciar GNOME Shell** (X11):
   ```bash
   # Método 1: Alt+F2, escribir 'r', Enter
   # Método 2: Cerrar sesión y volver a iniciar
   ```

3. **Habilitar manualmente**:
   - Abrir "Extensiones"
   - Buscar "VPN GVA Connector"
   - Activar el switch

### Script no encontrado

Si la extensión muestra error de script no encontrado:

1. **Verificar ubicación del script**:
   ```bash
   ls ~/ubuntu-install-scripts/VPN-SAN-GVA.sh
   ```

2. **Hacer ejecutable si es necesario**:
   ```bash
   chmod +x ~/ubuntu-install-scripts/VPN-SAN-GVA.sh
   ```

### Error de permisos

Para problemas de permisos con GNOME Shell:

1. **Verificar propiedad de archivos**:
   ```bash
   chown -R $USER:$USER ~/.local/share/gnome-shell/extensions/vpn-gva@arkantu.local
   ```

2. **Verificar permisos**:
   ```bash
   chmod 755 ~/.local/share/gnome-shell/extensions/vpn-gva@arkantu.local
   chmod 644 ~/.local/share/gnome-shell/extensions/vpn-gva@arkantu.local/*
   ```

### Logs de depuración

Para ver logs de la extensión:

```bash
# Ver logs en tiempo real
journalctl -f /usr/bin/gnome-shell

# Buscar logs específicos de la extensión
journalctl -b | grep "VPN GVA"
```

## 📋 Requisitos del Sistema

- **GNOME Shell**: 42 o superior
- **Ubuntu/Debian**: 20.04 LTS o superior
- **Dependencias**: openconnect, gnutls-bin, gnome-shell-extensions
- **Script VPN**: VPN-SAN-GVA.sh en el mismo directorio

## 🔄 Actualizaciones

Para actualizar la extensión:

1. **Reemplazar archivos**:
   ```bash
   ./install-vpn-extension.sh
   ```

2. **Reiniciar GNOME Shell** (si es necesario)

3. **Verificar funcionamiento**

## 📚 Información Técnica

### Archivos de la Extensión

- `metadata.json`: Metadatos de la extensión
- `extension.js`: Código principal en JavaScript
- `stylesheet.css`: Estilos personalizados

### Compatibilidad

- **GNOME Shell**: 42, 43, 44, 45
- **Sesiones**: X11 y Wayland
- **Distribuciones**: Ubuntu, Debian, Fedora, openSUSE

### UUID

La extensión usa el UUID: `vpn-gva@arkantu.local`

## 🤝 Soporte

Para problemas o sugerencias:

1. Verifique este README
2. Ejecute diagnóstico del script VPN
3. Revise logs de GNOME Shell
4. Compruebe versión de GNOME Shell compatible

---

**Nota**: Esta extensión complementa el script VPN-SAN-GVA.sh existente, proporcionando una interfaz gráfica conveniente para su uso diario.