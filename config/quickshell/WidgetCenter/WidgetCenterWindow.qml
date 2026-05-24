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
    WlrLayershell.namespace: "qs-widget-center"
    exclusionMode: WlrLayershell.Ignore
    implicitWidth: 340
    color: "transparent"

    anchors { right: true; top: true; bottom: true }
    margins { top: 54; bottom: 20; right: root.slideMargin }

    property bool isOpen: false
    visible: isOpen || slideAnim.running

    property real slideMargin: isOpen ? 12 : -380
    Behavior on slideMargin {
        NumberAnimation { id: slideAnim; duration: 320; easing.type: Easing.OutQuint }
    }

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
        target: "widget-center"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open():   void { root.isOpen = true  }
        function close():  void { root.isOpen = false }
    }

    // ── Reusable components ───────────────────────────────────────────────────

    component Divider: Rectangle {
        Layout.fillWidth: true; implicitHeight: 1
        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
    }

    component RowLabel: Text {
        color: Theme.on_surface
        font.family: Theme.fontFamily; font.pixelSize: 14
        Layout.fillWidth: true
    }

    component WCSwitch: Item {
        id: sw
        property bool checked: false
        property bool ready:   false
        signal toggled()
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 44; implicitHeight: 24

        Rectangle {
            anchors.fill: parent; radius: 12
            color: sw.checked
                   ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 1.0)
                   : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 1.0)
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, sw.checked ? 0 : 0.35)
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                x: sw.checked ? parent.width - width - 3 : 3
                y: 3; implicitWidth: 18; implicitHeight: 18; radius: 9
                color: sw.checked ? Theme.on_primary : Theme.on_surface_variant
                Behavior on x     { NumberAnimation  { duration: 150 } }
                Behavior on color { ColorAnimation   { duration: 150 } }
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: if (sw.ready) sw.toggled()
        }
    }

    component WCSlider: Slider {
        id: sl
        Layout.fillWidth: true
        background: Rectangle {
            x: sl.leftPadding
            y: sl.topPadding + sl.availableHeight / 2 - height / 2
            width: sl.availableWidth; height: 5; radius: 3
            color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g,
                           Theme.surface_container_high.b, 1.0)
            Rectangle {
                width: sl.visualPosition * parent.width
                height: parent.height; radius: 3; color: Theme.primary
            }
        }
        handle: Rectangle {
            x: sl.leftPadding + sl.visualPosition * (sl.availableWidth - width)
            y: sl.topPadding + sl.availableHeight / 2 - height / 2
            implicitWidth: 15; implicitHeight: 15; radius: 8
            color: sl.pressed ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.7)
                              : Theme.primary
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
            border.width: 1
        }
    }

    // ── UI ────────────────────────────────────────────────────────────────────

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent; radius: 16
            color: Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g,
                           Theme.surface_container_low.b, 1.0)
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // ── Profile ───────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true; spacing: 14

                Rectangle {
                    implicitWidth: 48; implicitHeight: 48; radius: 24
                    color: Qt.rgba(Theme.primary_container.r, Theme.primary_container.g,
                                   Theme.primary_container.b, 1.0)
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: "file://" + Quickshell.env("HOME") + "/.face"
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent; text: "󰀄"
                        font.family: "monospace"; font.pixelSize: 26
                        color: Theme.on_primary_container
                        visible: parent.children[0].status !== Image.Ready
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: Quickshell.env("USER"); color: Theme.on_surface
                        font.family: Theme.fontFamily; font.pixelSize: 16; font.bold: true
                    }
                    Text {
                        id: uptimeText; text: "…"
                        color: Theme.on_surface_variant
                        font.family: Theme.fontFamily; font.pixelSize: 11
                        Process {
                            command: ["bash", "-c", "uptime -p | sed 's/up //'"]
                            running: root.isOpen
                            stdout: StdioCollector { onStreamFinished: uptimeText.text = this.text.trim() }
                        }
                    }
                }
            }

            Divider {}

            // ── Scrollable content ────────────────────────────────────────────
            ScrollView {
                id: scrollView
                Layout.fillWidth: true; Layout.fillHeight: true
                contentHeight: col.implicitHeight; clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4; radius: 2; color: Theme.primary
                        opacity: parent.pressed ? 0.9 : parent.active ? 0.6 : 0.3
                    }
                }

                ColumnLayout {
                    id: col
                    width: scrollView.width
                    spacing: 14

                    // ── Volume ────────────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Text {
                            text: volSlider.value === 0 ? "󰝟" : volSlider.value < 30 ? "󰕿" : volSlider.value < 70 ? "󰖀" : "󰕾"
                            font.family: "monospace"; font.pixelSize: 16
                            color: Theme.on_surface_variant; Layout.alignment: Qt.AlignVCenter
                        }
                        WCSlider {
                            id: volSlider; from: 0; to: 100; value: 50
                            Process {
                                command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}'"]
                                running: root.isOpen
                                stdout: StdioCollector { onStreamFinished: {
                                    let v = parseInt(this.text.trim())
                                    if (!isNaN(v)) volSlider.value = v
                                }}
                            }
                            onMoved: Quickshell.execDetached(["bash", "-c",
                                "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.round(value) + "%"])
                        }
                    }

                    // ── Brightness ────────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Text {
                            text: brightSlider.value < 35 ? "󰃞" : brightSlider.value < 70 ? "󰃟" : "󰃠"
                            font.family: "monospace"; font.pixelSize: 16
                            color: Theme.on_surface_variant; Layout.alignment: Qt.AlignVCenter
                        }
                        WCSlider {
                            id: brightSlider; from: 10; to: 100; value: 100
                            Process {
                                command: ["bash", "-c", "brightnessctl -m | awk -F, '{gsub(\"%\",\"\",$4); print $4}'"]
                                running: root.isOpen
                                stdout: StdioCollector { onStreamFinished: {
                                    let v = parseInt(this.text.trim())
                                    if (!isNaN(v)) brightSlider.value = Math.max(10, v)
                                }}
                            }
                            onMoved: Quickshell.execDetached(["bash", "-c",
                                "brightnessctl set " + Math.round(value) + "%"])
                        }
                    }

                    Divider {}

                    // ── UI toggles ────────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        RowLabel { text: "Waybar" }
                        WCSwitch {
                            id: waybarSw
                            Process {
                                command: ["bash", "-c", "test -f ~/.config/quickshell/state/waybar-disabled && echo 0 || echo 1"]
                                running: root.isOpen
                                stdout: StdioCollector { onStreamFinished: {
                                    waybarSw.checked = this.text.trim() === "1"; waybarSw.ready = true
                                }}
                            }
                            onToggled: {
                                Quickshell.execDetached(["bash", "-c",
                                    (checked ? "touch" : "rm -f") + " ~/.config/quickshell/state/waybar-disabled;" +
                                    Quickshell.env("HOME") + "/.config/waybar/launch.sh"])
                                checked = !checked
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        RowLabel { text: "Dock" }
                        WCSwitch {
                            id: dockSw
                            Process {
                                command: ["bash", "-c", "test -f ~/.config/quickshell/state/dock-disabled && echo 0 || echo 1"]
                                running: root.isOpen
                                stdout: StdioCollector { onStreamFinished: {
                                    dockSw.checked = this.text.trim() === "1"; dockSw.ready = true
                                }}
                            }
                            onToggled: {
                                Quickshell.execDetached(["bash", "-c",
                                    (checked ? "touch" : "rm -f") + " ~/.config/quickshell/state/dock-disabled;" +
                                    Quickshell.env("HOME") + "/.config/nwg-dock-hyprland/launch.sh"])
                                checked = !checked
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        RowLabel { text: "Gamemode" }
                        WCSwitch {
                            id: gamemodeSw
                            Process {
                                command: ["bash", "-c", "test -f ~/.config/quickshell/state/gamemode-enabled && echo 1 || echo 0"]
                                running: root.isOpen
                                stdout: StdioCollector { onStreamFinished: {
                                    gamemodeSw.checked = this.text.trim() === "1"; gamemodeSw.ready = true
                                }}
                            }
                            onToggled: {
                                Quickshell.execDetached(["bash", "-c",
                                    Quickshell.env("HOME") + "/.config/hypr/scripts/gamemode.sh"])
                                checked = !checked
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        RowLabel { text: "Fastfetch" }
                        WCSwitch {
                            id: fastfetchSw
                            Process {
                                command: ["bash", "-c", "test -f ~/.config/quickshell/state/hide-fastfetch && echo 0 || echo 1"]
                                running: root.isOpen
                                stdout: StdioCollector { onStreamFinished: {
                                    fastfetchSw.checked = this.text.trim() === "1"; fastfetchSw.ready = true
                                }}
                            }
                            onToggled: {
                                Quickshell.execDetached(["bash", "-c",
                                    "f=~/.config/quickshell/state/hide-fastfetch; [ -f \"$f\" ] && rm \"$f\" || touch \"$f\""])
                                checked = !checked
                            }
                        }
                    }

                    Divider {}

                    // ── Launch buttons ────────────────────────────────────────
                    Repeater {
                        model: [
                            { label: "Wallpaper", icon: "󰋩", cmd: "qs ipc call wallpaper toggle" },
                            { label: "Theme",     icon: "󰸌", cmd: Quickshell.env("HOME") + "/.config/quickshell/scripts/qs-themes.sh" }
                        ]
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            RowLabel { text: modelData.label }
                            Text {
                                text: modelData.icon; font.family: "monospace"; font.pixelSize: 18
                                color: Theme.on_surface_variant
                                MouseArea { anchors.fill: parent; onClicked: {
                                    root.isOpen = false
                                    Quickshell.execDetached(["bash", "-c", modelData.cmd])
                                }}
                            }
                        }
                    }

                    Item { implicitHeight: 4 }
                }
            }
        }
    }
}
