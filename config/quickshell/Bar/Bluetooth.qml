import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.CustomTheme

Item {
    id: root
    implicitWidth: label.implicitWidth + 8
    implicitHeight: parent.height

    readonly property bool hasAdapter: Bluetooth.defaultAdapter !== null
    readonly property bool powered: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property bool anyConnected: {
        var devs = Bluetooth.defaultAdapter?.devices ?? []
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].connected) return true
        }
        return false
    }

    visible: hasAdapter

    Text {
        id: label
        anchors.centerIn: parent
        text: "[  ]"
        font.pixelSize: 12
        font.family: "JetBrainsMono Nerd Font"
        color: root.anyConnected ? Theme.tertiary
             : root.powered      ? Theme.primary
             :                     Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4)
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
