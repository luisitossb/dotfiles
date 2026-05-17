import Quickshell
import Quickshell.Io
import "PowerApp"
import "SidebarApp"
import "CalendarApp"
import "WallpaperApp"
import "DashboardApp"
import "BluetoothApp"
import "WiFiApp"
import "ScreenshotApp"
import "ClipboardApp"
import "LauncherApp"
import "CustomTheme"

ShellRoot {
    // Test IPC tools: qs ipc show

    IpcHandler {
        target: "theme-manager"
        function reload(): void {
            Theme.reloadTheme()
        }
    }

    PowerWindow {}
    SidebarWindow {}
    CalendarWindow {}
    WallpaperWindow {}
    DashboardWindow {}
    BluetoothWindow {}
    WiFiWindow {}
    ScreenshotWindow {}
    ClipboardWindow {}
    LauncherWindow {}
}