import QtQuick
import Quickshell
import Quickshell.Networking
import qs.CustomTheme

Item {
    id: root
    implicitWidth: label.implicitWidth + 8
    implicitHeight: parent.height

    readonly property var activeDevice: {
        var devs = Networking.devices.values
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].connected) return devs[i]
        }
        return null
    }

    readonly property bool isWifi:   activeDevice?.type === DeviceType.Wifi
    readonly property bool isWired:  activeDevice?.type === DeviceType.Wired

    readonly property int wifiSignal: {
        if (!isWifi || !activeDevice) return 0
        var nets = activeDevice.networks.values
        for (var i = 0; i < nets.length; i++) {
            if (nets[i].connected) return Math.round(nets[i].signalStrength * 100)
        }
        return 0
    }

    readonly property string displayText: {
        if (isWired) return "[ ETH ]"
        if (isWifi)  return "[ WIFI " + wifiSignal + "% ]"
        return "[ ⚠ ]"
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.displayText
        font.pixelSize: 12
        font.family: Theme.fontFamily
        color: Theme.primary
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
