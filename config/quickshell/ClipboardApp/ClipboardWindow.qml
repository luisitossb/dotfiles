import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
        target: "clipboard"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open():   void { root.isOpen = true  }
        function close():  void { root.isOpen = false }
    }

    // ── State ─────────────────────────────────────────────────────────────────

    property var    entries:    []
    property string filterText: ""
    property bool   loading:    false

    function refresh() {
        root.loading = true
        clipProc.running = false
        clipProc.running = true
    }

    onIsOpenChanged: {
        if (isOpen) {
            filterText = ""
            refresh()
        }
    }

    Process {
        id: clipProc
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/clipboard-entries.sh"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                root.entries = JSON.parse(this.text.trim())
            } catch(e) { root.entries = [] }
            root.loading = false
        }}
    }

    // ── Filtered model ────────────────────────────────────────────────────────

    property var filteredEntries: {
        if (!filterText) return entries
        let q = filterText.toLowerCase()
        return entries.filter(e => e.preview.toLowerCase().includes(q))
    }

    // ── UI ────────────────────────────────────────────────────────────────────

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            MouseArea {
                anchors.fill: parent
                onClicked: root.isOpen = false
            }
        }

        Rectangle {
            anchors.centerIn: parent
            implicitWidth: 400
            implicitHeight: Math.min(600, headerCol.implicitHeight + listView.contentHeight + 32)
            radius: 16
            color: Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g,
                           Theme.surface_container_low.b, 0.98)
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
            border.width: 1

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                ColumnLayout {
                    id: headerCol
                    Layout.fillWidth: true
                    spacing: 12

                    // Header row
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Text {
                            text: "󰅍"
                            font.family: "monospace"; font.pixelSize: 20
                            color: Theme.primary
                        }
                        Text {
                            text: "Clipboard"
                            color: Theme.on_surface
                            font.family: Theme.fontFamily; font.pixelSize: 17; font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: root.loading ? "Loading…" : (root.entries.length + " items")
                            color: Theme.on_surface_variant
                            font.family: Theme.fontFamily; font.pixelSize: 12
                        }
                        Text {
                            text: "✕"; color: Theme.on_surface_variant
                            font.family: Theme.fontFamily; font.pixelSize: 15
                            MouseArea { anchors.fill: parent; onClicked: root.isOpen = false }
                        }
                    }

                    // Search box
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 36; radius: 8
                        color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g,
                                       Theme.surface_container.b, 0.80)
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 8
                            Text {
                                text: "󰍉"
                                font.family: "monospace"; font.pixelSize: 14
                                color: Theme.on_surface_variant
                            }
                            Item {
                                Layout.fillWidth: true; implicitHeight: 20

                                Text {
                                    anchors.fill: parent
                                    text: "Search clipboard…"
                                    color: Theme.on_surface_variant
                                    font.family: Theme.fontFamily; font.pixelSize: 13
                                    visible: searchBox.text === ""
                                    verticalAlignment: Text.AlignVCenter
                                }

                                TextInput {
                                    id: searchBox
                                    anchors.fill: parent
                                    color: Theme.on_surface
                                    font.family: Theme.fontFamily; font.pixelSize: 13
                                    text: root.filterText
                                    onTextChanged: root.filterText = text
                                    verticalAlignment: TextInput.AlignVCenter

                                    Timer {
                                        id: focusTimer
                                        interval: 80; repeat: false
                                        onTriggered: searchBox.forceActiveFocus()
                                    }

                                    Connections {
                                        target: root
                                        function onIsOpenChanged() {
                                            if (root.isOpen) { searchBox.text = ""; focusTimer.start() }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 1
                        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                    }
                }

                // Entry list
                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: root.filteredEntries

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    Text {
                        anchors.centerIn: parent
                        text: root.loading ? "Loading…" : "No entries"
                        color: Theme.on_surface_variant
                        font.family: Theme.fontFamily; font.pixelSize: 13
                        visible: listView.count === 0
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: listView.width
                        implicitHeight: modelData.is_image ? 64 : 44
                        radius: 8
                        property bool hov: false
                        color: hov ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)
                                   : Qt.rgba(Theme.surface_container.r, Theme.surface_container.g,
                                             Theme.surface_container.b, 0.40)
                        Behavior on color { ColorAnimation { duration: 80 } }

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 10

                            // Image thumbnail or text icon
                            Item {
                                implicitWidth: 40; implicitHeight: 40

                                Image {
                                    anchors.fill: parent
                                    source: modelData.is_image ? ("file://" + modelData.img_path) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: modelData.is_image && status === Image.Ready
                                    layer.enabled: true
                                    layer.effect: null
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.is_image ? "󰋩" : "󰈚"
                                    font.family: "monospace"; font.pixelSize: 18
                                    color: Theme.on_surface_variant
                                    visible: !modelData.is_image
                                }
                            }

                            Text {
                                text: modelData.preview
                                color: Theme.on_surface
                                font.family: Theme.fontFamily; font.pixelSize: 12
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }
                        }

                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onEntered: parent.hov = true
                            onExited:  parent.hov = false
                            onClicked: {
                                let id = modelData.id
                                root.isOpen = false
                                Quickshell.execDetached(["bash", "-c",
                                    "cliphist decode " + id + " | wl-copy"])
                            }
                            onPressAndHold: {
                                // Long-press to delete
                                let id = modelData.id
                                Quickshell.execDetached(["bash", "-c",
                                    "echo '" + id + "' | cliphist delete"])
                                root.refresh()
                            }
                        }
                    }
                }
            }
        }
    }
}
