import QtQuick
import Quickshell
import Quickshell.Io
import qs.CustomTheme

Item {
    id: root
    implicitWidth: label.implicitWidth + 12
    implicitHeight: parent.height

    property string modeIcon: ""
    property string modeClass: "laptop"
    property string modeTooltip: ""

    Text {
        id: label
        anchors.centerIn: parent
        text: root.modeIcon
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
        color: root.modeClass === "server" ? Theme.secondary : Theme.primary
    }

    Process {
        id: modeProc
        command: [Quickshell.env("HOME") + "/.local/bin/mode-status.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(this.text.trim())
                    root.modeIcon    = d.text    || ""
                    root.modeClass   = d["class"] || "laptop"
                    root.modeTooltip = d.tooltip  || ""
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: { modeProc.running = false; modeProc.running = true }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/toggle-mode.sh"])
            Qt.callLater(() => modeProc.running = true)
        }
        HoverHandler { id: modeHover }
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
        visible: modeHover.hovered
    }
}
