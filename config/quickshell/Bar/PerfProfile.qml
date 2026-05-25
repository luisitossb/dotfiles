import QtQuick
import Quickshell.Services.UPower
import qs.CustomTheme

Item {
    id: root
    implicitWidth: label.implicitWidth + 12
    implicitHeight: parent.height

    readonly property string profileIcon: {
        if (PowerProfiles.profile === PowerProfile.Performance) return ""
        if (PowerProfiles.profile === PowerProfile.PowerSaver)  return ""
        return ""
    }

    readonly property color profileColor: {
        if (PowerProfiles.profile === PowerProfile.Performance) return Theme.tertiary
        if (PowerProfiles.profile === PowerProfile.PowerSaver)  return Theme.secondary
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

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (PowerProfiles.profile === PowerProfile.Balanced) {
                PowerProfiles.profile = PowerProfile.Performance
            } else if (PowerProfiles.profile === PowerProfile.Performance) {
                PowerProfiles.profile = PowerProfile.PowerSaver
            } else {
                PowerProfiles.profile = PowerProfile.Balanced
            }
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
