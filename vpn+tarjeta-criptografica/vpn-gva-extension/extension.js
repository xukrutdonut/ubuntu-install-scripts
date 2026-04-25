/* extension.js
 *
 * VPN GVA Connector - Extensión GNOME Shell para conexión VPN
 */

const { GObject, St, Gio, GLib, Shell } = imports.gi;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const MessageTray = imports.ui.messageTray;

const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();

// Estados de la VPN
const VPNStates = {
    DISCONNECTED: 'disconnected',
    CONNECTING: 'connecting',
    CONNECTED: 'connected',
    ERROR: 'error'
};

// Iconos para cada estado
const StateIcons = {
    [VPNStates.DISCONNECTED]: 'network-vpn-disconnected-symbolic',
    [VPNStates.CONNECTING]: 'network-vpn-acquiring-symbolic', 
    [VPNStates.CONNECTED]: 'network-vpn-symbolic',
    [VPNStates.ERROR]: 'dialog-error-symbolic'
};

class VpnGvaIndicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'VPN GVA');
        
        this._state = VPNStates.DISCONNECTED;
        this._vpnProcess = null;
        this._scriptPath = GLib.get_home_dir() + '/ubuntu-install-scripts/VPN-SAN-GVA.sh';
        
        // Crear icono del panel
        this._icon = new St.Icon({
            icon_name: StateIcons[this._state],
            style_class: 'system-status-icon'
        });
        this.add_child(this._icon);
        
        // Crear menú
        this._createMenu();
        
        // Verificar disponibilidad del script
        this._checkScriptAvailability();
        
        // Configurar notificaciones
        this._notificationSource = null;
    }
    
    _createMenu() {
        // Estado actual
        this._statusItem = new PopupMenu.PopupMenuItem('VPN GVA: Desconectado', {
            reactive: false,
            style_class: 'vpn-status-item'
        });
        this.menu.addMenuItem(this._statusItem);
        
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        
        // Botón conectar/desconectar
        this._connectButton = new PopupMenu.PopupMenuItem('Conectar VPN');
        this._connectButton.connect('activate', () => {
            if (this._state === VPNStates.DISCONNECTED || this._state === VPNStates.ERROR) {
                this._connectVPN();
            } else if (this._state === VPNStates.CONNECTED) {
                this._disconnectVPN();
            }
        });
        this.menu.addMenuItem(this._connectButton);
        
        // Botón diagnóstico
        this._diagnosticButton = new PopupMenu.PopupMenuItem('Ejecutar Diagnóstico');
        this._diagnosticButton.connect('activate', () => {
            this._runDiagnostic();
        });
        this.menu.addMenuItem(this._diagnosticButton);
        
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        
        // Información
        this._infoItem = new PopupMenu.PopupMenuItem('Abrir Terminal VPN', {
            style_class: 'vpn-info-item'
        });
        this._infoItem.connect('activate', () => {
            this._openTerminal();
        });
        this.menu.addMenuItem(this._infoItem);
        
        // Configuración
        this._configItem = new PopupMenu.PopupMenuItem('Configurar (.env)');
        this._configItem.connect('activate', () => {
            this._openConfig();
        });
        this.menu.addMenuItem(this._configItem);
    }
    
    _updateState(newState, message = null) {
        this._state = newState;
        this._icon.icon_name = StateIcons[newState];
        
        // Actualizar texto del menú
        let statusText = '';
        let buttonText = '';
        
        switch (newState) {
            case VPNStates.DISCONNECTED:
                statusText = 'VPN GVA: Desconectado';
                buttonText = 'Conectar VPN';
                this._connectButton.setSensitive(true);
                break;
            case VPNStates.CONNECTING:
                statusText = 'VPN GVA: Conectando...';
                buttonText = 'Conectando...';
                this._connectButton.setSensitive(false);
                break;
            case VPNStates.CONNECTED:
                statusText = 'VPN GVA: Conectado ✓';
                buttonText = 'Desconectar VPN';
                this._connectButton.setSensitive(true);
                break;
            case VPNStates.ERROR:
                statusText = 'VPN GVA: Error de conexión';
                buttonText = 'Reintentar conexión';
                this._connectButton.setSensitive(true);
                break;
        }
        
        this._statusItem.label.text = statusText;
        this._connectButton.label.text = buttonText;
        
        // Mostrar notificación si se proporciona mensaje
        if (message) {
            this._showNotification(message);
        }
    }
    
    _checkScriptAvailability() {
        let file = Gio.File.new_for_path(this._scriptPath);
        if (!file.query_exists(null)) {
            this._updateState(VPNStates.ERROR, 'Script VPN-SAN-GVA.sh no encontrado');
            this._connectButton.setSensitive(false);
            this._diagnosticButton.setSensitive(false);
        }
    }
    
    _connectVPN() {
        this._updateState(VPNStates.CONNECTING, 'Iniciando conexión VPN...');
        
        // Ejecutar el script VPN en una terminal
        let command = [
            'gnome-terminal', 
            '--title=Conexión VPN GVA',
            '--',
            'bash', 
            this._scriptPath,
            '-c'  // Modo conexión directa
        ];
        
        try {
            let [success, pid] = GLib.spawn_async(
                null, // working directory
                command,
                null, // envp
                GLib.SpawnFlags.SEARCH_PATH | GLib.SpawnFlags.DO_NOT_REAP_CHILD,
                null // child_setup
            );
            
            if (success) {
                this._vpnProcess = pid;
                
                // Monitorear el proceso
                GLib.child_watch_add(GLib.PRIORITY_DEFAULT, pid, (pid, status) => {
                    this._onVpnProcessExit(status);
                });
                
                // Simular conexión establecida después de un tiempo
                // En una implementación real, monitorizarías el estado de la VPN
                GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 5, () => {
                    this._checkConnectionStatus();
                    return false;
                });
                
            } else {
                this._updateState(VPNStates.ERROR, 'Error al ejecutar el script VPN');
            }
        } catch (e) {
            log('Error ejecutando VPN: ' + e.message);
            this._updateState(VPNStates.ERROR, 'Error: ' + e.message);
        }
    }
    
    _disconnectVPN() {
        // Desconectar VPN usando pkill
        let command = ['pkill', '-f', 'openconnect'];
        
        try {
            let [success, stdout, stderr, exit_status] = GLib.spawn_sync(
                null,
                command,
                null,
                GLib.SpawnFlags.SEARCH_PATH,
                null
            );
            
            this._updateState(VPNStates.DISCONNECTED, 'VPN desconectada');
        } catch (e) {
            log('Error desconectando VPN: ' + e.message);
        }
    }
    
    _runDiagnostic() {
        let command = [
            'gnome-terminal',
            '--title=Diagnóstico VPN GVA', 
            '--',
            'bash',
            this._scriptPath,
            '-d'  // Modo diagnóstico
        ];
        
        try {
            GLib.spawn_async(
                null,
                command, 
                null,
                GLib.SpawnFlags.SEARCH_PATH,
                null
            );
            
            this._showNotification('Ejecutando diagnóstico VPN...');
        } catch (e) {
            log('Error ejecutando diagnóstico: ' + e.message);
        }
    }
    
    _openTerminal() {
        let scriptDir = GLib.path_get_dirname(this._scriptPath);
        let command = [
            'gnome-terminal',
            '--title=Terminal VPN GVA',
            '--working-directory=' + scriptDir
        ];
        
        try {
            GLib.spawn_async(null, command, null, GLib.SpawnFlags.SEARCH_PATH, null);
        } catch (e) {
            log('Error abriendo terminal: ' + e.message);
        }
    }
    
    _openConfig() {
        let configPath = GLib.path_get_dirname(this._scriptPath) + '/.env';
        let examplePath = GLib.path_get_dirname(this._scriptPath) + '/.env.example';
        
        // Si no existe .env, copiar desde .env.example
        let envFile = Gio.File.new_for_path(configPath);
        let exampleFile = Gio.File.new_for_path(examplePath);
        
        if (!envFile.query_exists(null) && exampleFile.query_exists(null)) {
            try {
                exampleFile.copy(envFile, Gio.FileCopyFlags.NONE, null, null);
            } catch (e) {
                log('Error copiando .env.example: ' + e.message);
            }
        }
        
        // Abrir archivo de configuración
        let command = ['xdg-open', configPath];
        
        try {
            GLib.spawn_async(null, command, null, GLib.SpawnFlags.SEARCH_PATH, null);
        } catch (e) {
            // Si xdg-open falla, intentar con editor de texto
            let fallbackCommand = ['gnome-text-editor', configPath];
            try {
                GLib.spawn_async(null, fallbackCommand, null, GLib.SpawnFlags.SEARCH_PATH, null);
            } catch (e2) {
                log('Error abriendo configuración: ' + e2.message);
            }
        }
    }
    
    _checkConnectionStatus() {
        // Verificar si openconnect está corriendo
        let command = ['pgrep', '-f', 'openconnect'];
        
        try {
            let [success, stdout, stderr, exit_status] = GLib.spawn_sync(
                null,
                command,
                null, 
                GLib.SpawnFlags.SEARCH_PATH,
                null
            );
            
            if (success && exit_status === 0) {
                this._updateState(VPNStates.CONNECTED, 'VPN conectada correctamente');
            } else {
                this._updateState(VPNStates.DISCONNECTED);
            }
        } catch (e) {
            this._updateState(VPNStates.ERROR, 'Error verificando estado de VPN');
        }
    }
    
    _onVpnProcessExit(status) {
        if (status === 0) {
            // Proceso terminó correctamente
            this._checkConnectionStatus();
        } else {
            this._updateState(VPNStates.ERROR, 'El script VPN terminó con errores');
        }
        this._vpnProcess = null;
    }
    
    _showNotification(message) {
        if (!this._notificationSource) {
            this._notificationSource = new MessageTray.Source('VPN GVA', 'network-vpn-symbolic');
            Main.messageTray.add(this._notificationSource);
        }
        
        let notification = new MessageTray.Notification(
            this._notificationSource,
            'VPN GVA',
            message
        );
        
        this._notificationSource.showNotification(notification);
    }
    
    destroy() {
        if (this._vpnProcess) {
            // Limpiar proceso si existe
            this._vpnProcess = null;
        }
        super.destroy();
    }
}

let vpnGvaIndicator;

function init() {
    log('Inicializando VPN GVA Extension');
}

function enable() {
    log('Habilitando VPN GVA Extension');
    vpnGvaIndicator = new VpnGvaIndicator();
    Main.panel.addToStatusArea('vpn-gva', vpnGvaIndicator);
}

function disable() {
    log('Deshabilitando VPN GVA Extension');
    if (vpnGvaIndicator) {
        vpnGvaIndicator.destroy();
        vpnGvaIndicator = null;
    }
}