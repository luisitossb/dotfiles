import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme
import "../shared"

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
        target: "wifi-panel"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open():   void { root.isOpen = true  }
        function close():  void { root.isOpen = false }
    }

    // ── State ─────────────────────────────────────────────────────────────────

    property bool   wifiEnabled: true
    property var    networks:    []
    property bool   connecting:  false
    property string statusMsg:   ""
    property string errorMsg:    ""

    function refresh() {
        wifiProc.running = false; wifiProc.running = true
    }

    onIsOpenChanged: if (isOpen) { statusMsg = ""; refresh() }

    Timer { interval: 8000; running: root.isOpen; repeat: true; onTriggered: root.refresh() }
    Timer { id: connectDelay; interval: 3000; repeat: false; onTriggered: { root.connecting = false; root.refresh() } }

    Process {
        id: wifiProc
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/wifi-networks.sh"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                let d = JSON.parse(this.text.trim())
                root.wifiEnabled = d.enabled
                root.networks    = d.networks || []
                root.errorMsg    = ""
            } catch(e) {
                let msg = "Failed to parse network list: " + e
                console.warn("wifi-networks: " + msg)
                root.errorMsg = msg
            }
        }}
        stderr: StdioCollector { onStreamFinished: {
            let e = this.text.trim()
            if (e) { console.warn("wifi-networks: " + e); root.errorMsg = e }
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
                    text: "󰤨"; font.family: "monospace"; font.pixelSize: 20
                    color: root.wifiEnabled ? Theme.primary : Theme.on_surface_variant
                }
                Text {
                    text: "WiFi"; color: Theme.on_surface
                    font.family: Theme.fontFamily; font.pixelSize: 16; font.bold: true
                    Layout.fillWidth: true
                }
                // Toggle switch
                Rectangle {
                    implicitWidth: 46; implicitHeight: 26; radius: 13
                    color: root.wifiEnabled ? Theme.primary : Theme.surface_container_high
                    border.color: Theme.primary; border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        x: root.wifiEnabled ? parent.width - width - 2 : 2
                        y: 2; width: 22; height: 22; radius: 11
                        color: root.wifiEnabled ? Theme.on_primary : Theme.on_primary_container
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            let cmd = root.wifiEnabled ? "nmcli radio wifi off" : "nmcli radio wifi on"
                            Quickshell.execDetached(["bash", "-c", cmd])
                            root.wifiEnabled = !root.wifiEnabled
                        }
                    }
                }
            }

            // Status message
            Text {
                Layout.fillWidth: true
                text: root.statusMsg
                color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                visible: root.statusMsg !== ""
            }

            ErrorBanner { message: root.errorMsg }

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 1
                color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
            }

            // Network list
            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                visible: root.wifiEnabled && root.networks.length > 0

                Repeater {
                    model: root.networks
                    delegate: Rectangle {
                        required property var modelData
                        property bool hov: false
                        Layout.fillWidth: true; implicitHeight: 44; radius: 8
                        color: modelData.connected
                               ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)
                               : hov ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.05)
                               : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 10
                            Text {
                                text: modelData.connected ? "󰤨" : "󰤫"
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
                                if (modelData.connected || root.connecting) return
                                root.connecting = true
                                root.statusMsg = "Connecting to " + modelData.name + "..."
                                Quickshell.execDetached(["bash", "-c",
                                    "nmcli connection up '" + modelData.name + "' 2>/dev/null || " +
                                    "nmcli device wifi connect '" + modelData.name + "' 2>/dev/null"])
                                connectDelay.start()
                            }
                        }
                    }
                }
            }

            // Empty / disabled states
            Text {
                Layout.fillWidth: true
                text: root.wifiEnabled ? "No saved networks" : "WiFi is off"
                color: Theme.on_surface_variant; font.family: Theme.fontFamily
                font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter
                visible: !root.wifiEnabled || root.networks.length === 0
                Layout.bottomMargin: 4
            }

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 1
                color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                visible: root.wifiEnabled
            }

            // Open full network manager
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 36; radius: 8; visible: root.wifiEnabled
                property bool hov: false
                color: hov ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10) : "transparent"
                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.30)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }
                Text {
                    anchors.centerIn: parent
                    text: "󰐪  More networks"
                    color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 13
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: parent.hov = true
                    onExited:  parent.hov = false
                    onClicked: {
                        root.isOpen = false
                        Quickshell.execDetached(["bash", "-c", "networkmanager_dmenu"])
                    }
                }
            }

            Item { implicitHeight: 6 }
        }
    }
}
