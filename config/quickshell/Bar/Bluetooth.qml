import QtQuick
import Quickshell
import Quickshell.Io
import qs.CustomTheme

Item {
    id: root
    implicitWidth: label.implicitWidth + 8
    implicitHeight: parent.height

    property string btState: "on"

    readonly property string displayText: btState === "none" ? "" : "[  ]"

    readonly property color iconColor: {
        if (btState === "connected") return Theme.tertiary
        if (btState === "off")
            return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4)
        if (btState === "disabled")
            return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
        return Theme.primary
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.displayText
        font.pixelSize: 12
        font.family: "JetBrainsMono Nerd Font"
        color: root.iconColor
        visible: root.btState !== "none"
    }

    Process {
        id: btProc
        command: ["bash", "-c", [
            "POWERED=$(bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}')",
            "if [ -z \"$POWERED\" ]; then echo 'none'; exit; fi",
            "if [ \"$POWERED\" != 'yes' ]; then echo 'off'; exit; fi",
            "CONN=$(bluetoothctl devices Connected 2>/dev/null | wc -l)",
            "[ \"$CONN\" -gt 0 ] && echo 'connected' || echo 'on'"
        ].join("; ")]
        stdout: StdioCollector {
            onStreamFinished: {
                root.btState = this.text.trim() || "none"
            }
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: btProc.running = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "bluetooth-panel", "toggle"])
        HoverHandler { id: btHover }
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
        visible: btHover.hovered
    }
}
