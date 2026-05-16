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
    implicitWidth: 300
    color: "transparent"

    anchors { right: true; top: true }
    margins { right: 16; top: 54 }

    // ── Open / close ──────────────────────────────────────────────────────────

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
        target: "bluetooth-panel"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open():   void { root.isOpen = true  }
        function close():  void { root.isOpen = false }
    }

    // ── State ─────────────────────────────────────────────────────────────────

    property bool    btPowered: false
    property var     btDevices: []
    property bool    scanning:  false

    function refresh() {
        btStateProc.running = false; btStateProc.running = true
        btDevicesProc.running = false; btDevicesProc.running = true
    }

    onIsOpenChanged: if (isOpen) refresh()

    Timer { interval: 5000; running: root.isOpen; repeat: true; onTriggered: root.refresh() }
    Timer { id: actionDelay; interval: 2000; repeat: false; onTriggered: root.refresh() }
    Timer { id: scanTimer;   interval: 5500; repeat: false; onTriggered: { root.scanning = false; root.refresh() } }

    Process {
        id: btStateProc
        command: ["bash", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo 1 || echo 0"]
        stdout: StdioCollector { onStreamFinished: root.btPowered = (this.text.trim() === "1") }
    }

    Process {
        id: btDevicesProc
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/bt-devices.sh"]
        stdout: StdioCollector { onStreamFinished: {
            try { root.btDevices = JSON.parse(this.text.trim()) } catch(e) { root.btDevices = [] }
        }}
    }

    // ── UI ────────────────────────────────────────────────────────────────────

    implicitHeight: panelCol.implicitHeight + 36

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent; radius: 14
            color: Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g,
                           Theme.surface_container_low.b, 0.95)
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
            border.width: 1
        }

        ColumnLayout {
            id: panelCol
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.margins: 18
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                Text {
                    text: "󰂯"; font.family: "monospace"; font.pixelSize: 20
                    color: root.btPowered ? Theme.primary : Theme.on_surface_variant
                }
                Text {
                    text: "Bluetooth"; color: Theme.on_surface
                    font.family: Theme.fontFamily; font.pixelSize: 16; font.bold: true
                    Layout.fillWidth: true
                }
                // Power toggle switch
                Rectangle {
                    implicitWidth: 46; implicitHeight: 26; radius: 13
                    color: root.btPowered ? Theme.primary : Theme.surface_container_high
                    border.color: Theme.primary; border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        x: root.btPowered ? parent.width - width - 2 : 2
                        y: 2; width: 22; height: 22; radius: 11
                        color: root.btPowered ? Theme.on_primary : Theme.on_primary_container
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            let cmd = root.btPowered ? "bluetoothctl power off" : "bluetoothctl power on"
                            Quickshell.execDetached(["bash", "-c", cmd])
                            root.btPowered = !root.btPowered
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 1
                color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
            }

            // Device list
            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                visible: root.btPowered && root.btDevices.length > 0

                Repeater {
                    model: root.btDevices
                    delegate: Rectangle {
                        required property var modelData
                        property bool hov: false
                        Layout.fillWidth: true; implicitHeight: 46; radius: 8
                        color: modelData.connected
                               ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)
                               : hov ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.05)
                               : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 10
                            Text {
                                text: modelData.connected ? "  " : "   "
                                font.family: "monospace"; font.pixelSize: 16
                                color: modelData.connected ? Theme.primary : Theme.on_surface_variant
                            }
                            Text {
                                text: modelData.name
                                color: modelData.connected ? Theme.primary : Theme.on_surface
                                font.family: Theme.fontFamily; font.pixelSize: 13
                                Layout.fillWidth: true; elide: Text.ElideRight
                            }
                            Text {
                                text: modelData.connected ? "connected" : ""; color: Theme.primary
                                font.family: Theme.fontFamily; font.pixelSize: 11; opacity: 0.7
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onEntered: parent.hov = true
                            onExited:  parent.hov = false
                            onClicked: {
                                let mac = modelData.mac
                                let cmd = modelData.connected
                                    ? "bluetoothctl disconnect " + mac
                                    : "bluetoothctl connect " + mac
                                Quickshell.execDetached(["bash", "-c", cmd])
                                actionDelay.start()
                            }
                        }
                    }
                }
            }

            // Empty state
            Text {
                Layout.fillWidth: true
                text: root.btPowered ? "No paired devices" : "Bluetooth is off"
                color: Theme.on_surface_variant; font.family: Theme.fontFamily
                font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter
                visible: !root.btPowered || root.btDevices.length === 0
                Layout.bottomMargin: 4
            }

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 1
                color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                visible: root.btPowered
            }

            // Scan button
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 36; radius: 8; visible: root.btPowered
                property bool hov: false
                color: hov ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10) : "transparent"
                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.30)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }
                Text {
                    anchors.centerIn: parent
                    text: root.scanning ? "Scanning..." : "󰑓  Scan for devices"
                    color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 13
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: parent.hov = true
                    onExited:  parent.hov = false
                    onClicked: {
                        if (root.scanning) return
                        root.scanning = true
                        Quickshell.execDetached(["bash", "-c", "bluetoothctl scan on & sleep 5; kill %1 2>/dev/null"])
                        scanTimer.start()
                    }
                }
            }

            Item { implicitHeight: 6 }
        }
    }
}
