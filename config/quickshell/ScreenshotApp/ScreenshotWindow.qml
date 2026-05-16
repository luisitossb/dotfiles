import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
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
        target: "screenshot"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open():   void { root.isOpen = true  }
        function close():  void { root.isOpen = false }
    }

    // ── State ─────────────────────────────────────────────────────────────────

    // 0 = choose mode, 1 = choose action
    property int   step:         0
    property string selectedMode: ""

    onIsOpenChanged: if (isOpen) { step = 0; selectedMode = "" }

    // ── Backdrop ──────────────────────────────────────────────────────────────

    Item {
        anchors.fill: parent

        // Dim overlay
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            MouseArea {
                anchors.fill: parent
                onClicked: root.isOpen = false
            }
        }

        // Card
        Rectangle {
            anchors.centerIn: parent
            implicitWidth: 340
            implicitHeight: cardCol.implicitHeight + 48
            radius: 16
            color: Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g,
                           Theme.surface_container_low.b, 0.98)
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
            border.width: 1

            // Swallow clicks so backdrop doesn't close
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: cardCol
                anchors { left: parent.left; right: parent.right; top: parent.top }
                anchors.margins: 24
                spacing: 16

                // Header
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    Text {
                        text: "󰹑"
                        font.family: "monospace"; font.pixelSize: 22
                        color: Theme.primary
                    }
                    Text {
                        text: root.step === 0 ? "Screenshot" : "Screenshot — " + root.selectedMode
                        color: Theme.on_surface
                        font.family: Theme.fontFamily; font.pixelSize: 17; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "✕"; color: Theme.on_surface_variant
                        font.family: Theme.fontFamily; font.pixelSize: 15
                        MouseArea { anchors.fill: parent; onClicked: root.isOpen = false }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 1
                    color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                }

                // Step 0: Mode selection
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 8
                    visible: root.step === 0

                    Repeater {
                        model: [
                            { icon: "󰹑", label: "Full Screen",    mode: "screen"  },
                            { icon: "󰍹", label: "Active Window",  mode: "active"  },
                            { icon: "󰆟", label: "Select Region",  mode: "area"    },
                            { icon: "󰍺", label: "Active Display", mode: "output"  },
                        ]
                        delegate: ShotButton {
                            required property var modelData
                            Layout.fillWidth: true
                            iconText:  modelData.icon
                            labelText: modelData.label
                            onActivated: {
                                root.selectedMode = modelData.mode
                                root.step = 1
                            }
                        }
                    }
                }

                // Step 1: Action selection
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 8
                    visible: root.step === 1

                    Repeater {
                        model: [
                            { icon: "󰆒", label: "Copy to Clipboard",     action: "copy"     },
                            { icon: "󰆓", label: "Save to File",           action: "save"     },
                            { icon: "󰯍", label: "Copy + Save",            action: "copysave" },
                        ]
                        delegate: ShotButton {
                            required property var modelData
                            Layout.fillWidth: true
                            iconText:  modelData.icon
                            labelText: modelData.label
                            onActivated: {
                                let mode   = root.selectedMode
                                let action = modelData.action
                                root.isOpen = false
                                Qt.callLater(() => {
                                    Quickshell.execDetached(["bash", "-c",
                                        "sleep 0.3 && grimblast --notify " + action + " " + mode])
                                })
                            }
                        }
                    }

                    // Back button
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 38; radius: 8
                        property bool hov: false
                        color: hov ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.10)
                                   : "transparent"
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.25)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }
                        RowLayout {
                            anchors.centerIn: parent; spacing: 6
                            Text { text: "←"; color: Theme.on_surface_variant; font.pixelSize: 13 }
                            Text {
                                text: "Back"
                                color: Theme.on_surface_variant
                                font.family: Theme.fontFamily; font.pixelSize: 13
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onEntered: parent.hov = true
                            onExited:  parent.hov = false
                            onClicked: root.step = 0
                        }
                    }
                }

                Item { implicitHeight: 4 }
            }
        }
    }
}
