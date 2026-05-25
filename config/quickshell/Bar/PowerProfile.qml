import QtQuick
import Quickshell
import Quickshell.Io
import qs.CustomTheme

Item {
    id: root
    implicitWidth: label.implicitWidth + 12
    implicitHeight: parent.height

    property string profile: "balanced"

    readonly property string profileIcon: {
        if (profile === "performance") return ""
        if (profile === "power-saver") return ""
        return ""
    }

    readonly property color profileColor: {
        if (profile === "performance") return Theme.tertiary
        if (profile === "power-saver") return Theme.secondary
        return Theme.primary
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.profileIcon
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
        color: root.profileColor
    }

    Process {
        id: ppProc
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.profile = this.text.trim() || "balanced"
            }
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: { ppProc.running = false; ppProc.running = true }
    }

    Process {
        id: ppSetProc
        onExited: (code, status) => {
            ppProc.running = false
            ppProc.running = true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            var next = root.profile === "balanced"     ? "performance"
                     : root.profile === "performance"  ? "power-saver"
                     : "balanced"
            ppSetProc.command = ["powerprofilesctl", "set", next]
            ppSetProc.running = false
            ppSetProc.running = true
        }
        HoverHandler { id: ppHover }
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
        visible: ppHover.hovered
    }
}
