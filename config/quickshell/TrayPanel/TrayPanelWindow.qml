import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore
    color: "transparent"

    anchors { left: true; right: true; top: true; bottom: true }

    property bool isOpen: false
    visible: isOpen

    HyprlandFocusGrab {
        windows: [root]
        active: root.isOpen
        onCleared: root.isOpen = false
    }

    Shortcut {
        sequence: "Escape"
        onActivated: if (root.isOpen) root.isOpen = false
    }

    IpcHandler {
        target: "tray-panel"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open():   void { root.isOpen = true }
        function close():  void { root.isOpen = false }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.isOpen = false
    }

    // ── UI ────────────────────────────────────────────────────────────────────

    Item {
        anchors.centerIn: parent
        width: 360
        height: col.implicitHeight + 48

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Qt.rgba(Theme.surface_container_low.r,
                           Theme.surface_container_low.g,
                           Theme.surface_container_low.b, 1.0)
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
            border.width: 1
        }

        ColumnLayout {
            id: col
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 16

            Text {
                text: "System Tray"
                color: Theme.on_surface
                font.family: Theme.fontFamily
                font.pixelSize: 14; font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            // ── Icon row ──────────────────────────────────────────────────────
            Flow {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                Repeater {
                    model: SystemTray.items.values
                    delegate: Item {
                        required property var modelData

                        width: 36; height: 36

                        Rectangle {
                            anchors.fill: parent; radius: 8
                            color: iconArea.containsMouse
                                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                : "transparent"
                            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b,
                                iconArea.containsMouse ? 0.5 : 0.25)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Behavior on border.color { ColorAnimation { duration: 100 } }
                        }

                        Image {
                            anchors.centerIn: parent
                            source: modelData.icon
                            width: 22; height: 22
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        MouseArea {
                            id: iconArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    modelData.menu?.open(iconArea, 0, -modelData.menu.height)
                                } else {
                                    modelData.activate()
                                    root.isOpen = false
                                }
                            }
                        }

                        // Tooltip
                        Rectangle {
                            visible: iconArea.containsMouse && modelData.title !== ""
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top
                            anchors.bottomMargin: 6
                            width: tipText.implicitWidth + 12
                            height: tipText.implicitHeight + 8
                            radius: 6
                            color: Qt.rgba(Theme.surface_container_high.r,
                                           Theme.surface_container_high.g,
                                           Theme.surface_container_high.b, 1.0)
                            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                            border.width: 1
                            z: 10
                            Text {
                                id: tipText
                                anchors.centerIn: parent
                                text: modelData.title
                                color: Theme.on_surface
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }

            Text {
                visible: SystemTray.items.values.length === 0
                text: "No tray apps running"
                color: Theme.on_surface_variant
                font.family: Theme.fontFamily
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
