import QtQuick
import Quickshell
import Quickshell.Io
import qs.CustomTheme

Item {
    id: root
    implicitWidth: label.implicitWidth + 8
    implicitHeight: parent.height

    property string netType: "disconnected"
    property int    wifiSignal: 0

    readonly property string displayText: {
        if (netType === "ethernet") return "[ ETH ]"
        if (netType === "wifi")     return "[ WIFI " + wifiSignal + "% ]"
        return "[ ⚠ ]"
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.displayText
        font.pixelSize: 12
        font.family: "JetBrainsMono Nerd Font"
        color: Theme.primary
    }

    Process {
        id: netProc
        command: ["bash", "-c",
            "IFACE=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \\K\\S+' | head -1); " +
            "if [ -z \"$IFACE\" ]; then echo disconnected; exit; fi; " +
            "if iw dev \"$IFACE\" info >/dev/null 2>&1 || echo \"$IFACE\" | grep -qE '^wl'; then " +
            "SIG=$(nmcli -t -f ACTIVE,SIGNAL dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 | head -1); " +
            "echo \"wifi:${SIG:-0}\"; else echo ethernet; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var txt = this.text.trim()
                if (txt.startsWith("wifi:")) {
                    root.netType    = "wifi"
                    root.wifiSignal = parseInt(txt.split(":")[1]) || 0
                } else if (txt === "ethernet") {
                    root.netType    = "ethernet"
                } else {
                    root.netType    = "disconnected"
                }
            }
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: { netProc.running = false; netProc.running = true }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["kitty", "--class", "dotfiles-floating", "-e", "nmtui"])
            } else {
                Quickshell.execDetached(["qs", "ipc", "call", "wifi-panel", "toggle"])
            }
        }
        HoverHandler { id: netHover }
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
        visible: netHover.hovered
    }
}
