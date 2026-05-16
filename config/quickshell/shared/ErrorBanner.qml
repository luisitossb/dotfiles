import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

Rectangle {
    id: root
    property string message: ""

    Layout.fillWidth: true
    implicitHeight: message !== "" ? 34 : 0
    visible: message !== ""
    radius: 6
    color: Qt.rgba(Theme.error_container.r, Theme.error_container.g, Theme.error_container.b, 0.85)

    Behavior on implicitHeight { NumberAnimation { duration: 120 } }

    RowLayout {
        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
        spacing: 6

        Text {
            text: "⚠"
            color: Theme.error
            font.pixelSize: 13
        }
        Text {
            Layout.fillWidth: true
            text: root.message
            color: Theme.on_error_container
            font.family: Theme.fontFamily
            font.pixelSize: 11
            elide: Text.ElideRight
        }
        Text {
            text: "✕"
            color: Theme.on_error_container
            font.pixelSize: 11
            opacity: 0.7
            MouseArea {
                anchors.fill: parent
                onClicked: root.message = ""
            }
        }
    }
}
