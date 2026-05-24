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
    WlrLayershell.namespace: "qs-settings-app"
    exclusionMode: WlrLayershell.Ignore
    implicitWidth: 720
    implicitHeight: 520
    color: "transparent"

    property bool isOpen: false
    property real panelOpacity: isOpen ? 1.0 : 0.0
    property real panelScale:   isOpen ? 1.0 : 0.95

    Behavior on panelOpacity { NumberAnimation { id: fadeAnim; duration: 250; easing.type: Easing.OutQuint } }
    Behavior on panelScale   { NumberAnimation {               duration: 250; easing.type: Easing.OutQuint } }

    visible: isOpen || fadeAnim.running

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
        target: "settings-app"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open():   void { root.isOpen = true  }
        function close():  void { root.isOpen = false }
    }

    property int selectedCategory: 0

    readonly property var categories: [
        { name: "Appearance",    icon: "󰸌", sections: ["Theme", "Wallpaper", "Fonts"] },
        { name: "Input",         icon: "󰍽", sections: ["Mouse", "Trackpad", "Keyboard"] },
        { name: "Audio & Display", icon: "󰕾", sections: ["Volume", "Brightness", "Night Mode"] },
        { name: "System & Apps", icon: "󰮤", sections: ["Startup Apps", "Power", "About"] }
    ]

    // ── Root container ────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        opacity: root.panelOpacity

        transform: Scale {
            origin.x: root.implicitWidth  / 2
            origin.y: root.implicitHeight / 2
            xScale: root.panelScale
            yScale: root.panelScale
        }

        // Window background
        Rectangle {
            anchors.fill: parent; radius: 16
            color: Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g,
                           Theme.surface_container_low.b, 1.0)
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
            border.width: 1
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── Left nav sidebar ──────────────────────────────────────────────
            Item {
                Layout.preferredWidth: 200
                Layout.fillHeight: true

                Rectangle {
                    anchors.fill: parent; radius: 16
                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g,
                                   Theme.surface_container.b, 1.0)
                    // Square off the right-side corners
                    Rectangle {
                        anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
                        width: 16
                        color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g,
                                       Theme.surface_container.b, 1.0)
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 4

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 10
                        spacing: 8
                        Text {
                            text: "󰒓"
                            font.family: "monospace"; font.pixelSize: 18
                            color: Theme.primary
                        }
                        Text {
                            text: "Settings"
                            color: Theme.on_surface
                            font.family: Theme.fontFamily
                            font.pixelSize: 16; font.bold: true
                        }
                    }

                    // Category nav items
                    Repeater {
                        model: root.categories
                        delegate: Item {
                            id: navItem
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            implicitHeight: 42

                            property bool isSelected: root.selectedCategory === index

                            Rectangle {
                                anchors.fill: parent; radius: 10
                                color: navItem.isSelected
                                    ? Qt.rgba(Theme.primary_container.r, Theme.primary_container.g,
                                              Theme.primary_container.b, 1.0)
                                    : navHov.containsMouse
                                        ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g,
                                                  Theme.surface_container_high.b, 1.0)
                                        : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12; anchors.rightMargin: 12
                                spacing: 10
                                Text {
                                    text: navItem.modelData.icon
                                    font.family: "monospace"; font.pixelSize: 16
                                    color: navItem.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                                Text {
                                    text: navItem.modelData.name
                                    color: navItem.isSelected ? Theme.on_primary_container : Theme.on_surface
                                    font.family: Theme.fontFamily; font.pixelSize: 13
                                    Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                            }

                            MouseArea {
                                id: navHov; anchors.fill: parent; hoverEnabled: true
                                onClicked: root.selectedCategory = navItem.index
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Close button
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 36

                        Rectangle {
                            anchors.fill: parent; radius: 10
                            color: closeHov.containsMouse
                                ? Qt.rgba(Theme.error_container.r, Theme.error_container.g,
                                          Theme.error_container.b, 0.4)
                                : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12; anchors.rightMargin: 12
                            spacing: 10
                            Text {
                                text: "󰅗"
                                font.family: "monospace"; font.pixelSize: 14
                                color: Theme.error
                            }
                            Text {
                                text: "Close"
                                color: Theme.on_surface_variant
                                font.family: Theme.fontFamily; font.pixelSize: 13
                            }
                        }
                        MouseArea {
                            id: closeHov; anchors.fill: parent; hoverEnabled: true
                            onClicked: root.isOpen = false
                        }
                    }
                }
            }

            // ── Content area ──────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    anchors.leftMargin: 20
                    spacing: 16

                    // Category title
                    Text {
                        text: root.categories[root.selectedCategory].name
                        color: Theme.on_surface
                        font.family: Theme.fontFamily
                        font.pixelSize: 20; font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 1
                        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                    }

                    // Settings cards (placeholder)
                    ScrollView {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        contentHeight: cardsCol.implicitHeight; clip: true

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle {
                                implicitWidth: 4; radius: 2; color: Theme.primary
                                opacity: parent.pressed ? 0.9 : parent.active ? 0.6 : 0.3
                            }
                        }

                        ColumnLayout {
                            id: cardsCol
                            width: parent.width - 8
                            spacing: 10

                            Repeater {
                                model: root.categories[root.selectedCategory].sections
                                delegate: Rectangle {
                                    required property string modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 60
                                    radius: 12
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g,
                                                   Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g,
                                                          Theme.outline_variant.b, 0.2)
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 3
                                        Text {
                                            text: modelData
                                            color: Theme.on_surface
                                            font.family: Theme.fontFamily; font.pixelSize: 14
                                        }
                                        Text {
                                            text: "Coming soon..."
                                            color: Theme.on_surface_variant
                                            font.family: Theme.fontFamily; font.pixelSize: 11
                                        }
                                    }
                                }
                            }

                            Item { implicitHeight: 4 }
                        }
                    }
                }
            }
        }
    }
}
