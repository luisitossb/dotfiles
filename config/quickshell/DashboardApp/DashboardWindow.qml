import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.CustomTheme
import "../shared"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore
    implicitWidth:  420
    implicitHeight: 680
    color: "transparent"

    anchors { left: true; top: true }
    margins { left: 8; top: 54 }

    // ── Open / close ──────────────────────────────────────────────────────────

    property bool isOpen: false
    visible: isOpen

    HyprlandFocusGrab {
        windows: [root]
        active: root.isOpen
        onCleared: root.isOpen = false
    }

    Shortcut {
        sequence: "Escape"
        onActivated: if (root.isOpen) root.isOpen = false
    }

    IpcHandler {
        target: "dashboard"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open():   void { root.isOpen = true  }
        function close():  void { root.isOpen = false }
    }

    // ── Polled data ───────────────────────────────────────────────────────────

    property int    cpuUsage:  0
    property string cpuTemp:   "?"
    property int    ramUsage:  0
    property string ramUsed:   "?"
    property int    diskUsage: 0
    property string diskInfo:  "?"
    property int    vramUsage: 0
    property string gpuTemp:   "N/A"
    property string vramInfo:  "?"
    property int    volPct:    0
    property bool   isMuted:   false
    property int    batPct:    100
    property string batStatus: "Unknown"
    property int    batHealth: 100
    property string netSpeed:  "? / ?"
    property string uptimeStr: ""
    property string clockTime:  Qt.formatTime(new Date(), "HH:mm")
    property string clockDate:  Qt.formatDate(new Date(), "dddd, MMMM d")
    property string lastError:  ""
    property bool   modeServer:   false
    property bool   shaderOn:     false
    property string powerProfile: "balanced"
    property bool   dndOn:        false

    onIsOpenChanged: {
        if (isOpen) {
            modeProc.running   = false; modeProc.running   = true
            shaderProc.running = false; shaderProc.running = true
            powerProc.running  = false; powerProc.running  = true
            dndProc.running    = false; dndProc.running    = true
        }
    }

    function logErr(source, msg) {
        let e = msg.split('\n')[0]   // first line only in UI
        console.warn("dashboard [" + source + "]: " + msg)
        root.lastError = source + ": " + e
    }

    function toggleMode() {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.local/bin/toggle-mode.sh"])
        root.modeServer = !root.modeServer
        modeTimer.start()
    }
    function toggleShader() {
        Quickshell.execDetached(["bash", "-c",
            "sleep 0.5 && (pgrep -x hyprsunset && pkill -x hyprsunset || hyprsunset &)"])
        shaderTimer.start()
    }
    function cycleProfile() {
        let profiles = ["balanced", "performance", "power-saver"]
        let next = profiles[(profiles.indexOf(root.powerProfile) + 1) % profiles.length]
        Quickshell.execDetached(["bash", "-c", "powerprofilesctl set " + next])
        root.powerProfile = next
    }
    function toggleDnd() {
        Quickshell.execDetached(["bash", "-c", "swaync-client -d -sw"])
        root.dndOn = !root.dndOn
    }

    // ── Timers ────────────────────────────────────────────────────────────────

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            root.clockTime = Qt.formatTime(new Date(), "HH:mm")
            root.clockDate = Qt.formatDate(new Date(), "dddd, MMMM d")
        }
    }

    Timer {
        interval: 2000; running: root.isOpen; repeat: true; triggeredOnStart: true
        onTriggered: {
            cpuProc.running  = false; cpuProc.running  = true
            ramProc.running  = false; ramProc.running  = true
            vramProc.running = false; vramProc.running = true
            volProc.running  = false; volProc.running  = true
            if (!netProc.running)    netProc.running   = true
        }
    }

    Timer {
        interval: 30000; running: root.isOpen; repeat: true; triggeredOnStart: true
        onTriggered: {
            diskProc.running = false; diskProc.running = true
            batProc.running  = false; batProc.running  = true
        }
    }

    Timer {
        interval: 60000; running: root.isOpen; repeat: true; triggeredOnStart: true
        onTriggered: { uptimeProc.running = false; uptimeProc.running = true }
    }

    Timer { id: modeTimer;   interval: 3000; repeat: false; onTriggered: { modeProc.running   = false; modeProc.running   = true } }
    Timer { id: shaderTimer; interval: 900;  repeat: false; onTriggered: { shaderProc.running = false; shaderProc.running = true } }

    // ── Processes ─────────────────────────────────────────────────────────────

    Process {
        id: cpuProc
        command: ["bash", "-c",
            "top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}';" +
            "sensors 2>/dev/null | awk '/^Package id 0/{gsub(/[^0-9.]/,\"\",$4); print int($4); exit}' || echo '?'"]
        stdout: StdioCollector { onStreamFinished: {
            let l = this.text.trim().split("\n")
            root.cpuUsage = parseInt(l[0]) || 0
            root.cpuTemp  = l[1] || "?"
        }}
    }

    Process {
        id: ramProc
        command: ["bash", "-c",
            "free | awk '/Mem:/{printf \"%d\\n%.1f\", $3/$2*100, $3/1024/1024}'"]
        stdout: StdioCollector { onStreamFinished: {
            let l = this.text.trim().split("\n")
            root.ramUsage = parseInt(l[0]) || 0
            root.ramUsed  = (l[1] || "?") + "G"
        }}
    }

    Process {
        id: vramProc
        command: ["bash", "-c",
            "which nvidia-smi >/dev/null 2>&1 && " +
            "nvidia-smi --query-gpu=memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | " +
            "awk -F', ' '{printf \"%d\\n%s\\n%.1f/%.1fG\", $1/$2*100, $3, $1/1024, $2/1024}' || printf '0\\nN/A\\n?'"]
        stdout: StdioCollector { onStreamFinished: {
            let l = this.text.trim().split("\n")
            root.vramUsage = parseInt(l[0]) || 0
            root.gpuTemp   = l[1] || "N/A"
            root.vramInfo  = l[2] || "?"
        }}
    }

    Process {
        id: diskProc
        command: ["bash", "-c",
            "df / | awk 'NR==2{gsub(/%/,\"\"); printf \"%s\\n\", $5}';" +
            "df -h / | awk 'NR==2{printf \"%s/%s\", $3, $2}'"]
        stdout: StdioCollector { onStreamFinished: {
            let l = this.text.trim().split("\n")
            root.diskUsage = parseInt(l[0]) || 0
            root.diskInfo  = l[1] || "?"
        }}
    }

    Process {
        id: volProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: {
            let line = this.text.trim()
            root.isMuted = line.includes("MUTED")
            let m = line.match(/[\d.]+/)
            root.volPct = m ? Math.round(parseFloat(m[0]) * 100) : 0
        }}
    }

    Process {
        id: batProc
        command: ["bash", "-c",
            "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo 100;" +
            "cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1 || echo Unknown;" +
            "cat /sys/class/power_supply/BAT*/energy_full /sys/class/power_supply/BAT*/energy_full_design 2>/dev/null | " +
            "awk 'NR==1{ef=$1} NR==2{printf \"%.0f\",ef/$1*100}' || echo '?'"]
        stdout: StdioCollector { onStreamFinished: {
            let l = this.text.trim().split("\n")
            root.batPct    = parseInt(l[0]) || 100
            root.batStatus = l[1] || "Unknown"
            root.batHealth = parseInt(l[2]) || 100
        }}
    }

    Process {
        id: netProc
        command: ["bash", Quickshell.env("HOME") + "/.config/eww/scripts/net-speed.sh"]
        stdout: StdioCollector { onStreamFinished: {
            let s = this.text.trim()
            if (s) root.netSpeed = s
            netProc.running = false
        }}
        stderr: StdioCollector { onStreamFinished: {
            let e = this.text.trim()
            if (e) root.logErr("net-speed", e)
        }}
    }

    Process {
        id: uptimeProc
        command: ["bash", "-c", "uptime -p | sed 's/up //'"]
        stdout: StdioCollector { onStreamFinished: root.uptimeStr = this.text.trim() }
    }

    Process {
        id: modeProc
        command: ["bash", "-c", "cat $HOME/.config/mode/current 2>/dev/null || echo laptop"]
        stdout: StdioCollector { onStreamFinished: root.modeServer = this.text.trim() === "server" }
    }
    Process {
        id: shaderProc
        command: ["bash", "-c", "pgrep -x hyprsunset >/dev/null 2>&1 && echo 1 || echo 0"]
        stdout: StdioCollector { onStreamFinished: root.shaderOn = this.text.trim() === "1" }
    }
    Process {
        id: powerProc
        command: ["bash", "-c", "powerprofilesctl get 2>/dev/null || echo balanced"]
        stdout: StdioCollector { onStreamFinished: root.powerProfile = this.text.trim() }
    }
    Process {
        id: dndProc
        command: ["bash", "-c", "swaync-client -D 2>/dev/null || echo false"]
        stdout: StdioCollector { onStreamFinished: root.dndOn = this.text.trim() === "true" }
    }

    // ── Reusable components ───────────────────────────────────────────────────

    component StatBar: Item {
        id: barRoot
        property int   pct:      0
        property color barColor: Theme.primary
        Layout.fillWidth: true
        implicitHeight: 5

        Rectangle { anchors.fill: parent; radius: 3; color: Theme.surface_container_high }
        Rectangle {
            width: Math.max(0, Math.min(1, barRoot.pct / 100)) * barRoot.width
            height: parent.height; radius: 3; color: barRoot.barColor
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        }
    }

    component Divider: Rectangle {
        Layout.fillWidth: true; implicitHeight: 1
        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
    }

    component StatRow: ColumnLayout {
        property string statLabel: ""
        property string statIcon:  ""
        property int    statPct:   0
        property string statInfo:  ""
        property color  statColor: Theme.primary
        Layout.fillWidth: true
        spacing: 4

        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text {
                text: statIcon; font.family: "monospace"; font.pixelSize: 14
                color: Theme.on_surface_variant; Layout.minimumWidth: 22
            }
            Text {
                text: statLabel; color: Theme.on_surface_variant
                font.family: Theme.fontFamily; font.pixelSize: 12; Layout.fillWidth: true
            }
            Text {
                text: statInfo; color: Theme.on_surface_variant
                font.family: Theme.fontFamily; font.pixelSize: 11
            }
            Text {
                text: statPct + "%"; color: Theme.on_surface_variant
                font.family: Theme.fontFamily; font.pixelSize: 12
                Layout.minimumWidth: 32; horizontalAlignment: Text.AlignRight
            }
        }
        StatBar { pct: statPct; barColor: statColor }
    }

    component SysRow: RowLayout {
        property string rowIcon:  ""
        property string rowLabel: ""
        property string rowValue: ""
        Layout.fillWidth: true; spacing: 8
        Text {
            text: rowIcon; font.family: "monospace"; font.pixelSize: 14
            color: Theme.on_surface_variant; Layout.minimumWidth: 22
        }
        Text {
            text: rowLabel; color: Theme.on_surface_variant
            font.family: Theme.fontFamily; font.pixelSize: 12; Layout.fillWidth: true
        }
        Text {
            text: rowValue; color: Theme.on_surface_variant
            font.family: Theme.fontFamily; font.pixelSize: 12; horizontalAlignment: Text.AlignRight
        }
    }

    component TogglePill: Item {
        id: pill
        property string iconText:    ""
        property string tipText:     ""
        property bool   active:      false
        property color  activeColor: Theme.primary
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 52

        property bool hov: false

        Rectangle {
            anchors.fill: parent; radius: 10
            color: pill.active
                   ? Qt.rgba(pill.activeColor.r, pill.activeColor.g, pill.activeColor.b, 0.18)
                   : pill.hov
                   ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.06)
                   : Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 0.50)
            border.color: pill.active
                          ? Qt.rgba(pill.activeColor.r, pill.activeColor.g, pill.activeColor.b, 0.35)
                          : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.10)
            border.width: 1
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        ColumnLayout {
            anchors.centerIn: parent; spacing: 3
            Text {
                text: pill.iconText
                font.family: "monospace"; font.pixelSize: 18
                color: pill.active ? pill.activeColor : Theme.on_surface_variant
                Layout.alignment: Qt.AlignHCenter
                Behavior on color { ColorAnimation { duration: 100 } }
            }
            Text {
                text: pill.tipText
                visible: pill.tipText !== ""
                font.family: Theme.fontFamily; font.pixelSize: 9
                color: pill.active ? pill.activeColor : Theme.on_surface_variant
                Layout.alignment: Qt.AlignHCenter
                opacity: 0.8
            }
        }

        MouseArea {
            anchors.fill: parent; hoverEnabled: true
            onEntered: pill.hov = true
            onExited:  pill.hov = false
            onClicked: pill.clicked()
        }
    }

    // ── UI ────────────────────────────────────────────────────────────────────

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent; radius: 16
            color: Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g,
                           Theme.surface_container_low.b, 1.0)
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
            border.width: 1
        }

        ScrollView {
            anchors.fill: parent
            contentHeight: mainCol.implicitHeight
            clip: true

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 4; radius: 2; color: Theme.primary
                    opacity: parent.pressed ? 0.9 : parent.active ? 0.6 : 0.3
                }
            }

            ColumnLayout {
                id: mainCol
                width: parent.width
                spacing: 0

                Item { implicitHeight: 22 }

                // ── Resource stats ────────────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 22; Layout.rightMargin: 22
                    spacing: 14

                    StatRow {
                        statLabel: "CPU";  statIcon: "󰻠"; statPct: root.cpuUsage
                        statInfo: root.cpuTemp + "°C"; statColor: Theme.primary
                    }
                    StatRow {
                        statLabel: "RAM";  statIcon: "󰍛"; statPct: root.ramUsage
                        statInfo: root.ramUsed;           statColor: Theme.tertiary
                    }
                    StatRow {
                        statLabel: "Disk"; statIcon: "󰉉"; statPct: root.diskUsage
                        statInfo: root.diskInfo;          statColor: Theme.secondary
                    }
                    StatRow {
                        statLabel: "VRAM"; statIcon: "󰍹"; statPct: root.vramUsage
                        statInfo: root.vramInfo
                        statColor: root.vramUsage > 85 ? Theme.error : Theme.tertiary
                    }

                }

                Item { implicitHeight: 14 }
                Divider { Layout.leftMargin: 22; Layout.rightMargin: 22 }
                Item { implicitHeight: 12 }

                // ── System info ───────────────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 22; Layout.rightMargin: 22
                    spacing: 10

                    SysRow { rowIcon: "󰓅"; rowLabel: "Network"; rowValue: root.netSpeed }
                    SysRow { rowIcon: "󰔟"; rowLabel: "Uptime";  rowValue: root.uptimeStr }
                }

                Item { implicitHeight: 14 }

                // ── Now Playing (MPRIS) ───────────────────────────────────────
                Loader {
                    Layout.fillWidth: true
                    Layout.leftMargin: 22; Layout.rightMargin: 22
                    active: Mpris.players.values.length > 0
                    visible: active
                    sourceComponent: ColumnLayout {
                        spacing: 10
                        Divider {}
                        Item { implicitHeight: 2 }
                        Repeater {
                            model: Mpris.players.values
                            delegate: RowLayout {
                                required property var modelData
                                property var player: modelData
                                Layout.fillWidth: true; spacing: 12
                                Text {
                                    text: player.isPlaying ? "󰎇" : "󰏤"
                                    font.family: "monospace"; font.pixelSize: 28
                                    color: Theme.tertiary
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: player.isPlaying = !player.isPlaying
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text {
                                        text: player.trackTitle || "Nothing playing"
                                        color: Theme.on_surface; font.family: Theme.fontFamily
                                        font.pixelSize: 13; font.bold: true
                                        elide: Text.ElideRight; Layout.fillWidth: true
                                    }
                                    Text {
                                        text: player.trackArtist || ""
                                        color: Theme.on_surface_variant; font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        elide: Text.ElideRight; Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }

                Item { implicitHeight: 8 }
                ErrorBanner { message: root.lastError }
                Item { implicitHeight: 14 }
            }
        }
    }
}
