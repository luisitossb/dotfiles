import QtQuick
import Quickshell.Services.UPower
import qs.CustomTheme

Item {
    id: root
    implicitWidth: label.implicitWidth + 8
    implicitHeight: parent.height

    readonly property int capacity: Math.round(UPower.displayDevice?.percentage ?? 100)
    readonly property var state: UPower.displayDevice?.state ?? UPowerDeviceState.FullyCharged

    readonly property string displayText: {
        if (state === UPowerDeviceState.Charging)      return "[ CHR " + capacity + "% ]"
        if (state === UPowerDeviceState.FullyCharged)  return "[ PWR " + capacity + "% ]"
        return "[ BAT " + capacity + "% ]"
    }

    readonly property bool isWarning:  capacity <= 30 && state === UPowerDeviceState.Discharging
    readonly property bool isCritical: capacity <= 15 && state === UPowerDeviceState.Discharging

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
}
