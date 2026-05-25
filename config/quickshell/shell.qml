import Quickshell
import Quickshell.Io
import QtQuick
import "WidgetCenter"
import "WallpaperApp"
import "ResourceManager"
import "BluetoothApp"
import "WiFiApp"
import "ClipboardApp"
import "AppLauncher"
import "TrayPanel"
import "CustomTheme"
import "SettingsApp"
import "Bar"

ShellRoot {
    // Test IPC tools: qs ipc show

    FontLoader {
        source: "file:///usr/share/fonts/TTF/PressStart2P.ttf"
    }

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
    SettingsApp {}
    BarWindow {}
}