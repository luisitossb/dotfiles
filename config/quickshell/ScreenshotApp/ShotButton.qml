import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

Rectangle {
    id: root

    signal activated()

    property string iconText:  ""
    property string labelText: ""

    implicitHeight: 44; radius: 8
    property bool hov: false
    color: hov ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10) : "transparent"
    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
    border.width: 1
    Behavior on color { ColorAnimation { duration: 100 } }

    RowLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 12
        Text {
            text: root.iconText
            font.family: "monospace"; font.pixelSize: 18
            color: Theme.primary
        }
        Text {
            text: root.labelText
            color: Theme.on_surface
            font.family: Theme.fontFamily; font.pixelSize: 14
            Layout.fillWidth: true
        }
    }

    MouseArea {
        anchors.fill: parent; hoverEnabled: true
        onEntered: root.hov = true
        onExited:  root.hov = false
        onClicked: root.activated()
    }
}
