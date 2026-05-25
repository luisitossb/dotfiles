import QtQuick
import Quickshell
import Quickshell.Io
import qs.CustomTheme

Item {
    id: root
    implicitWidth: label.implicitWidth + 8
    implicitHeight: parent.height

    property int volume: 50
    property bool muted: false

    Text {
        id: label
        anchors.centerIn: parent
        text: root.muted ? "[ MUTED ]" : "[ VOL " + root.volume + "% ]"
        font.pixelSize: 12
        font.family: "JetBrainsMono Nerd Font"
        color: root.muted ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.5)
                          : Theme.primary
    }

    Process {
        id: volProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo 'Volume: 0.50'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var txt = this.text.trim()
                root.muted   = txt.includes("[MUTED]")
                var m = txt.match(/Volume:\s*([\d.]+)/)
                root.volume  = m ? Math.round(parseFloat(m[1]) * 100) : 50
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: volProc.running = true
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: Quickshell.execDetached(["pavucontrol"])
        onWheel: function(event) {
            var delta = event.angleDelta.y > 0 ? 5 : -5
            Quickshell.execDetached(["bash", "-c",
                "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (root.volume + delta) + "%"])
            volProc.running = true
        }

        HoverHandler { id: volHover }
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
        visible: volHover.hovered
    }
}
