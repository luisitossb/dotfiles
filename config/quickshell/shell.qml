import Quickshell
import Quickshell.Io
import "WidgetCenter"
import "WallpaperApp"
import "ResourceManager"
import "BluetoothApp"
import "WiFiApp"
import "ClipboardApp"
import "AppLauncher"
import "TrayPanel"
import "CustomTheme"

ShellRoot {
    // Test IPC tools: qs ipc show

    IpcHandler {
        target: "theme-manager"
        function reload(): void {
            Theme.reloadTheme()
        }
    }

    WidgetCenterWindow {}
    WallpaperWindow {}
    ResourceManagerWindow {}
    BluetoothWindow {}
    WiFiWindow {}
    ClipboardWindow {}
    AppLauncherWindow {}
    TrayPanelWindow {}
}