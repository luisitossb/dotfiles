import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.CustomTheme

Item {
    id: root
    implicitWidth: label.implicitWidth + 8
    implicitHeight: parent.height

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property int volume: Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100)
    readonly property bool muted: Pipewire.defaultAudioSink?.audio.muted ?? false

    Text {
        id: label
        anchors.centerIn: parent
        text: root.muted ? "[ MUTED ]" : "[ VOL " + root.volume + "% ]"
        font.pixelSize: 12
        font.family: Theme.fontFamily
        color: root.muted ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.5)
                          : Theme.primary
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: Quickshell.execDetached(["pavucontrol"])
        onWheel: function(event) {
            var delta = event.angleDelta.y > 0 ? 5 : -5
            var newVol = Math.max(0, Math.min(100, root.volume + delta))
            Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", newVol + "%"])
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
