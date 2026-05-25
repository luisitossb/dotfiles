import QtQuick
import qs.CustomTheme

Text {
    id: root

    color: Theme.primary
    font.pixelSize: 12
    font.family: "JetBrainsMono Nerd Font"

    property var now: new Date()
    text: Qt.formatDateTime(now, "hh:mm AP ddd")

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }
}
