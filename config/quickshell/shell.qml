import Quickshell
import Quickshell.Io
import "WelcomeApp"
import "PowerApp"
import "SidebarApp"
import "CalendarApp"
import "WallpaperApp"
import "DashboardApp"
import "BluetoothApp"
import "WiFiApp"
import "CustomTheme"

ShellRoot {
    // Test IPC tools: qs ipc show

    IpcHandler {
        target: "theme-manager"
        function reload(): void {
            Theme.reloadTheme()
        }
    }

    WelcomeWindow {}
    PowerWindow {}
    SidebarWindow {}
    CalendarWindow {}
    WallpaperWindow {}
    DashboardWindow {}
    BluetoothWindow {}
    WiFiWindow {}
}