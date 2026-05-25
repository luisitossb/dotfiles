import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.CustomTheme

Item {
    id: root

    readonly property string home: Quickshell.env("HOME")

    property var clients: []
    property string focusedAddress: ""
    property var pinnedApps: []

    // Icon cache: class -> svg path (empty string = no icon found)
    property var iconCache: ({})
    property var iconSeen: ({})        // class -> true if queued/loaded
    property int iconCacheVer: 0
    property var iconQueue: []
    property bool iconBusy: false

    function ensureIcon(cls) {
        if (!cls || iconSeen[cls]) return
        iconSeen[cls] = true
        iconQueue.push(cls)
        if (!iconBusy) drainIcons()
    }

    function drainIcons() {
        if (iconQueue.length === 0) { iconBusy = false; return }
        iconBusy = true
        iconWorker.appClass = iconQueue.shift()
        iconWorker.running  = true
    }

    Process {
        id: iconWorker
        property string appClass: ""
        command: [root.home + "/.local/bin/qs-icon-lookup.py", appClass]
        stdout: StdioCollector {
            onStreamFinished: {
                root.iconCache[iconWorker.appClass] = this.text.trim()
                root.iconCacheVer++
                root.drainIcons()
            }
        }
    }

    // ── Task model ────────────────────────────────────────────────────────────

    property var taskItems: []

    function buildTaskModel() {
        var pinnedClasses = []
        for (var i = 0; i < pinnedApps.length; i++) {
            pinnedClasses.push(pinnedApps[i].class.toLowerCase())
        }

        var items = []

        // 1. Pinned apps (always visible, in saved order)
        for (var pi = 0; pi < pinnedApps.length; pi++) {
            var p = pinnedApps[pi]
            var cls = p.class.toLowerCase()
            var wins = []
            for (var ci = 0; ci < clients.length; ci++) {
                if (clients[ci].class && clients[ci].class.toLowerCase() === cls)
                    wins.push(clients[ci])
            }
            var isFocused = false
            for (var fi = 0; fi < wins.length; fi++) {
                if (wins[fi].address === focusedAddress) { isFocused = true; break }
            }
            items.push({
                isPinned:  true,
                appClass:  p.class,
                exec:      p.exec || "",
                nerdIcon:  p.icon || "󰣆",
                name:      p.name || p.class,
                isRunning: wins.length > 0,
                isFocused: isFocused,
                address:   wins.length > 0 ? wins[0].address : ""
            })
            ensureIcon(p.class)
        }

        // 2. Non-pinned running windows (one entry per window, like wlr/taskbar)
        for (var wi = 0; wi < clients.length; wi++) {
            var w = clients[wi]
            if (!w.class) continue
            var wCls = w.class.toLowerCase()
            var isPinned = false
            for (var pci = 0; pci < pinnedClasses.length; pci++) {
                if (pinnedClasses[pci] === wCls) { isPinned = true; break }
            }
            if (isPinned) continue
            items.push({
                isPinned:  false,
                appClass:  w.class,
                exec:      "",
                nerdIcon:  "󰣆",
                name:      w.title || w.class,
                isRunning: true,
                isFocused: w.address === focusedAddress,
                address:   w.address
            })
            ensureIcon(w.class)
        }

        taskItems = items
    }

    onClientsChanged:        Qt.callLater(buildTaskModel)
    onFocusedAddressChanged: Qt.callLater(buildTaskModel)
    onPinnedAppsChanged:     Qt.callLater(buildTaskModel)

    // ── Load pinned apps ──────────────────────────────────────────────────────

    Process {
        id: pinsProc
        command: ["cat", root.home + "/.config/waybar/pinned-apps.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.pinnedApps = JSON.parse(this.text) }
                catch(e) { root.pinnedApps = [] }
            }
        }
    }

    Component.onCompleted: pinsProc.running = true

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: pinsProc.running = true
    }

    // ── Layout ────────────────────────────────────────────────────────────────

    implicitWidth:  taskRow.implicitWidth
    implicitHeight: 34

    Row {
        id: taskRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: root.taskItems

            delegate: Item {
                required property var modelData
                required property int index

                width: 36
                height: 34

                readonly property bool isActive:  modelData.isFocused
                readonly property bool isRunning: modelData.isRunning
                readonly property bool isPinned:  modelData.isPinned

                // Highlight background
                Rectangle {
                    anchors.centerIn: parent
                    width: 32; height: 30
                    radius: 6
                    color: isActive
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
                        : itemHov.hovered
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                // Running indicator (dot at bottom)
                Rectangle {
                    visible: isRunning
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1
                    width: isActive ? 8 : 4
                    height: 2
                    radius: 1
                    color: Theme.primary
                    Behavior on width { NumberAnimation { duration: 120 } }
                }

                // App icon (SVG)
                Image {
                    id: iconImg
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1
                    width: 22; height: 22
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    opacity: isPinned && !isRunning ? 0.35 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    source: {
                        var _ = root.iconCacheVer
                        var p = root.iconCache[modelData.appClass]
                        return (p && p.length > 0) ? ("file://" + p) : ""
                    }
                }

                // Nerd font fallback
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1
                    text: modelData.nerdIcon || "󰣆"
                    font.pixelSize: 18
                    font.family: "JetBrainsMono Nerd Font"
                    color: Theme.on_surface
                    opacity: isPinned && !isRunning ? 0.35 : 1.0
                    visible: iconImg.status !== Image.Ready
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            if (modelData.isPinned) {
                                Quickshell.execDetached(["bash",
                                    root.home + "/.local/bin/waybar-unpin.sh",
                                    modelData.appClass])
                            } else {
                                Quickshell.execDetached([root.home + "/.local/bin/waybar-pin.sh"])
                            }
                            return
                        }
                        if (modelData.isRunning && modelData.address) {
                            Hyprland.dispatch("focuswindow address:" + modelData.address)
                        } else if (modelData.exec) {
                            Quickshell.execDetached(modelData.exec.split(" "))
                        }
                    }

                    HoverHandler { id: itemHov }
                }
            }
        }
    }
}
