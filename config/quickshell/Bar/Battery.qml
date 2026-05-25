import QtQuick
import Quickshell.Io
import qs.CustomTheme

Item {
    id: root
    implicitWidth: label.implicitWidth + 8
    implicitHeight: parent.height

    property int capacity: 100
    property string status: "Full"

    readonly property string displayText: {
        if (status === "Charging") return "[ CHR " + capacity + "% ]"
        if (status === "Full" || (status !== "Discharging" && capacity >= 95))
            return "[ PWR " + capacity + "% ]"
        return "[ BAT " + capacity + "% ]"
    }

    property bool isWarning: capacity <= 30 && status === "Discharging"
    property bool isCritical: capacity <= 15 && status === "Discharging"

    Text {
        id: label
        anchors.centerIn: parent
        text: root.displayText
        font.pixelSize: 12
        font.family: Theme.fontFamily
        color: root.isCritical ? Theme.error
             : root.isWarning  ? Theme.secondary
             : Theme.primary

        SequentialAnimation on opacity {
            running: root.isCritical
            loops: Animation.Infinite
            NumberAnimation { to: 0.2; duration: 500 }
            NumberAnimation { to: 1.0; duration: 500 }
        }
    }

    Process {
        id: battProc
        command: ["bash", "-c",
            "echo \"$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 100):$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo Full)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split(":")
                root.capacity = parseInt(parts[0]) || 100
                root.status   = parts[1] || "Full"
            }
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: { battProc.running = false; battProc.running = true }
    }
}
