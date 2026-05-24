import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.CustomTheme
import "../shared"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-wifi"
    exclusionMode: WlrLayershell.Ignore
    implicitWidth: 320
    color: "transparent"

    anchors { right: true; top: true }
    margins { right: 16; top: 54 }

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
        function open():   void { root.isOpen = true }
        function close():  void { root.isOpen = false }
    }

    // ── State ─────────────────────────────────────────────────────────────────

    property bool   wifiEnabled:  true
    property var    networks:     []
    property bool   fullBrowser:  false
    property bool   scanning:     false
    property string filterText:   ""
    property string statusMsg:    ""
    property string errorMsg:     ""
    property string connectingTo: ""
    property string selectedSsid: ""
    property string passwordText: ""
    property bool   pwHidden:     true

    onIsOpenChanged: {
        if (isOpen) {
            fullBrowser  = false
            filterText   = ""
            statusMsg    = ""
            errorMsg     = ""
            selectedSsid = ""
            passwordText = ""
            networks     = []
            quickProc.running = false; quickProc.running = true
        }
    }

    Timer { interval: 10000; running: root.isOpen && root.fullBrowser;  repeat: true; onTriggered: { scanProc.running  = false; scanProc.running  = true } }
    Timer { interval: 8000;  running: root.isOpen && !root.fullBrowser; repeat: true; onTriggered: { quickProc.running = false; quickProc.running = true } }
    Timer { id: connectDelay; interval: 4000; onTriggered: { root.connectingTo = ""; scanProc.running = false; scanProc.running = true } }
    Timer { id: statusClear;  interval: 3000; onTriggered: root.statusMsg = "" }

    Process {
        id: quickProc
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/wifi-networks.sh"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                let d = JSON.parse(this.text.trim())
                root.wifiEnabled = d.enabled
                root.networks = (d.networks || []).map(function(n) {
                    return { ssid: n.name, signal: 70, security: "", saved: true, connected: n.connected }
                })
                root.errorMsg = ""
            } catch(e) { root.errorMsg = "Failed to load networks" }
        }}
        stderr: StdioCollector { onStreamFinished: {
            let e = this.text.trim(); if (e) root.errorMsg = e
        }}
    }

    Process {
        id: scanProc
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/wifi-scan.sh"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                let d = JSON.parse(this.text.trim())
                root.wifiEnabled = d.enabled
                root.networks = d.networks || []
                root.errorMsg = ""
            } catch(e) { root.errorMsg = "Failed to scan networks" }
            root.scanning = false
        }}
        stderr: StdioCollector { onStreamFinished: {
            let e = this.text.trim(); if (e) { root.errorMsg = e; root.scanning = false }
        }}
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    function signalIcon(s) {
        if (s >= 75) return "󰤨"
        if (s >= 55) return "󰤥"
        if (s >= 35) return "󰤢"
        return "󰤟"
    }

    function signalColor(s) {
        if (s >= 60) return "#4caf50"
        if (s >= 35) return "#ff9800"
        return "#f44336"
    }

    function doConnect(ssid, saved, password) {
        root.connectingTo = ssid
        root.statusMsg    = "Connecting to " + ssid + "…"
        root.selectedSsid = ""
        root.passwordText = ""
        if (password !== "") {
            Quickshell.execDetached(["bash", "-c",
                "nmcli device wifi connect '" + ssid + "' password '" + password + "' 2>/dev/null"])
        } else {
            Quickshell.execDetached(["bash", "-c",
                "nmcli connection up '" + ssid + "' 2>/dev/null || nmcli device wifi connect '" + ssid + "' 2>/dev/null"])
        }
        connectDelay.restart()
        statusClear.restart()
    }

    // ── UI ────────────────────────────────────────────────────────────────────

    implicitHeight: panelCol.implicitHeight + 36

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent; radius: 14
            color: Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g,
                           Theme.surface_container_low.b, 0.97)
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
            border.width: 1
        }

        ColumnLayout {
            id: panelCol
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.margins: 16
            spacing: 10

            // ── Header ────────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true; spacing: 10

                Rectangle {
                    visible: root.fullBrowser
                    implicitWidth: 28; implicitHeight: 28; radius: 8
                    color: backHov.containsMouse
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "󰁍"; font.family: "monospace"; font.pixelSize: 16; color: Theme.primary }
                    MouseArea {
                        id: backHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            root.fullBrowser  = false
                            root.filterText   = ""
                            root.selectedSsid = ""
                            root.networks     = []
                            quickProc.running = false; quickProc.running = true
                        }
                    }
                }

                Text {
                    visible: !root.fullBrowser
                    text: "󰤨"; font.family: "monospace"; font.pixelSize: 20
                    color: root.wifiEnabled ? Theme.primary : Theme.on_surface_variant
                }

                Text {
                    text: root.fullBrowser ? "All Networks" : "WiFi"
                    color: Theme.on_surface; font.family: Theme.fontFamily
                    font.pixelSize: 15; font.bold: true; Layout.fillWidth: true
                }

                Rectangle {
                    visible: root.fullBrowser
                    implicitWidth: 28; implicitHeight: 28; radius: 8
                    color: rescanHov.containsMouse
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent; text: "󰑐"; font.family: "monospace"; font.pixelSize: 15
                        color: Theme.primary; opacity: root.scanning ? 0.4 : 1.0
                    }
                    MouseArea {
                        id: rescanHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: if (!root.scanning) { root.scanning = true; scanProc.running = false; scanProc.running = true }
                    }
                }

                Rectangle {
                    implicitWidth: 46; implicitHeight: 26; radius: 13
                    color: root.wifiEnabled ? Theme.primary
                        : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 1.0)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        x: root.wifiEnabled ? parent.width - width - 2 : 2
                        y: 2; width: 22; height: 22; radius: 11
                        color: root.wifiEnabled ? Theme.on_primary
                            : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.6)
                        Behavior on x     { NumberAnimation { duration: 150; easing.type: Easing.OutQuint } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Quickshell.execDetached(["bash", "-c",
                                root.wifiEnabled ? "nmcli radio wifi off" : "nmcli radio wifi on"])
                            root.wifiEnabled = !root.wifiEnabled
                            root.networks = []
                        }
                    }
                }
            }

            Text {
                visible: root.statusMsg !== ""; Layout.fillWidth: true
                text: root.statusMsg; color: Theme.primary
                font.family: Theme.fontFamily; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter
            }

            ErrorBanner { message: root.errorMsg }

            RowLayout {
                visible: root.scanning && root.fullBrowser; Layout.fillWidth: true; spacing: 8
                Text { text: "󰤨"; font.family: "monospace"; font.pixelSize: 14; color: Theme.primary; opacity: 0.6 }
                Text { text: "Scanning…"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 12 }
            }

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 1
                color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
            }

            // ── Filter bar ────────────────────────────────────────────────────
            Rectangle {
                visible: root.fullBrowser
                Layout.fillWidth: true; implicitHeight: 36; radius: 8
                color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g,
                               Theme.surface_container_high.b, 0.8)
                border.color: filterField.activeFocus
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.5) : "transparent"
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    spacing: 8
                    Text { text: "󰍉"; font.family: "monospace"; font.pixelSize: 14; color: Theme.on_surface_variant }
                    TextField {
                        id: filterField
                        Layout.fillWidth: true
                        placeholderText: "Filter networks…"
                        color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13
                        background: null
                        leftPadding: 0; rightPadding: 0; topPadding: 0; bottomPadding: 0
                        onTextChanged: root.filterText = text
                    }
                    Text {
                        visible: root.filterText !== ""; text: "󰅖"
                        font.family: "monospace"; font.pixelSize: 13; color: Theme.on_surface_variant
                        MouseArea { anchors.fill: parent; onClicked: { root.filterText = ""; filterField.text = "" } }
                    }
                }
            }

            // ── Network list ──────────────────────────────────────────────────
            ColumnLayout {
                id: netCol
                Layout.fillWidth: true
                spacing: 3
                visible: root.wifiEnabled

                    Repeater {
                        model: root.networks
                        delegate: Rectangle {
                            required property var modelData
                            property bool isSelected: root.selectedSsid === modelData.ssid
                            property bool hov: false
                            property bool passMatch: root.filterText === "" ||
                                modelData.ssid.toLowerCase().indexOf(root.filterText.toLowerCase()) !== -1

                            visible: passMatch
                            Layout.fillWidth: true
                            implicitHeight: isSelected ? 82 : 44
                            radius: 10; clip: true

                            Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutQuint } }

                            color: modelData.connected
                                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                                : isSelected
                                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                                    : hov
                                        ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.8)
                                        : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.4)
                            Behavior on color { ColorAnimation { duration: 100 } }

                            ColumnLayout {
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true; implicitHeight: 44; spacing: 10

                                    Text {
                                        text: root.fullBrowser ? root.signalIcon(modelData.signal) : "󰤨"
                                        font.family: "monospace"; font.pixelSize: 16
                                        color: modelData.connected ? Theme.primary
                                            : root.fullBrowser ? root.signalColor(modelData.signal)
                                            : Theme.on_surface_variant
                                    }

                                    ColumnLayout { Layout.fillWidth: true; spacing: 1
                                        Text {
                                            text: modelData.ssid; Layout.fillWidth: true
                                            color: modelData.connected ? Theme.primary : Theme.on_surface
                                            font.family: Theme.fontFamily; font.pixelSize: 13; font.bold: modelData.connected
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            visible: root.fullBrowser
                                            text: modelData.saved ? "Saved" : (modelData.security || "Open")
                                            color: modelData.saved ? Theme.primary : Theme.on_surface_variant
                                            font.family: Theme.fontFamily; font.pixelSize: 10; opacity: 0.8
                                        }
                                    }

                                    Text {
                                        text: modelData.connected ? "connected"
                                            : root.connectingTo === modelData.ssid ? "connecting…" : ""
                                        color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 11
                                        opacity: 0.8; visible: text !== ""
                                    }

                                    Text {
                                        visible: root.fullBrowser && !modelData.saved
                                            && modelData.security !== "" && modelData.security !== "Open"
                                            && !modelData.connected
                                        text: "󰌾"; font.family: "monospace"; font.pixelSize: 13
                                        color: Theme.on_surface_variant; opacity: 0.6
                                    }

                                    Rectangle {
                                        visible: modelData.connected
                                        implicitWidth: 26; implicitHeight: 26; radius: 6
                                        color: disconnHov.containsMouse
                                            ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2) : "transparent"
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        Text { anchors.centerIn: parent; text: "󰖪"; font.family: "monospace"; font.pixelSize: 13; color: Theme.error; opacity: 0.8 }
                                        MouseArea {
                                            id: disconnHov; anchors.fill: parent; hoverEnabled: true
                                            onClicked: {
                                                Quickshell.execDetached(["bash", "-c",
                                                    "nmcli con down '" + modelData.ssid + "' 2>/dev/null || true"])
                                                root.statusMsg = "Disconnected"
                                                statusClear.restart()
                                                scanProc.running = false; scanProc.running = true
                                            }
                                        }
                                    }
                                }

                                // Password row
                                RowLayout {
                                    visible: isSelected; Layout.fillWidth: true; spacing: 6; Layout.bottomMargin: 8

                                    Rectangle {
                                        Layout.fillWidth: true; implicitHeight: 30; radius: 6
                                        color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                        border.color: pwField.activeFocus
                                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.6)
                                            : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                                        border.width: 1
                                        Behavior on border.color { ColorAnimation { duration: 120 } }

                                        RowLayout {
                                            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                            spacing: 6
                                            TextField {
                                                id: pwField
                                                Layout.fillWidth: true
                                                placeholderText: "Password"
                                                echoMode: root.pwHidden ? TextInput.Password : TextInput.Normal
                                                color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 12
                                                background: null
                                                leftPadding: 0; rightPadding: 0; topPadding: 0; bottomPadding: 0
                                                onTextChanged: root.passwordText = text
                                                Keys.onReturnPressed: root.doConnect(modelData.ssid, modelData.saved, root.passwordText)
                                                Component.onCompleted: forceActiveFocus()
                                            }
                                            Text {
                                                text: root.pwHidden ? "󰈈" : "󰈉"
                                                font.family: "monospace"; font.pixelSize: 13; color: Theme.on_surface_variant
                                                MouseArea { anchors.fill: parent; onClicked: root.pwHidden = !root.pwHidden }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        implicitWidth: 30; implicitHeight: 30; radius: 6
                                        color: connBtnHov.containsMouse
                                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 1.0)
                                            : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.7)
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        Text { anchors.centerIn: parent; text: "󰍕"; font.family: "monospace"; font.pixelSize: 14; color: Theme.on_primary }
                                        MouseArea {
                                            id: connBtnHov; anchors.fill: parent; hoverEnabled: true
                                            onClicked: root.doConnect(modelData.ssid, modelData.saved, root.passwordText)
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true
                                onEntered: parent.hov = true
                                onExited:  parent.hov = false
                                onClicked: {
                                    if (modelData.connected || root.connectingTo === modelData.ssid) return
                                    let ssid     = modelData.ssid
                                    let saved    = modelData.saved
                                    let secured  = modelData.security !== "" && modelData.security !== "Open"
                                    if (saved || !secured) {
                                        root.doConnect(ssid, saved, "")
                                    } else {
                                        root.selectedSsid = ssid
                                        root.passwordText = ""
                                        root.pwHidden     = true
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.networks.length === 0 && !root.scanning
                        Layout.fillWidth: true; Layout.topMargin: 8; Layout.bottomMargin: 8
                        text: root.fullBrowser ? "No networks found" : "No saved networks"
                        color: Theme.on_surface_variant; font.family: Theme.fontFamily
                        font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter
                    }
            }

            Text {
                visible: !root.wifiEnabled; Layout.fillWidth: true
                text: "WiFi is off"; color: Theme.on_surface_variant
                font.family: Theme.fontFamily; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 1
                visible: root.wifiEnabled && !root.fullBrowser
                color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
            }

            // ── Browse all button ─────────────────────────────────────────────
            Rectangle {
                visible: root.wifiEnabled && !root.fullBrowser
                Layout.fillWidth: true; implicitHeight: 36; radius: 8
                property bool hov: false
                color: hov ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3); border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }
                RowLayout { anchors.centerIn: parent; spacing: 8
                    Text { text: "󰤨"; font.family: "monospace"; font.pixelSize: 14; color: Theme.primary }
                    Text { text: "Browse all networks"; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 13 }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: parent.hov = true; onExited: parent.hov = false
                    onClicked: {
                        root.fullBrowser = true
                        root.networks    = []
                        root.scanning    = true
                        scanProc.running = false; scanProc.running = true
                    }
                }
            }

            Item { implicitHeight: 4 }
        }
    }
}
