import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.CustomTheme
import "../shared"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore
    implicitWidth:  320
    implicitHeight: mainCol.implicitHeight + 2
    color: "transparent"

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
        target: "resource-manager"
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

    onIsOpenChanged: {
        if (isOpen) {
            modeProc.running   = false; modeProc.running   = true
            shaderProc.running = false; shaderProc.running = true
            powerProc.running  = false; powerProc.running  = true
        }
    }

    function logErr(source, msg) {
        let e = msg.split('\n')[0]
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

    // ── Reusable components ───────────────────────────────────────────────────

    component Divider: Rectangle {
        Layout.fillWidth: true; implicitHeight: 1
        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
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

    component RingGauge: Item {
        id: ringItem
        property int    pct:      0
        property string label:    ""
        property string subLabel: ""
        property color  ringColor: Theme.primary

        implicitWidth:  120
        implicitHeight: 126

        Canvas {
            id: ringCanvas
            readonly property int size: Math.min(ringItem.width, 100)
            width:  size
            height: size
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            property int   drawnPct:   ringItem.pct
            property color drawnColor: ringItem.ringColor
            onDrawnPctChanged:   requestPaint()
            onDrawnColorChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var cx = width  / 2
                var cy = height / 2
                var r  = Math.min(cx, cy) - 7
                var lw = 7

                var startAngle = 135 * Math.PI / 180
                var sweep      = 270 * Math.PI / 180

                // Background track
                ctx.beginPath()
                ctx.arc(cx, cy, r, startAngle, startAngle + sweep, false)
                ctx.lineWidth   = lw
                ctx.strokeStyle = Qt.rgba(Theme.surface_container_high.r,
                                          Theme.surface_container_high.g,
                                          Theme.surface_container_high.b, 0.65)
                ctx.lineCap = "round"
                ctx.stroke()

                // Value arc
                if (drawnPct > 0) {
                    var endAngle = startAngle + (Math.min(drawnPct, 100) / 100) * sweep
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, startAngle, endAngle, false)
                    ctx.lineWidth   = lw
                    ctx.strokeStyle = Qt.rgba(drawnColor.r, drawnColor.g, drawnColor.b, 1.0)
                    ctx.lineCap = "round"
                    ctx.stroke()
                }
            }
        }

        // Percentage text
        Text {
            anchors.horizontalCenter: ringCanvas.horizontalCenter
            anchors.verticalCenter:   ringCanvas.verticalCenter
            anchors.verticalCenterOffset: ringItem.subLabel !== "" ? -7 : 0
            text:  ringItem.pct + "%"
            color: Theme.on_surface
            font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true
        }

        // Sub-info (temp / used) inside ring
        Text {
            visible: ringItem.subLabel !== ""
            anchors.horizontalCenter: ringCanvas.horizontalCenter
            anchors.verticalCenter:   ringCanvas.verticalCenter
            anchors.verticalCenterOffset: 9
            text:  ringItem.subLabel
            color: Theme.on_surface_variant
            font.family: Theme.fontFamily; font.pixelSize: 9
        }

        // Label below ring
        Text {
            anchors.top:              ringCanvas.bottom
            anchors.topMargin:        6
            anchors.horizontalCenter: parent.horizontalCenter
            text:  ringItem.label
            color: Theme.on_surface_variant
            font.family: Theme.fontFamily; font.pixelSize: 11
            font.letterSpacing: 1
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
            contentWidth: width
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

                Item { implicitHeight: 20 }

                // ── Ring gauges (2×2 grid) ────────────────────────────────────
                GridLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16; Layout.rightMargin: 16
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8

                    RingGauge {
                        Layout.fillWidth: true
                        pct: root.cpuUsage; label: "CPU"
                        subLabel: root.cpuTemp + "°C"
                        ringColor: Theme.primary
                    }
                    RingGauge {
                        Layout.fillWidth: true
                        pct: root.diskUsage; label: "DISK"
                        subLabel: root.diskInfo
                        ringColor: Theme.secondary
                    }
                    RingGauge {
                        Layout.fillWidth: true
                        pct: root.ramUsage; label: "RAM"
                        subLabel: root.ramUsed
                        ringColor: Theme.tertiary
                    }
                    RingGauge {
                        Layout.fillWidth: true
                        pct: root.vramUsage; label: "VRAM"
                        subLabel: root.vramInfo
                        ringColor: root.vramUsage > 85 ? Theme.error : Theme.tertiary
                    }
                }

                Item { implicitHeight: 14 }
                Divider { Layout.leftMargin: 22; Layout.rightMargin: 22 }
                Item { implicitHeight: 12 }

                // ── System info rows ──────────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 22; Layout.rightMargin: 22
                    spacing: 10

                    SysRow { rowIcon: "󰓅"; rowLabel: "Network"; rowValue: root.netSpeed }
                    SysRow { rowIcon: "󰔟"; rowLabel: "Uptime";  rowValue: root.uptimeStr }
                }

                Item { implicitHeight: 8 }
                ErrorBanner { message: root.lastError }
                Item { implicitHeight: 14 }
            }
        }
    }
}
