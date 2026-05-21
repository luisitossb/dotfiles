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
    WlrLayershell.namespace: "qs-app-launcher"
    exclusionMode: WlrLayershell.Ignore
    color: "transparent"

    implicitWidth: 420
    implicitHeight: 400

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
        target: "app-launcher"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open():   void { root.isOpen = true  }
        function close():  void { root.isOpen = false }
    }

    // ── State ─────────────────────────────────────────────────────────────────

    property var    allApps:     []
    property string query:       ""
    property bool   loading:     false
    property int    highlighted: 0
    property string errorMsg:    ""

    function refresh() {
        root.loading = true
        appProc.running = false
        appProc.running = true
    }

    onIsOpenChanged: {
        if (isOpen) {
            query = ""
            highlighted = 0
            refresh()
        }
    }

    Process {
        id: appProc
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/app-list.sh"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                root.allApps  = JSON.parse(this.text.trim())
                root.errorMsg = ""
            } catch(e) {
                let msg = "Failed to parse app list: " + e
                console.warn("launcher: " + msg)
                root.errorMsg = msg
                root.allApps  = []
            }
            root.loading = false
        }}
        stderr: StdioCollector { onStreamFinished: {
            let e = this.text.trim()
            if (e) { console.warn("launcher: " + e); root.errorMsg = e; root.loading = false }
        }}
    }

    property var filteredApps: {
        if (!query) return allApps
        let q = query.toLowerCase()
        return allApps.filter(a =>
            a.name.toLowerCase().includes(q) ||
            a.comment.toLowerCase().includes(q)
        )
    }

    onFilteredAppsChanged: highlighted = 0

    function launch(app) {
        root.isOpen = false
        Quickshell.execDetached(["bash",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/track-usage.sh",
            app.name])
        if (app.terminal) {
            Quickshell.execDetached(["bash", "-c", "kitty -e " + app.exec])
        } else {
            Quickshell.execDetached(["bash", "-c", app.exec + " &"])
        }
    }

    // ── UI ────────────────────────────────────────────────────────────────────

    Item {
        anchors.fill: parent

        // Launcher panel
        Rectangle {
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            width: 380
            color: Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g,
                           Theme.surface_container_low.b, 1.0)
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
            border.width: 1

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                // Header
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    Text {
                        text: "󱗼"
                        font.family: "monospace"; font.pixelSize: 22
                        color: Theme.primary
                    }
                    Text {
                        text: "Applications"
                        color: Theme.on_surface
                        font.family: Theme.fontFamily; font.pixelSize: 17; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.loading ? "…" : (root.filteredApps.length + "")
                        color: Theme.on_surface_variant
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                }

                // Search box
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 40; radius: 10
                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g,
                                   Theme.surface_container.b, 0.80)
                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.30)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 8
                        Text {
                            text: "󰍉"
                            font.family: "monospace"; font.pixelSize: 15
                            color: Theme.on_surface_variant
                        }
                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: Theme.on_surface
                            font.family: Theme.fontFamily; font.pixelSize: 14
                            text: root.query
                            onTextChanged: root.query = text

                            Keys.onUpPressed: {
                                if (root.highlighted > 0) root.highlighted--
                                appList.positionViewAtIndex(root.highlighted, ListView.Contain)
                            }
                            Keys.onDownPressed: {
                                if (root.highlighted < root.filteredApps.length - 1) root.highlighted++
                                appList.positionViewAtIndex(root.highlighted, ListView.Contain)
                            }
                            Keys.onReturnPressed: {
                                if (root.filteredApps.length > 0)
                                    root.launch(root.filteredApps[root.highlighted])
                            }

                            Timer {
                                id: searchFocusTimer
                                interval: 80; repeat: false
                                onTriggered: searchInput.forceActiveFocus()
                            }

                            Connections {
                                target: root
                                function onIsOpenChanged() {
                                    if (root.isOpen) {
                                        searchInput.text = ""
                                        searchFocusTimer.start()
                                    }
                                }
                            }
                        }

                        Text {
                            text: "✕"; color: Theme.on_surface_variant; font.pixelSize: 12
                            visible: root.query !== ""
                            MouseArea { anchors.fill: parent; onClicked: searchInput.text = "" }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 1
                    color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                }

                ErrorBanner { message: root.errorMsg }

                // App list
                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: root.filteredApps

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    Text {
                        anchors.centerIn: parent
                        text: root.loading ? "Loading apps…" : "No results"
                        color: Theme.on_surface_variant
                        font.family: Theme.fontFamily; font.pixelSize: 13
                        visible: appList.count === 0
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: appList.width
                        implicitHeight: 52; radius: 8
                        property bool hov: false
                        property bool isHighlighted: index === root.highlighted

                        color: isHighlighted
                               ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                               : hov
                               ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                               : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 8; spacing: 10

                            // Icon
                            Item {
                                implicitWidth: 36; implicitHeight: 36

                                Image {
                                    anchors.fill: parent
                                    source: modelData.icon ? ("file://" + modelData.icon) : ""
                                    fillMode: Image.PreserveAspectFit
                                    visible: modelData.icon !== "" && status === Image.Ready
                                    smooth: true
                                }

                                Rectangle {
                                    anchors.fill: parent; radius: 8
                                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                    visible: !modelData.icon || parent.children[0].status !== Image.Ready
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name.charAt(0).toUpperCase()
                                        color: Theme.primary
                                        font.family: Theme.fontFamily; font.pixelSize: 16; font.bold: true
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text {
                                    text: modelData.name
                                    color: isHighlighted ? Theme.primary : Theme.on_surface
                                    font.family: Theme.fontFamily; font.pixelSize: 13; font.bold: isHighlighted
                                    Layout.fillWidth: true; elide: Text.ElideRight
                                }
                                Text {
                                    text: modelData.comment
                                    color: Theme.on_surface_variant
                                    font.family: Theme.fontFamily; font.pixelSize: 11
                                    Layout.fillWidth: true; elide: Text.ElideRight
                                    visible: modelData.comment !== ""
                                }
                            }

                            Text {
                                text: modelData.terminal ? "  " : ""
                                font.family: "monospace"; font.pixelSize: 12
                                color: Theme.on_surface_variant
                            }
                        }

                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onEntered: { parent.hov = true; root.highlighted = index }
                            onExited:  parent.hov = false
                            onClicked: root.launch(modelData)
                        }
                    }
                }
            }
        }
    }
}
